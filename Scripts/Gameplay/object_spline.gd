extends Line2D

export(String) var object
export var distance = 50.0
export var scale_distance = 0.0
export var offset = 0.0
export var remove_first = false


# Called when the node enters the scene tree for the first time.
func _ready():
	_scale_points()
	_populate_spline()


func _populate_spline():
	distance *= 1 / global_scale.x
	var object_resource = load(object)
	var point = get_point_position(0)
	var first = true
	
	for i in range(get_point_count() - 1):
		var target_point = get_point_position(i + 1)
		var direction = point.direction_to(target_point) * distance
		
		while point.distance_to(target_point) > distance:
			if remove_first:
				if !first:
					_instantiate_object(point, object_resource)
			else:
				_instantiate_object(point, object_resource)
			point += direction
			if first:
				first = false
		
		_instantiate_object(point, object_resource)
		
		var old_point = point
		if i < get_point_count() - 2:
			point = get_point_position(i + 1)
			target_point = get_point_position(i + 2)
			direction = point.direction_to(target_point)
			
			while point.distance_to(old_point) < distance:
				point += direction


func _instantiate_object(point : Vector2, resource : Resource):
	var object_instance = resource.instance()
	object_instance.global_position = point
	object_instance.global_scale = Vector2(1 / global_scale.x, 1 / global_scale.y)
	add_child(object_instance)


func _scale_points():
	var point
	var next_point
	var direction
	var offset_direction
	for i in range(get_point_count()):
		point = get_point_position(i)
		if i < get_point_count() - 1:
			next_point = get_point_position(i + 1)
			direction = next_point.direction_to(point).tangent() * scale_distance
			offset_direction = point.direction_to(next_point) * offset
		
		point += direction
		point += offset_direction
		set_point_position(i, point)
