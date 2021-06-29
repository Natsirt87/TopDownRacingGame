extends Node2D


var config_path = "user://config.cfg"
var config = ConfigFile.new()

var tracks = ["Track1"]


func _ready():
	if !config.load(config_path):
		push_warning("Error loading config file")
	
	_init_video_cfg()
	_init_controls_cfg()
	_init_session_cfg()
	_init_game_cfg()
	_init_audio_cfg()


func _init_video_cfg():
	var fullscreen = load_cfg_value("Video", "Fullscreen")
	var borderless = load_cfg_value("Video", "Borderless")
	var resolution = load_cfg_value("Video", "Resolution")
	var vsync = load_cfg_value("Video", "VSync")
	
	if fullscreen != null:
		OS.window_fullscreen = fullscreen
	else:
		save_cfg_value("Video", "Fullscreen", false)
		OS.window_fullscreen = false
	
	if borderless != null:
		if fullscreen:
			save_cfg_value("Video", "Borderless", false)
			OS.window_borderless = false
		else:
			OS.window_borderless = borderless
	else:
		save_cfg_value("Video", "Borderless", false)
		OS.window_borderless = false
	
	if resolution == null:
		resolution = Vector2(1920, 1080)
		save_cfg_value("Video", "Resolution", resolution)
	
	if !OS.window_fullscreen:
		OS.window_size = resolution
		OS.set_window_position(OS.get_screen_size() * 0.5 - OS.window_size * 0.5)
	else:
		get_viewport().size = resolution
	
	if vsync != null:
		OS.vsync_enabled = vsync
	else:
		save_cfg_value("Video", "VSync", false)
		OS.vsync_enabled = false


func _init_controls_cfg():
	if load_cfg_value("Controls", "accelerate") == null:
		save_cfg_value("Controls", "accelerate", InputMap.get_action_list("accelerate"))
	
	if load_cfg_value("Controls", "brake") == null:
		save_cfg_value("Controls", "brake", InputMap.get_action_list("brake"))
	
	if load_cfg_value("Controls", "steer_left") == null:
		save_cfg_value("Controls", "steer_left", InputMap.get_action_list("steer_left"))
	
	if load_cfg_value("Controls", "steer_right") == null:
		save_cfg_value("Controls", "steer_right", InputMap.get_action_list("steer_right"))
	
	if load_cfg_value("Controls", "handbrake") == null:
		save_cfg_value("Controls", "handbrake", InputMap.get_action_list("handbrake"))
	
	if load_cfg_value("Controls", "gear_up") == null:
		save_cfg_value("Controls", "gear_up", InputMap.get_action_list("gear_up"))
	
	if load_cfg_value("Controls", "gear_down") == null:
		save_cfg_value("Controls", "gear_down", InputMap.get_action_list("gear_down"))
	
	if load_cfg_value("Controls", "clutch") == null:
		save_cfg_value("Controls", "clutch", InputMap.get_action_list("clutch"))
	
	
	for i in InputMap.get_action_list("accelerate"):
		InputMap.action_erase_event("accelerate", i)
	for i in load_cfg_value("Controls", "accelerate"):
		InputMap.action_add_event("accelerate", i)
	
	for i in InputMap.get_action_list("brake"):
		InputMap.action_erase_event("brake", i)
	for i in load_cfg_value("Controls", "brake"):
		InputMap.action_add_event("brake", i)
	
	for i in InputMap.get_action_list("steer_left"):
		InputMap.action_erase_event("steer_left", i)
	for i in load_cfg_value("Controls", "steer_left"):
		InputMap.action_add_event("steer_left", i)
	
	for i in InputMap.get_action_list("steer_right"):
		InputMap.action_erase_event("steer_right", i)
	for i in load_cfg_value("Controls", "steer_right"):
		InputMap.action_add_event("steer_right", i)
	
	for i in InputMap.get_action_list("handbrake"):
		InputMap.action_erase_event("handbrake", i)
	for i in load_cfg_value("Controls", "handbrake"):
		InputMap.action_add_event("handbrake", i)
	
	for i in InputMap.get_action_list("gear_up"):
		InputMap.action_erase_event("gear_up", i)
	for i in load_cfg_value("Controls", "gear_up"):
		InputMap.action_add_event("gear_up", i)
	
	for i in InputMap.get_action_list("gear_down"):
		InputMap.action_erase_event("gear_down", i)
	for i in load_cfg_value("Controls", "gear_down"):
		InputMap.action_add_event("gear_down", i)
	
	for i in InputMap.get_action_list("clutch"):
		InputMap.action_erase_event("clutch", i)
	for i in load_cfg_value("Controls", "clutch"):
		InputMap.action_add_event("clutch", i)
	


func _init_session_cfg():
	if load_cfg_value("Session", "Car") == null:
		save_cfg_value("Session", "Car", 0)
	
	if load_cfg_value("Session", "Track") == null:
		save_cfg_value("Session", "Track", 0)
	
	if load_cfg_value("Session", "Mode") == null:
		save_cfg_value("Session", "Mode", 0)


func _init_game_cfg():
	if load_cfg_value("Game", "Automatic") == null:
		save_cfg_value("Game", "Automatic", true)
	
	if load_cfg_value("Game", "SteeringSensitivity") == null:
		save_cfg_value("Game", "SteeringSensitivity", 0.7)
	
	if load_cfg_value("Game", "SteeringSpeedDecay") == null:
		save_cfg_value("Game", "SteeringSpeedDecay", 0.5)
	
	if load_cfg_value("Game", "CountersteerAssist") == null:
		save_cfg_value("Game", "CountersteerAssist", 0.4);
	
	if load_cfg_value("Game", "CameraZoomSpeed") == null:
		save_cfg_value("Game", "CameraZoomSpeed", 0.35)


func _init_audio_cfg():
	var master_volume = load_cfg_value("Audio", "MasterVolume")
	
	if master_volume == null:
		master_volume = save_cfg_value("Audio", "MasterVolume", 0.5)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(master_volume))


func save_cfg_value(section : String, key : String, value):
	config.set_value(section, key, value)
	config.save(config_path)


func load_cfg_value(section : String, key : String):
	return config.get_value(section, key, null)
