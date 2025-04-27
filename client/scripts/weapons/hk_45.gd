extends Node3D

@export var weapon_name: String = "HK 45"
@export var damage: float = 25.0
@export var fire_rate: float = 0.25  # Time between shots
@export var reload_time: float = 1.5
@export var max_ammo: int = 10
@export var current_ammo: int = 10
@export var recoil_amount: float = 0.05

var can_fire: bool = true
var is_reloading: bool = false
var last_shot_time: float = 0.0
var weapon_position: Vector3
var target_position: Vector3

# New recoil variables
var default_camera_rotation = 0.0
var current_recoil = 0.0
var max_recoil = 0.5  # Maximum amount camera can recoil

@onready var ray = $RayCast3D
@onready var muzzle_flash = $MuzzleFlash
@onready var fire_sound = $FireSound

signal ammo_changed(current, maximum)
signal weapon_fired
signal weapon_reloaded

func _ready():
	muzzle_flash.visible = false
	weapon_position = position
	target_position = position
	emit_signal("ammo_changed", current_ammo, max_ammo)
	
	# Store initial camera rotation
	var camera = get_viewport().get_camera_3d()
	if camera:
		default_camera_rotation = camera.rotation.x

func _process(delta):
	# Handle inputs
	if Input.is_action_just_pressed("fire") and can_fire and current_ammo > 0 and !is_reloading:
		fire()
	
	if Input.is_action_just_pressed("reload") and current_ammo < max_ammo and !is_reloading:
		reload()
	
	# Handle code-based weapon movement
	position = position.lerp(target_position, 10 * delta)
	
	# Recoil recovery
	if current_recoil > 0:
		current_recoil = max(0, current_recoil - delta * 2.0)  # Recover 2 units per second
		var camera = get_viewport().get_camera_3d()
		if camera:
			camera.rotation.x = default_camera_rotation - current_recoil
			# Ensure camera stays within reasonable limits
			camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)

func fire():
	if Time.get_ticks_msec() - last_shot_time < fire_rate * 1000:
		return
		
	last_shot_time = Time.get_ticks_msec()
	current_ammo -= 1
	emit_signal("ammo_changed", current_ammo, max_ammo)
	emit_signal("weapon_fired")
	
	# Visual and sound effects
	muzzle_flash.visible = true
	if fire_sound.stream:
		fire_sound.play()
	
	# Code-based recoil
	target_position = weapon_position + Vector3(0, 0, recoil_amount)
	
	# Apply recoil to camera - use negative value to make camera look up
	current_recoil = min(current_recoil + recoil_amount, max_recoil)
	var camera = get_viewport().get_camera_3d()
	if camera:
		camera.rotation.x = default_camera_rotation - current_recoil
		# Ensure camera stays within reasonable limits
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
	
	# Reset weapon position after recoil
	await get_tree().create_timer(0.1).timeout
	target_position = weapon_position
	
	# Hide muzzle flash after a short time
	await get_tree().create_timer(0.05).timeout
	muzzle_flash.visible = false
	
	# Check for hit
	if ray.is_colliding():
		var hit_object = ray.get_collider()
		var hit_position = ray.get_collision_point()
		
		if hit_object.has_method("take_damage"):
			hit_object.take_damage(damage, hit_position)
	
	if current_ammo <= 0:
		can_fire = false
		reload()

func reload():
	if current_ammo == max_ammo or is_reloading:
		return
		
	is_reloading = true
	
	# Wait for reload time
	await get_tree().create_timer(reload_time).timeout
	
	current_ammo = max_ammo
	is_reloading = false
	can_fire = true
	
	emit_signal("ammo_changed", current_ammo, max_ammo)
	emit_signal("weapon_reloaded")
