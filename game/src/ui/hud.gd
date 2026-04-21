## In-game HUD — health bar, fuel gauge, ammo counter, weapon name, crosshair.
extends CanvasLayer

var player: CharacterBody2D

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthBar/Label
@onready var fuel_bar: ProgressBar = $FuelBar
@onready var ammo_label: Label = $AmmoLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var crosshair: TextureRect = $Crosshair
@onready var kill_feed_container: VBoxContainer = $KillFeedContainer
@onready var match_timer_label: Label = $MatchTimerLabel


func _ready() -> void:
	# Find local player
	await get_tree().process_frame
	_find_player()

	EventBus.kill_feed_entry.connect(_on_kill_feed_entry)


func _process(_delta: float) -> void:
	if not player or not is_instance_valid(player):
		_find_player()
		return

	_update_health()
	_update_fuel()
	_update_ammo()
	_update_crosshair()
	_update_timer()


func _find_player() -> void:
	for node in get_tree().get_nodes_in_group("players"):
		if node is CharacterBody2D:
			var character: CharacterBody2D = node as CharacterBody2D
			if character.player_id == GameState.local_player_id:
				player = character
				# Connect health signals
				var hs: Node = player.get_node_or_null("HealthSystem")
				if hs:
					if not hs.is_connected("health_changed", _on_health_changed):
						hs.health_changed.connect(_on_health_changed)
				# Connect weapon signals
				var wm: Node = player.get_node_or_null("WeaponManager")
				if wm:
					if not wm.is_connected("weapon_changed", _on_weapon_changed):
						wm.weapon_changed.connect(_on_weapon_changed)
					if not wm.is_connected("ammo_changed", _on_ammo_changed):
						wm.ammo_changed.connect(_on_ammo_changed)
				break


func _update_health() -> void:
	var hs: HealthSystem = player.get_node("HealthSystem") as HealthSystem
	health_bar.value = hs.get_hp_percent() * 100.0
	health_label.text = "%d" % int(hs.current_hp)

	# Flash red at low HP
	if hs.get_hp_percent() < 0.3:
		var flash: float = absf(sin(Time.get_ticks_msec() * 0.005))
		health_bar.modulate = Color(1.0, flash, flash)
	else:
		health_bar.modulate = Color.WHITE


func _update_fuel() -> void:
	fuel_bar.value = (player.jetpack_fuel / Constants.JETPACK_FUEL_MAX) * 100.0


func _update_ammo() -> void:
	var wm: WeaponManager = player.get_node("WeaponManager") as WeaponManager
	var weapon: WeaponDefinition = wm.get_current_weapon()
	if weapon:
		if weapon.ammo_capacity < 0:
			ammo_label.text = "INF"
		else:
			ammo_label.text = "%d / %d" % [wm.get_current_ammo(), weapon.ammo_capacity]
		weapon_label.text = weapon.weapon_name

		if wm.is_reloading:
			ammo_label.text = "RELOADING..."
	else:
		ammo_label.text = "---"
		weapon_label.text = "No Weapon"


func _update_crosshair() -> void:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	crosshair.global_position = mouse_pos - crosshair.size / 2


func _update_timer() -> void:
	# Find match manager to get timer
	var mm: Node = get_tree().current_scene.get_node_or_null("MatchManager")
	if mm and "match_timer" in mm and "time_limit" in mm:
		var remaining: float = maxf(mm.time_limit - mm.match_timer, 0.0)
		var mins: int = int(remaining) / 60
		var secs: int = int(remaining) % 60
		match_timer_label.text = "%d:%02d" % [mins, secs]


func _on_health_changed(_current: float, _max_hp: float) -> void:
	pass  # Handled in _process


func _on_weapon_changed(weapon: WeaponDefinition) -> void:
	if weapon:
		weapon_label.text = weapon.weapon_name


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	if max_ammo < 0:
		ammo_label.text = "INF"
	else:
		ammo_label.text = "%d / %d" % [current, max_ammo]


func _on_kill_feed_entry(killer_name: String, victim_name: String, weapon_name: String) -> void:
	var entry := Label.new()
	entry.text = "%s [%s] %s" % [killer_name, weapon_name, victim_name]
	entry.add_theme_font_size_override("font_size", 14)
	entry.add_theme_color_override("font_color", Color(1.0, 0.9, 0.7))
	kill_feed_container.add_child(entry)

	# Auto-remove after 5 seconds
	var timer: SceneTreeTimer = get_tree().create_timer(5.0)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(entry):
			entry.queue_free()
	)

	# Limit to 5 entries
	while kill_feed_container.get_child_count() > 5:
		kill_feed_container.get_child(0).queue_free()
