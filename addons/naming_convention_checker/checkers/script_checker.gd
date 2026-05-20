class_name ScriptChecker extends RefCounted

const EXTENDS: String = "extends"

var rules: Array[Dictionary] = []


func get_matched_rule(full_path: String) -> Dictionary:
	var node_class: String = _get_extends_class(full_path)
	return _find_rule(node_class)


func _get_extends_class(full_path: String) -> String:
	var node_class: String = ""
	
	var content: String = FileAccess.get_file_as_string(full_path)
	for line in content.split("\n"):
		if EXTENDS not in line: continue
		
		node_class = line.split(EXTENDS)[1].strip_edges().get_slice(" ", 0)
		break
	
	return node_class


func _find_rule(node_class: String) -> Dictionary:
	for rule: Dictionary in rules:
		var parent_class: String = rule.get("class", "")
		if parent_class.is_empty(): continue
		if node_class == parent_class or ClassDB.is_parent_class(node_class, parent_class): return rule
	
	return {}
