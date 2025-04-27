extends Node

@export var player_scene: PackedScene
@export var test_map_scene: PackedScene

var current_map = null
var player = null
var objectives_completed = 0
var total_objectives = 1
var round_active = false

@onready var ui = $GameUI

func _ready():
	start_game()

func start_game():
	load_map()
	
func load_map():
	# Clean up existing map if any
	if current_map:
		current_map.queue_free()
	
	# Instance new map
	current_map = test_map_scene.instantiate()
	add_child(current_map)
	
	# Connect to objectives
	var objectives = get_tree().get_nodes_in_group("Objective")
	total_objectives = objectives.size()
	objectives_completed = 0
	
	for objective in objectives:
		if !objective.is_connected("objective_completed", _on_objective_completed):
			objective.connect("objective_completed", _on_objective_completed)
	
	# Find the player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("Player")
	
	if player:
		# Connect to player's weapon manager
		var weapon_manager = player.find_child("WeaponHolder")
		if weapon_manager:
			var weapon = weapon_manager.get_current_weapon()
			if weapon:
				ui.update_weapon_info(weapon)
	
	# Set objective info
	if objectives.size() > 0:
		ui.show_objective_info(objectives[0].objective_text)
	
	start_round()

# In game_manager.gd, add this to start_round()
func start_round():
	round_active = true
	print("GM: Attempting to call ui.start_round()")
	if ui:
		print("GM: UI exists")
		ui.start_round()
	else:
		print("GM: UI is null!")

func end_round(won = true):
	round_active = false
	ui.end_round(won)
	
	if won:
		# Wait a bit before restarting for the next round
		await get_tree().create_timer(5.0).timeout
		load_map()  # For a real game, you'd move to the next level

func _on_objective_completed():
	objectives_completed += 1
	
	if objectives_completed >= total_objectives:
		end_round(true)
