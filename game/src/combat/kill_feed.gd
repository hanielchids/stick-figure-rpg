## Tracks kill events and emits kill feed entries for the UI to display.
## Autoload-friendly or attach to a scene manager.
extends Node


func _ready() -> void:
	EventBus.player_died.connect(_on_player_died)


func _on_player_died(victim_id: int, killer_id: int, weapon_name: String) -> void:
	var killer_name := _get_player_name(killer_id)
	var victim_name := _get_player_name(victim_id)

	EventBus.kill_feed_entry.emit(killer_name, victim_name, weapon_name)
	GameState.record_kill(killer_id, victim_id)


func _get_player_name(player_id: int) -> String:
	if GameState.players.has(player_id):
		return GameState.players[player_id]["name"]
	return "Player %d" % player_id
