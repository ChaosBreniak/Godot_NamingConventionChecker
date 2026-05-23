@tool
extends EditorPlugin

const DEFAULT_SETTINGS_PATH: String = "res://addons/naming_convention_checker/default/settings.default.txt"
const USER_SETTINGS_PATH: String = "res://addons/naming_convention_checker/settings.cfg"

var _config := NamingConventionConfig.new()
var _script_checker := ScriptChecker.new()
var _resource_checker := ResourceChecker.new()
var _file_checker := FileChecker.new()
var _regex_snake_case := RegEx.create_from_string("^[a-z0-9]+(_[a-z0-9]+)*$")


func _enter_tree() -> void:
	_create_user_settings()
	EditorInterface.get_resource_filesystem().filesystem_changed.connect(_run_check)


func _exit_tree() -> void:
	EditorInterface.get_resource_filesystem().filesystem_changed.disconnect(_run_check)


func _create_user_settings() -> void:
	if FileAccess.file_exists(USER_SETTINGS_PATH): return
	
	var default_content: String = FileAccess.get_file_as_string(DEFAULT_SETTINGS_PATH)
	var file := FileAccess.open(USER_SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		var error: String = error_string(file.get_open_error())
		push_error("[NamingConventionChecker] Error: <%s> -> Could not create user settings at: %s" % [error, USER_SETTINGS_PATH])
		return
	
	file.store_string(default_content)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	print_rich("[color=green][NamingConventionChecker][/color] Settings created at: [color=white]%s[/color] - Edit it to define your naming conventions." % USER_SETTINGS_PATH)


func _run_check() -> void:
	var filesystem_root: EditorFileSystemDirectory = EditorInterface.get_resource_filesystem().get_filesystem()
	if filesystem_root == null: return
	
	_config.load_from(USER_SETTINGS_PATH)
	_script_checker.rules = _config.script_rules
	_resource_checker.rules = _config.resource_rules
	_file_checker.rules = _config.file_rules
	
	_check_directory(filesystem_root)


func _check_directory(root: EditorFileSystemDirectory) -> void:
	var stack: Array[EditorFileSystemDirectory] = [root]
	while not stack.is_empty():
		var current: EditorFileSystemDirectory = stack.pop_back()
		var current_name: String = current.get_name()
		if current_name in _config.ignored_folders: continue
		
		var current_path: String = current.get_path()
		
		for i: int in current.get_file_count():
			_check_file(current.get_file(i), current_path)
		
		if not current_name.is_empty():
			_assert_snake_case(current_name, current_path)
		
		for i: int in current.get_subdir_count():
			stack.push_back(current.get_subdir(i))


func _check_file(filename: String, directory_path: String) -> void:
	var extension: String = filename.get_extension().to_lower()
	if extension in _config.ignored_extensions: return
	
	var full_path: String = directory_path.path_join(filename)
	
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
	
	if rule.is_empty():
		_assert_snake_case(filename, full_path)
	else:
		_assert_prefix(filename, full_path, rule["prefixes"])


func _assert_prefix(filename: String, full_path: String, prefixes: PackedStringArray) -> void:
	for prefix: String in prefixes:
		if not filename.begins_with(prefix): continue
		
		var prefixless_file: String = filename.substr(prefix.length())
		_assert_snake_case(prefixless_file, full_path)
		return
	
	var message: String = "%s [color=grey]must begin with [color=yellow]%s[color=grey] -> [color=white]%s"
	_print_violation(message % [filename, prefixes, full_path])


func _assert_snake_case(asset_name: String, full_path: String) -> void:
	if _config.ignore_snake_case: return
	
	var asset_basename: String = asset_name.get_basename()
	if _regex_snake_case.search(asset_basename) != null: return
	
	var message: String = "%s [color=grey]is not snake_case -> [color=white]%s"
	_print_violation(message % [asset_basename, full_path])


func _print_violation(text: String) -> void:
	print_rich("[color=red][FILE NAMING] [color=white]%s" % text)
