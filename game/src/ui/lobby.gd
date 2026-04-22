## Lobby screen — host or join a multiplayer game, or play offline with bots.
extends Control

@onready var host_button: Button = $Panel/VBox/Buttons/HostButton
@onready var join_button: Button = $Panel/VBox/Buttons/JoinButton
@onready var offline_button: Button = $Panel/VBox/Buttons/OfflineButton
@onready var back_button: Button = $Panel/VBox/BackButton
@onready var address_input: LineEdit = $Panel/VBox/JoinConfig/AddressInput
@onready var port_input: SpinBox = $Panel/VBox/JoinConfig/PortInput
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var player_list: VBoxContainer = $Panel/VBox/PlayerList
@onready var start_button: Button = $Panel/VBox/StartButton
@onready var bot_count_input: SpinBox = $Panel/VBox/BotConfig/BotCount
@onready var map_option: OptionButton = $Panel/VBox/MapConfig/MapOption

var _in_lobby: bool = false
var _maps: Array[String] = [
	"res://src/maps/map_arena.tscn",
	"res://src/maps/map_towers.tscn",
	"res://src/maps/map_bunker.tscn",
]


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	host_button.pressed.connect(_on_host)
	join_button.pressed.connect(_on_join)
	offline_button.pressed.connect(_on_offline)
	back_button.pressed.connect(_on_back)
	start_button.pressed.connect(_on_start)
	start_button.visible = false

	map_option.add_item("Arena", 0)
	map_option.add_item("Towers", 1)
	map_option.add_item("Bunker", 2)
	map_option.selected = 0

	NetworkManager.player_connected.connect(_on_player_joined)
	NetworkManager.player_disconnected.connect(_on_player_left)
	NetworkManager.connection_succeeded.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connect_failed)

	status_label.text = "Choose a mode"


func _on_host() -> void:
	var port: int = int(port_input.value)
	var error: Error = NetworkManager.host_game(port)
	if error == OK:
		status_label.text = "Hosting on port %d. Waiting for players..." % port
		_in_lobby = true
		start_button.visible = true
		_update_player_list()
	else:
		status_label.text = "Failed to host: %s" % error_string(error)


func _on_join() -> void:
	var address: String = address_input.text.strip_edges()
	if address.is_empty():
		address = "127.0.0.1"
	var port: int = int(port_input.value)
	var error: Error = NetworkManager.join_game(address, port)
	if error == OK:
		status_label.text = "Connecting to %s:%d..." % [address, port]
	else:
		status_label.text = "Failed to connect: %s" % error_string(error)


func _on_offline() -> void:
	NetworkManager.disconnect_game()
	var selected_map: String = _maps[map_option.selected]
	get_tree().change_scene_to_file(selected_map)


func _on_back() -> void:
	NetworkManager.disconnect_game()
	get_tree().change_scene_to_file("res://src/ui/main_menu.tscn")


func _on_start() -> void:
	if not NetworkManager.is_server():
		return
	# Tell all peers to load the game scene
	_load_game.rpc()


@rpc("authority", "reliable", "call_local")
func _load_game() -> void:
	var selected_map: String = _maps[map_option.selected]
	get_tree().change_scene_to_file(selected_map)


func _on_connected() -> void:
	status_label.text = "Connected! Waiting for host to start..."
	_in_lobby = true
	_update_player_list()


func _on_connect_failed() -> void:
	status_label.text = "Connection failed. Check address and try again."
	_in_lobby = false


func _on_player_joined(_peer_id: int) -> void:
	_update_player_list()


func _on_player_left(_peer_id: int) -> void:
	_update_player_list()


func _update_player_list() -> void:
	for child in player_list.get_children():
		child.queue_free()

	# Add self
	var self_label := Label.new()
	self_label.text = "You (ID: %d)%s" % [NetworkManager.get_my_id(), " [HOST]" if NetworkManager.is_host else ""]
	self_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	player_list.add_child(self_label)

	# Add connected peers
	for peer_id in NetworkManager.connected_peers:
		var peer_label := Label.new()
		peer_label.text = "Player (ID: %d)" % peer_id
		player_list.add_child(peer_label)
