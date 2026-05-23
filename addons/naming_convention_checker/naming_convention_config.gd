class_name NamingConventionConfig extends RefCounted

const IGNORES: String = "Ignores"

var ignore_snake_case: bool = false
var ignored_extensions: PackedStringArray = []
var ignored_folders: PackedStringArray = []
var script_rules: Array[Dictionary]
var file_rules: Array[Dictionary]
var resource_rules: Array[Dictionary]


func load_from(path: String) -> void:
	var config := ConfigFile.new()
	config.load(path)
	
	ignore_snake_case = config.get_value(IGNORES, "ignore_snake_case", false)
	ignored_extensions = config.get_value(IGNORES, "ignored_extensions", [])
	ignored_folders = config.get_value(IGNORES, "ignored_folders", [])
	
	script_rules = _get_rules(config, "Scripts")
	file_rules = _get_rules(config, "Files")
	resource_rules = _get_rules(config, "Resources")


func _get_rules(config: ConfigFile, section: String) -> Array[Dictionary]:
	var config_keys: PackedStringArray = config.get_section_keys(section)
	var rule: Array[Dictionary] = []
	rule.resize(config_keys.size())
	
	for i: int in config_keys.size():
		rule[i] = config.get_value(section, config_keys[i], {})
	
	return rule
