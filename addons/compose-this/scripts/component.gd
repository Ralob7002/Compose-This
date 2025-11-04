@tool
@icon("res://addons/compose-this/icons/component.svg")
extends Node
class_name Component
## Base class for all component objects.
##
## Components can be used to add or extend functionality to a [Node] without
## creating a dependency between them; that is, a component can be disabled or removed
## from a node without causing problems. [br][br]
## The components, despite being flexible, have certain rules that cannot be broken. [br]
## [color=light_blue][b][1][/b][/color] Components cannot have their names changed.
## If changed, the name will revert to the default. [br]
## [color=light_blue][b][2][/b][/color] Only one type of the same component can be added
## to a parent. [br][br]
## Since the Component class extends the Node class, it cannot perform drawing operations.
## However, this is possible through its parent class. [br]
## [b]Example:[/b]
## [codeblock]
## func _ready() -> void:
## 	if parent is Node2D:
## 		parent.draw.connect(_on_parent_draw)
##
## func _on_parent_draw() -> void:
## 	parent.draw_circle(Vector2.ZERO, 32, Color.WHITE)
## [/codeblock][br]
## If your component overrides the virtual [method Node._enter_tree] method,
## then you will need to manually call the class method in your code. [br]
## [b]Example:[/b]
## [codeblock]
## func _enter_tree() -> void:
## 	super._enter_tree()
## [/codeblock][br]

#region Exports

## Defines whether the component is enabled or not.
## When disabled, it calls the function to disable processing of the component.
@export var enabled: bool = true:
	set(value):
		enabled = value
		if not Engine.is_editor_hint():
			_update_process(value)

#endregion

#region Variables

## Reference to the component's owner node.
@onready var parent: Node = get_parent()

#endregion

#region Virtual Functions

func _ready() -> void:
	if not Engine.is_editor_hint():
		if has_method("_component_ready"):
			self["_component_ready"].call()

func _enter_tree() -> void:
	# Updates the Component's parent if it is reparented.
	if parent and parent != get_parent():
		parent = get_parent()
		request_ready()

	if not ready.is_connected(_on_component_ready):
		ready.connect(_on_component_ready)
	if not tree_exited.is_connected(_on_component_tree_exited):
		tree_exited.connect(_on_component_tree_exited)
	if not renamed.is_connected(_on_component_renamed):
		renamed.connect(_on_component_renamed)

	# It prevents two components of the same type from being added to the same parent.
	await get_tree().create_timer(0.0).timeout

	# Called when the Component is added via Node.add_child,
	# since only Compose.add_component changes its name before adding it.
	if get_script().get_global_name() != name:
		queue_free()

	if Engine.is_editor_hint():
		var component_name: String = get_script().get_global_name()
		for child: Node in self.get_parent().get_children():
			if child != self and child.name == component_name:
				queue_free()
				push_error("The {comp} has already been added to {node}.".format({
					comp = component_name,
					node = get_tree().edited_scene_root.name
				}))
				break

#endregion

#region Functions

## It calls the component's functions [method Node.set_process], [method Node.set_physics_process],
## and [method Node.set_process_input], disabling or enabling its processing.
func _update_process(enable: bool) -> void:
	set_process(enable)
	set_physics_process(enable)
	set_process_input(enable)

#endregion

#region Signal Callables

## Called when the component is ready.
func _on_component_ready() -> void:
	if is_queued_for_deletion():
		return

	if parent is Node2D:
		parent.queue_redraw()

	if Engine.is_editor_hint():
		_update_process(false)
	else:
		_update_process(enabled)
		# References the component's parent to Compose._parent_references.
		var default_name: String = get_script().get_global_name()
		if not Compose._parents_reference.has(default_name):
			Compose._parents_reference[default_name] = []
		if not Compose._parents_reference[default_name].has(parent):
			Compose._parents_reference[default_name].append(parent)


## Called when the component exits the tree.
func _on_component_tree_exited() -> void:
	if not Engine.is_editor_hint():
		var default_name: String = get_script().get_global_name()
		if Compose._parents_reference.has(default_name):
			Compose._parents_reference[default_name].erase(parent)
			if Compose._parents_reference[default_name].size() == 0:
				Compose._parents_reference.erase(default_name)

	if parent is Node2D:
		for sig in parent.get_signal_list():
			for connection in parent.get_signal_connection_list(sig.name):
				if connection.callable.get_object() == self:
					parent[sig.name].disconnect(connection.callable)
		parent.queue_redraw()


## Called when the component is renamed.
func _on_component_renamed() -> void:
	var default_name: String = get_script().get_global_name()
	if name != default_name:
		name = default_name
		push_error("The names of the components cannot be changed.")

#endregion
