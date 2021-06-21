extends Sprite

# i feel like these are pretty self-explanatory
var _shadow_offset = Vector2(0, 0)
var _sun_direction = Vector2(0, 0)
export var _sun_height = 40
export var dynamic = false


var _done = false


onready var scene_switcher = get_node("/root/SceneSwitcher")
onready var sun = get_node("/root/World/Sun")

# local direction vectors
onready var forward = global_transform.y.normalized()
onready var right = global_transform.x.normalized()

func _ready():
	_sun_direction = sun.position 

func _process(delta):
	if dynamic or !_done:
		_update_shadows()
	if !_done:
		_done = true


func _update_shadows():
	# update direction vectors
	forward = global_transform.y.normalized()
	right = global_transform.x.normalized()
	
	# give the calculated offset to the shadow shader
	self.material.set('shader_param/offset', Vector2(_sun_direction.dot(right) * _sun_height, _sun_direction.dot(forward) * _sun_height))
