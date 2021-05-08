extends Area2D

# export variables
export var wheel_name = "" # the name of the wheel, for debugging purposes
export var front = false # if these wheel is a front wheel
export var is_steering = false  # wether a wheel responds to steering input
export var max_angle = 0.0  # maximum anngle the wheel can steer to
export var power = 0.0  # how much a wheel responds to drive input

# public variables
var steering_speed = 0.0  # how fast the wheel steers, set by vehicle.gd
var grip = 1.0 # modifier for the force the tire exerts, changed by weight shift and suspension
var traction_limit = 0.0 # traction limit of the tire, set by vehicle.gd
var braking_force = 0.0 # how powerfully this wheel can brake, determined by vehicle.gd
var long_acceleration = 0.0 # longitudinal acceleration the vehicle is under, set by vehicle.gd
var ABS = true # if the car has anti-lock brakes, set by Vehicle.gd
var downforce = 0.0 # how much downforce the wheel is effected by
var wheel_locked = false # if the wheel is currently locked by the handbrake
var handbrake_multiplier = 0.0

# private variables
var _effective_grip = 0.0 # the actual grip of the tire
var _desired_traction = 0.0 # how much traction we are requiring from the tire
var _current_traction_limit = 0.0
var _applied_downforce
var _torque = 0.0 # the torque being applied to the wheel
var _wheel_speed = 0 # the speed the wheel is spinning at in mph
var _has_traction = true # if the wheel currently has traction (necessary because _desired_traction is reset and recalculated every frame)
var _wheel_spinning = false # if the wheel is spinning
var _on_grass = true # if the wheel is currently on grass

var _drawing_tire_trail = false # if a tire trail is currently being drawn
var _tire_trail_dark = false
var _tire_trail # the current tire trail Line2D object that is responsible for skid marks


# onready variables
onready var vehicle: Vehicle # set by Vehicle.gd, until then just some temporary rigidbody so that the script throw a fit
onready var forward = -global_transform.y.normalized() # vehicle's forward vector
onready var right = global_transform.x.normalized() # vehicle's right vector
onready var player_to_wheel = Vector2(0, 0) # offset of the wheel relative to the center of the vehicle
onready var last_position = global_position 
onready var linear_velocity = global_position - last_position
onready var tire_smoke_particle = $TireSmoke # reference to the tire smoke particle effect node


func _process(delta):
	# update direction unit vectors and position vector relative to body
	forward = -(global_transform.y.normalized())
	right = global_transform.x.normalized()
	player_to_wheel = global_position - vehicle.global_position
	
	_handle_tire_effects()


func _ready():
	self.connect("area_entered", self, "_toggle_grass")
	self.connect("area_exited", self, "_toggle_grass")
	
	


func _physics_process(delta):
	# get approximate velocity vector
	linear_velocity = global_position - last_position
	last_position = global_position


func setup_suspension(suspension_setup):
	# simulates suspension changes to make the car understeer or oversteer more easily
	if front:
		traction_limit -= (traction_limit / 4) * suspension_setup
	else:
		traction_limit += (traction_limit / 4) * suspension_setup


func set_grip_balance(grip_balance):
	if front:
		grip *= 1 + (grip_balance * 0.2)
		traction_limit += (traction_limit / 4) * grip_balance
	else:
		grip *= 1 - (grip_balance * 0.2)
		traction_limit -= (traction_limit /4) * grip_balance


func steer(steering_input):
	if is_steering:
		var desired_angle = steering_input * max_angle
		var new_angle = lerp(rotation_degrees, desired_angle, steering_speed)
		rotation_degrees = new_angle


func drive(throttle_input):
	if power > 0:
		var power_applied = 0
	
		if !vehicle.clutch_in and !vehicle.in_neutral:
			var speed_mod = clamp(-0.1 * vehicle.speed + 2, 1, 2)
			power_applied = clamp(_effective_grip / (grip) * speed_mod, 0, 1) * (power * vehicle.current_power)
		
		if vehicle.gear == 0:
			power_applied *= -1
		
		if vehicle.rpm < vehicle.redline:
			if !wheel_locked:
				vehicle.apply_impulse(player_to_wheel, throttle_input * power_applied * forward)
				
				if !vehicle.clutch_in and !vehicle.in_neutral:
					_torque = abs(power * vehicle.current_power) * throttle_input
				else:
					_torque = 0
			
			vehicle.hitting_redline = false
		else:
			if !vehicle.clutch_in and !vehicle.in_neutral and !_wheel_spinning:
				vehicle.apply_impulse(player_to_wheel, (-linear_velocity.normalized().dot(forward) * forward) * 4)
			vehicle.hitting_redline = true
			_torque = 0
		
		_set_wheel_speed(throttle_input)


func brake(brake_input):
	# slow down by braking_force when brakes applied, if car is almost stopped set its velocity to 0
	if brake_input > 0:
		if vehicle.linear_velocity.length() < 5:
			vehicle.linear_velocity = Vector2(0, 0)
			vehicle.angular_velocity = 0
		
		var desired_braking_force = -linear_velocity.normalized() * (braking_force * brake_input)
		
		# front tires do more work when braking
		if front:
			desired_braking_force *= 1.25
		else:
			desired_braking_force *= 0.75
		
		# take away torque proportional to how much the wheel is braking
		if _torque > 0:
			_torque = clamp(_torque - (braking_force * brake_input), 0, _torque)
		
		if !_has_traction and ABS:
			desired_braking_force *= 0.1
		
		
		if vehicle.linear_velocity.length() > 5:
			vehicle.apply_impulse(player_to_wheel, desired_braking_force)
			pass
		
		_desired_traction += abs(desired_braking_force.length())


func handbrake():
	if !front:
		_desired_traction += _current_traction_limit * handbrake_multiplier
		print(handbrake_multiplier)
		wheel_locked = true

func apply_wheel_forces():
	var lateral_velocity = linear_velocity.dot(right)
	var desired_lateral_force = -(grip * lateral_velocity * right)
	
	_shift_weight()
	_apply_downforce()
	
	# determine how much traction the wheel is being asked to provide
	_desired_traction += abs(desired_lateral_force.length())
	
	if _on_grass:
		_current_traction_limit = 2.0
	else:
		_current_traction_limit = traction_limit + _applied_downforce
	
	if _has_traction:
		_desired_traction += abs(_torque * 0.02)
		if _wheel_speed > vehicle.speed + 1:
			_desired_traction += abs(_wheel_speed - vehicle.speed)
	else:
		# if the wheel is already sliding then any torque being applied will make it want to keep sliding
		if _wheel_spinning:
			var speed_diff = _wheel_speed - vehicle.speed
			var possible_torque = power * vehicle.current_power
			
			if vehicle.speed > 0:
				_desired_traction += (abs(speed_diff) * ((3 / (vehicle.speed)) ) + (possible_torque)) * (pow(vehicle.current_power, 3))
			else:
				_desired_traction += (abs(speed_diff)  + (possible_torque)) * (vehicle.current_power) * 5
		else:
			_desired_traction *= 1.5
	
	if _desired_traction > _current_traction_limit:
		# if the wheel breaks traction, decrease its effective_grip depending on how much its going over its traction limit
		var traction_difference = clamp(log(_desired_traction - (_current_traction_limit)) * 0.1, 0.1, grip * 0.5)
		_effective_grip = clamp(_effective_grip - (traction_difference * grip), 0.2, 1.0)
		
		
		# if any _torque is applied, then the wheel is spinning and will have reduced grip depending on the torque
		if (traction_difference > 0):
			if (power > 0  and (_wheel_speed - vehicle.speed > 4 or _torque > (_current_traction_limit / 3))):
				var spin_mod 
				if _wheel_speed - vehicle.speed > 0.1:
					spin_mod = 0.03 * sqrt(_wheel_speed - vehicle.speed)
				else:
					spin_mod = 0
				
				var wheel_spin_grip = (grip * 0.62) - spin_mod
				_effective_grip = clamp(wheel_spin_grip, 0.25, 1.0)
				
				if !wheel_locked:
					_wheel_spinning = true
				else:
					_wheel_spinning = false
				
				_apply_sliding_friction(traction_difference * 20)
			else:
				_wheel_spinning = false
				_apply_sliding_friction(traction_difference)
		
		_has_traction = false
	else:
		_wheel_spinning = false
		_has_traction = true
	
	# apply the lateral force generated from the tire that was just calculated
	var lateral_force = -(_effective_grip * lateral_velocity * right)
	vehicle.apply_impulse(player_to_wheel, lateral_force)
	
	if _on_grass:
		_effective_grip *= 0.8
	
	# reset variables to be recalculated next frame
	_desired_traction = 0.0
	_effective_grip = grip


func lock_wheel_speed(new_wheel_speed):
	if power > 0:
		if abs(_wheel_speed - new_wheel_speed) > 5:
			_wheel_speed = new_wheel_speed


func _apply_sliding_friction(traction_difference):
	# apply opposing force at the wheel when traction is broken to simulate friction from the tire sliding
	vehicle.apply_central_impulse(-linear_velocity.normalized() * ((linear_velocity.length() / 120) / (traction_difference * 6)))


func _shift_weight():
	# distribute longitudinal grip depending on the acceleration of the car, simulates the COM shifting
	if front:
		_effective_grip -= long_acceleration * 0.005
		_desired_traction -= long_acceleration * 0.1 
	else:
		_effective_grip += long_acceleration * 0.005
		_desired_traction += long_acceleration * 0.1


func _apply_downforce():
	_applied_downforce = 0.5 * downforce * pow(linear_velocity.length(), 2)
	_applied_downforce /= 170


func _set_wheel_speed(throttle_input):
	
	# only set the rpm based on the wheels if the wheels are driven
	if power > 0: 
		# if the wheels are spinning, properly set their speed based on power applied to them
		if _wheel_spinning and _wheel_speed > vehicle.speed:
			
			var speed_diff = _wheel_speed - vehicle.speed
			var speed_fall = pow(speed_diff, 2) / 200 + _current_traction_limit
			var torque_increase = _torque * 0.8 / (_current_traction_limit / 2)
			
			if vehicle.speed != 0:
				torque_increase *= clamp(30 / (vehicle.speed + 10), 1, 3)
				torque_increase *= pow(vehicle.current_power, 4)
			
			var speed_climb = (torque_increase + (throttle_input * (pow(speed_diff, 2) / 600 + _current_traction_limit)))
			
			if vehicle.hitting_redline:
				speed_fall *= 0.2
			_wheel_speed += speed_climb
			_wheel_speed -= speed_fall
		elif !vehicle.clutch_in and !vehicle.in_neutral and vehicle.rpm_diff > 200:
			var new_wheel_speed = (vehicle.rpm - vehicle.current_idle_rpm) / vehicle.gear_ratios[vehicle.gear]
			_wheel_speed = lerp(_wheel_speed, new_wheel_speed, 0.8)
		else:
			_wheel_speed = vehicle.speed
		
		vehicle.add_wheel_speed(wheel_name, _wheel_speed)


func _handle_tire_effects():
	# draws tire trail if wheel is sliding and stops them from drawing if it isn't
	if power > 0:
		if !_on_grass:
			if _wheel_speed - vehicle.speed > 10:
				tire_smoke_particle.emitting = true
			else:
				tire_smoke_particle.emitting = false
			
			if _wheel_spinning:
				if !_drawing_tire_trail:
					
					if _wheel_spinning:
						_tire_trail = load("res://Scenes/TireTrail.tscn").instance()
						_tire_trail_dark = true
					else:
						_tire_trail = load("res://Scenes/LightTireTrail.tscn").instance()
						_tire_trail_dark = false
					
					_tire_trail.init(player_to_wheel)
					vehicle.add_child(_tire_trail)
					_drawing_tire_trail = true
				else:
					_tire_trail.offset = player_to_wheel
					_tire_trail.draw_trail = true
			elif !vehicle.hitting_redline:
				if _tire_trail:
					_tire_trail.draw_trail = false
				_drawing_tire_trail = false
		else:
			if _tire_trail:
				_tire_trail.draw_trail = false
			_drawing_tire_trail = false
			tire_smoke_particle.emitting = false


func _toggle_grass(area):
	if "Track" in area.name:
		_on_grass = !_on_grass
