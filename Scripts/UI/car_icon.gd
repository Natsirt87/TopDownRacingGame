extends TextureRect


export(int) var car_num

var _cars = ["Mini", "RX-7"]


# Called when the node enters the scene tree for the first time.
func _ready():
	var car = load("res://Vehicles/Cars/" + _cars[car_num] + ".tscn")
	print(car.automatic)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
