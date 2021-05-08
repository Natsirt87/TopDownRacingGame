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


func goto_scene(path, animate, remove = true): # Game requests to switch to this scene.
	for i in range(save_system.tracks.size()):
		if save_system.tracks[i] in path:
			cache_num = i
	
	if cache_num > -1 and cached_scenes[cache_num] != null:
		current_scene.queue_free()
		set_new_scene(cached_scenes[cache_num])
	else:
		loader = ResourceLoader.load_interactive(path)
		if loader == null: # Check for errors.
			print("Loader Bad, Uh Oh")
			return
		set_process(true)
		
		if remove:
			current_scene.queue_free()
		
		if animate:
			get_node("CanvasLayer/LoadingAnimation").play("loading_anim")
			wait_time = 0.4
		else:
			wait_time = 0.0


func _process(time):
	if loader == null:
		# no need to process anymore
		set_process(false)
		return

	# Wait for frames to let the "loading" animation show up.
	if wait_time > 0:
		wait_time -= time
		return

	var t = OS.get_ticks_msec()
	# Use "time_max" to control for how long we block this thread.
	while OS.get_ticks_msec() < t + time_max:
		# Poll your loader.
		var err = loader.poll()

		if err == ERR_FILE_EOF: # Finished loading.
			var resource = loader.get_resource()
			loader = null
			set_new_scene(resource)
			break
		elif err == OK:
			pass # update loading bar progress here
		else: # Error during loading.
			print("Error during loading")
			loader = null
			break


func set_new_scene(scene_resource):
	if cache_num > -1:
		cached_scenes[cache_num] = scene_resource
		cache_num = -1
	
	current_scene = scene_resource.instance()
	get_node("/root").add_child(current_scene)
	
	var anim = get_node("CanvasLayer/LoadingAnimation")
	
	if get_node("CanvasLayer/ColorRect").visible:
		anim.play("unloading_anim")
