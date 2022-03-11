tool
# Displays the contents of all files in a directory in a label. Remember that
# text files are not normally included in project export, so add an exception 
# in the export settings for each target, or a wildcard like "license/*".

class_name DirAllTextDisplay
extends Label

export (String, DIR) var source_dir: String setget set_source_dir


func set_source_dir(new_source_dir: String):
	source_dir = new_source_dir
	update_content()


func update_content():
	text = TextFileReader.dir_get_all_text(source_dir).join("\n\n")


func _ready():
	update_content()
