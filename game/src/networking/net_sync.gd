## Network state synchronization with client-side prediction and lag compensation.
## Attach as child of a player CharacterBody2D.
extends Node

var player: CharacterBody2D
var _sync_rate: float = 1.0 / 20.0  # 20 Hz
var _sync_timer: float = 0.0
var _is_local: bool = true

# --- Client-side prediction ---
# Stores recent inputs so we can replay them after server correction
var _input_history: Array[Dictionary] = []
var _last_server_tick: int = 0
var _tick: int = 0
var _max_history: int = 60  # ~1 second at 60fps

# --- Remote player interpolation ---
var _state_buffer: Array[Dictionary] = []  # ring buffer of received states
var _buffer_size: int = 3  # interpolation delay in snapshots
var _interp_time: float = 0.0

# --- Lag compensation ---
var _position_history: Array[Dictionary] = []  # for server-side rewind
var _max_position_history: int = 30  # ~0.5 sec at 60fps


func _ready() -> void:
	player = get_parent()
	if NetworkManager.is_online:
		_is_local = player.get_multiplayer_authority() == multiplayer.get_unique_id()
	else:
		_is_local = true


func _physics_process(delta: float) -> void:
	if not NetworkManager.is_online:
		return

	_tick += 1

	if _is_local:
		_process_local(delta)
	else:
		_process_remote(delta)

	# Server records position history for lag compensation
	if NetworkManager.is_server():
		_record_position()


# === LOCAL PLAYER (client-side prediction) ===

func _process_local(delta: float) -> void:
	# Record input for this tick (for replay on correction)
	var input_snapshot: Dictionary = {
		"tick": _tick,
		"position": player.global_position,
		"velocity": player.velocity,
	}
	_input_history.append(input_snapshot)
	if _input_history.size() > _max_history:
		_input_history.pop_front()

	# Send state to all peers
	_sync_timer += delta
	if _sync_timer >= _sync_rate:
		_sync_timer = 0.0
		_broadcast_state.rpc(
			player.global_position,
			player.velocity,
			player.current_state,
			player.facing_right,
			player.jetpack_fuel,
			_tick
		)


# Called when server sends authoritative position back
func _apply_server_correction(server_pos: Vector2, server_vel: Vector2, server_tick: int) -> void:
	# Find how far off our prediction was
	var error: float = player.global_position.distance_to(server_pos)

	# Only correct if error exceeds threshold (prevents jitter from micro-corrections)
	if error > 5.0:
		# Snap if way off, smooth if close
		if error > 50.0:
			player.global_position = server_pos
			player.velocity = server_vel
		else:
			player.global_position = player.global_position.lerp(server_pos, 0.3)
			player.velocity = player.velocity.lerp(server_vel, 0.3)

	_last_server_tick = server_tick

	# Remove old input history up to the corrected tick
	while not _input_history.is_empty() and _input_history[0]["tick"] <= server_tick:
		_input_history.pop_front()


# === REMOTE PLAYER (interpolation) ===

func _process_remote(delta: float) -> void:
	if _state_buffer.size() < 2:
		return

	# Advance interpolation time
	_interp_time += delta

	# Find the two states to interpolate between
	var render_time: float = _interp_time - _buffer_size * _sync_rate

	# Find bracketing states
	var from_state: Dictionary = _state_buffer[0]
	var to_state: Dictionary = _state_buffer[0]

	for i in range(1, _state_buffer.size()):
		if _state_buffer[i]["time"] > render_time:
			to_state = _state_buffer[i]
			from_state = _state_buffer[i - 1]
			break

	# Calculate interpolation factor
	var time_span: float = to_state["time"] - from_state["time"]
	var t: float = 0.0
	if time_span > 0.001:
		t = clampf((render_time - from_state["time"]) / time_span, 0.0, 1.0)

	# Apply interpolated state
	player.global_position = from_state["position"].lerp(to_state["position"], t)
	player.velocity = from_state["velocity"].lerp(to_state["velocity"], t)
	player.current_state = to_state["state"]
	player.facing_right = to_state["facing_right"]

	# Clean up old states (keep at least buffer_size + 1)
	while _state_buffer.size() > _buffer_size + 2:
		_state_buffer.pop_front()


# === RPC FUNCTIONS ===

@rpc("any_peer", "unreliable_ordered")
func _broadcast_state(pos: Vector2, vel: Vector2, state: int, facing: bool, fuel: float, tick: int) -> void:
	if _is_local:
		return  # Don't apply our own broadcast to ourselves

	# Add to interpolation buffer for remote players
	_state_buffer.append({
		"position": pos,
		"velocity": vel,
		"state": state,
		"facing_right": facing,
		"fuel": fuel,
		"tick": tick,
		"time": Time.get_ticks_msec() / 1000.0,
	})

	# If we're the server, send correction back to the owning client
	if NetworkManager.is_server():
		var sender_id: int = multiplayer.get_remote_sender_id()
		_receive_correction.rpc_id(sender_id, pos, vel, tick)


@rpc("authority", "unreliable_ordered")
func _receive_correction(server_pos: Vector2, server_vel: Vector2, server_tick: int) -> void:
	if _is_local:
		_apply_server_correction(server_pos, server_vel, server_tick)


# === LAG COMPENSATION (server-side) ===

func _record_position() -> void:
	_position_history.append({
		"position": player.global_position,
		"time": Time.get_ticks_msec(),
	})
	if _position_history.size() > _max_position_history:
		_position_history.pop_front()


func get_position_at_time(timestamp_ms: int) -> Vector2:
	## Server uses this to rewind a player's position for hit detection.
	## Returns the interpolated position at the given timestamp.
	if _position_history.is_empty():
		return player.global_position

	# Find bracketing entries
	for i in range(_position_history.size() - 1, 0, -1):
		if _position_history[i - 1]["time"] <= timestamp_ms:
			var from_entry: Dictionary = _position_history[i - 1]
			var to_entry: Dictionary = _position_history[i]
			var time_span: int = to_entry["time"] - from_entry["time"]
			if time_span <= 0:
				return from_entry["position"]
			var t: float = clampf(
				float(timestamp_ms - from_entry["time"]) / float(time_span),
				0.0, 1.0
			)
			return from_entry["position"].lerp(to_entry["position"], t)

	return _position_history[0]["position"]


# === NETWORK COMBAT SYNC ===

@rpc("any_peer", "reliable")
func sync_damage(victim_id: int, attacker_id: int, damage: float, weapon_name: String) -> void:
	# Server validates and applies damage
	if not multiplayer.is_server():
		return

	for node in get_tree().get_nodes_in_group("players"):
		if node is CharacterBody2D and node.player_id == victim_id:
			var health: Node = node.get_node_or_null("HealthSystem")
			if health:
				health.take_damage(damage, attacker_id, weapon_name)
			break


@rpc("any_peer", "reliable", "call_local")
func sync_kill(victim_id: int, killer_id: int, weapon_name: String) -> void:
	EventBus.player_died.emit(victim_id, killer_id, weapon_name)
	GameState.record_kill(killer_id, victim_id)
