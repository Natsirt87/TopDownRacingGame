extends Button


export(String) var scene

func _ready():
	connect("button_up", self, "_on_pressed")


func _on_pressed():
	if scene == "Quit":
		get_tree().quit()
	else:
		get_tree().change_scene(scene)
