extends Node3D

@export var starting_weapon_scene: PackedScene

var current_weapon = null

signal weapon_changed(weapon)

func _ready():
	if starting_weapon_scene:
		equip_weapon(starting_weapon_scene.instantiate())

func equip_weapon(weapon_instance):
	# Remove current weapon if one exists
	if current_weapon:
		current_weapon.queue_free()
	
	# Add new weapon
	current_weapon = weapon_instance
	add_child(current_weapon)
	
	# Connect weapon signals
	current_weapon.connect("ammo_changed", _on_weapon_ammo_changed)
	current_weapon.connect("weapon_fired", _on_weapon_fired)
	
	emit_signal("weapon_changed", current_weapon)

func _on_weapon_ammo_changed(current, maximum):
	# Forward to UI (will connect later)
	pass
	
func _on_weapon_fired():
	# Could trigger camera shake or other effects
	pass

func get_current_weapon():
	return current_weapon
