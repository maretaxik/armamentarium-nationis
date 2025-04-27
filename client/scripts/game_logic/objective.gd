extends Node3D

signal objective_completed
signal objective_progress_changed(progress)

enum Faction {NEUTRAL, ALLIED, ENEMY}

@export var objective_text: String = "Hold E to capture objective"
@export var time_to_capture: float = 5.0
@export var capture_radius: float = 3.0
@export var current_faction: Faction = Faction.NEUTRAL
@export var height: float = 0.05  # Only few centimeters high

var player_in_radius: bool = false
var progress: float = 0.0
var completed: bool = false
var neutral_color = Color(1.0, 1.0, 1.0, 0.3)  # White transparent
var allied_color = Color(0.0, 0.7, 1.0, 0.3)    # Blue transparent
var enemy_color = Color(1.0, 0.2, 0.2, 0.3)     # Red transparent
var capture_progress = 0.0  # 0 to 1 capture progress

@onready var interaction_area = $InteractionArea
@onready var progress_indicator = $ProgressIndicator/ProgressBar
@onready var capture_mesh = $CaptureMesh
@onready var glow_mesh = $GlowMesh
@onready var animation_player = $AnimationPlayer

func _ready():
	# Set up the collision shape radius
	var collision_shape = $InteractionArea/CollisionShape3D
	collision_shape.shape.radius = capture_radius
	
	# Connect area signals programmatically
	if interaction_area and interaction_area is Area3D:
		interaction_area.connect("body_entered", Callable(self, "_on_interaction_area_body_entered"))
		interaction_area.connect("body_exited", Callable(self, "_on_interaction_area_body_exited"))
	
	# Set up the capture area mesh
	var material = StandardMaterial3D.new()
	material.flags_transparent = true
	material.albedo_color = get_faction_color()
	material.emission_enabled = true
	material.emission = get_faction_color()
	material.emission_energy = 0.5
	capture_mesh.material_override = material
	
	# Set up mesh size based on its type
	if capture_mesh.mesh is CylinderMesh:
		var cylinder_mesh = capture_mesh.mesh as CylinderMesh
		cylinder_mesh.height = height
		cylinder_mesh.top_radius = capture_radius
		cylinder_mesh.bottom_radius = capture_radius
	elif capture_mesh.mesh is BoxMesh:
		var box_mesh = capture_mesh.mesh as BoxMesh
		box_mesh.size = Vector3(capture_radius * 2, height, capture_radius * 2)
	else:
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(capture_radius * 2, height, capture_radius * 2)
		capture_mesh.mesh = box_mesh
	
	# Set up glow mesh
	var glow_material = StandardMaterial3D.new()
	glow_material.flags_transparent = true
	glow_material.albedo_color = Color(1, 1, 1, 0.1)
	glow_material.emission_enabled = true
	glow_material.emission = get_faction_color()
	glow_material.emission_energy = 2.0
	glow_mesh.material_override = glow_material
	
	# Initialize UI elements
	progress_indicator.visible = false
	progress_indicator.max_value = time_to_capture
	progress_indicator.value = progress
	
	# Create animations
	setup_animations()
	
	# Start idle animation
	animation_player.play("pulse")

func _process(delta):
	# Check interact key (helpful debug)
	if Input.is_action_pressed("interact"):
		print("Interact key pressed!")
	
	# Debug player detection
	if player_in_radius:
		print("Player is in radius: ", player_in_radius)
	
	if completed:
		return
		
	if player_in_radius and Input.is_action_pressed("interact"):
		progress += delta
		progress = min(progress, time_to_capture)
		print("Capturing: ", progress, "/", time_to_capture)
		
		if !animation_player.is_playing() or animation_player.current_animation == "pulse":
			animation_player.play("capture")
			
		if progress >= time_to_capture:
			complete_objective()
	else:
		progress = max(0, progress - delta)
		
		if !animation_player.is_playing() or animation_player.current_animation == "capture":
			animation_player.play("pulse")
	
	# Update capture progress
	capture_progress = progress / time_to_capture
	
	# Update materials based on capture progress
	update_materials()
	
	# Update UI
	progress_indicator.value = progress
	progress_indicator.visible = player_in_radius
	
	emit_signal("objective_progress_changed", capture_progress)

func update_materials():
	# Get materials
	var capture_mat = capture_mesh.material_override
	var glow_mat = glow_mesh.material_override
	
	# Update base color based on faction and progress
	var base_color = get_faction_color()
	capture_mat.albedo_color = base_color
	capture_mat.emission = base_color
	
	# Adjust emission intensity based on capture progress
	var emission_energy = 0.5 + capture_progress
	capture_mat.emission_energy = emission_energy
	
	# Update glow material
	glow_mat.emission = base_color
	glow_mat.emission_energy = 2.0 + capture_progress * 3.0

func get_faction_color() -> Color:
	match current_faction:
		Faction.ALLIED:
			return allied_color
		Faction.ENEMY:
			return enemy_color
		_:  # NEUTRAL
			return neutral_color

func set_faction(faction: Faction):
	current_faction = faction
	update_materials()

func complete_objective():
	completed = true
	set_faction(Faction.ALLIED)
	progress_indicator.visible = false
	print("OBJECTIVE COMPLETED!")
	emit_signal("objective_completed")
	
	# Play completion animation
	animation_player.play("complete")

func _on_interaction_area_body_entered(body):
	print("Body entered: ", body.name)
	# Test with name instead of group
	if body.name == "Player": 
		print("PLAYER ENTERED AREA")
		player_in_radius = true

func _on_interaction_area_body_exited(body):
	print("Body exited: ", body.name)
	if body.name == "Player":
		print("PLAYER EXITED AREA")
		player_in_radius = false

func setup_animations():
	# Get or create the default animation library
	var lib_name = ""
	if not animation_player.has_animation_library(lib_name):
		animation_player.add_animation_library(lib_name, AnimationLibrary.new())
	
	var lib = animation_player.get_animation_library(lib_name)
	
	# Create pulse animation
	var pulse = Animation.new()
	var pulse_track = pulse.add_track(Animation.TYPE_VALUE)
	pulse.track_set_path(pulse_track, NodePath("../GlowMesh:scale"))
	pulse.length = 2.0
	pulse.track_insert_key(pulse_track, 0.0, Vector3(1, 1, 1))
	pulse.track_insert_key(pulse_track, 1.0, Vector3(1.1, 1, 1.1))
	pulse.track_insert_key(pulse_track, 2.0, Vector3(1, 1, 1))
	pulse.loop_mode = Animation.LOOP_LINEAR
	
	# Create capture animation
	var capture = Animation.new()
	var capture_track = capture.add_track(Animation.TYPE_VALUE)
	capture.track_set_path(capture_track, NodePath("../CaptureMesh:material_override:emission_energy"))
	capture.length = 0.5
	capture.track_insert_key(capture_track, 0.0, 0.5)
	capture.track_insert_key(capture_track, 0.25, 2.0)
	capture.track_insert_key(capture_track, 0.5, 0.5)
	capture.loop_mode = Animation.LOOP_LINEAR
	
	# Create complete animation
	var complete = Animation.new()
	
	var scale_track = complete.add_track(Animation.TYPE_VALUE)
	complete.track_set_path(scale_track, NodePath("../CaptureMesh:scale"))
	
	var emission_track = complete.add_track(Animation.TYPE_VALUE)
	complete.track_set_path(emission_track, NodePath("../CaptureMesh:material_override:emission_energy"))
	
	complete.length = 1.0
	complete.track_insert_key(scale_track, 0.0, Vector3(1, 1, 1))
	complete.track_insert_key(scale_track, 0.5, Vector3(1.2, 1.2, 1.2))
	complete.track_insert_key(scale_track, 1.0, Vector3(1, 1, 1))
	
	complete.track_insert_key(emission_track, 0.0, 0.5)
	complete.track_insert_key(emission_track, 0.5, 3.0)
	complete.track_insert_key(emission_track, 1.0, 2.0)
	
	# Add animations to the library
	if lib.has_animation("pulse"):
		lib.remove_animation("pulse")
	lib.add_animation("pulse", pulse)
	
	if lib.has_animation("capture"):
		lib.remove_animation("capture")
	lib.add_animation("capture", capture)
	
	if lib.has_animation("complete"):
		lib.remove_animation("complete")
	lib.add_animation("complete", complete)
