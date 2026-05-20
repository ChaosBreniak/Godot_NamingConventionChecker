@tool
extends EditorPlugin

const SETTINGS_PATH: String = "res://addons/naming_convention_checker/settings.cfg"

var _config := NamingConventionConfig.new()
var _script_checker := ScriptChecker.new()
var _resource_checker := ResourceChecker.new()
var _file_checker := FileChecker.new()


func _enter_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_run_check)


func _exit_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_run_check)


func _run_check() -> void:
	var filesystem_root: EditorFileSystemDirectory = EditorInterface.get_resource_filesystem().get_filesystem()
	if filesystem_root == null: return
	
	_config.load_from(SETTINGS_PATH)
	_script_checker.rules = _config.script_rules
	_resource_checker.rules = _config.resource_rules
	_file_checker.rules = _config.file_rules
	
	_check_directory(filesystem_root)


func _check_directory(root: EditorFileSystemDirectory) -> void:
	var stack: Array[EditorFileSystemDirectory] = [root]
	
	while not stack.is_empty():
		var current: EditorFileSystemDirectory = stack.pop_back()
		if current.get_name() in _config.ignored_folders: continue
		
		for i: int in current.get_file_count():
			_check_file(current.get_file(i), current.get_path())
		
		for i: int in current.get_subdir_count():
			stack.push_back(current.get_subdir(i))


func _check_file(filename: String, directory_path: String) -> void:
	var extension: String = filename.get_extension().to_lower()
	if extension in _config.ignored_extensions: return
	
	var full_path: String = directory_path.path_join(filename)
	
	if not _config.ignore_spaces and filename.contains(" "):
		var error_space: String = "%s [color=grey]has space in its name -> [color=white]%s"
		_print_violation(error_space % full_path)
	
	var rule: Dictionary = {}
	match extension:
		"gd":
			rule = _script_checker.get_matched_rule(full_path)
		"tres":
			rule = _resource_checker.get_matched_rule(full_path)
		"res":
			rule = _resource_checker.get_matched_rule(full_path)
		_:
			rule = _file_checker.get_matched_rule(full_path)
	
	if rule.is_empty(): return
	
	_assert_prefix(filename, full_path, rule["prefixes"])


func _assert_prefix(filename: String, full_path: String, prefixes: PackedStringArray) -> void:
	var base_name: String = filename.get_basename()
	
	for prefix in prefixes:
		if base_name.begins_with(prefix): return
	
	var message: String = "%s [color=grey]must begin with [color=yellow]%s[color=grey] -> [color=white]%s"
	_print_violation(message % [filename, prefixes, full_path])


func _print_violation(text: String) -> void:
	print_rich("[color=red][FILE NAMING] [color=white]%s" % text)
