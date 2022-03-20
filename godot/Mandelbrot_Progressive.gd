extends Node2D

var width = 1920
var height = 1080
#var iterations = 512
var bounds = Rect2(-1, 0, width/100, height/100)

# Previous number of iterations to store to test for perioodicity.
# Memory usage is 64 bits * max_periodicity * width * height.
var max_periodicity_tests = 15
var points = []
var in_set = []

# used for detecting cycles
var tortoise = []
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
var screenshot_mutex = Mutex.new()

func _exit_tree():
	print("shutting down...")
	cleanup()
	print("goodbye")

func screen_space_to_set_space(pos: Vector2):
	pos.x = clamp(pos.x, 0, width)
	pos.y = clamp(pos.y, 0, height)
	var final_pos = pos
	final_pos = final_pos / Vector2(width, height)
	final_pos *= bounds.size
	final_pos += bounds.position - bounds.size / 2
	return final_pos


func startup():
	print("starting up...")
	tex.create_from_image(img)
	$Sprite.texture = tex
	#var blank_iteration = []
	for x in range(width):
		for y in range(height):
			var point = Vector2.ZERO
			points.push_back(point)
			#blank_iteration.push_back(Vector2.INF)
			reached_nan.push_back(-1)
			in_set.push_back(false)

	tortoise = points.duplicate(true)
	threads_need_to_stop = false
	for i in thread_count:
		var thread = Thread.new()
		threads.push_back(thread)
		thread.start(self, "do_iterations", [i, thread_count])


func _ready():
	img.create(width, height, false, Image.FORMAT_RGBA8)
	img.lock()
	startup()


func cleanup():
	print("Stopping threads...")
	threads_need_to_stop = true
	for thread in threads:
		thread.wait_to_finish()
	print("Clearing arrays...")
	threads.clear()
	points.clear()
	reached_nan.clear()
	tortoise.clear()
	in_set.clear()
	

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
		
		if in_set[i]:
			img.set_pixel(screen_point.x, screen_point.y, Color.black)
			continue
		
		value = complex_multiply(value, value)
		value += set_point
		
		if iteration_number%2 == 1:
			var tort = tortoise[i]
			tort = complex_multiply(tort, tort)
			tort += set_point
			tortoise[i] = tort

		#print(str(value) + " =? " + str(tortoise[i]))
		if value == tortoise[i]:
			in_set[i] = true
			img.set_pixel(screen_point.x, screen_point.y, Color.black)
			continue

		
		if value.length_squared() >= 4 or is_nan(value.x) or is_nan(value.y):
			reached_nan[i] = iteration_number
		points[i] = value
		
		#img.set_pixel(screen_point.x, screen_point.y, Color.black)
		img.set_pixel(screen_point.x, screen_point.y, Color((value.x + 2) / 4, (value.y + 2) / 4, 0))


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
	screenshot_mutex.lock()
	OS.delay_msec(500)
	img.save_png("res://screenshot.png")
	screenshot_mutex.unlock()

func do_iterations(params):
	var starting = params[0]
	var ending = height
	var jump = params[1]

	var iteration = 0
	while true:
		screenshot_mutex.lock()
		screenshot_mutex.unlock()
		if starting == 0:
			current_iteration = iteration
		if threads_need_to_stop:
			return
		if threads_need_to_pause:
			pass
		for y in range(starting, ending, jump):
			draw_row(y, iteration)
		iteration += 1
		
			
