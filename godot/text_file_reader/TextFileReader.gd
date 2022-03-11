# Provides static utility functions for reading text from a single file or
# from all files in a directory.
class_name TextFileReader
extends Object


# Returns a PoolStringArray containing the text of all files in a specified
# directory.
static func dir_get_all_text(dir_path: String) -> PoolStringArray:
	var file_contents = PoolStringArray()
	var dir = Directory.new()
	dir.open(dir_path)
	dir.list_dir_begin(true, true)
	
	while true:
		var file_name = dir.get_next()
		
		if file_name == "":
			break
		
		file_name = dir_path + "/" + file_name
		file_contents.push_back(file_get_text(file_name))
	
	dir.list_dir_end()
	
	return file_contents


# Returns a String containing the text of file_path. Leading and trailing
# whitespace is removed.
static func file_get_text(file_path: String) -> String:
	var file = File.new()
	var text = ""
	
	if file.file_exists(file_path):
		file.open(file_path, File.READ)
		text = file.get_as_text().strip_edges()
		file.close()
	else:
		push_error("failed to read " + file_path)
	
	return text
