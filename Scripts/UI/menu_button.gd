extends Button


export(String) var scene

onready var scene_switcher = get_node("/root/SceneSwitcher")

func _ready():
	connect("button_up", self, "_on_pressed")


func _on_pressed():
	if scene == "Quit":
		get_tree().quit()
	else:
		scene_switcher.goto_scene(scene, false)
		#get_tree().change_scene(scene)
