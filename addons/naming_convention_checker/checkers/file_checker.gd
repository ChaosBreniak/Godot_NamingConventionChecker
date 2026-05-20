class_name FileChecker extends RefCounted

var rules: Array[Dictionary] = []


func get_matched_rule(full_path: String) -> Dictionary:
	var extension: String = full_path.get_extension()
	
	for rule in rules:
		if extension in rule["extensions"]: return rule
	
	return {}
