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
var steering_input = 0
var clutch = false
var gear_up = false
var gear_down = false

var current_state = null
var state_time = 0

var velocity = Vector2(0, 0)
var angular_velocity = 0

var save_system 

func init(car_num):
	save_system = get_node("/root/SaveSystem")
	vehicle_name = _cars[car_num]


# instantiates a vehicle for the controller to control, called from lobby script
func create_vehicle():
	var vehicle_resource = load("res://Vehicles/Cars/" + vehicle_name + ".tscn")
	vehicle = vehicle_resource.instance()
	vehicle.set_name(vehicle_name)
	vehicle.networked = true
	vehicle.automatic = automatic
	vehicle.steering_speed = steering_speed
	vehicle.steering_speed_decay = steering_speed_decay
	vehicle.countersteer_assist = countersteer_assist
	add_child(vehicle)


func _physics_process(delta):
	_set_input()
	if current_state != null:
		_set_position(current_state["P"])
		_set_rotation(current_state["R"])
		current_state = null
	
	set_velocity(velocity)
	set_angular_velocity(angular_velocity)


func _set_input():
	vehicle.throttle_input = throttle
	vehicle.brake_input = brake
	vehicle.handbrake_pressed = handbrake
	vehicle.steering_input = steering_input
	vehicle.clutch_pressed = clutch


func set_state(state):
	if state["T"] > state_time:
		state_time = state["T"]
		current_state = state


func shift_up():
	vehicle.gear_up()

func shift_down():
	vehicle.gear_down()


func _set_position(position):
	if vehicle.other_position == null:
		vehicle.other_position = position

func _set_rotation(rotation):
	if vehicle.other_rotation == null:
		vehicle.other_rotation = rotation


func set_velocity(velocity):
	vehicle.other_velocity = velocity

func set_angular_velocity(angular_velocity):
	vehicle.other_angular_velocity = angular_velocity
