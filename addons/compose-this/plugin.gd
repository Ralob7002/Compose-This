@tool
extends EditorPlugin

#region Virtual Functions.

func _enable_plugin() -> void:
	add_autoload_singleton("Compose", "res://addons/compose-this/scripts/compose.gd")


func _disable_plugin() -> void:
	remove_autoload_singleton("Compose")

#endregion
