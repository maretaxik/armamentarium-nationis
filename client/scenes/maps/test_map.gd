extends Node3D

@export var player_scene: PackedScene
@export var objective_scene: PackedScene

func _ready():
	# Spawn player
	var player = player_scene.instantiate()
	player.position = $PlayerSpawnPoint.position
	add_child(player)
	
	# Create objectives
	var objective = objective_scene.instantiate()
	objective.position = $ObjectivePoint.position
	add_child(objective)
