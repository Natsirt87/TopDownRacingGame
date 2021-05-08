extends Control


onready var scene_switcher = get_node("/root/SceneSwitcher")
onready var player_list : ItemList = $Menu/MainRow/PlayerList

# connect all those dang functions 

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

# player info, ID associated to data
var player_info = {}

# info to be sent to other player
var my_info = {}

func set_name(new_name):
	my_info["name"] = new_name
	player_list.add_item(new_name, null, false)

func _player_connected(id):
	# called on both clients and server when peer connects. Send my info to it
	rpc_id(id, "register_player", my_info)

func _player_disconnected(id):
	player_list.remove_item(player_info[id]["idx"])
	player_info.erase(id) # delete player info

func _connected_ok():
	print("Connected successfully")

func _server_disconnected():
	visible = false
	print("Kicked from server, uh-oh")
	_go_back()

func _connected_fail():
	visible = false
	print("Unable to connect to server")
	_go_back()


remote func register_player(info):
	# get id of RPC sender
	var id = get_tree().get_rpc_sender_id()
	# store the info
	player_info[id] = info
	player_list.add_item(info["name"], null, false)
	player_info[id]["idx"] = player_list.get_item_count() - 1
	print(player_info)


func _on_disconnect():
	get_tree().network_peer = null
	visible = false
	_go_back()

func _go_back():
	scene_switcher.goto_scene("res://Scenes/UI/MainMenu/MultiplayerScreen.tscn", false, false)
	player_info.clear()
	
	player_list.clear()
	
	print(player_info)
