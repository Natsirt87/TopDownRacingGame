extends Node2D
class_name RaceManager

export var starting_points = []

var mode

var _drivers: Array = []
var _num_checkpoints

onready var save_system = get_node("/root/SaveSystem")

class Driver:
	var driver_name = ""
	var controller: VehicleController
	var completed_checkpoints = []
	var lap_times = []
	var starting_pos = 1
	var lap_started = false
	var lap_valid = true
	
	var _lap_start_time = -1
	var _lap_end_time = -1
	
	func _init(controller_reference: VehicleController):
		controller = controller_reference
		driver_name = controller.name
	
	
	func process(delta):
		if controller is PlayerController and lap_started:
			controller.set_lap_time(OS.get_ticks_msec() - _lap_start_time)
	
	
	func new_lap():
		print(driver_name + " is starting a new lap")
		for i in range(completed_checkpoints.size()):
			completed_checkpoints[i] = false
		
		if _lap_start_time == -1:
			lap_started = true
			_lap_start_time = OS.get_ticks_msec()
		else:
			_lap_end_time = OS.get_ticks_msec()
			var lap_time = _lap_end_time - _lap_start_time
			
			if lap_valid:
				lap_times.append(lap_time)
			else:
				lap_times.append(-1)
			
			_lap_start_time = _lap_end_time
			lap_valid = true
			
		
		if controller is PlayerController:
				controller.set_lap_num(lap_times.size() + 1)
				var real_lap_times = []
				
				if lap_times.size() > 0:
					for i in lap_times:
						if (i > 0):
							real_lap_times.append(i)
					
					if real_lap_times.size() > 0:
						controller.set_best_lap(real_lap_times.min())


# Called when the node enters the scene tree for the first time.
func _ready():
	mode = save_system.load_cfg_value("Session", "Mode")
	
	_num_checkpoints = $Checkpoints.get_child_count()
	var drivers_node = get_node("/root/" + get_node("/root/SceneSwitcher").current_scene.name + "/Drivers")
	
	for i in drivers_node.get_children():
		_drivers.append(Driver.new(i))
	
	for i in range(_num_checkpoints):
		for j in _drivers:
			j.completed_checkpoints.append(false)
	
	if mode == 0:
		for i in range(_drivers.size()):
			_drivers[i].starting_pos = i + 1
	
	for i in _drivers:
		i.controller.set_global_position(get_node(starting_points[i.starting_pos - 1]).get_global_position())
		i.controller.set_global_rotation(get_node(starting_points[i.starting_pos - 1]).get_global_rotation())
#		i.controller.get_child(0).set_global_position(get_node(starting_points[i.starting_pos - 1]).get_global_position())
#		i.controller.get_child(0).set_global_rotation(get_node(starting_points[i.starting_pos - 1]).get_global_rotation())


func _process(delta):
	for i in _drivers:
		i.process(delta)


func on_checkpoint_completed(id, driver):
	for i in _drivers:
		if i.controller == driver:
			if id == 0:
				if !i.completed_checkpoints[i.completed_checkpoints.size() - 1] and i.lap_started:
					i.lap_valid = false
					print(driver.name + " cut the track, lap was invalidated")
				
				i.new_lap()
				i.completed_checkpoints[0] = true
			else:
				i.completed_checkpoints[id] = true
				if !i.completed_checkpoints[id - 1] and i.lap_started:
					print(driver.name + " cut the track, lap will be invalidated")
					i.lap_valid = false
					if i.controller is PlayerController:
						i.controller.invalidate_lap()
