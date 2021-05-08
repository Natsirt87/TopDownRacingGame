extends Control

export(NodePath) var intial_focus_button_path
export(NodePath) var focus_container_path


onready var focus_button = get_node(intial_focus_button_path)
onready var focus_container = get_node(focus_container_path)


func _input(event):
	if _is_focused():
		if event.is_action_pressed("ui_unfocus"):
			for i in focus_container.get_children():
				i.release_focus()
	else:
		if event.is_action_pressed("ui_focus"):
			focus_button.grab_focus()


func _is_focused():
	for i in focus_container.get_children():
		if i.has_focus():
			return true
	return false


func _on_mouse_used():
	for i in focus_container.get_children():
		i.release_focus()
