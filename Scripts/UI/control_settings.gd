extends HBoxContainer


var can_change_key = false
var can_change_joy_button = false
var can_change_joy_axis = false
var action_string
enum ACTIONS {accelerate, brake, steer_right, steer_left, handbrake, gear_up, gear_down, clutch}

onready var save_system = get_node("/root/SaveSystem")


# Called when the node enters the scene tree for the first time.
func _ready():
	_set_keys()
	_set_joy_controls()


func _set_keys():
	for i in ACTIONS:
		var key_button = get_node("Keybinds/" + str(i))
		key_button.set_pressed(false)
		
		if !InputMap.get_action_list(i).empty():
			var action_list = InputMap.get_action_list(i)
			var key_action = "N/A"
			
			for j in range(action_list.size()):
				if action_list[j] is InputEventKey:
					key_action = action_list[j].as_text()
			
			if "BUTTON_LEFT" in key_action:
				key_action = "LMB"
			elif "BUTTON_RIGHT" in key_action:
				key_action = "RMB"
			
			key_button.set_text(key_action)
		else:
			key_button.set_text("N/A")


func _set_joy_controls():
	var itr = 0
	var joy_control
	var is_button
	
	for i in ACTIONS:
		itr += 1
		
		if itr <= 4:
			joy_control = get_node("JoyControls/Axes/" + str(i))
			is_button = false
		else:
			joy_control = get_node("JoyControls/Buttons/" + str(i))
			is_button = true
		
		joy_control.set_pressed(false)
		
		if !InputMap.get_action_list(i).empty():
			var action_list = InputMap.get_action_list(i)
			var joy_action = "N/A"
			
			for j in range(action_list.size()):
				if is_button:
					if action_list[j] is InputEventJoypadButton:
						joy_action = action_list[j].as_text()
				else:
					if action_list[j] is InputEventJoypadMotion:
						joy_action = action_list[j].as_text()
			
			
			if "axis=7" in joy_action:
				joy_action = "Right Trigger"
			elif "axis=6" in joy_action:
				joy_action = "Left Trigger"
			elif "axis=0" in joy_action:
				if "axis_value=1" in joy_action:
					joy_action = "Left Stick - Right"
				else:
					joy_action = "Left Stick - Left"
			elif "index=0," in joy_action:
				joy_action = "Bottom Face Button"
			elif "index=1," in joy_action:
				joy_action = "Right Face Button"
			elif "index=2," in joy_action:
				joy_action = "Left Face Button"
			elif "index=3," in joy_action:
				joy_action = "Top Face Button"
			elif "index=4," in joy_action:
				joy_action = "Left Bumper"
			elif "index=5," in joy_action:
				joy_action = "Right Bumper"
			elif "index=8," in joy_action:
				joy_action = "Left Stick In"
			elif "index=9," in joy_action:
				joy_action = "Right Stick In"
			elif "index=12," in joy_action:
				joy_action = "DPad Up"
			elif "index=13," in joy_action:
				joy_action = "DPad Down"
			elif "index=14," in joy_action:
				joy_action = "DPad Left"
			elif "index=15," in joy_action:
				joy_action = "DPad Right"
			elif "index=10," in joy_action:
				joy_action = "Select"
			elif "index=11," in joy_action:
				joy_action = "Start"
			else:
				joy_action = "N/A"
			
			joy_control.set_text(joy_action)
		else:
			joy_control.set_text("N/A")


func _mark_key_button(action):
	can_change_key = true
	action_string = action
	
	for i in ACTIONS:
		if i != action:
			get_node("Keybinds/" + str(i)).set_pressed(false)
		else:
			get_node("Keybinds/" + str(i)).set_text("...")


func _mark_joy_button(action, axis):
	can_change_joy_axis = axis
	can_change_joy_button = !axis
	action_string = action
	
	var itr = 0
	for i in ACTIONS:
		itr += 1
		
		if axis and itr <= 4:
			if i != action:
				get_node("JoyControls/Axes/" + str(i)).set_pressed(false)
			else:
				get_node("JoyControls/Axes/" + str(i)).set_text("...")
		elif !axis and itr > 4:
			if i != action:
				get_node("JoyControls/Buttons/" + str(i)).set_pressed(false)
			else:
				get_node("JoyControls/Buttons/" + str(i)).set_text("...")


func _input(event):
	if can_change_key:
		if event is InputEventKey or event is InputEventMouseButton:
			_change_key(event)
			can_change_key = false
	
	if can_change_joy_axis:
		if event is InputEventJoypadMotion:
			_change_joy_axis(event)
			can_change_joy_axis = false
	
	if can_change_joy_button:
		if event is InputEventJoypadButton:
			_change_joy_button(event)
			can_change_joy_button = false


func _change_key(new_key):
	# delete key of pressed button
	
	var action_list = InputMap.get_action_list(action_string)
	
	for i in range(action_list.size()):
		if action_list[i] is InputEventKey:
			InputMap.action_erase_event(action_string, action_list[i])
	
	
	# remove key if it was assigned to another control
	for i in ACTIONS:
		if InputMap.action_has_event(i, new_key):
			InputMap.action_erase_event(i, new_key)
	
	# add new key
	InputMap.action_add_event(action_string, new_key)
	save_system.save_cfg_value("Controls", action_string, InputMap.get_action_list(action_string))
	_set_keys()


func _change_joy_axis(new_axis):
	var action_list = InputMap.get_action_list(action_string)

	if new_axis.get_axis() != 0 and new_axis.get_axis() != 1:
		for i in range(action_list.size()):
			if action_list[i] is InputEventJoypadMotion:
				InputMap.action_erase_event(action_string, action_list[i])
		
		for i in ACTIONS:
			if InputMap.action_has_event(i, new_axis):
				InputMap.action_erase_event(i, new_axis)
		
		InputMap.action_add_event(action_string, new_axis)
		save_system.save_cfg_value("Controls", action_string, InputMap.get_action_list(action_string))
	_set_joy_controls()


func _change_joy_button(new_button):
	var action_list = InputMap.get_action_list(action_string)
	
	for i in range(action_list.size()):
		if action_list[i] is InputEventJoypadButton:
			InputMap.action_erase_event(action_string, action_list[i])
	
	for i in ACTIONS:
		if InputMap.action_has_event(i, new_button):
			InputMap.action_erase_event(i, new_button)
	
	InputMap.action_add_event(action_string, new_button)
	save_system.save_cfg_value("Controls", action_string, InputMap.get_action_list(action_string))
	_set_joy_controls()


func _on_accelerate_pressed():
	_mark_key_button("accelerate")
func _on_brake_pressed():
	_mark_key_button("brake")
func _on_steer_right_pressed():
	_mark_key_button("steer_right")
func _on_steer_left_pressed():
	_mark_key_button("steer_left")
func _on_handbrake_pressed():
	_mark_key_button("handbrake")
func _on_gear_up_pressed():
	_mark_key_button("gear_up")
func _on_gear_down_pressed():
	_mark_key_button("gear_down")
func _on_clutch_pressed():
	_mark_key_button("clutch")

func _on_accelerate_joy_pressed():
	_mark_joy_button("accelerate", true)
func _on_brake_joy_pressed():
	_mark_joy_button("brake", true)
func _on_handbrake_joy_pressed():
	_mark_joy_button("handbrake", false)
func _on_gear_up_joy_pressed():
	_mark_joy_button("gear_up", false)
func _on_gear_down_joy_pressed():
	_mark_joy_button("gear_down", false)
func _on_clutch_joy_pressed():
	_mark_joy_button("clutch", false)
