extends Node2D

var width = 1280
var height = 720
var iterations = 512
var bounds = Rect2(-1, 0, 6.4, 3.6)
var points = []
var reached_nan = []
var img = Image.new()
var threads = []
var next_texture = null
# monitor your PC's CPU usage when adjusting this value. If you add enough
# threads for CPU usage to hit 100%, you'll lock up pretty badly. 4 threads
# keeps it at around 80% usage for me, which is okay.
var thread_count = 4
var tex = ImageTexture.new()
var threads_need_to_stop = false
var threads_need_to_pause = false
var current_iteration = 0
var screenshot_semaphore = Semaphore.new()

func _exit_tree():
	cleanup()

func screen_space_to_set_space(pos: Vector2):
	pos.x = clamp(pos.x, 0, width)
	pos.y = clamp(pos.y, 0, height)
	var final_pos = pos
	final_pos = final_pos / Vector2(width, height)
	final_pos *= bounds.size
	final_pos += bounds.position - bounds.size / 2
	return final_pos


func startup():
	tex.create_from_image(img)
	$Sprite.texture = tex
	for x in range(width):
		for y in range(height):
			var point = Vector2.ZERO
			points.push_back(point)
			reached_nan.push_back(-1)
	threads_need_to_stop = false
	for i in thread_count:
		screenshot_semaphore.post()
		var thread = Thread.new()
		threads.push_back(thread)
		thread.start(self, "do_iterations", [i, thread_count])


func _ready():
	img.create(width, height, false, Image.FORMAT_RGBA8)
	img.lock()
	startup()


func cleanup():
	threads_need_to_stop = true
	for thread in threads:
		thread.wait_to_finish()
	threads.clear()
	points.clear()
	reached_nan.clear()
	

func to_color(num):
	num *= 5
	var num_sign = int(num)/256
	if num_sign %2 == 0:
		return Color8(num%256, num%256, 100)
	else:
		return Color8(256 - num%256, 256 - num%256, 100)

func draw_row(y, iteration_number):
	for i in range(width * y, width * y + width):
		var value = points[i]
		var screen_point = Vector2(i%width, i / width)
		var set_point = screen_space_to_set_space(screen_point)
		if reached_nan[i] >= 0:
			img.set_pixel(screen_point.x, screen_point.y, to_color(reached_nan[i]))
			continue
		value = complex_multiply(value, value)
		value += set_point
		if value.length_squared() >= 4 or is_nan(value.x) or is_nan(value.y):
			reached_nan[i] = iteration_number
		points[i] = value
		#img.set_pixel(screen_point.x, screen_point.y, Color.black)
		img.set_pixel(screen_point.x, screen_point.y, Color(value.x, value.y, 0))
	

# Multiplies two vectors together, treating the y component as the imaginary
# component of a complex number
#
# For example, passing (3,4) and (5,8) gets treated as (3+4i) * (5+8i)
# which works out to 
# 15 + 24i + 20i + 32i^2
# = 15 +44i - 32
# = -17 + 44i
#
# The return value is (-17, 44)                  
func complex_multiply(first: Vector2, second:Vector2) -> Vector2:
	var res = Vector2.ZERO
	var x_1 = first.x
	var x_2 = second.x
	var y_1 = first.y
	var y_2 = second.y
	
	# First, Outside, Inside, Last
	var f = x_1 * x_2
	var o = x_1 * y_2
	var i = x_2 * y_1
	var l = y_1 * y_2
	
	res.x = f - l #L's sign is flipped because it's the square of an imaginary number
	res.y = o + i
	return res


func _process(delta):
	var mouse_pos = get_global_mouse_position()
	mouse_pos.x = clamp(int(mouse_pos.x), 0, width - 1)
	mouse_pos.y = clamp(int(mouse_pos.y), 0, height - 1)
	
	var mouse_set_pos = screen_space_to_set_space(mouse_pos)
	var point_index = mouse_pos.y * width + mouse_pos.x
	var value_at_mouse = points[point_index]
	var nan_track = reached_nan[point_index]
	var message = "Position: %s  Value: %s Reached NaN at iteration %s" % [mouse_set_pos, value_at_mouse, nan_track]
	$UILayer/UI/TopBar/Label.text = message
	$UILayer/UI/BottomBar/Label.text = "Current iteration: %s Focus: %s" % [current_iteration, bounds]
	tex.create_from_image(img)
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		bounds.size /= 8
		bounds.position = mouse_set_pos
		cleanup()
		startup()


func _input(event):
	if event.is_action_pressed("screenshot"):
		handle_screenshot()


func handle_screenshot():
	print("attempting to screenshot!")
	var thread_index = 0
	for thread in threads:
		print("trying to grab all sempahores %s" % thread_index)
		thread_index += 1
		screenshot_semaphore.wait()
	print("got them all.")
	print("saving screenshot")
	img.save_png("res://screenshot.png")
	OS.delay_msec(500)
	print("done")
	thread_index = 0
	print("releasing all semaphores")
	for thread in threads:
		print(thread_index)
		thread_index += 1
		
		screenshot_semaphore.post()
	print("done")


func do_iterations(params):
	var starting = params[0]
	var ending = height
	var jump = params[1]

	for iteration in range(iterations):
		screenshot_semaphore.wait()
		if starting == 0:
			for thread in threads:
				screenshot_semaphore.post()
		if starting == 0:
			current_iteration = iteration
		if threads_need_to_stop:
			return
		if threads_need_to_pause:
			pass
		for y in range(starting, ending, jump):
			draw_row(y, iteration)
		
		
			
