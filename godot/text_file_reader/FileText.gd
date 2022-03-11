tool
# Displays the contents of a file in a label. Remember, text files are not
# normally included in project export, so add an exception in the export
# settings for each target, or a wildcard like "*.txt".

class_name FileTextDisplay
extends Label

export (String, FILE) var source_file:String setget set_source_file


func set_source_file(new_source_file: String):
	source_file = new_source_file
	update_content()


func update_content():
	text = TextFileReader.file_get_text(source_file)


func _ready():
	update_content()
