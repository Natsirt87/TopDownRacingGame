extends PlayerController
class_name NetworkedPlayerController

var player_state
var sync_tick = 0
const max_tick = 20
onready var replicator = get_node("/root/Replicator")


func _physics_process(delta):
	_replicate_input()
	_replicate_state()


func _replicate_input():
	replicator.send_throttle_input(Input.get_action_strength("accelerate"))
	replicator.send_brake_input(vehicle.brake_input)
	replicator.send_handbrake_input(vehicle.handbrake_pressed)
	replicator.send_steering_input(vehicle.steering_input)
	replicator.send_clutch_input(vehicle.clutch_pressed)
	
	
	if Input.is_action_just_pressed("gear_up"):
		replicator.send_shift_up()
	elif Input.is_action_just_pressed("gear_down"):
		replicator.send_shift_down()


func _replicate_state():
	if vehicle.state_position != null:
		if sync_tick == max_tick:
			sync_tick = 0
			player_state = {"T": OS.get_system_time_msecs(), "P": vehicle.state_position, "R": vehicle.state_rotation}
			replicator.send_state(player_state)
		else:
			sync_tick += 1
#
		replicator.send_velocity(vehicle.linear_velocity)
		replicator.send_angular_velocity(vehicle.angular_velocity)
