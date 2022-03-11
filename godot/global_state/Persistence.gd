# Manages all data that needs to be accessed globally, and all data that needs
# be saved between sessions. Supports creating new save slots or saving over
# existing slots. Also supports global config that should be shared between
# all slots.

# Keep these data structures as flat as possible. Nested dictionaries could
# cause problems.

extends Node

signal global_data_loaded()
signal slot_loaded(slot_name)

const global_data_file := "user://global_settings"
const saves_directory := "user://saves"

# Define your game-specific data structures here

var example_data_structure := {
	example_key = "example value",
	another_example_key = "another_example_value"
}

var another_example_data_structure := {
	key1 = "value1",
	key2 = "value2"
}

var example_global_data_structure := {
	key1 = "value1"
}

# Used by the audio system to save volume settings
var audio := {
	sfx_volume = 100,
	music_volume = 100
}

# Metadata about saves
var saves := {
	largest_id = 0
}

# List any data structures that should be saved in a save slot here.
var slot_save_data := {
	slot_name = "save-0",
	example_data_structure = example_data_structure,
	another_example_data_structure = another_example_data_structure
}

# List any data structures that should be saved globally here.
var global_save_data := {
	saves = saves,
	audio = audio,
	example_global_data_structure = example_global_data_structure
}

# Create a data structure for holding save slot preview data here.
var preview := {
	max_life = 8,
	dungeons_complete = 3
}

func _ready():
	var dir = Directory.new()
	dir.make_dir_recursive(saves_directory)


func save_global():
	save_data(global_save_data, global_data_file)


func save_over_slot(slot_name: String):
	save_data(slot_save_data, "%s/%s" % [saves_directory, slot_name])


func save_new_slot():
	var slot_id = global_save_data.saves.largest_id + 1
	var slot_name = str("save-%s" % slot_id)
	global_save_data.saves.largest_id = slot_id
	save_over_slot(slot_name)
	save_global()


func save_data(data: Dictionary, file_path: String):
	var file = File.new()
	file.open(file_path, file.WRITE)
	file.store_var(global_save_data, false)
	file.close()


func load_data(data:Dictionary, file_path: String):
	var file = File.new()
	
	if not file.file_exists(file_path):
		push_error("File not found: %s" % file_path)
		
		return
	
	file.open(file_path, file.READ)
	merge_dict(data, file.get_var(false))


func load_global():
	load_data(global_save_data, global_data_file)
	emit_signal("global_data_loaded")


func load_slot(slot_name: String):
	load_data(slot_save_data, "%s/%s" % [saves_directory,slot_name])
	emit_signal("slot_loaded", slot_name)


func load_slot_preview(slot_name: String):
	var preview = {}
	load_data(preview, "%s/%s.preview" % [saves_directory, slot_name])


func list_slots() -> Array:
	var slots = []
	var dir = Directory.new()
	dir.open(saves_directory)
	dir.list_dir_begin(true, true)
	
	while true:
		var file_name = dir.get_next()
		
		if file_name == "":
			break
		
		if file_name.ends_with(".preview"):
			pass
		
		slots.push_back(file_name)
	
	dir.list_dir_end()
	
	return slots

func merge_dict(base, overlay):
	for key in overlay:
		base[key] = overlay[key]
