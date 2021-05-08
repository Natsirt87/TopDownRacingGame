extends Area2D

var _id
onready var race_manager: RaceManager = get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
	_id = int(name.substr(10, 2))
	connect("body_entered", self, "_on_completed")
	pass # Replace with function body.


func _on_completed(body):
	race_manager.on_checkpoint_completed(_id, body.get_parent())
