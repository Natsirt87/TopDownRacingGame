extends Control

onready var resume = $Menu/Resume
onready var restart = $Menu/Restart
onready var quit = $Menu/Quit
onready var scene_switcher = get_node("/root/SceneSwitcher")
onready var save_system = get_node("/root/SaveSystem")
onready var lobby = get_node("/root/Lobby")


func _ready():
	resume.connect("button_up", self, "_on_resume")
	restart.connect("button_up", self, "_on_restart")
	quit.connect("button_up", self, "_on_quit")


func _input(event):
	if event.is_action_pressed("pause"):
		if not lobby.game_started:
			get_tree().set_pause(!get_tree().paused)
			$Menu/Restart.disabled = true
		else:
			$Menu/Restart.disabled = true
		visible = !visible
		
	elif event.is_action_pressed("ui_cancel") and get_tree().paused:
		get_tree().set_pause(false)
		visible = false
	


func _on_resume():
	get_tree().set_pause(false)
	visible = false


func _on_restart():
	_on_resume()


func _on_quit():
	get_tree().set_pause(false)
	if lobby.game_started:
		lobby.on_disconnect()
	else:
		get_node("/root/World").queue_free()
		get_tree().change_scene("res://Scenes/UI/MainMenu/TitleScreen.tscn")
