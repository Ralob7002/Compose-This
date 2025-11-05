@tool
extends Node
## Autoload created by the Compose addon.
##
## Provides functions for working with components and their parents.

#region Private Variables

## Dictionary containing all nodes that have at least one component.
## They are organized by the [member Component.default_name].
var _parents_reference: Dictionary[String, Array]

#endregion

#region Functions

## Returns an [Array] containing all the components of a node. [br][br]
## [b]Note:[/b] Only first-level components will be returned.
## Child components of the node will be ignored.
func get_components(node: Node) -> Array[Component]:
	var components: Array[Component] = []
	for child in node.get_children():
		if child is Component:
			components.append(child)
	return components


## Returns an [Array] with the default names of all node components. [br][br]
## [b]Note:[/b] Only first-level components will be returned.
## Child components of the node will be ignored.
func get_components_name(node: Node) -> Array[String]:
	var names: Array[String] = []
	for child in node.get_children():
		if child is Component:
			names.append(child.name)
	names.sort()
	return names


## Adds a [Component] to the node. If a component of the same type already exists in the node,
## it will be replaced by the new one. If a [ClassDB] is passed
## as the [param component] parameter,
## it will be automatically instantiated. [br][br]
## The [method Node.add_child] function cannot be used to add new components.
## If used, they will be automatically released.
func add_component(node: Node, component: Variant) -> void:
	if component is GDScript:
		component = component.new()
	var default_name: String = component.get_script().get_global_name()
	component.free()

	if node.has_node(default_name):
		node.get_node(default_name).free()

	component.name = default_name
	node.add_child(component)


## Adds a [Component] to the node only if it doesn't already have the component.
## If a [ClassDB] is passed as the [param component] parameter,
## it will be automatically instantiated. [br][br]
## The [method Node.add_child] function cannot be used to add new components.
## If used, they will be automatically released.
func ensure_component(node: Node, component: Variant) -> void:
	if component is GDScript:
		component = component.new()
	var default_name: String = component.get_script().get_global_name()
	component.free()

	if not node.has_node(default_name):
		component.name = default_name
		node.add_child(component)


## Remove a specific [Component] from a node. The component to be removed,
## or its [ClassDB], can be passed as the [param component] parameter. [br][br]
## [method Node.remove_child] can be used to remove components,
## but you will need to use [method Node.has_node] to check if the node has
## the component before removing it.
func remove_component(node: Node, component: Variant) -> void:
	if component is GDScript:
		component = component.new()
	var default_name: String = component.get_script().get_global_name()
	component.free()

	if node.has_node(default_name):
		node.get_node(default_name).queue_free()


## Returns all nodes that contain exactly all the [param components] passed
## as in [param components].
func query_all(components: Array) -> Array:
	var components_name: Array[String] = []
	for comp in components:
		if comp is GDScript:
			var component = comp.new()
			components_name.append(component.get_script().get_global_name())
			component.free()
		else:
			components_name.append(comp)
	components_name.sort()

	var smallest_comp_key: String = components_name[0]
	for key in components_name:
		if _parents_reference.has(key) and _parents_reference.has(smallest_comp_key):
			if _parents_reference[key].size() < _parents_reference[smallest_comp_key].size():
				smallest_comp_key = key

	var queryded_parents: Array = []
	if _parents_reference.has(smallest_comp_key):
		for parent in _parents_reference[smallest_comp_key]:
			var names = get_components_name(parent)

			var match_to_filter: bool = true
			for comp_name in components_name:
				if not names.has(comp_name):
					match_to_filter = false
					break
			if match_to_filter:
				queryded_parents.append(parent)
	return queryded_parents


## Returns an array containing all nodes that have at least one of the [param components]. [br][br]
func query_any(components: Array) -> Array:
	var components_name: Array[String] = []
	for comp in components:
		if comp is GDScript:
			var component = comp.new()
			components_name.append(component.get_script().get_global_name())
			component.free()
		else:
			components_name.append(comp)
	components_name.sort()

	var queryded_parents: Array = []
	for key in components_name:
		if _parents_reference.has(key):
			for parent in _parents_reference[key]:
				if not queryded_parents.has(parent):
					queryded_parents.append(parent)
	return queryded_parents

#endregion
