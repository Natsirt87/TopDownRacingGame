extends Line2D

export var is_light = false

var draw_trail = false # you should probably know what this does
var fade_interval = 5.5 # interval (in seconds) to delete (or "fade out") the last point in the trail
var offset = Vector2(0, 0) # offsets the location of the target point, in order to draw trail at wheel position
# the offset is necessary because if the tire trail is a child of the wheel, it draws in the wrong place (for some reason)
# so instead it's a child of the vehicle scene and thus needs to be offset to match the wheel position (offset given by wheel.gd on creation)

var _point_distance = 3 # distance between points of the line
var _target_point = Vector2(0, 0) # location the line is drawing to (the location of the wheel hopefully)
var _time = 0 # time variable for fading out trail at constant rate
var _point_counter = 0

onready var point = get_parent().global_position # holds the point to add to the line

func init(wheel_offset):
	offset = wheel_offset

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# timer logic
	_time += delta
	
	# make sure the whole trail never moves
	global_position = Vector2(0, 0)
	global_rotation = 0
	
	# make the target point and draw the trail
	_target_point = get_parent().global_position + offset
	_make_trail()
	
	# fade out the end of the trail over time
	if _time > fade_interval:
		remove_point(0)
		_time = 0
	
	# if the trail goes over 1000 points it dies a horrible death, so don't let it do that
	while get_point_count() > 1000:
		remove_point(0)
	
	# if this trail object isn't productive kill it and stop it from eating precious memory
	if !draw_trail and get_point_count() == 0:
		get_parent().remove_child(self)

func _make_trail():
	# gets unit vector towards target point and makes length of point distance
	var direction = point.direction_to(_target_point) * _point_distance
	
	# draw trail towards the target so that every point is _point_distance apart
	while point.distance_to(_target_point) > _point_distance:
		point += direction
		if draw_trail:
			if _point_counter > 15:
				add_point(point)
			else:
				_point_counter += 1
