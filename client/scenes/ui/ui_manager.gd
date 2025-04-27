extends CanvasLayer

@onready var main_menu = $MainMenu
@onready var lobby_screen = $LobbyScreen
@onready var game_hud = $GameHUD
@onready var connection_dialog = $ConnectionDialog
@onready var error_dialog = $ErrorDialog

func _ready():
	# Initialize UI state
	main_menu.visible = true
	lobby_screen.visible = false
	game_hud.visible = false
	connection_dialog.visible = false
	error_dialog.visible = false

func show_main_menu():
	print("Showing main menu")
	main_menu.visible = true
	lobby_screen.visible = false
	game_hud.visible = false
	connection_dialog.hide()
	error_dialog.hide()

func show_lobby():
	print("Showing lobby")
	main_menu.visible = false
	lobby_screen.visible = true
	game_hud.visible = false

func show_game_ui():
	print("Showing game UI")
	main_menu.visible = false
	lobby_screen.visible = false
	game_hud.visible = true
	
	# Enable mouse capture for FPS controls
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_connecting_dialog():
	print("Showing connecting dialog")
	connection_dialog.popup_centered()
	$ConnectionDialog/StatusLabel.text = "Connecting to server..."

func show_error(message):
	print("Showing error: " + message)
	error_dialog.popup_centered()
	$ErrorDialog/VBoxContainer/ErrorLabel.text = message

func update_player_list(players_dict):
	print("Updating player list")
	var player_list = $LobbyScreen/VBoxContainer/PlayerList
	player_list.clear()
	
	for id in players_dict:
		var player_info = players_dict[id]
		var text = str(id) + ": " + player_info.name
		
		# Add team info
		if player_info.team == 1:
			text += " [Blue]"
		elif player_info.team == 2:
			text += " [Red]"
			
		# Add ready status
		if player_info.ready:
			text += " (Ready)"
		else:
			text += " (Not Ready)"
			
		player_list.add_item(text)

func update_health_display(health):
	$GameHUD/HealthBar.value = health

func update_ammo_display(current, max_ammo):
	$GameHUD/AmmoCounter.text = "AMMO: " + str(current) + "/" + str(max_ammo)

func update_score(blue_score, red_score):
	$GameHUD/ScorePanel/ScoreLabel.text = "BLUE: " + str(blue_score) + "  RED: " + str(red_score)
