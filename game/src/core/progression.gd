## Tracks XP, levels, and cosmetic unlocks for the local player.
## Access via the Progression autoload singleton.
extends Node

signal xp_gained(amount: int, total: int)
signal level_up(new_level: int)
signal cosmetic_unlocked(cosmetic_id: String)

# XP thresholds per level (cumulative)
const XP_PER_LEVEL: int = 100  # linear: level N requires N * 100 XP

# XP rewards
const XP_KILL: int = 10
const XP_ASSIST: int = 5
const XP_WIN: int = 25
const XP_MATCH_COMPLETE: int = 10

var current_xp: int = 0
var current_level: int = 1
var total_xp: int = 0

# Unlocked cosmetics
var unlocked_skins: Array[String] = ["default"]
var equipped_skin: String = "default"

# Skin definitions: id -> { name, body_color, accent_color, unlock_level }
var skin_catalog: Dictionary = {
	"default": {"name": "Classic", "body": Color(0.9, 0.9, 0.9), "accent": Color(0.4, 0.7, 1.0), "level": 1},
	"fire": {"name": "Fire", "body": Color(1.0, 0.6, 0.2), "accent": Color(1.0, 0.3, 0.0), "level": 3},
	"ice": {"name": "Ice", "body": Color(0.6, 0.85, 1.0), "accent": Color(0.2, 0.5, 1.0), "level": 5},
	"toxic": {"name": "Toxic", "body": Color(0.5, 1.0, 0.3), "accent": Color(0.2, 0.8, 0.0), "level": 7},
	"shadow": {"name": "Shadow", "body": Color(0.3, 0.3, 0.35), "accent": Color(0.5, 0.2, 0.8), "level": 10},
	"gold": {"name": "Gold", "body": Color(1.0, 0.85, 0.3), "accent": Color(0.9, 0.7, 0.1), "level": 15},
	"neon": {"name": "Neon", "body": Color(0.0, 1.0, 0.8), "accent": Color(1.0, 0.0, 0.8), "level": 20},
	"crimson": {"name": "Crimson", "body": Color(0.7, 0.1, 0.15), "accent": Color(1.0, 0.2, 0.2), "level": 25},
}


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)
	EventBus.match_ended.connect(_on_match_ended)
	_check_unlocks()


func add_xp(amount: int) -> void:
	current_xp += amount
	total_xp += amount
	xp_gained.emit(amount, total_xp)

	# Check level up
	while current_xp >= xp_for_next_level():
		current_xp -= xp_for_next_level()
		current_level += 1
		level_up.emit(current_level)
		_check_unlocks()


func xp_for_next_level() -> int:
	return current_level * XP_PER_LEVEL


func xp_progress() -> float:
	return float(current_xp) / float(xp_for_next_level())


func equip_skin(skin_id: String) -> bool:
	if skin_id in unlocked_skins:
		equipped_skin = skin_id
		# Save to backend if logged in
		if ApiClient.is_logged_in:
			ApiClient.update_loadout(skin_id, skin_id, func(_r: Dictionary) -> void: pass)
		return true
	return false


func get_skin_colors() -> Array:
	## Returns [body_color, accent_color] for the equipped skin.
	if skin_catalog.has(equipped_skin):
		var skin: Dictionary = skin_catalog[equipped_skin]
		return [skin["body"], skin["accent"]]
	return [Color(0.9, 0.9, 0.9), Color(0.4, 0.7, 1.0)]


func _check_unlocks() -> void:
	for skin_id in skin_catalog:
		var skin: Dictionary = skin_catalog[skin_id]
		if skin["level"] <= current_level and skin_id not in unlocked_skins:
			unlocked_skins.append(skin_id)
			cosmetic_unlocked.emit(skin_id)


func _on_player_died(victim_id: int, killer_id: int, _weapon: String) -> void:
	if killer_id == GameState.local_player_id and victim_id != killer_id:
		add_xp(XP_KILL)


func _on_match_ended(results: Dictionary) -> void:
	add_xp(XP_MATCH_COMPLETE)
	var scoreboard: Array = results.get("scoreboard", [])
	if not scoreboard.is_empty():
		if scoreboard[0].get("id", -1) == GameState.local_player_id:
			add_xp(XP_WIN)


func sync_from_backend(user_data: Dictionary) -> void:
	## Called after login to sync state from the backend.
	current_level = user_data.get("level", 1)
	current_xp = user_data.get("xp_current", 0)
	_check_unlocks()
