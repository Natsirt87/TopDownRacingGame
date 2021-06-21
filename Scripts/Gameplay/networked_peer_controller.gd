extends VehicleController
class_name NetworkedPeerController

var vehicle : Vehicle
var vehicle_name

# control preferences set from lobby script by corresponding client
var steering_speed = 0
var steering_speed_decay = 0
var countersteer_assist = 0

# these input variables are set by the corresponding client over the network
var throttle = 0
var brake = 0
var handbrake = false
var steer_right = 0
var steer_left = 0
var clutch = false
var gear_up = false
var gear_down = false

var save_system 


func init(car_num):
	save_system = get_node("/root/SaveSystem")
	vehicle_name = _cars[car_num]


# instantiates a vehicle for the controller to control, called from lobby script
func create_vehicle():
	var vehicle_resource = load("res://Vehicles/Cars/" + vehicle_name + ".tscn")
	vehicle = vehicle_resource.instance()
	vehicle.set_name(vehicle_name)
	vehicle.automatic = automatic
	vehicle.steering_speed = steering_speed
	vehicle.steering_speed_decay = steering_speed_decay
	vehicle.countersteer_assist = countersteer_assist
	add_child(vehicle)


func _process(delta):
	_set_input()


# time for input

func _set_input():
	vehicle.throttle_input = throttle
	vehicle.brake_input = brake
	vehicle.handbrake_pressed = handbrake
	
	_set_steering_input()
	_process_clutch()
	_process_shifting()


func _set_steering_input():
	var steering_input = 0.0
	var steer_right_strength = steer_right
	var steer_left_strength = steer_left
	steering_input += steer_right_strength
	steering_input -= steer_left_strength
	vehicle.steering_input = steering_input


func _process_clutch():
	vehicle.clutch_pressed = clutch

func _process_shifting():
	if gear_up:
		vehicle.gear_up()
	elif gear_down:
		vehicle.gear_down()
