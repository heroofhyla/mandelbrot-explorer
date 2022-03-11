# Extends AudioPoolPlayer with the ability to give tracks randomized pitch
# shifting. Useful for keeping sound effects from sounding repetitive.
extends AudioPoolPlayer

var rng := RandomNumberGenerator.new()


func _ready():
	rng.randomize()


func play(stream: AudioStream, randomize_pitch := false):
	if randomize_pitch:
		stream.pitch_scale = rng.randf_range(0.9,1.1)
	else:
		stream.pitch_scale = 1.0
	.play(stream)
