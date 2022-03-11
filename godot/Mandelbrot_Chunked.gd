extends Node2D

var width = 900
var height = 900
var loading = false
var repetitions = 5000
var side_cells = 30
var chunks = []
var chunk_width = width / side_cells
var threads = []
var max_threads = 4
#var bounds = Rect2(-1.339111, -0.051103,0.00025,0.00025)
var bounds = Rect2(-1.339111, -0.051103,0.00025 * 2,0.00025 * 2)
func _ready():
	for i in range(max_threads):
		threads.push_back({
			thread = Thread.new(),
			queue = []
		})
	
	for chunk_x in side_cells:
		for chunk_y in side_cells:
			chunks.push_back(Rect2(chunk_width * chunk_x, chunk_width * chunk_y, chunk_width, chunk_width))
	print(len(chunks))
	
	var i = 0
	for chunk in chunks:
		threads[i].queue.push_back(chunk)
		i+=1
		i %= len(threads)
		
	
	for thread in threads:
		thread.thread.start(self, "create_all_chunks", thread.queue)


func _exit_tree():
	for thread in threads:
		thread.wait_to_finish()

func create_all_chunks(chunk_queue):
	for chunk in chunk_queue:
		create_chunk(chunk)


func create_chunk(this_chunk):
	print("drawing chunk " + str(this_chunk))
	var img = Image.new()
	img.create(chunk_width, chunk_width, false, Image.FORMAT_RGBA8)
	img.lock()
	var tex = draw_chunk(img, repetitions, this_chunk)
	var sprite = Sprite.new()
	sprite.centered = false
	sprite.texture = tex
	add_child(sprite)
	sprite.position = this_chunk.position

func draw_chunk(img: Image, reps: int, chunk: Rect2):
	for global_x in range(chunk.position.x, chunk.position.x + chunk.size.x):
		for global_y in range(chunk.position.y, chunk.position.y + chunk.size.y):
			var scaled_x = (float(global_x)/width) * bounds.size.x + bounds.position.x - bounds.size.x / 2
			var scaled_y = (float(global_y)/height) * bounds.size.y + bounds.position.y - bounds.size.y / 2
			var draw_x = global_x - chunk.position.x
			var draw_y = global_y - chunk.position.y
			var res = draw_mandelbrot(scaled_x, scaled_y, reps)
			if res == Vector2(2,2):
				img.set_pixel(draw_x, draw_y, Color(1,1,1))
			else:
				img.set_pixel(draw_x, draw_y, Color(res.x, res.y, 0))
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex


func draw_mandelbrot(x, y, reps) -> Vector2:
	var value = Vector2.ZERO
	for k in range(reps):
		value = complex_multiply(value, value)
		value += Vector2(x,y)
		if value.length_squared() >= 4:
			return Vector2(2,2)
		if value == Vector2.ZERO:
			return Vector2(2,2)
	value.x = abs(value.x)
	value.y = abs(value.y)
	return value

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
	mouse_pos = mouse_pos / Vector2(width, height)
	mouse_pos *= bounds.size
	mouse_pos += bounds.position - bounds.size / 2
	$CanvasLayer/Label.text = str(mouse_pos)
