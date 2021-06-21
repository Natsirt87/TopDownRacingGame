extends VBoxContainer


onready var save_system = get_node("/root/SaveSystem")

onready var auto_button : CheckButton = $Automatic
onready var sens_slider : HSlider = $Sliders/Sens
onready var speed_slider : HSlider = $Sliders/Speed
onready var counter_slider : HSlider = $Sliders/Counter
onready var zoom_slider : HSlider = $Sliders/Zoom



# Called when the node enters the scene tree for the first time.
func _ready():
	auto_button.pressed = save_system.load_cfg_value("Game", "Automatic")
	sens_slider.value = save_system.load_cfg_value("Game", "SteeringSensitivity")
	speed_slider.value = 3.6 - save_system.load_cfg_value("Game", "SteeringSpeedDecay")
	counter_slider.value = 2 * save_system.load_cfg_value("Game", "CountersteerAssist") - 0.2;
	zoom_slider.value = save_system.load_cfg_value("Game", "CameraZoomSpeed")
	
	auto_button.connect("toggled", self, "_on_automatic_toggled")
	sens_slider.connect("value_changed", self, "_on_sens_changed")
	speed_slider.connect("value_changed", self, "_on_speed_sens_changed")
	counter_slider.connect("value_changed", self, "_on_counter_changed")
	zoom_slider.connect("value_changed", self, "_on_zoom_changed")


func _on_automatic_toggled(pressed):
	save_system.save_cfg_value("Game", "Automatic", pressed)


func _on_sens_changed(value):
	save_system.save_cfg_value("Game", "SteeringSensitivity", value)


func _on_speed_sens_changed(value):
	save_system.save_cfg_value("Game", "SteeringSpeedDecay", 3.6 - value)

func _on_counter_changed(value):
	save_system.save_cfg_value("Game", "CountersteerAssist", (value + 0.2) / 2);

func _on_zoom_changed(value):
	save_system.save_cfg_value("Game", "CameraZoomSpeed", value)
