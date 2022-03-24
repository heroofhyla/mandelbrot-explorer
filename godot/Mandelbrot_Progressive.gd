extends Node2D

# CONFIGURATION OPTIONS, adjust these as needed

# The resolution here is for the actual texture that the set is being rendered
# to. Bigger textures will result in higher quality screenshot exports, but will
# have much slower iteration time.
# Be sure to match the aspect ratio of the window resolution specified in
# Project Settings -> Window, or the renders will appear squashed.
var width = 1280
var height = 720

# The ideal thread count will be based on your CPU's capabilities. Monitor your
# system resources and find a thread count that allows for high CPU usage
# without clobbering the rest of your system.
var thread_count = 4

# This directory is relative to the game's executable.
var screenshot_directory = "screenshots"

# Initial rendering bounds on the set. Note that the position is centered, not
# at the top-left. The height is automatically calculated based on the given
# width and the aspect ratio.
var bounds_x = -1.0
var bounds_y = 0.0
var bounds_width = 6.0

# INTERNAL VARIABLES, not meant to be manually adjusted
var bounds_height = bounds_width / width * height
var window_width = 1280
var window_height = 720

# Using separate x and y arrays for better precision than Vector2
var points_x = []
var points_y = []
var in_set = []
var row_all_clear = []
var tortoise_x = []
var tortoise_y = []
var reached_nan = []
var current_iteration = 0
var img = Image.new()
var tex = ImageTexture.new()
var screenshot_mutex = Mutex.new()
var threads = []
var threads_need_to_stop = false

func _exit_tree():
	print("shutting down...")
	cleanup()
	print("goodbye")


func texture_space_to_set_space(pos_x:float, pos_y:float) -> Array:
	pos_x = clamp(pos_x, 0, width)
	pos_y = clamp(pos_y, 0, height)
	pos_x /= width
	pos_y /= height
	pos_x *= bounds_width
	pos_y *= bounds_height
	pos_x += bounds_x - bounds_width / 2
	pos_y += bounds_y - bounds_height / 2
	return [pos_x, pos_y]


func window_space_to_set_space(pos_x:float, pos_y:float) -> Array:
	pos_x = clamp(pos_x, 0, window_width)
	pos_y = clamp(pos_y, 0, window_height)
	pos_x /= window_width
	pos_y /= window_height
	pos_x *= bounds_width
	pos_y *= bounds_height
	pos_x += bounds_x - bounds_width / 2
	pos_y += bounds_y - bounds_height / 2
	return [pos_x, pos_y]


func window_space_to_texture_space(pos_x:float, pos_y:float) -> Array:
	pos_x = clamp(pos_x, 0, window_width)
	pos_y = clamp(pos_y, 0, window_height)
	pos_x /= window_width
	pos_y /= window_height
	pos_x *= width
	pos_y *= height
	return[int(pos_x), int(pos_y)]


func startup():
	print("starting up...")
	tex.create_from_image(img)
	$UILayer/Sprite.texture = tex
	
	for x in range(width):
		for y in range(height):
			points_x.push_back(0)
			points_y.push_back(0)
			tortoise_x.push_back(0)
			tortoise_y.push_back(0)
			reached_nan.push_back(-1)
			in_set.push_back(false)
	
	for y in range(height):
		row_all_clear.push_back(false)
		
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
	points_x.clear()
	points_y.clear()
	reached_nan.clear()
	tortoise_x.clear()
	tortoise_y.clear()
	in_set.clear()
	row_all_clear.clear()


func to_color(num):
	num *= 5
	var num_sign = int(num)/256
	
	if num_sign %2 == 0:
		return Color8(num%256, num%256, 100)
	else:
		return Color8(256 - num%256, 256 - num%256, 100)


func draw_row(y, iteration_number):
	var all_clear = true
	
	for i in range(width * y, width * y + width):
		var val_x = points_x[i]
		var val_y = points_y[i]
		var texture_x = i%width
		var texture_y = i / width
		
		var set_point = texture_space_to_set_space(texture_x, texture_y)
		var set_point_x = set_point[0]
		var set_point_y = set_point[1]

		if reached_nan[i] >= 0:
			img.set_pixel(texture_x, texture_y, to_color(reached_nan[i]))
			continue
		
		if in_set[i]:
			img.set_pixel(texture_x, texture_y, Color.black)
			continue
		
		var value = complex_multiply(val_x, val_y, val_x, val_y)
		val_x = value[0]
		val_y = value[1]
		val_x += set_point_x
		val_y += set_point_y
		
		if iteration_number%2 == 1:
			var tort_x = tortoise_x[i]
			var tort_y = tortoise_y[i]
			var tort = complex_multiply(tort_x, tort_y, tort_x, tort_y)
			tort_x = tort[0]
			tort_y = tort[1]
			tort_x += set_point_x
			tort_y += set_point_y
			
			tortoise_x[i] = tort_x
			tortoise_y[i] = tort_y

		if val_x == tortoise_x[i] and val_y == tortoise_y[i]:
			in_set[i] = true
			img.set_pixel(texture_x, texture_y, Color.black)
			continue
		
		if val_x * val_x + val_y * val_y >= 4:
			reached_nan[i] = iteration_number
		
		points_x[i] = val_x
		points_y[i] = val_y
		
		img.set_pixel(texture_x, texture_y, Color((val_x + 2) / 4, (val_y + 2) / 4, 0))
		all_clear = false
	
	return all_clear

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
func complex_multiply(x_1: float, y_1: float, x_2: float, y_2: float) -> Array:
	var res = Vector2.ZERO
	
	# First, Outside, Inside, Last
	var f = x_1 * x_2
	var o = x_1 * y_2
	var i = x_2 * y_1
	var l = y_1 * y_2
	
	return [f-l, o+i]


func _process(delta):
	window_width = get_viewport_rect().size.x
	window_height = get_viewport_rect().size.y
	var mouse_pos = get_global_mouse_position()
	mouse_pos.x = clamp(int(mouse_pos.x), 0, width - 1)
	mouse_pos.y = clamp(int(mouse_pos.y), 0, height - 1)
	var mouse_set_pos = window_space_to_set_space(mouse_pos.x, mouse_pos.y)
	var mouse_set_x = mouse_set_pos[0]
	var mouse_set_y = mouse_set_pos[1]
	var mouse_texture_pos = window_space_to_texture_space(mouse_pos.x, mouse_pos.y)
	var mouse_texture_x = mouse_texture_pos[0]
	var mouse_texture_y = mouse_texture_pos[1]
	var point_index = mouse_texture_y * width + mouse_texture_x
	var mouse_val_x = points_x[point_index]
	var mouse_val_y = points_y[point_index]
	var nan_track = reached_nan[point_index]
	var message = "Position: (%.16f,%.16f)  Value: (%.16f,%.16f)   Out of set at iteration %s" % [mouse_set_x, mouse_set_y, mouse_val_x, mouse_val_y, nan_track]
	$UILayer/UI/TopBar/MarginContainer/Label.text = message
	$UILayer/UI/BottomBar/MarginContainer/Label.text = "Current iteration: %s   Center: (%.16f, %.16f)  Size: %.16f by %.16f" % [current_iteration, bounds_x, bounds_y, bounds_width, bounds_height]
	tex.create_from_image(img)
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		bounds_width /= 8
		bounds_height /= 8
		bounds_x = mouse_set_x
		bounds_y = mouse_set_y
		cleanup()
		startup()


func _input(event):
	if event.is_action_pressed("screenshot"):
		handle_screenshot()


func handle_screenshot():
	var dir = Directory.new()
	dir.open(OS.get_executable_path().get_base_dir())
	
	if not dir.dir_exists(screenshot_directory):
		dir.make_dir(screenshot_directory)
	
	print("attempting to screenshot!")
	var fname = "%s/screenshot-%.16f-%.16f-%.16f-%.16f-%s.png" % [screenshot_directory, bounds_x, bounds_y, bounds_width, bounds_height, current_iteration]
	img.save_png(fname)


func do_iterations(params):
	var starting = params[0]
	var ending = height
	var jump = params[1]
	var iteration = 0
	
	while true:
		var all_rows_done = true
		screenshot_mutex.lock()
		screenshot_mutex.unlock()
		
		if starting == 0:
			current_iteration = iteration
		
		if threads_need_to_stop:
			return
		
		for y in range(starting, ending, jump):
			if row_all_clear[y]:
				continue
			
			var all_clear = draw_row(y, iteration)
			
			if all_clear:
				row_all_clear[y] = true
			else:
				all_rows_done = false
		
		if all_rows_done:
			return
		
		iteration += 1
