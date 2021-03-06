extends Control

onready var resume = $Menu/Resume
onready var restart = $Menu/Restart
onready var quit = $Menu/Quit
onready var scene_switcher = get_node("/root/SceneSwitcher")
onready var save_system = get_node("/root/SaveSystem")


func _ready():
	resume.connect("button_up", self, "_on_resume")
	restart.connect("button_up", self, "_on_restart")
	quit.connect("button_up", self, "_on_quit")


func _input(event):
	if event.is_action_pressed("pause"):
		get_tree().paused = !get_tree().paused
		visible = !visible
	elif event.is_action_pressed("ui_cancel") and get_tree().paused:
		get_tree().paused = false
		visible = false
	


func _on_resume():
	get_tree().paused = false
	visible = false


func _on_restart():
	var path = "res://Scenes/Tracks/" + save_system.tracks[save_system.load_cfg_value("Session", "Track")] + ".tscn"
	scene_switcher.goto_scene(path, false)
	get_tree().paused = false


func _on_quit():
	get_tree().paused = false
	scene_switcher.goto_scene("res://Scenes/UI/MainMenu/TitleScreen.tscn", false)
