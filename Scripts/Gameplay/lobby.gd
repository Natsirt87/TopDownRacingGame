
extends Control

onready var player_list : ItemList = $Menu/MainRow/PlayerList
onready var save_system = get_node("/root/SaveSystem")

# player info, ID associated to data
var player_info = {}
var my_info = {name = "", ready = false, starting_pos = -1}
var clients_loaded = []
var server_loaded = false
var game_started = false

# connect all those dang functions 
func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	set_info()

func set_info():
	my_info["car"] = save_system.load_cfg_value("Session", "Car")
	my_info["auto"] = save_system.load_cfg_value("Game", "Automatic")
	my_info["steer_sens"] = save_system.load_cfg_value("Game", "SteeringSensitivity")
	my_info["steer_decay"] = save_system.load_cfg_value("Game", "SteeringSpeedDecay")
	my_info["ctrsteer_assist"] = save_system.load_cfg_value("Game", "CountersteerAssist")

func set_name(new_name):
	my_info["name"] = new_name
	player_list.add_item(new_name, null, false)


func _player_connected(id):
	# called on both clients and server when peer connects. Send my info to it
	rpc_id(id, "register_player", my_info)


func _player_disconnected(id):
	player_info.erase(id) # delete player info
	if  game_started:
		var driver = get_node_or_null("/root/World/Drivers/" + str(id))
		if driver != null:
			driver.queue_free()
	else:
		player_list.remove_item(player_info[id]["idx"])
	


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


func _go_back():
	if game_started:
		get_node("/root/World").queue_free()
		game_started = false
		if get_tree().is_network_server():
			get_tree().refuse_new_network_connections = false
	
	my_info["ready"] = false
	my_info["starting_pos"] = -1
	$Menu/Ready.pressed = false
	server_loaded = false
	clients_loaded = []
	player_info = {}
	
	get_tree().change_scene("res://Scenes/UI/MainMenu/MultiplayerScreen.tscn")
	player_info.clear()
	player_list.clear()


func _on_ready_toggled(button_pressed):
	my_info["ready"] = button_pressed
	rpc("update_player", my_info)
	for p in player_info:
		if player_info[p]["ready"] == false:
			return
	
	if my_info["ready"]:
		rpc_id(1, "start_game")


func on_disconnect():
	get_tree().network_peer = null
	visible = false
	_go_back()


remote func register_player(info):
	# get id of RPC sender
	var id = get_tree().get_rpc_sender_id()
	# store the info
	player_info[id] = info
	player_list.add_item(info["name"], null, false)
	player_info[id]["idx"] = player_list.get_item_count() - 1


remote func update_player(info):
	var id = get_tree().get_rpc_sender_id()
	player_info[id] = info
	
	if get_tree().is_network_server() and my_info["starting_pos"] != -1:
		for p in player_info:
			if player_info[p]["starting_pos"] == -1:
				return
		get_tree().refuse_new_network_connections = true
		rpc("pre_configure_game")


remotesync func start_game():
	if get_tree().is_network_server():
		var starting_positions = []
		for i in player_info.size() + 1:
			starting_positions.append(i + 1)
		
		starting_positions.shuffle()
		
		my_info["starting_pos"] = starting_positions[0]
		rpc("update_player", my_info)
		
		var itr = 1
		for p in player_info:
			rpc_id(p, "set_starting_pos", starting_positions[itr])
			itr += 1


remote func set_starting_pos(pos):
	my_info["starting_pos"] = pos
	rpc("update_player", my_info)


remotesync func pre_configure_game():
	get_tree().set_pause(true)
	var selfPeerID = get_tree().get_network_unique_id()
	print(player_info)
	# load world
	var levelPath = "res://Scenes/Tracks/" + save_system.tracks[save_system.load_cfg_value("Session", "Track")] + ".tscn"
	var world = load(levelPath).instance()
	get_node("/root").add_child(world)
	
	# load player
	var player = preload("res://Scenes/NetworkedPlayer.tscn").instance()
	player.set_name(str(selfPeerID))
	player.set_network_master(selfPeerID)
	get_node("/root/World/Drivers").add_child(player)
	player.init()
	player.starting_pos = my_info["starting_pos"]
	
	# load other players
	for p in player_info:
		var peer = preload("res://Scenes/NetworkedPeer.tscn").instance()
		peer.set_name(str(p))
		peer.set_network_master(p)
		get_node("/root/World/Drivers").add_child(peer)
		
		# setting all of the player data to the correct values for each peer
		peer.starting_pos = player_info[p]["starting_pos"]
		peer.steering_speed = player_info[p]["steer_sens"]
		peer.steering_speed_decay = player_info[p]["steer_decay"]
		peer.countersteer_assist = player_info[p]["ctrsteer_assist"]
		peer.init(player_info[p]["car"])
	
	if get_tree().is_network_server():
		server_loaded = true
	else:
		rpc_id(1, "done_preconfiguring")


remote func done_preconfiguring():
	var who = get_tree().get_rpc_sender_id()
	assert(get_tree().is_network_server())
	assert(who in player_info)
	assert(not who in clients_loaded)
	
	clients_loaded.append(who)
	if clients_loaded.size() == player_info.size() and server_loaded:
		rpc("post_configure_game")


remotesync func post_configure_game():
	if get_tree().get_rpc_sender_id() == 1:
		get_tree().set_pause(false)
		game_started = true
		get_node("/root/World/RaceManager").init()
		visible = false
