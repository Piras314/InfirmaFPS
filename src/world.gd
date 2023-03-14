extends Node

@onready var main_menu = $UI/MainMenu
@onready var address_entry = $UI/MainMenu/MarginContainer/VBoxContainer/AddressEntry
@onready var hud = $UI/HUD
@onready var health_bar = $UI/HUD/HealthBar

const Player = preload("res://scn/ent/player.tscn")

const RV_ADDRESS = "192.168.1.2"
const RV_PORT = 19571

var enet_peer = ENetMultiplayerPeer.new()
var hole_puncher = preload('res://addons/Holepunch/holepunch_node.gd').new()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("esc"):
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			get_tree().quit()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if Input.is_action_just_pressed("shoot") && \
		Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_host_button_pressed():
	main_menu.hide()
	hud.show()
	
	hole_puncher.rendevouz_address = RV_ADDRESS
	hole_puncher.rendevouz_port = RV_PORT
	
	add_child(hole_puncher)
	
	hole_puncher.start_traversal(address_entry.text, true, OS.get_unique_id())
	
	var result = await hole_puncher.hole_punched
	print("punch")
	var port = result[0]
	print(port)
	
	multiplayer.multiplayer_peer = null
	
	print(enet_peer.create_server(port, 1))
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(rm_player)
	
	add_player(multiplayer.get_unique_id())

func _on_join_button_pressed():
	main_menu.hide()
	hud.show()
	
	hole_puncher.rendevouz_address = RV_ADDRESS
	hole_puncher.rendevouz_port = RV_PORT
	
	add_child(hole_puncher)
	
	hole_puncher.start_traversal(address_entry.text, false, OS.get_unique_id() + "-client")

	var result = await hole_puncher.hole_punched
	var host_ip = result[2]
	var host_port = result[1]
	var own_port = result[0]
	
	enet_peer.create_client(host_ip, host_port, 0, 0, own_port)
	multiplayer.multiplayer_peer = enet_peer

func add_player(peer_id):
	var player = Player.instantiate()
	
	player.name = str(peer_id)
	add_child(player)
	
	if player.is_multiplayer_authority():
		player.health_changed.connect(update_health_bar)

func rm_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	
	if player:
		player.queue_free()

func update_health_bar(value):
	health_bar.value = value

func _on_multiplayer_spawner_spawned(node):
	#if node != CharacterBody3D: pass
	
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
