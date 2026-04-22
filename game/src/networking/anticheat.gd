## Server-side anti-cheat validation.
## Checks player inputs and state for impossible values.
## Only runs on the server.
extends Node

const MAX_SPEED: float = 400.0  # max horizontal speed (run + jetpack boost)
const MAX_FIRE_RATE: float = 15.0  # max shots per second (SMG is 12)
const MAX_TELEPORT_DIST: float = 100.0  # max position change per tick
const VIOLATION_THRESHOLD: int = 10  # violations before kick

var _violations: Dictionary = {}  # peer_id -> int
var _last_positions: Dictionary = {}  # peer_id -> Vector2
var _fire_counts: Dictionary = {}  # peer_id -> { time, count }


func validate_player_state(peer_id: int, position: Vector2, velocity: Vector2) -> bool:
	if not NetworkManager.is_server():
		return true

	var valid: bool = true

	# Speed check
	if velocity.length() > MAX_SPEED * 1.5:
		_add_violation(peer_id, "speed_hack: %.0f" % velocity.length())
		valid = false

	# Teleport check
	if _last_positions.has(peer_id):
		var last_pos: Vector2 = _last_positions[peer_id]
		var dist: float = position.distance_to(last_pos)
		if dist > MAX_TELEPORT_DIST:
			_add_violation(peer_id, "teleport: %.0f units" % dist)
			valid = false

	_last_positions[peer_id] = position
	return valid


func validate_fire_rate(peer_id: int) -> bool:
	if not NetworkManager.is_server():
		return true

	var now: float = Time.get_ticks_msec() / 1000.0

	if not _fire_counts.has(peer_id):
		_fire_counts[peer_id] = {"time": now, "count": 0}

	var entry: Dictionary = _fire_counts[peer_id]
	entry["count"] += 1

	var elapsed: float = now - entry["time"]
	if elapsed >= 1.0:
		var rate: float = entry["count"] / elapsed
		if rate > MAX_FIRE_RATE:
			_add_violation(peer_id, "fire_rate: %.1f/s" % rate)
			entry["time"] = now
			entry["count"] = 0
			return false
		entry["time"] = now
		entry["count"] = 0

	return true


func _add_violation(peer_id: int, reason: String) -> void:
	if not _violations.has(peer_id):
		_violations[peer_id] = 0
	_violations[peer_id] += 1

	print("[AntiCheat] Violation for peer %d: %s (total: %d)" % [peer_id, reason, _violations[peer_id]])

	if _violations[peer_id] >= VIOLATION_THRESHOLD:
		print("[AntiCheat] Kicking peer %d for too many violations" % peer_id)
		# In a real game, we'd disconnect this peer
		# multiplayer.multiplayer_peer.disconnect_peer(peer_id)


func clear_player(peer_id: int) -> void:
	_violations.erase(peer_id)
	_last_positions.erase(peer_id)
	_fire_counts.erase(peer_id)
