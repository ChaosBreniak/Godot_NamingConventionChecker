class_name ResourceChecker extends RefCounted

const TYPE: String = "type"
const SCRIPT_CLASS: String = "script_class"

var rules: Array[Dictionary] = []


func get_matched_rule(full_path: String) -> Dictionary:
	var godot_type: String = ""
	var script_class: String = ""
	
	if full_path.get_extension() == "tres":
		var header: Dictionary = _read_tres_header(full_path)
		godot_type = header[TYPE]
		script_class = header[SCRIPT_CLASS]
	else:
		var resource: Resource = ResourceLoader.load(full_path)
		if resource != null:
			godot_type = resource.get_class()
			var script: Script = resource.get_script()
			script_class = script.get_global_name() if script != null else ""
	
	if godot_type.is_empty(): return {}
	
	for rule: Dictionary in rules:
		var target: String = rule["class"]
		
		var matches: bool = _is_native_matches(godot_type, target) or \
							(not script_class.is_empty() and script_class == target)
		
		if matches: return rule
	
	return {}


func _is_native_matches(godot_type: String, target: String) -> bool:
	return godot_type == target or ClassDB.is_parent_class(godot_type, target)


func _read_tres_header(full_path: String) -> Dictionary[String, String]:
	var result: Dictionary[String, String] = {TYPE : "", SCRIPT_CLASS : ""}
	
	var header_line: String = FileAccess.get_file_as_string(full_path).split("\n")[0]
	
	result[TYPE] = _extract_header_field(header_line, TYPE)
	result[SCRIPT_CLASS] = _extract_header_field(header_line, SCRIPT_CLASS)
	return result


func _extract_header_field(line: String, field: String) -> String:
	var pattern: String = field + '="'
	var start: int = line.find(pattern)
	if start == -1: return ""
	
	start += pattern.length()
	var end: int = line.find('"', start)
	if end == -1: return ""
	
	return line.substr(start, end - start)
