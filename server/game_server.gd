extends Node

# Server settings
const DEFAULT_PORT = 28960
const MAX_PLAYERS = 16

# Player data
var players = {}

# Game state
var game_started = false
var round_time = 0

func _ready():
	print("Starting server...")
	
	# Initialize server
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(DEFAULT_PORT, MAX_PLAYERS)
	
	if result != OK:
		print("Failed to create server: ", result)
		get_tree().quit(1)
		return
		
	multiplayer.multiplayer_peer = peer
	print("Server listening on port ", DEFAULT_PORT)
	
	# Connect multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Disable rendering for dedicated server
	get_viewport().disable_3d = true
	get_viewport().disable_2d = true

func _on_peer_connected(id):
	print("Client connected: ", id)
	
	# Initialize player data
	players[id] = {
		"id": id,
		"name": "Player" + str(id),
		"team": assign_team(),
		"ready": false,
		"position": Vector3.ZERO,
		"rotation": Vector3.ZERO
	}
	
	print("Added player to dictionary with ID: ", id)

func _on_peer_disconnected(id):
	print("Client disconnected: ", id)
	
	if players.has(id):
		var player_name = players[id].name
		print("Removing player: ", player_name, " (ID: ", id, ")")
		players.erase(id)
		
		# Notify remaining players
		player_left.rpc(id)
		print("Notified all clients about player departure")
	else:
		print("WARNING: Disconnected player ID not found in players dictionary")
	
	check_game_state()

func _process(delta):
	# Main game loop - handle game state here
	if game_started:
		round_time += delta
		
		# Example: End game after 5 minutes
		if round_time >= 300:  # 5 minutes
			end_game()

# RPCs received FROM clients
@rpc("any_peer", "reliable")
func register_player(name):
	var id = multiplayer.get_remote_sender_id()
	
	print("Client " + str(id) + " attempting to register with name: " + name)
	
	if !players.has(id):
		print("WARNING: Player ID not in dictionary, adding it now...")
		# Create the player entry if it doesn't exist
		players[id] = {
			"id": id,
			"name": name,
			"team": assign_team(),
			"ready": false,
			"position": Vector3.ZERO,
			"rotation": Vector3.ZERO
		}
	
	print("Registering player: ", name)
	
	# Update player info
	players[id].name = name
	
	print("Sending registration confirmation to player " + str(id))
	# Tell this player about themselves
	player_registered.rpc_id(id, id, players[id].name, players[id].team)
	
	print("Notifying " + str(id) + " about other players")
	# Tell this player about other players
	for other_id in players:
		if other_id != id:
			player_joined.rpc_id(id, other_id, players[other_id].name, players[other_id].team)
	
	print("Notifying other players about " + str(id))
	# Tell other players about this player
	for other_id in players:
		if other_id != id:
			player_joined.rpc_id(other_id, id, players[id].name, players[id].team)

@rpc("any_peer", "reliable")
func set_player_ready(is_ready):
	var id = multiplayer.get_remote_sender_id()
	
	if !players.has(id):
		print("WARNING: Ready state change requested for nonexistent player: ", id)
		return
	
	print("Player ", id, " ready state changed to: ", is_ready)
	players[id].ready = is_ready
	
	# Notify everyone
	ready_changed.rpc(id, is_ready)
	
	# Check if all players are ready
	check_all_ready()

@rpc("any_peer", "reliable")
func request_team_change(team_id):
	var id = multiplayer.get_remote_sender_id()
	
	if !players.has(id) or team_id < 1 or team_id > 2:
		print("WARNING: Invalid team change requested by player: ", id)
		return
	
	print("Player ", id, " changing to team: ", team_id)
	players[id].team = team_id
	
	# Notify everyone
	team_changed.rpc(id, team_id)

@rpc("any_peer", "unreliable")
func player_position(position, rotation):
	var id = multiplayer.get_remote_sender_id()
	
	if !players.has(id):
		return
	
	# Update stored position
	players[id].position = position
	players[id].rotation = rotation
	
	# Relay to other clients
	for other_id in players:
		if other_id != id:
			player_position_update.rpc_id(other_id, id, position, rotation)

@rpc("any_peer", "reliable")
func player_shoot(position, direction):
	var id = multiplayer.get_remote_sender_id()
	
	if !players.has(id):
		return
	
	print("Player ", id, " fired a shot")
	
	# Validate the shot (could add more validation)
	
	# Relay to all clients
	player_shot.rpc(id, position, direction)
	
	# Process hit detection
	process_shot(id, position, direction)

# Helper functions
func assign_team():
	# Count players per team
	var team1_count = 0
	var team2_count = 0
	
	for id in players:
		if players[id].team == 1:
			team1_count += 1
		elif players[id].team == 2:
			team2_count += 1
	
	# Assign to team with fewer players
	return 1 if team1_count <= team2_count else 2

func check_all_ready():
	# Need at least 2 players
	if players.size() < 2:
		print("Not enough players to start game: ", players.size())
		return
	
	# Check if all are ready
	for id in players:
		if !players[id].ready:
			print("Waiting for player ", id, " to be ready")
			return
	
	# Everyone's ready - start game
	print("All players ready, starting game")
	start_game()

func start_game():
	if game_started:
		return
	
	game_started = true
	round_time = 0
	
	print("Game starting, notifying all clients")
	
	# Notify all clients
	game_started_rpc.rpc()
	
	# Spawn players
	for id in players:
		spawn_player(id)

func end_game():
	game_started = false
	print("Game ending, notifying all clients")
	
	# Reset player ready states
	for id in players:
		players[id].ready = false
		ready_changed.rpc(id, false)
	
	# Return to lobby
	game_ended_rpc.rpc()

func spawn_player(id):
	if !players.has(id):
		return
	
	# Determine spawn point based on team
	var team = players[id].team
	var spawn_pos = get_spawn_position(team)
	
	print("Spawning player ", id, " on team ", team, " at position ", spawn_pos)
	
	# Tell client to spawn
	spawn_player_at.rpc_id(id, id, spawn_pos, Vector3(0, 0, 0))

func get_spawn_position(team):
	# Simple team-based spawn positions
	if team == 1:
		return Vector3(-10, 1, 0)
	else:
		return Vector3(10, 1, 0)

func process_shot(shooter_id, position, direction):
	# Simple raycast implementation
	# In a real game, you'd want to use PhysicsServer for this
	var max_distance = 100.0
	var hit_pos = position + direction * max_distance
	
	# Check for player hits
	for id in players:
		if id != shooter_id:
			var target_pos = players[id].position
			
			# Simplified collision check
			var to_target = target_pos - position
			var proj_length = to_target.dot(direction)
			
			if proj_length > 0:
				var closest_point = position + direction * proj_length
				if closest_point.distance_to(target_pos) < 1.0:  # Simple radius check
					# Hit!
					player_hit(id, shooter_id, 25.0)  # 25 damage
					break

func player_hit(target_id, shooter_id, damage):
	# In a real game, you'd track health and handle death
	print("Player " + str(target_id) + " hit by " + str(shooter_id) + " for " + str(damage) + " damage")

func check_game_state():
	# Check if game should end (e.g., not enough players)
	if game_started and players.size() < 2:
		print("Not enough players, ending game")
		end_game()

# RPCs sent TO clients
@rpc("authority", "reliable")
func player_registered(id, name, team):
	# Implemented by client
	pass

@rpc("authority", "reliable")
func player_joined(id, name, team):
	# Implemented by client
	pass

@rpc("authority", "reliable")
func player_left(id):
	# Implemented by client
	pass

@rpc("authority", "reliable")
func team_changed(id, new_team):
	# Implemented by client
	pass

@rpc("authority", "reliable")
func ready_changed(id, is_ready):
	# Implemented by client
	pass

@rpc("authority", "reliable")
func game_started_rpc():
	# Implemented by client
	pass

@rpc("authority", "reliable")
func game_ended_rpc():
	# Implemented by client
	pass

@rpc("authority", "reliable")
func spawn_player_at(id, pos, rot):
	# Implemented by client
	pass

@rpc("authority", "unreliable")
func player_position_update(id, pos, rot):
	# Implemented by client
	pass

@rpc("authority", "reliable")
func player_shot(id, pos, dir):
	# Implemented by client
	pass
