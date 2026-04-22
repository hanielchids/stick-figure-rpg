## Flag entity for Capture the Flag mode.
## Can be picked up, carried, dropped on death, and scored.
extends Area2D

@export var team: int = 0  # 0 = blue, 1 = red
@export var flag_color: Color = Color(0.3, 0.5, 1.0)

var is_at_base: bool = true
var carrier: CharacterBody2D = null
var base_position: Vector2
var _return_timer: float = 0.0
const RETURN_TIME: float = 15.0  # auto-return after 15 sec on ground


func _ready() -> void:
	base_position = global_position
	collision_layer = Constants.LAYER_PICKUPS
	collision_mask = Constants.LAYER_PLAYERS
	body_entered.connect(_on_body_entered)

	# Visual
	var visual := _create_flag_visual()
	add_child(visual)

	# Collision shape
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	shape.shape = circle
	add_child(shape)


func _process(delta: float) -> void:
	if carrier and is_instance_valid(carrier):
		# Follow carrier
		global_position = carrier.global_position + Vector2(0, -35)

		# Check if carrier died
		if carrier.is_dead:
			drop()
	elif not is_at_base:
		# Auto-return timer
		_return_timer -= delta
		if _return_timer <= 0:
			return_to_base()


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return

	var character: CharacterBody2D = body as CharacterBody2D

	# Can't pick up your own team's flag (unless returning it)
	var player_team: int = _get_player_team(character.player_id)

	if player_team == team:
		# Touching your own flag at base while carrying enemy flag = SCORE
		if is_at_base and _is_carrying_enemy_flag(character):
			_score_point(character)
		# Touching your own dropped flag = return it
		elif not is_at_base and carrier == null:
			return_to_base()
	else:
		# Enemy touching your flag = pick up
		if carrier == null:
			_pickup(character)


func _pickup(character: CharacterBody2D) -> void:
	carrier = character
	is_at_base = false
	monitoring = false  # stop detecting collisions while carried
	SoundManager.play_sfx("pickup")


func drop() -> void:
	carrier = null
	_return_timer = RETURN_TIME
	monitoring = true


func return_to_base() -> void:
	carrier = null
	is_at_base = true
	global_position = base_position
	_return_timer = 0.0
	monitoring = true


func _score_point(scoring_player: CharacterBody2D) -> void:
	# Find the enemy flag being carried and return it
	var flags: Array[Node] = get_tree().get_nodes_in_group("flags")
	for flag_node in flags:
		if flag_node is Area2D and flag_node != self and flag_node.has_method("return_to_base"):
			if flag_node.carrier == scoring_player:
				flag_node.return_to_base()

	# Award points
	GameState.record_kill(scoring_player.player_id, -1)  # reuse kill counter as score
	EventBus.notification_requested.emit("%s CAPTURED THE FLAG!" % _get_player_name(scoring_player.player_id), 3.0)
	SoundManager.play_sfx("pickup", 5.0)


func _get_player_team(player_id: int) -> int:
	if GameState.players.has(player_id):
		return GameState.players[player_id].get("team", 0)
	return 0


func _get_player_name(player_id: int) -> String:
	if GameState.players.has(player_id):
		return GameState.players[player_id].get("name", "Player")
	return "Player"


func _is_carrying_enemy_flag(character: CharacterBody2D) -> bool:
	var flags: Array[Node] = get_tree().get_nodes_in_group("flags")
	for flag_node in flags:
		if flag_node is Area2D and flag_node.has_method("drop"):
			if flag_node.carrier == character and flag_node.team != team:
				return true
	return false


func _create_flag_visual() -> Node2D:
	var container := Node2D.new()

	# Pole
	var pole := Line2D.new()
	pole.add_point(Vector2(0, 0))
	pole.add_point(Vector2(0, -20))
	pole.width = 2.0
	pole.default_color = Color(0.7, 0.7, 0.7)
	container.add_child(pole)

	# Flag cloth (triangle)
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([
		Vector2(0, -20),
		Vector2(12, -15),
		Vector2(0, -10),
	])
	cloth.color = flag_color
	container.add_child(cloth)

	return container
