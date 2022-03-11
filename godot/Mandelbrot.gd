extends Node2D

var width = 900
var height = 900
var loading = false
var repetitions = 5
var side_cells = 10

func _ready():
	draw_fractal(30)


func draw_fractal(reps: int):
	var img = Image.new()
	img.create(width, height, false, Image.FORMAT_RGBA8)
	img.lock()
	for x in range(width):
		for y in range(height):
			var scaled_x = float(x)/width - 0.5
			var scaled_y = float(y)/height - 0.5
			var res = test_mandelbrot(scaled_x, scaled_y, reps)
			img.set_pixel(x, y, Color(res.x, res.y, 0))
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	$Sprite.texture = tex
	pass

func test_mandelbrot(x, y, reps) -> Vector2:
	var value = Vector2.ZERO
	for k in range(reps):
		value += Vector2(x,y)
		value = complex_multiply(value, value)
		
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

func _input(event):
	if loading: 
		return
	if event.is_action_pressed("ui_up"):
		repetitions += 1
		draw_fractal(repetitions)
	elif event.is_action_pressed("ui_down"):
		repetitions -= 1
		draw_fractal(repetitions)
