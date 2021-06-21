extends VBoxContainer

var _car_num
var _car_names = ["Mini", "RX-7", "Alfa"]
var _car_stats = ["", "", ""]

var _track_num
var _track_names = ["Test Track"]

var _mode_num
var _mode_names = ["Practice"]

var _car_texture
var _track_texture

onready var car_name: Label = $TopRow/CarSection/Car
onready var track_name: Label = $TopRow/TrackSection/Track
onready var mode_name: Label = $TopRow/ModeSection/Mode

onready var car_icon: TextureRect = $BottomRow/Car/CarIcon

onready var start_button: Button = get_node("../Start")
onready var save_system = get_node("/root/SaveSystem")
onready var scene_switcher = get_node("/root/SceneSwitcher")


func _ready():
	_car_num = save_system.load_cfg_value("Session", "Car")
	_track_num = save_system.load_cfg_value("Session", "Track")
	_mode_num = save_system.load_cfg_value("Session", "Mode")
	
	car_name.text = _car_names[_car_num]
	track_name.text = _track_names[_track_num]
	mode_name.text = _mode_names[_mode_num]
	
	_set_car_stats()
	_apply_car_change()
	
	start_button.connect("button_down", self, "_on_start")


func _on_start():
	var levelPath = "res://Scenes/Tracks/" + save_system.tracks[save_system.load_cfg_value("Session", "Track")] + ".tscn"
	get_tree().change_scene(levelPath)


func _set_car_stats():
	var mini = "Inline 4 - 110hp\n1890 lbs (857 kg)\n4 Speed Manual\nFront Wheel Drive"
	var rx_7 = "Rotary - 180hp\n2700 lbs (1225 kg)\n5 Speed Manual\nRear Wheel Drive"
	var alfa = "Inline 4 Turbo - 240hp\n2400 lbs (1088 kg)\n6 Speed Dual Clutch\nRear Wheel Drive"
	
	_car_stats[0] = mini
	_car_stats[1] = rx_7
	_car_stats[2] = alfa


func _apply_car_change():
	car_name.text = _car_names[_car_num]
	save_system.save_cfg_value("Session", "Car", _car_num)
	
	_car_texture = load("res://Sprites/Vehicles/" + _car_names[_car_num] + "/" + _car_names[_car_num] + "_1.png")
	car_icon.set_texture(_car_texture)
	
	$BottomRow/Car/Stats/Text.text = _car_stats[_car_num]


func _on_car_previous():
	if _car_num > 0:
		_car_num -= 1
	else:
		_car_num = _car_names.size() - 1
	
	_apply_car_change()



func _on_car_next():
	if _car_num < _car_names.size() - 1:
		_car_num += 1
	else:
		_car_num = 0
	
	_apply_car_change()


func _on_track_previous():
	if _track_num > 0:
		_track_num -= 1
	else:
		_track_num = _track_names.size() - 1
	
	track_name.text = _track_names[_track_num]
	save_system.save_cfg_value("Session", "Track", _track_num)


func _on_track_next():
	if _track_num < _track_names.size() - 1:
		_track_num += 1
	else:
		_track_num = 0
	
	track_name.text = _track_names[_track_num]
	save_system.save_cfg_value("Session", "Track", _track_num)


func _on_mode_previous():
	if _mode_num > 0:
		_mode_num -= 1
	else:
		_mode_num = _mode_names.size() - 1
	
	mode_name.text = _mode_names[_mode_num]
	save_system.save_cfg_value("Session", "Mode", _mode_num)


func _on_mode_next():
	if _mode_num < _mode_names.size() - 1:
		_mode_num += 1
	else:
		_mode_num = 0
	
	mode_name.text = _mode_names[_mode_num]
	save_system.save_cfg_value("Session", "Mode", _mode_num)
