extends Node2D

var width = 1000
var height = 1000
var iterations = 255
var bounds = Rect2(-1, 0, 4, 4)
var points = []
var reached_nan = []
var img = Image.new()
var threads = []
var next_texture = null
var thread_count = 6
var tex = ImageTexture.new()
var threads_need_to_stop = false
var current_iteration = 0

func _exit_tree():
	cleanup()

func screen_space_to_set_space(pos: Vector2):
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
	

func draw_row(y, iteration_number):
	for i in range(width * y, width * y + width):
		var value = points[i]
		var screen_point = Vector2(i%width, i / width)
		var set_point = screen_space_to_set_space(screen_point)
		if is_nan(value.x) or is_nan(value.y):
			img.set_pixel(screen_point.x, screen_point.y, Color8(0,0,reached_nan[i]))
			continue
		value = complex_multiply(value, value)
		value += set_point
		if is_nan(value.x) or is_nan(value.y):
			reached_nan[i] = iteration_number
		points[i] = value
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

func do_iterations(params):
	var starting = params[0]
	var ending = height
	var jump = params[1]

	for iteration in range(iterations):
		if starting == 0:
			current_iteration = iteration
		if threads_need_to_stop:
			return
		for y in range(starting, ending, jump):
			draw_row(y, iteration)
		
			
