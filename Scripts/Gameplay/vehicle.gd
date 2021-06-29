extends RigidBody2D
class_name Vehicle


var automatic = false
var steering_speed
var steering_speed_decay
var countersteer_assist


export(float) var drag = 0.26
export var traction_limit = 4.0
export var braking_force = 2.0
export var front_downforce = 0.0
export var rear_downforce = 0.0
export var handbrake_multiplier = 2.0
export(float, -1, 1) var weight_bias = 0
export(float, -1, 1) var suspension_setup = 0
export(float, -1, 1) var steering_speed_decay_modifier = 0
export(float, 0, 2) var steering_sensitivity_modifier = 1.0
export var dual_clutch = false
export var redline = 7000
export var gear_speeds = [0, 0, 0, 0, 0, 0]
export(Curve) var torque_curve


# basic car stuff
var ABS = true
var rpm = 0 # the flywheel or engine rpm, this is what's displayed
var trans_rpm = 0 # the transmission rpm, this changes depending on the gear
var rpm_diff = 0 # the difference between the two different rpms
var gear = 1 # the gear the car is in
var speed = 0.0 # the speed of the car in mph
var wheel_speed = 0.0
var gear_ratios = [] # the gear ratios for the car, determined based on gear_speeds
var current_power = 1.0 # power modifier, changes power depending on where rpm is in power curve
var idle_rpm = 800 # the engine's idle rpm
var current_idle_rpm = 800 # the engine's current idle rpm (used to slightly modulate rpm when idling)
var engine_load = false # if the engine is under load
var clutch_in = false # if the clutch is in
var shifting = false # if the car is in the process of shifting
var in_neutral = false # if the transmission is in neutral
var hitting_redline = false
var rear_left_traction = true
var rear_right_traction = true

# input variables, set by controller
var throttle_input = 0
var brake_input = 0
var steering_input = 0
var handbrake_pressed = false
var clutch_pressed = false

# variables for physics network synchronization
var networked = false
var state_position = null
var state_rotation = null
var other_position = null
var other_rotation = null
var other_velocity = Vector2(0, 0)
var other_angular_velocity = null
var interp_timer = 0
var interp_pos = null
var velocity_buffer = []
const interp_length = 5

# private car stuff
var _manual_clutch = true
var _wheel_speeds = [50000.0, 50000.0, 50000.0, 50000.0]
var _rear_wheel_speeds = []
var _front_wheel_speeds = []
var _steps_since_redline = -1


# local direction vectors
onready var forward = -global_transform.y.normalized()
onready var right = global_transform.x.normalized()

onready var wheel_group = str(get_instance_id()) + "-wheels"  # unique name for the wheel group
onready var long_velocity_last = 0.0 # vehicle's longitudinal velocity last frame
onready var smooth_tween = get_node("SmoothTween")


func _ready():
	drag *= 0.01
	
	rpm = idle_rpm
	_manual_clutch = !(dual_clutch or automatic)
	
	for i in range(gear_speeds.size()):
		gear_ratios.append((redline - idle_rpm) / gear_speeds[i])
	
	# add wheels to group with unique name
	var wheels = $Wheels.get_children()
	for wheel in wheels:
		wheel.add_to_group(wheel_group)
	
	drag += (rear_downforce + front_downforce) * 0.0004
	
	# give the wheels relevant info
	get_tree().set_group(wheel_group, "vehicle", self)
	get_tree().set_group(wheel_group, "traction_limit", traction_limit)
	get_tree().set_group(wheel_group, "braking_force", braking_force)
	get_tree().set_group(wheel_group, "steering_speed", steering_speed * steering_sensitivity_modifier)
	get_tree().set_group(wheel_group, "countersteer_assist", countersteer_assist)
	get_tree().set_group(wheel_group, "ABS", ABS)
	get_tree().call_group(wheel_group, "setup_suspension", suspension_setup)
	get_tree().call_group(wheel_group, "set_grip_balance", weight_bias)
	get_tree().set_group(wheel_group, "handbrake_multiplier", handbrake_multiplier)
	
	for i in get_tree().get_nodes_in_group(wheel_group):
		if i.front:
			i.downforce = front_downforce
		else:
			i.downforce = rear_downforce


func _process(_delta):
	# update direction vectors
	right = global_transform.x.normalized()
	forward = -global_transform.y.normalized()
	
	if gear == 1 && rpm / redline < 0.5:
		current_power = 0.7
	else:
		current_power = torque_curve.interpolate(rpm / redline)
	
	# calculate and display speed
	speed = (linear_velocity.length() * 0.08) / 1.46666667


func _physics_process(_delta):
	# handle managing and fading between engine audio samples
	_handle_engine_audio()
	
	# process all inputs from the vehicle controller
	_process_input()
	
	# set the wheel speed used for transmission rpm calculation
	_set_trans_wheel_speed()
	
	# apply all tire forces
	get_tree().call_group(wheel_group, "apply_wheel_forces")
	
	# calculate longitudinal acceleration and send it to the wheels to simulate weight shifting
	var long_acceleration = linear_velocity.dot(forward) - long_velocity_last
	long_velocity_last = linear_velocity.dot(forward)
	get_tree().set_group(wheel_group, "long_acceleration", long_acceleration)
	
	if !networked:
		# apply air resistance
		var vel = drag * linear_velocity
		var velSquared = vel.length_squared() * vel.normalized()
		apply_central_impulse(-0.1 * velSquared)


func _integrate_forces(state):
	if networked:
		var transform = state.get_transform()
		
		if other_velocity != null:
			state.linear_velocity = other_velocity
		
		if other_angular_velocity != null:
			state.angular_velocity = other_angular_velocity
		
		if other_rotation != null:
			#global_rotation = lerp(global_rotation, other_rotation, 0.8)
			transform = state.transform.rotated(other_rotation - transform.get_rotation())
		
		
		if other_position != null:
			transform.origin.x = global_position.x
			transform.origin.y = global_position.y
			smooth_tween.interpolate_property(self, "interp_pos", transform.origin, other_position, 0.01, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
			smooth_tween.start()

		if interp_pos != null:
			transform.origin.x = interp_pos.x
			transform.origin.y = interp_pos.y
		
		state.set_transform(transform)
		
		other_rotation = null
		other_velocity = null
		other_angular_velocity = null
	
	state_position = state.transform.get_origin()
	state_rotation = state.transform.get_rotation()


func _on_interp_completed(object, key):
	print("yeah")
	interp_pos = null
	other_position = null


#func _interp_to_position(state, pos):
#	if interp_timer < interp_length:
#		var future_pos = pos
#		future_pos.x += ((state.linear_velocity.x / 60) * (interp_length))
#		future_pos.y += ((state.linear_velocity.y / 60) * (interp_length))
#
#		var x_increase = (future_pos.x - state.transform.origin.x) / interp_length
#		var y_increase = (future_pos.y - state.transform.origin.y) / interp_length
#		state.transform.origin.x += x_increase
#		state.transform.origin.y += y_increase
#
#		interp_timer += 1 
#	else:
#		interp_timer = 0
#		other_position = null


func _interp_to_position(state, pos):
	var length_left = clamp(interp_length - interp_timer, 1, 100)
	var starting_pos = pos

	for i in velocity_buffer.size():
		starting_pos.x += velocity_buffer[i].x
		starting_pos.y += velocity_buffer[i].y

	var future_pos = starting_pos
	future_pos.x += ((state.linear_velocity.x / 60) * (length_left))
	future_pos.y += ((state.linear_velocity.y / 60) * (length_left))

	if interp_timer < interp_length:
		var x_increase = (future_pos.x - state.transform.origin.x) / interp_length
		var y_increase = (future_pos.y - state.transform.origin.y) / interp_length
		state.transform.origin.x += x_increase
		state.transform.origin.y += y_increase

		velocity_buffer.append(state.linear_velocity)
		interp_timer += 1
	else:
		state.transform.origin = future_pos
		interp_timer = 0
		other_position = null
		velocity_buffer.clear()


# wheels send their speeds to the vehicle through this function, vehicle keeps track of them
func add_wheel_speed(wheel_name, new_wheel_speed):
	var index
	match wheel_name:
		"FL":
			index = 0
		"FR":
			index = 1
		"RL":
			index = 2
		"RR":
			index = 3
	
	_wheel_speeds[index] = abs(new_wheel_speed)


func _handle_engine_audio():
	$Audio.set_engine_values(engine_load, rpm / redline)


func _process_input():

	if _steps_since_redline > -1:
		throttle_input = 0
	
	if shifting:
		throttle_input = _set_rpm(throttle_input)
	else:
		_set_rpm(throttle_input)
	if hitting_redline or _steps_since_redline > -1:
		throttle_input = 0
	if throttle_input > 0:
		engine_load = true
	else:
		engine_load = false
	
	if _steps_since_redline > -1:
		if _steps_since_redline < 5:
			_steps_since_redline += 1
		else:
			_steps_since_redline = -1
	
	get_tree().call_group(wheel_group, "drive", throttle_input)
	
	# braking input
	get_tree().call_group(wheel_group, "brake", brake_input)
	
	if handbrake_pressed:
		get_tree().call_group(wheel_group, "handbrake")
	else:
		get_tree().set_group(wheel_group, "wheel_locked", false)
	
	if clutch_pressed:
		if !shifting and _manual_clutch:
			clutch_in = true
	else:
		if !shifting and _manual_clutch:
			clutch_in = false
	
	
	# steering input
	var decay = steering_speed_decay - steering_speed_decay_modifier
	steering_input /= decay * pow(6, linear_velocity.length() / 3000) - (decay - 1)
	
	get_tree().call_group(wheel_group, "steer", steering_input, !(rear_left_traction and rear_right_traction))
	
	if automatic:
		if rpm / redline >= 0.975 and gear != 0 and !in_neutral:
			_shift_up()
		else:
			var new_trans_rpm = abs(wheel_speed) * gear_ratios[gear - 1] + current_idle_rpm
			if new_trans_rpm / redline <= 0.9 and gear != 1 and !in_neutral:
				_shift_down()


func gear_up():
	if !automatic:
		_shift_up()
	elif gear == 0 or in_neutral:
		_shift_up()


func gear_down():
	if !automatic:
		_shift_down()
	elif gear == 1 or in_neutral:
		_shift_down()


func _set_trans_wheel_speed():
	wheel_speed = _wheel_speeds.min()
	get_tree().call_group(wheel_group, "lock_wheel_speed", wheel_speed)


func _shift_up():
	var max_gear = gear_ratios.size() - 1
	if in_neutral:
		gear = 1
		in_neutral = false
	elif gear == 0:
		in_neutral = true
	else:
		if !clutch_in and gear < max_gear:
			clutch_in = true
			shifting = true
		gear = clamp(gear + 1, 0, max_gear)


func _shift_down():
	var max_gear = gear_ratios.size() - 1
	if in_neutral:
		gear = 0
		in_neutral = false
	elif gear == 1:
		in_neutral = true
	else:
		if !clutch_in and gear > 0:
			clutch_in = true
			shifting = true
		gear = clamp(gear - 1, 0, max_gear)


func _set_rpm(throttle_input):
	if randi() % 8 == 1 and speed == 0:
		current_idle_rpm *= rand_range(0.99, 1.01)
	elif speed != 0:
		current_idle_rpm = idle_rpm
	
	# set the transmission rpm
	trans_rpm = clamp(abs(wheel_speed) * gear_ratios[gear] + current_idle_rpm, current_idle_rpm, redline)
	
	# update rpm_diff and initialize new drive input for rev matching
	rpm_diff = rpm - trans_rpm
	var new_throttle_input = 0
	
	
	# set how fast rpm will climb or fall, determines shift speed
	var  rpm_climb = 0.03 * redline
	var rpm_fall = 0.52 * rpm_climb
	
	if dual_clutch and !in_neutral:
		rpm_climb = 0.086 * redline
		rpm_fall = 0.05 * redline
	
	if _steps_since_redline > -1:
		rpm_fall = 75
	
	# rev match if the vehicle is in the process of shifting
	if shifting:
		if abs(rpm_diff) > 200:
			new_throttle_input = _rev_match(rpm_climb, rpm_fall)
			throttle_input = new_throttle_input
		else:
			shifting = false
			clutch_in = false
	
	if clutch_in or in_neutral:
		if !hitting_redline:
			rpm += throttle_input * rpm_climb
		else:
			_steps_since_redline = 0
		
		rpm = clamp(rpm - rpm_fall, current_idle_rpm, redline)
	else:
		_steps_since_redline = -1
		if abs(rpm_diff) < 200:
			rpm = clamp(trans_rpm, 0, redline)
		else:
			var lerp_speed = 0.4
			rpm = lerp(rpm, trans_rpm, lerp_speed)
	return new_throttle_input


func _rev_match(rpm_climb, rpm_fall):
	var net_climb = rpm_climb - rpm_fall
	if trans_rpm < rpm:
		if rpm_diff > rpm_fall:
			return 0
		else:
			var fall_diff = rpm_fall - rpm_diff
			return fall_diff / net_climb
	else:
		return 1



