extends Node2D

const songs = [ 
	"res://example/music/caravan.ogg",
	"res://example/music/the_field_of_dreams.ogg"
]

var current_song = 0


func _on_NextSong_pressed():
	$MusicPlayer.play(songs[current_song])
	current_song += 1
	current_song %= len(songs)


func _on_PlaySFX_pressed():
	$SFXPlayer.play("res://example/sfx/magic_spell.ogg", true)


func _on_VolumeUp_pressed():
	$MusicPlayer.volume_linear += 0.1


func _on_VolumeDown_pressed():
	$MusicPlayer.volume_linear -= 0.1


func _on_Stop_pressed():
	$MusicPlayer.stop()
