extends Node
class_name NetworkService

# The service name is used for registration
var service_name = ""

# Reference to the network manager
var network_manager = null

func _init(name: String):
	service_name = name

# Called when service is registered with the network manager
func register(manager):
	network_manager = manager
	_register_rpcs()

# Register your RPCs here - in Godot 4 this is mostly documentation
# as RPCs are automatically registered through annotations
func _register_rpcs():
	pass

# Helper function to get player ID
func get_sender_id():
	return multiplayer.get_remote_sender_id()

# Helper for server to check if it's the server
func is_server():
	return network_manager.is_server if network_manager else false
