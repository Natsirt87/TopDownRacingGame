extends Node2D


# input replication (sending)
func send_throttle_input(throttle_input):
	rpc_unreliable("receive_throttle_input", throttle_input)

func send_brake_input(brake_input):
	rpc_unreliable("receive_brake_input", brake_input)

func send_steering_input(steering_input):
	rpc_unreliable("receive_steering_input", steering_input)

func send_handbrake_input(handbrake_pressed):
	rpc_unreliable("receive_handbrake_input", handbrake_pressed)

func send_clutch_input(clutch_input):
	rpc_unreliable("receive_clutch_input", clutch_input)

func send_shift_up():
	rpc("receive_shift_up")

func send_shift_down():
	rpc("receive_shift_down")


# input replication (receiving)
remote func receive_throttle_input(throttle_input):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.throttle = throttle_input

remote func receive_brake_input(brake_input):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.brake = brake_input

remote func receive_steering_input(steering_input):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.steering_input = steering_input

remote func receive_handbrake_input(handbrake_pressed):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.handbrake = handbrake_pressed

remote func receive_clutch_input(clutch_input):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.clutch = clutch_input

remote func receive_shift_up():
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.shift_up()

remote func receive_shift_down():
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.shift_down()


# state replication (sending)
func send_state(player_state):
	rpc_unreliable("receive_state", player_state)

func send_velocity(velocity):
	rpc_unreliable("receive_velocity", velocity)

func send_angular_velocity(angular_velocity):
	rpc_unreliable("receive_angular_velocity", angular_velocity)


# state replication (receiving)
remote func receive_state(player_state):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.set_state(player_state)

remote func receive_velocity(velocity):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.velocity = velocity

remote func receive_angular_velocity(angular_velocity):
	var peer : NetworkedPeerController = get_node_or_null("/root/World/Drivers/" + str(get_tree().get_rpc_sender_id())) 
	if peer == null: return
	peer.angular_velocity = angular_velocity
