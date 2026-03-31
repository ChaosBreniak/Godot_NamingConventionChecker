@tool
extends EditorPlugin

const SETTINGS_PATH: String = "res://addons/naming_convention_checker/settings.cfg"

# Settings section and key
const BASE: String = "Base"
const PREFIXES: String = "prefixes"

# Resource header
const TYPE: String = "type"
const SCRIPT_CLASS: String = "script_class"

var _config := ConfigFile.new()
var _ignore_spaces: bool
var _ignored_extensions: PackedStringArray
var _ignored_folders: PackedStringArray
var _file_rules: Array[Dictionary]
var _resource_rules: Array[Dictionary]


func _enter_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_run_check)


func _exit_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_run_check)


func _run_check() -> void:
	var filesystem_root: EditorFileSystemDirectory = EditorInterface.get_resource_filesystem().get_filesystem()
	if filesystem_root == null: return
	
	_config.load(SETTINGS_PATH)
	_ignore_spaces = _config.get_value(BASE, "ignore_spaces", false)
	_ignored_extensions = _config.get_value(BASE, "ignored_extensions", [])
	_ignored_folders = _config.get_value(BASE, "ignored_folders", [])
	_file_rules = _get_rules("Files")
	_resource_rules = _get_rules("Resources")
	
	_check_directory(filesystem_root)


func _get_rules(section: String) -> Array[Dictionary]:
	var config_keys: PackedStringArray = _config.get_section_keys(section)
	var rule: Array[Dictionary] = []
	rule.resize(config_keys.size())
	
	for i: int in config_keys.size():
		rule[i] = _config.get_value(section, config_keys[i], {})
	
	return rule


func _check_directory(root: EditorFileSystemDirectory) -> void:
	var stack: Array[EditorFileSystemDirectory] = [root]
	
	while not stack.is_empty():
		var current: EditorFileSystemDirectory = stack.pop_back()
		if current.get_name() in _ignored_folders: continue
		
		for i: int in current.get_file_count():
			_check_file(current.get_file(i), current.get_path())
		
		for i: int in current.get_subdir_count():
			stack.push_back(current.get_subdir(i))


func _check_file(filename: String, directory_path: String) -> void:
	var extension: String = filename.get_extension().to_lower()
	if extension in _ignored_extensions: return
	
	if not _ignore_spaces and filename.contains(" "):
		var error_space: String = "%s [color=grey]has space in its name -> [color=white]%s"
		_print_violation(error_space % [filename, directory_path.path_join(filename)])
	
	if extension == "tres" or extension == "res":
		_check_resource_file(filename, directory_path, extension)
		return
	
	var rule: Dictionary = _find_rule(extension)
	if rule.is_empty(): return
	
	_assert_prefix(filename, directory_path, rule[PREFIXES])


func _check_resource_file(filename: String, directory_path: String, extension: String) -> void:
	var full_path: String = directory_path.path_join(filename)
	
	var godot_type: String = ""
	var script_class: String = ""
	
	if extension == "tres":
		var header: Dictionary = _read_tres_header(full_path)
		godot_type = header[TYPE]
		script_class = header[SCRIPT_CLASS]
	else:
		var resource: Resource = ResourceLoader.load(full_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if resource != null:
			godot_type = resource.get_class()
			var script: Script = resource.get_script()
			script_class = script.get_global_name() if script != null else ""
	
	if godot_type.is_empty(): return
	
	for type_rule: Dictionary in _resource_rules:
		var target: String = type_rule["class"]
		
		var matches: bool = _is_native_matches(godot_type, target) or \
							(not script_class.is_empty() and script_class == target)
		
		if not matches: continue
		
		_assert_prefix(filename, directory_path, type_rule[PREFIXES])
		return


func _read_tres_header(full_path: String) -> Dictionary[String, String]:
	var result: Dictionary[String, String] = {TYPE : "", SCRIPT_CLASS : ""}
	
	var file := FileAccess.open(full_path, FileAccess.READ)
	if file == null: return result
	
	var line: String = file.get_line()
	file.close()
	
	result[TYPE] = _extract_header_field(line, TYPE)
	result[SCRIPT_CLASS] = _extract_header_field(line, SCRIPT_CLASS)
	return result


func _extract_header_field(line: String, field: String) -> String:
	var pattern: String = field + '="'
	var start: int = line.find(pattern)
	if start == -1: return ""
	
	start += pattern.length()
	var end: int = line.find('"', start)
	if end == -1: return ""
	
	return line.substr(start, end - start)


func _find_rule(extension: String) -> Dictionary:
	for rule in _file_rules:
		if extension in rule["extensions"]: return rule
	
	return {}


func _is_native_matches(godot_type: String, target: String) -> bool:
	return godot_type == target or ClassDB.is_parent_class(godot_type, target)


func _assert_prefix(filename: String, directory_path: String, prefixes: PackedStringArray) -> void:
	var base_name: String = filename.get_basename()
	
	for prefix in prefixes:
		if base_name.begins_with(prefix): return
	
	var error_message: String = "%s [color=grey]must begin with [color=yellow]%s[color=grey] -> [color=white]%s"
	var full_path: String = directory_path.path_join(filename)
	_print_violation(error_message % [filename, prefixes, full_path])


func _print_violation(text: String) -> void:
	print_rich("[color=red][FILE NAMING] [color=white]%s" % text)
