extends Control

const DEFAULT_IP : String = "127.0.0.1"
const DEFAULT_PORT = 35516
const MAX_CLIENTS = 10

onready var lobby = get_node("/root/Lobby")

onready var join_button : Button = $Menu/JoinContainer/Join
onready var join_ip : TextEdit = $Menu/JoinContainer/IP
onready var host_button : Button = $Menu/Host
onready var player_name : TextEdit = $Menu/NameContainer/Name

func _ready():
	join_button.connect("button_down", self, "_on_join")
	host_button.connect("button_down", self, "_on_host")


func _process(delta):
	if player_name.text == "":
		join_button.disabled = true
		host_button.disabled = true
	else:
		if join_ip.text != "":
			join_button.disabled = false
		host_button.disabled = false


func _on_join():
	print("joining")
	lobby.set_info()
	lobby.set_name(player_name.text)
	var peer = NetworkedMultiplayerENet.new()
	peer.create_client(join_ip.text, DEFAULT_PORT)
	get_tree().network_peer = peer
	var current_scene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	current_scene.queue_free()
	lobby.visible = true


func _on_host():
	print("hosting")
	lobby.set_info()
	lobby.set_name(player_name.text)
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().network_peer = peer
	var current_scene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	current_scene.queue_free()
	lobby.visible = true


