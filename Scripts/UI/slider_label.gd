extends Label


func _ready():
	var slider = get_parent()
	text = str(slider.value)


func _on_SensSlider_value_changed(value):
	text = str(value)
