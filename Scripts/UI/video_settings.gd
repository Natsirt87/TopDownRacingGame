extends VBoxContainer


var popup
onready var save_system = get_node("/root/SaveSystem/")


func _ready():
	popup = $ResolutionPopUp.get_popup()
	popup.add_item("2560x1440")
	popup.add_item("1920x1080")
	popup.add_item("1680x1050")
	popup.add_item("1600x900")
	popup.add_item("1366x768")
	popup.add_item("1280x720")
	popup.connect("id_pressed", self, "_on_resolution_selected")
	
	
	var resolution
	if OS.window_fullscreen:
		resolution = get_viewport().size
	else:
		resolution = OS.window_size
	
	if OS.get_screen_size().y - resolution.y < 50:
		resolution = OS.get_screen_size()
	
	$ResolutionPopUp.text = _res_to_text(resolution)
	$FullscreenButton.pressed = OS.window_fullscreen
	$BorderlessButton.pressed = OS.window_borderless
	$VSyncButton.pressed = OS.vsync_enabled
	$FullscreenButton.disabled = $BorderlessButton.pressed
	$BorderlessButton.disabled = $FullscreenButton.pressed
	
	$FullscreenButton.connect("toggled", self, "_on_fullscreen_toggled")
	$BorderlessButton.connect("toggled", self, "_on_borderless_toggled")
	$VSyncButton.connect("toggled", self, "_on_vsync_toggled")


func _center_window():
	var screen_size = OS.get_screen_size()
	var window_size = OS.get_window_size()
	
	OS.set_window_position(screen_size * 0.5 - window_size * 0.5)


func _on_resolution_selected(id):
	$ResolutionPopUp.text = popup.get_item_text(id)
	var text = $ResolutionPopUp.text
	var resolution = _text_to_res(text)
	_change_resolution(resolution)


func _text_to_res(text):
	var x_location = text.find("x")
	var resolution = Vector2(int(text.substr(0, x_location)), int(text.substr(x_location + 1, text.length() - 1)))
	return resolution


func _res_to_text(resolution):
	return str(resolution.x) + "x" + str(resolution.y)


func _change_resolution(resolution):
	if !OS.window_fullscreen:
		OS.window_size = resolution
		_center_window()
	else:
		get_viewport().size = resolution
	
	save_system.save_cfg_value("Video", "Resolution", resolution)


func _on_fullscreen_toggled(pressed):
	OS.window_fullscreen = pressed
	$BorderlessButton.disabled = pressed
	if pressed:
		$ResolutionPopUp.text = _res_to_text(OS.get_screen_size())
	else:
		_change_resolution(_text_to_res($ResolutionPopUp.text))
	
	save_system.save_cfg_value("Video", "Fullscreen", pressed)
	save_system.save_cfg_value("Video", "Resolution", _text_to_res($ResolutionPopUp.text))


func _on_borderless_toggled(pressed):
	OS.window_borderless = pressed
	_change_resolution(_text_to_res($ResolutionPopUp.text))
	_center_window()
	$FullscreenButton.disabled = pressed
	
	save_system.save_cfg_value("Video", "Borderless", pressed)


func _on_vsync_toggled(pressed):
	OS.vsync_enabled = pressed
	
	save_system.save_cfg_value("Video", "VSync", pressed)
