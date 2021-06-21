extends Node2D

var loader
var wait_time
var cached_scenes = [null]
var cache_num = -1
var time_max = 10000 # msec
var current_scene

onready var save_system = get_node("/root/SaveSystem")

func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child(root.get_child_count() - 1)
	print(current_scene.name)


func goto_scene(path, animate, remove = true): # Game requests to switch to this scene
	get_tree().change_scene(path)
