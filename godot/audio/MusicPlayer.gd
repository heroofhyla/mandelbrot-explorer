# Specialized audio player designed for handling music rather than sound
# effects. Automatically fades out the currently-playing track when a new one
# is queued.

class_name MusicPlayer
extends AudioPoolPlayer

export var fadeout_time := 2.0

var tween: Tween = null
var now_playing = null


func _ready():
	tween = Tween.new()
	add_child(tween)
	for player in players:
		player.set_meta("stopping", false)
		player.connect("finished", self, "_player_finished", [player])
	tween.connect("tween_completed", self, "_tween_completed")


func _player_finished(player: AudioStreamPlayer):
	if players[last_player_id] == player:
		now_playing = null


func _tween_completed(player, _key):
	if not player is AudioStreamPlayer:
		return
	
	if is_equal_approx(player.volume_db, audible_threshold):
		player.playing = false


func play(track:AudioStream, fade_out_time:=self.fadeout_time):
	now_playing = track
	stop()
	tween.remove(players[next_player_id])
	players[next_player_id].volume_db = linear2db_with_offset(volume_linear)
	players[next_player_id].set_meta("stopping", false)
	.play(track)


func set_volume_linear(new_volume: float):
	volume_linear = clamp(new_volume,0,1)
	for player in players:
		if not player.get_meta("stopping"):
			player.volume_db = linear2db_with_offset(new_volume)


func stop(fadeout_time:=self.fadeout_time):
	var player_to_stop = players[last_player_id]
	player_to_stop.set_meta("stopping", true)
	tween.interpolate_property(
		player_to_stop, "volume_db", 
		player_to_stop.volume_db, 
		linear2db_with_offset(0), 
		fadeout_time
	)
	tween.start()


func serialize_slot():
	return {
		"now_playing": now_playing
	}


func load_slot(data: Dictionary):
	if data.now_playing != null:
		play(data.now_playing)
