@tool
extends EditorScript

func _run():
	# Create the scene root
	var client = Node.new()
	client.name = "Client"
	
	# Set the script
	var script = load("res://client/game_client.gd")
	client.set_script(script)
	
	# Create World structure
	var world = Node3D.new()
	world.name = "World"
	client.add_child(world)
	world.owner = client
	
	# Environment
	var env = WorldEnvironment.new()
	env.name = "Environment"
	var environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES  # Fixed: TONE_ACES → TONE_MAPPER_ACES
	environment.glow_enabled = true
	var sky = Sky.new()
	environment.sky = sky
	env.environment = environment
	world.add_child(env)
	env.owner = client
	
	# Light
	var light = DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.transform.basis = Basis(Vector3(-0.866025, -0.433013, 0.25), Vector3(0, 0.5, 0.866025), Vector3(-0.5, 0.75, -0.433013))
	light.shadow_enabled = true
	world.add_child(light)
	light.owner = client
	
	# Level, Players, Effects containers
	var level = Node3D.new()
	level.name = "Level"
	world.add_child(level)
	level.owner = client
	
	var players = Node3D.new()
	players.name = "Players"
	world.add_child(players)
	players.owner = client
	
	var effects = Node3D.new()
	effects.name = "Effects"
	world.add_child(effects)
	effects.owner = client
	
	# UI Structure
	var ui = CanvasLayer.new()
	ui.name = "UI"
	client.add_child(ui)
	ui.owner = client
	
	# Main Menu
	var main_menu = Control.new()
	main_menu.name = "MainMenu"
	main_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(main_menu)
	main_menu.owner = client
	
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.12, 0.12, 0.12, 1.0)
	main_menu.add_child(bg)
	bg.owner = client
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(400, 300)
	vbox.position = Vector2(-200, -150)
	main_menu.add_child(vbox)
	vbox.owner = client
	
	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "MULTIPLAYER GAME"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Using enum directly
	title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title)
	title.owner = client
	
	var spacer1 = Control.new()
	spacer1.name = "Spacer1"
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	spacer1.owner = client
	
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = "Your Name:"
	vbox.add_child(name_label)
	name_label.owner = client
	
	var name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.text = "Player"
	name_input.placeholder_text = "Enter your name"
	vbox.add_child(name_input)
	name_input.owner = client
	
	var spacer2 = Control.new()
	spacer2.name = "Spacer2"
	spacer2.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer2)
	spacer2.owner = client
	
	var addr_label = Label.new()
	addr_label.name = "AddressLabel"
	addr_label.text = "Server Address:"
	vbox.add_child(addr_label)
	addr_label.owner = client
	
	var addr_input = LineEdit.new()
	addr_input.name = "AddressInput"
	addr_input.text = "127.0.0.1"
	addr_input.placeholder_text = "Enter server address"
	vbox.add_child(addr_input)
	addr_input.owner = client
	
	var spacer3 = Control.new()
	spacer3.name = "Spacer3"
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)
	spacer3.owner = client
	
	var connect_btn = Button.new()
	connect_btn.name = "ConnectButton"
	connect_btn.text = "Connect"
	connect_btn.add_theme_font_size_override("font_size", 18)
	vbox.add_child(connect_btn)
	connect_btn.owner = client
	
	var spacer4 = Control.new()
	spacer4.name = "Spacer4"
	spacer4.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer4)
	spacer4.owner = client
	
	var quit_btn = Button.new()
	quit_btn.name = "QuitButton"
	quit_btn.text = "Quit Game"
	vbox.add_child(quit_btn)
	quit_btn.owner = client
	
	# Lobby Screen (create other UI components similarly)
	var lobby = Control.new()
	lobby.name = "LobbyScreen"
	lobby.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby.visible = false
	ui.add_child(lobby)
	lobby.owner = client
	
	var lobby_bg = ColorRect.new()
	lobby_bg.name = "Background"
	lobby_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	lobby_bg.color = Color(0.15, 0.15, 0.15, 1.0)
	lobby.add_child(lobby_bg)
	lobby_bg.owner = client
	
	var lobby_vbox = VBoxContainer.new()
	lobby_vbox.name = "VBoxContainer"
	lobby_vbox.set_anchors_preset(Control.PRESET_CENTER)
	lobby_vbox.custom_minimum_size = Vector2(500, 400)
	lobby_vbox.position = Vector2(-250, -200)
	lobby.add_child(lobby_vbox)
	lobby_vbox.owner = client
	
	var lobby_title = Label.new()
	lobby_title.name = "LobbyTitle"
	lobby_title.text = "Game Lobby"
	lobby_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lobby_title.add_theme_font_size_override("font_size", 24)
	lobby_vbox.add_child(lobby_title)
	lobby_title.owner = client
	
	var lobby_spacer1 = Control.new()
	lobby_spacer1.name = "Spacer1"
	lobby_spacer1.custom_minimum_size = Vector2(0, 10)
	lobby_vbox.add_child(lobby_spacer1)
	lobby_spacer1.owner = client
	
	var players_label = Label.new()
	players_label.name = "PlayersLabel"
	players_label.text = "Players:"
	lobby_vbox.add_child(players_label)
	players_label.owner = client
	
	var player_list = ItemList.new()
	player_list.name = "PlayerList"
	player_list.custom_minimum_size = Vector2(0, 200)
	lobby_vbox.add_child(player_list)
	player_list.owner = client
	
	var lobby_spacer2 = Control.new()
	lobby_spacer2.name = "Spacer2"
	lobby_spacer2.custom_minimum_size = Vector2(0, 10)
	lobby_vbox.add_child(lobby_spacer2)
	lobby_spacer2.owner = client
	
	var team_label = Label.new()
	team_label.name = "TeamLabel"
	team_label.text = "Choose Team:"
	lobby_vbox.add_child(team_label)
	team_label.owner = client
	
	var team_buttons = HBoxContainer.new()
	team_buttons.name = "TeamButtons"
	lobby_vbox.add_child(team_buttons)
	team_buttons.owner = client
	
	var team1_btn = Button.new()
	team1_btn.name = "Team1Button"
	team1_btn.text = "Join Blue Team"
	team1_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Fixed flag
	team_buttons.add_child(team1_btn)
	team1_btn.owner = client
	
	var team2_btn = Button.new()
	team2_btn.name = "Team2Button"
	team2_btn.text = "Join Red Team"
	team2_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Fixed flag
	team_buttons.add_child(team2_btn)
	team2_btn.owner = client
	
	var lobby_spacer3 = Control.new()
	lobby_spacer3.name = "Spacer3"
	lobby_spacer3.custom_minimum_size = Vector2(0, 20)
	lobby_vbox.add_child(lobby_spacer3)
	lobby_spacer3.owner = client
	
	var ready_btn = Button.new()
	ready_btn.name = "ReadyButton"
	ready_btn.text = "Ready"
	ready_btn.add_theme_font_size_override("font_size", 18)
	lobby_vbox.add_child(ready_btn)
	ready_btn.owner = client
	
	var disconnect_btn = Button.new()
	disconnect_btn.name = "DisconnectButton"
	disconnect_btn.text = "Disconnect"
	lobby_vbox.add_child(disconnect_btn)
	disconnect_btn.owner = client
	
	# Game HUD (simplified)
	var hud = Control.new()
	hud.name = "GameHUD"
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.visible = false
	ui.add_child(hud)
	hud.owner = client
	
	var score_panel = Panel.new()
	score_panel.name = "ScorePanel"
	score_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	score_panel.custom_minimum_size = Vector2(0, 40)
	hud.add_child(score_panel)
	score_panel.owner = client
	
	var score_label = Label.new()
	score_label.name = "ScoreLabel"
	score_label.text = "BLUE: 0  RED: 0"
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_label.set_anchors_preset(Control.PRESET_CENTER)
	score_panel.add_child(score_label)
	score_label.owner = client
	
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.value = 100
	health_bar.position = Vector2(20, -40)
	health_bar.size = Vector2(200, 20)
	health_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hud.add_child(health_bar)
	health_bar.owner = client
	
	var crosshair = Label.new()
	crosshair.name = "Crosshair"
	crosshair.text = "+"
	crosshair.add_theme_font_size_override("font_size", 20)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	hud.add_child(crosshair)
	crosshair.owner = client
	
	# Connection Dialog
	var conn_dialog = PopupPanel.new()
	conn_dialog.name = "ConnectionDialog"
	conn_dialog.size = Vector2(400, 100)
	ui.add_child(conn_dialog)
	conn_dialog.owner = client
	
	var status_label = Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "Connecting to server..."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.size = Vector2(392, 92) # Account for panel margins
	conn_dialog.add_child(status_label)
	status_label.owner = client
	
	# Error Dialog
	var error_dialog = PopupPanel.new()
	error_dialog.name = "ErrorDialog"
	error_dialog.size = Vector2(400, 150)
	ui.add_child(error_dialog)
	error_dialog.owner = client
	
	var error_vbox = VBoxContainer.new()
	error_vbox.size = Vector2(392, 142) # Account for panel margins
	error_dialog.add_child(error_vbox)
	error_vbox.owner = client
	
	var error_label = Label.new()
	error_label.name = "ErrorLabel"
	error_label.text = "Connection failed!"
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	error_vbox.add_child(error_label)
	error_label.owner = client
	
	var ok_btn = Button.new()
	ok_btn.name = "OkButton"
	ok_btn.text = "OK"
	error_vbox.add_child(ok_btn)
	ok_btn.owner = client
	
	# Audio Manager
	var audio = Node.new()
	audio.name = "AudioManager"
	client.add_child(audio)
	audio.owner = client
	
	var music = AudioStreamPlayer.new()
	music.name = "MusicPlayer"
	audio.add_child(music)
	music.owner = client
	
	var sfx = AudioStreamPlayer.new()
	sfx.name = "SFXPlayer"
	audio.add_child(sfx)
	sfx.owner = client
	
	# Connect signals
	connect_btn.connect("pressed", Callable(client, "_on_connect_button_pressed"))
	quit_btn.connect("pressed", Callable(client, "_on_quit_button_pressed"))
	team1_btn.connect("pressed", Callable(client, "_on_team1_button_pressed"))
	team2_btn.connect("pressed", Callable(client, "_on_team2_button_pressed"))
	ready_btn.connect("pressed", Callable(client, "_on_ready_button_pressed"))
	disconnect_btn.connect("pressed", Callable(client, "disconnect_from_server"))
	ok_btn.connect("pressed", Callable(error_dialog, "hide"))
	
	# Save the scene
	var packed_scene = PackedScene.new()
	packed_scene.pack(client)
	var result = ResourceSaver.save(packed_scene, "res://client/scenes/client_main.tscn")
	if result == OK:
		print("Scene saved successfully!")
	else:
		print("Error saving scene: ", result)
