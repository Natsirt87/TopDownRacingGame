extends VehicleController
class_name PlayerController


var steering_speed
var steering_speed_decay
var hud
var vehicle : Vehicle


var _lap_valid = false
var _vehicle_speed = 0.0


onready var save_system = get_node("/root/SaveSystem")

func _ready():
	automatic = save_system.load_cfg_value("Game", "Automatic")
	steering_speed = save_system.load_cfg_value("Game", "SteeringSensitivity")
	steering_speed_decay = save_system.load_cfg_value("Game", "SteeringSpeedDecay")
	
	_create_vehicle()
	
	hud = load("res://Scenes/UI/DebugHUD.tscn").instance()
	add_child(hud)


# instantiates a vehicle for the controller to control

func _create_vehicle():
	var vehicle_name = _cars[save_system.load_cfg_value("Session", "Car")]
	var vehicle_resource = load("res://Vehicles/Cars/" + vehicle_name + ".tscn")
	vehicle = vehicle_resource.instance()
	vehicle.set_name(vehicle_name)
	vehicle.automatic = automatic
	vehicle.steering_speed = steering_speed
	vehicle.steering_speed_decay = steering_speed_decay
	add_child(vehicle)
	
	
	var camera = VehicleCamera.new()
	camera.set_name("PlayerCamera")
	vehicle.add_child(camera)
	camera.current = true


func _process(delta):
	_set_input()
	_set_vehicle_stats()


# setting the vehicle stats that are displayed on the HUD

func _set_vehicle_stats():
	_vehicle_speed = vehicle.linear_velocity.length()
	hud.speed_label.text = str(int(vehicle.wheel_speed)) + " MPH"
	hud.rpm_label.text = "RPM: " + str(int(vehicle.rpm))
	_set_vehicle_gear(vehicle.gear, vehicle.in_neutral)


func _set_vehicle_gear(gear, in_neutral):
	if in_neutral:
		hud.gear_label.text = "Gear: N"
	elif gear == 0:
		hud.gear_label.text = "Gear: R"
	else:
		if automatic:
			hud.gear_label.text = "Gear: D"
		else:
			hud.gear_label.text = "Gear: " + str(gear) 


# some more HUD stuff, this time lap-related
# these functions are called by the RaceManager

func set_lap_num(lap_num):
	hud.lap_num_label.text = "Lap: " + str(lap_num)
	hud.lap_time_label.set("custom_colors/font_color", Color(1,1,1))
	hud.warning_label.visible = false
	_lap_valid = true;


func set_best_lap(lap_time):
	lap_time = float(lap_time / 1000.0)
	hud.best_lap_label.text = "Best Lap: " + _convert_to_time(lap_time, 3)


func set_lap_time(lap_time):
	lap_time = float(lap_time / 1000.0)
	hud.lap_time_label.text = _convert_to_time(lap_time, 2)


func invalidate_lap():
	hud.lap_time_label.set("custom_colors/font_color", Color(1,0,0))
	hud.warning_label.text = "Cut Detected, Lap Invalid"
	hud.warning_label.visible = true


# time for input
# this just gives all of the player input to the vehicle so it can do stuff with it

func _set_input():
	vehicle.throttle_input = Input.get_action_strength("accelerate")
	vehicle.brake_input = Input.get_action_strength("brake")
	vehicle.handbrake_pressed = Input.is_action_pressed("handbrake")
	
	_set_steering_input()
	_process_clutch()
	_process_shifting()


func _set_steering_input():
	var steering_input = 0.0
	var steer_right_strength = Input.get_action_strength("steer_right")
	var steer_left_strength = Input.get_action_strength("steer_left")
	steering_input += steer_right_strength
	steering_input -= steer_left_strength
	vehicle.steering_input = steering_input


func _process_clutch():
	if Input.is_action_just_pressed("clutch"):
		vehicle.clutch_pressed = true
	elif Input.is_action_just_released("clutch"):
		vehicle.clutch_pressed = false

func _process_shifting():
	if Input.is_action_just_pressed("gear_up"):
		vehicle.gear_up()
	elif Input.is_action_just_pressed("gear_down"):
		vehicle.gear_down()


func _convert_to_time(seconds, decimal_places):
	
	var time
	var cutoff = 0
	var added_zeros = 0
	var decimal = str(seconds).find(".")
	cutoff = str(seconds).substr(decimal).length() - (decimal_places + 1)
	
	if cutoff < 0:
		added_zeros = abs(cutoff)
		cutoff = 0
	
	if seconds < 60:
		time = str(seconds).substr(0, str(seconds).length() - cutoff)
	else:
		var minutes = int(seconds) / 60
		seconds -= 60 * minutes
		
		if seconds < 10:
			seconds = "0" + str(seconds)
		else:
			seconds = str(seconds)
		
		time = str(minutes) + ":" + seconds.substr(0, seconds.length() - cutoff)
	
	var zeros = ""
	for i in range(added_zeros):
		zeros += "0"
	time += zeros
	
	return time
