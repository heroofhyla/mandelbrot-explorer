# Maintains a pool of AudioStreamPlayer instances allowing for simultaneous
# playback of multiple audio files.

class_name AudioPoolPlayer
extends Node

export (int) var player_count := 10
export (float) var volume_linear := 1.00 setget set_volume_linear

const volume_offset_db := -7.0
const audible_threshold := -80

var players = []
var next_player_id := 0
var last_player_id := 0
var full_path = str(get_path()) + "/" + name
var audio_persist = null

func _ready():
	last_player_id = player_count - 1
	for i in range(player_count):
		var player := AudioStreamPlayer.new() 
		player.name = "Player " + str(i)
		player.volume_db = linear2db_with_offset(volume_linear)
		add_child(player)
		players.push_back(player)


func set_volume_linear(new_volume):
	volume_linear = clamp(new_volume,0,1)
	Persistence.global_save_data.audio[full_path].volume_linear = volume_linear
	for player in players:
		player.volume_db = linear2db_with_offset(new_volume)


func linear2db_with_offset(linear):
	return max(audible_threshold, linear2db(linear) + volume_offset_db)


func play(stream: AudioStream):
	players[next_player_id].stream = stream

	players[next_player_id].play()
	last_player_id = next_player_id
	next_player_id += 1
	next_player_id %= player_count


func serialize_global():
	return {
		"volume_linear": volume_linear
	}


func load_global(data: Dictionary):
	self.set_volume_linear(data.volume_linear)
