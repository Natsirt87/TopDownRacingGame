extends Sprite

# i feel like these are pretty self-explanatory
var _shadow_offset = Vector2(0, 0)
var _sun_direction = Vector2(0, 0)
export var _sun_height = 40
export var dynamic = false
export var car = false

onready var sun = get_node("/root/World/Sun")

# local direction vectors
onready var forward = global_transform.y.normalized()
onready var right = global_transform.x.normalized()

func _ready():
	_sun_direction = sun.position 
	
	if car:
		set_texture(get_parent().get_texture())
	
	_update_shadows()

func _process(delta):
	if dynamic:
		_update_shadows()


func _update_shadows():
	# update direction vectors
	forward = global_transform.y.normalized()
	right = global_transform.x.normalized()
	var offset = Vector2(_sun_direction.dot(right) * _sun_height, _sun_direction.dot(forward) * _sun_height)
	set_global_position(get_parent().get_global_position() + offset)
	# give the calculated offset to the shadow shader
	self.material.set_shader_param("offset", Vector2(_sun_direction.dot(right) * _sun_height, _sun_direction.dot(forward) * _sun_height))
