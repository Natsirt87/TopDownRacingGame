extends Camera2D
class_name VehicleCamera

export var zoom_sensitivity = 0.035


func _physics_process(delta):
	# mouse wheel zooming
	if Input.is_action_just_released("zoom_in"):
		zoom.x *= 1 - zoom_sensitivity
		zoom.y *= 1 - zoom_sensitivity
	elif Input.is_action_just_released("zoom_out"):
		zoom.x *= 1 + zoom_sensitivity
		zoom.y *= 1 + zoom_sensitivity
	
	# analog stick zooming
	var zoom_in_strength = Input.get_action_strength("zoom_in_axis")
	var zoom_out_strength = Input.get_action_strength("zoom_out_axis")
	zoom.x -= zoom_sensitivity * zoom_in_strength
	zoom.y -= zoom_sensitivity * zoom_in_strength
	zoom.x += zoom_sensitivity * zoom_out_strength
	zoom.y += zoom_sensitivity * zoom_out_strength
	
	# make sure the zoom doesn't get too crazy
	zoom.x = clamp(zoom.x, 0.5, 4)
	zoom.y = clamp(zoom.y, 0.5, 4)
	
	# keep the camera in line by forcing it to never rotate
	global_rotation_degrees = 0
	
	
