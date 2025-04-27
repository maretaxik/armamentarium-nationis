extends Node

# Network settings
const DEFAULT_PORT = 28960
var server_address = "127.0.0.1"
var is_connecting = false

# Player data
var player_name = "Player"
var player_id = 0
var players = {}

# Game state
var in_game = false
var team = 0

# UI references
@onready var ui = $UI
@onready var world = $World

# Signals
signal connected_to_server
signal connection_failed
signal disconnected

func _ready():
	# Debug UI paths
	print("Checking UI node paths:")
	print("MainMenu exists: " + str($UI/MainMenu != null))
	print("LobbyScreen exists: " + str($UI/LobbyScreen != null))
	print("ReadyButton exists: " + str($UI/LobbyScreen/VBoxContainer/ReadyButton != null))
	print("Team1Button exists: " + str($UI/LobbyScreen/VBoxContainer/TeamButtons/Team1Button != null))
	print("Team2Button exists: " + str($UI/LobbyScreen/VBoxContainer/TeamButtons/Team2Button != null))
	
	# Connect multiplayer signals
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_disconnected)
	
	# Connect UI buttons
	$UI/MainMenu/VBoxContainer/ConnectButton.pressed.connect(_on_connect_button_pressed)
	$UI/MainMenu/VBoxContainer/QuitButton.pressed.connect(_on_quit_button_pressed)
	
	# Manual button connections for lobby screen
	var team1_btn = $UI/LobbyScreen/VBoxContainer/TeamButtons/Team1Button
	var team2_btn = $UI/LobbyScreen/VBoxContainer/TeamButtons/Team2Button
	var ready_btn = $UI/LobbyScreen/VBoxContainer/ReadyButton
	var disconnect_btn = $UI/LobbyScreen/VBoxContainer/DisconnectButton
	
	if team1_btn:
		print("Connecting Team1Button")
		if team1_btn.is_connected("pressed", Callable(self, "_on_team1_button_pressed")):
			team1_btn.disconnect("pressed", Callable(self, "_on_team1_button_pressed"))
		team1_btn.pressed.connect(_on_team1_button_pressed)
	
	if team2_btn:
		print("Connecting Team2Button")
		if team2_btn.is_connected("pressed", Callable(self, "_on_team2_button_pressed")):
			team2_btn.disconnect("pressed", Callable(self, "_on_team2_button_pressed"))
		team2_btn.pressed.connect(_on_team2_button_pressed)
	
	if ready_btn:
		print("Connecting ReadyButton")
		if ready_btn.is_connected("pressed", Callable(self, "_on_ready_button_pressed")):
			ready_btn.disconnect("pressed", Callable(self, "_on_ready_button_pressed"))
		ready_btn.pressed.connect(_on_ready_button_pressed)
	
	if disconnect_btn:
		print("Connecting DisconnectButton")
		if disconnect_btn.is_connected("pressed", Callable(self, "disconnect_from_server")):
			disconnect_btn.disconnect("pressed", Callable(self, "disconnect_from_server"))
		disconnect_btn.pressed.connect(disconnect_from_server)
	
	# Error dialog OK button
	var ok_btn = $UI/ErrorDialog/VBoxContainer/OkButton
	if ok_btn:
		if ok_btn.is_connected("pressed", Callable(ui, "show_main_menu")):
			ok_btn.disconnect("pressed", Callable(ui, "show_main_menu"))
		ok_btn.pressed.connect(func(): $UI/ErrorDialog.hide())

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_R:
			print("R key pressed - forcing ready state toggle")
			_on_ready_button_pressed()
		elif event.pressed and event.keycode == KEY_1:
			print("1 key pressed - forcing team 1")
			_on_team1_button_pressed()
		elif event.pressed and event.keycode == KEY_2:
			print("2 key pressed - forcing team 2")
			_on_team2_button_pressed()

func _on_connect_button_pressed():
	if is_connecting:
		return
		
	is_connecting = true
	$UI/MainMenu/VBoxContainer/ConnectButton.disabled = true
	
	var address = $UI/MainMenu/VBoxContainer/AddressInput.text
	if address.strip_edges() == "":
		address = "127.0.0.1"
		
	player_name = $UI/MainMenu/VBoxContainer/NameInput.text
	if player_name.strip_edges() == "":
		player_name = "Player"
		
	connect_to_server(address, player_name)

func _on_quit_button_pressed():
	print("Quitting game")
	get_tree().quit()

func _on_team1_button_pressed():
	print("Team 1 button pressed, sending RPC")
	request_team_change.rpc_id(1, 1)

func _on_team2_button_pressed():
	print("Team 2 button pressed, sending RPC")
	request_team_change.rpc_id(1, 2)

func _on_ready_button_pressed():
	var ready_button = $UI/LobbyScreen/VBoxContainer/ReadyButton
	if not ready_button:
		print("ERROR: Ready button not found!")
		return
		
	# If text is "Ready", player is about to become ready
	var is_ready = ready_button.text == "Ready"  
	
	print("Ready button pressed - current text: " + ready_button.text)
	print("Setting ready state to: " + str(is_ready))
	
	# Update button text visually first
	if is_ready:
		ready_button.text = "Cancel"
	else:
		ready_button.text = "Ready"
	
	# Send RPC to server
	print("Sending set_player_ready RPC with value: " + str(is_ready))
	set_player_ready.rpc_id(1, is_ready)

func connect_to_server(address, name):
	print("Attempting to connect to: " + address)
	server_address = address
	player_name = name
	
	ui.show_connecting_dialog()
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(server_address, DEFAULT_PORT)
	
	if result != OK:
		print("Connection failed with error: " + str(result))
		ui.show_error("Connection failed: " + str(result))
		emit_signal("connection_failed")
		is_connecting = false
		$UI/MainMenu/VBoxContainer/ConnectButton.disabled = false
		return false
		
	print("Setting multiplayer peer...")
	multiplayer.multiplayer_peer = peer
	print("Connection attempt initiated, waiting for callback...")
	
	# Set a timeout for connection
	get_tree().create_timer(5.0).timeout.connect(func():
		if is_connecting and !multiplayer.is_server() and !multiplayer.is_connected_to_server():
			print("Connection timed out")
			ui.show_error("Connection timed out")
			disconnect_from_server()
	)
	
	return true

func disconnect_from_server():
	print("Disconnecting from server")
	is_connecting = false
	$UI/MainMenu/VBoxContainer/ConnectButton.disabled = false
	
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer = null
	
	players.clear()
	in_game = false
	player_id = 0
	
	ui.show_main_menu()

func _on_connected():
	player_id = multiplayer.get_unique_id()
	print("Connected to server with ID: ", player_id)
	
	# Hide connection dialog
	$UI/ConnectionDialog.hide()
	
	# Register with server
	print("Sending register_player RPC to server...")
	register_player.rpc_id(1, player_name)
	print("Register RPC sent, waiting for server response...")
	
	# Set a timeout to ensure we don't get stuck
	await get_tree().create_timer(3.0).timeout
	
	# If we're still not in the lobby, something went wrong with registration
	if $UI/MainMenu.visible:
		print("WARNING: No response from server after 3 seconds, forcing lobby display")
		# Force show lobby as a fallback
		players[player_id] = {
			"id": player_id,
			"name": player_name,
			"team": 1,
			"ready": false
		}
		ui.update_player_list(players)
		ui.show_lobby()
	
	is_connecting = false
	$UI/MainMenu/VBoxContainer/ConnectButton.disabled = false
	emit_signal("connected_to_server")

func _on_connection_failed():
	print("Connection failed")
	ui.show_error("Failed to connect to server")
	emit_signal("connection_failed")
	is_connecting = false
	$UI/MainMenu/VBoxContainer/ConnectButton.disabled = false

func _on_disconnected():
	print("Disconnected from server")
	ui.show_error("Disconnected from server")
	emit_signal("disconnected")
	is_connecting = false
	$UI/MainMenu/VBoxContainer/ConnectButton.disabled = false
	
	# Return to main menu
	disconnect_from_server()

# RPC functions called BY client TO server
@rpc("any_peer", "reliable")
func register_player(name):
	# Implemented by server
	pass

@rpc("any_peer", "reliable")
func set_player_ready(is_ready):
	# Implemented by server
	pass

@rpc("any_peer", "reliable") 
func request_team_change(team_id):
	# Implemented by server
	pass

@rpc("any_peer", "unreliable")
func player_position(position, rotation):
	# Implemented by server
	pass

@rpc("any_peer", "reliable")
func player_shoot(position, direction):
	# Implemented by server
	pass

# RPC functions called BY server TO client
@rpc("authority", "reliable")
func player_registered(id, name, team):
	print("RECEIVED player_registered RPC for ID: ", id, " with name: ", name)
	
	players[id] = {
		"id": id,
		"name": name,
		"team": team,
		"ready": false
	}
	
	# Update UI with player info
	ui.update_player_list(players)
	
	# If it's us, update our info
	if id == player_id:
		print("Showing lobby after registration")
		team = team
		ui.show_lobby()

@rpc("authority", "reliable")
func player_joined(id, name, team):
	print("RECEIVED player_joined RPC for ID: ", id, " with name: ", name)
	
	players[id] = {
		"id": id,
		"name": name,
		"team": team,
		"ready": false
	}
	
	ui.update_player_list(players)
	
	if in_game:
		# If we're already in game, spawn the new player
		spawn_player(id, team)

@rpc("authority", "reliable")
func player_left(id):
	print("RECEIVED player_left RPC for ID: ", id)
	
	if players.has(id):
		players.erase(id)
	
	ui.update_player_list(players)
	
	# Remove player from world if in game
	var player_node = world.get_node_or_null("Player" + str(id))
	if player_node:
		player_node.queue_free()

@rpc("authority", "reliable")
func team_changed(id, new_team):
	print("RECEIVED team_changed RPC for ID: ", id, " to team: ", new_team)
	
	if players.has(id):
		players[id].team = new_team
	
	if id == player_id:
		team = new_team
	
	ui.update_player_list(players)

@rpc("authority", "reliable")
func ready_changed(id, is_ready):
	print("RECEIVED ready_changed RPC for ID: ", id, " to: ", is_ready)
	
	if players.has(id):
		players[id].ready = is_ready
		
		# If it's us, update our button to match server state
		if id == player_id:
			print("Updating our ready button to match server state")
			$UI/LobbyScreen/VBoxContainer/ReadyButton.text = "Cancel" if is_ready else "Ready"
	
	ui.update_player_list(players)

@rpc("authority", "reliable")
func game_started_rpc():
	print("RECEIVED game_started_rpc")
	in_game = true
	
	# Show game UI instead of lobby
	ui.show_game_ui()
	
	# Spawn all players
	for id in players:
		spawn_player(id, players[id].team)

@rpc("authority", "reliable")
func game_ended_rpc():
	print("RECEIVED game_ended_rpc")
	in_game = false
	
	# Clean up the world
	for child in world.get_children():
		if child.name.begins_with("Player"):
			child.queue_free()
	
	# Return to lobby
	ui.show_lobby()

@rpc("authority", "reliable")
func spawn_player_at(id, pos, rot):
	print("RECEIVED spawn_player_at RPC for ID: ", id, " at position: ", pos)
	
	if id == player_id:
		# It's us - create local player
		var local_player = load("res://client/scenes/player/player.tscn").instantiate()
		local_player.name = "Player" + str(id)
		local_player.is_local_player = true
		local_player.player_id = id
		local_player.position = pos
		local_player.rotation = rot
		
		# Set team color/model
		if players.has(id):
			local_player.team = players[id].team
		
		world.add_child(local_player)
	
@rpc("authority", "unreliable")
func player_position_update(id, pos, rot):
	if id == player_id:
		return  # Don't update our own position from server
	
	var player_node = world.get_node_or_null("Player" + str(id))
	if player_node:
		player_node.network_update(pos, rot)

@rpc("authority", "reliable")
func player_shot(id, pos, dir):
	print("RECEIVED player_shot RPC from ID: ", id)
	# Create bullet effect
	spawn_bullet_effect(id, pos, dir)

# Helper functions
func spawn_player(id, team_id):
	# This is just a placeholder - the actual spawn happens via spawn_player_at RPC
	pass

func spawn_bullet_effect(player_id, pos, dir):
	# Create visual bullet effect
	var bullet = load("res://client/scenes/bullet_effect.tscn").instantiate()
	bullet.position = pos
	bullet.direction = dir
	world.add_child(bullet)
