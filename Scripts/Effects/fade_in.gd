extends ColorRect


export var reverse = false


# Called when the node enters the scene tree for the first time.
func _ready():
	visible = true
	if !reverse:
		$AnimationPlayer.play("fade_in")
	else:
		$AnimationPlayer.play_backwards("fade_in")


func _on_AnimationPlayer_animation_finished(anim_name):
	visible = false
