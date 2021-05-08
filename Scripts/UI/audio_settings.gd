extends VBoxContainer


onready var save_system = get_node("/root/SaveSystem")


func _ready():
	var master_volume = save_system.load_cfg_value("Audio", "MasterVolume") * 100
	$MasterSlider.value = master_volume
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(master_volume / 100))
	
	$MasterSlider.connect("value_changed", self, "_on_master_changed")


func _on_master_changed(value):
	var volume
	if value != 0:
		volume = value / 100
	else:
		volume = 0.0001
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(volume))
	save_system.save_cfg_value("Audio", "MasterVolume", volume)
