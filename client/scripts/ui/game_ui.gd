extends Control

@onready var weapon_name_label = $WeaponInfo/WeaponName
@onready var ammo_label = $WeaponInfo/AmmoCount
@onready var round_state_panel = $RoundStatePanel
@onready var round_state_label = $RoundStatePanel/RoundState
@onready var objective_info = $ObjectiveInfo
@onready var objective_label = $ObjectiveInfo/ObjectiveText
@onready var timer_label = $GameInfo/Timer

var current_weapon = null
var round_time = 0.0
var round_active = false

func _ready():
	round_state_panel.visible = false
	objective_info.visible = false
	print("GameUI ready")

func _process(delta):
	if round_active:
		round_time += delta
		update_timer()

func update_weapon_info(weapon):
	if !weapon:
		return
		
	current_weapon = weapon
	weapon_name_label.text = weapon.weapon_name
	update_ammo_count(weapon.current_ammo, weapon.max_ammo)
	
	# Connect to weapon signals if not already connected
	if !weapon.is_connected("ammo_changed", update_ammo_count):
		weapon.connect("ammo_changed", update_ammo_count)

func update_ammo_count(current, maximum):
	ammo_label.text = str(current) + " / " + str(maximum)

func update_timer():
	var minutes = int(round_time / 60)
	var seconds = int(round_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]

func show_objective_info(text):
	objective_info.visible = true
	objective_label.text = text

func hide_objective_info():
	objective_info.visible = false

func show_round_state(state_text):
	round_state_panel.visible = true
	round_state_label.text = state_text
	
	# Auto-hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	round_state_panel.visible = false

func start_round():
	round_active = true
	round_time = 0
	update_timer()
	show_round_state("Round Started")
	print("Round started")

func end_round(won):
	round_active = false
	show_round_state("Round " + ("Won" if won else "Failed"))
	print("Round ended")
