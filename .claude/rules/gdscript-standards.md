# GDScript Coding Standards & Error Prevention Rules

**Applies to:** All `.gd` files in this project
**Purpose:** Prevent compile errors, runtime crashes, and logic bugs BEFORE they happen.
**Priority:** These rules are MANDATORY. Never generate code that violates them.

---

## Rule 1: ALWAYS Use Explicit Static Types

GDScript can infer types, but inference fails on ambiguous expressions. ALWAYS declare types explicitly.

This is the #1 source of errors in this project. The error `Cannot infer the type of "X" variable because the value doesn't have a set type` happens when you use `:=` with an expression whose type Godot can't determine at parse time.

### Variables — ALWAYS specify the type

```gdscript
# ❌ WRONG — Will cause "Cannot infer type" errors
var angle := atan2(direction.y, direction.x)
var player_id := get_multiplayer_authority()
var closest_enemy := find_nearest_enemy()
var health := max(0, current_health - damage)
var result := some_function()

# ✅ CORRECT — Explicit types, always works
var angle: float = atan2(direction.y, direction.x)
var player_id: int = get_multiplayer_authority()
var closest_enemy: CharacterBody2D = find_nearest_enemy()
var health: float = max(0, current_health - damage)
var result: Variant = some_function()
```

### When `:=` IS safe (inferred from literal or constructor)

```gdscript
# ✅ These are safe because the right side has an unambiguous type
var speed := 300.0           # float literal
var name := "Player"         # String literal
var pos := Vector2.ZERO      # Constructor
var alive := true            # bool literal
var count := 0               # int literal
var enemies := []            # Array (untyped)

# ✅ Even better — fully explicit
var speed: float = 300.0
var name: String = "Player"
var pos: Vector2 = Vector2.ZERO
```

### When `:=` WILL FAIL (never use `:=` in these cases)

```gdscript
# ❌ Function return types Godot can't infer
var node := get_node("Path")          # Use: var node: Node = get_node("Path")
var child := get_child(0)             # Use: var child: Node = get_child(0)
var result := randi_range(1, 10)      # Use: var result: int = randi_range(1, 10)
var angle := atan2(y, x)             # Use: var angle: float = atan2(y, x)
var clamped := clamp(val, 0, 100)    # Use: var clamped: float = clamp(val, 0, 100)
var lerped := lerp(a, b, t)          # Use: var lerped: float = lerp(a, b, t)
var snapped := snappedf(val, 0.1)    # Use: var snapped: float = snappedf(val, 0.1)

# ❌ Method returns on dynamic objects
var id := multiplayer.get_unique_id()      # Use: var id: int = ...
var authority := get_multiplayer_authority() # Use: var authority: int = ...

# ❌ Ternary / conditional expressions
var dir := 1 if facing_right else -1       # Use: var dir: int = ...

# ❌ Array/Dictionary access
var item := inventory[0]                   # Use: var item: Variant = ...
var value := dict["key"]                   # Use: var value: Variant = ...
```

### Rule of thumb: When in doubt, write the full type. NEVER guess with `:=`.

---

## Rule 2: ALWAYS Type Function Signatures

Every function MUST have typed parameters and a return type.

```gdscript
# ❌ WRONG — Untyped
func take_damage(amount, source):
    health -= amount

func get_speed():
    return move_speed * speed_multiplier

# ✅ CORRECT — Fully typed
func take_damage(amount: float, source: Node2D) -> void:
    health -= amount

func get_speed() -> float:
    return move_speed * speed_multiplier

# ✅ CORRECT — Void for functions that don't return
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    pass
```

### Signal callbacks MUST match the signal's parameter types

```gdscript
# If the signal is: signal health_changed(new_health: float, old_health: float)
# Then the callback MUST be:
func _on_health_changed(new_health: float, old_health: float) -> void:
    health_bar.value = new_health
```

---

## Rule 3: ALWAYS Type Class Member Variables

```gdscript
# ❌ WRONG
var health = 100
var move_speed = 300
var velocity = Vector2.ZERO
var is_dead = false
var current_weapon = null

# ✅ CORRECT
var health: float = 100.0
var move_speed: float = 300.0
var velocity: Vector2 = Vector2.ZERO
var is_dead: bool = false
var current_weapon: WeaponDefinition = null
```

---

## Rule 4: Use Typed Arrays and Dictionaries

```gdscript
# ❌ WRONG — Untyped containers allow anything in, cause runtime errors
var enemies = []
var scores = {}

# ✅ CORRECT — Typed containers catch errors at parse time
var enemies: Array[CharacterBody2D] = []
var scores: Dictionary = {}  # Dictionary can't be fully typed yet, but declare it

# ✅ For loop variables must also be typed
for enemy: CharacterBody2D in enemies:
    enemy.take_damage(10.0)

for i: int in range(10):
    pass
```

---

## Rule 5: Null Safety — ALWAYS Check Before Accessing

Null references are the #1 runtime crash. Prevent them.

```gdscript
# ❌ WRONG — Will crash if find_enemy() returns null
var enemy := find_nearest_enemy()
enemy.take_damage(10.0)

# ✅ CORRECT — Null check
var enemy: CharacterBody2D = find_nearest_enemy()
if enemy != null:
    enemy.take_damage(10.0)

# ✅ CORRECT — Use is_instance_valid for nodes that might be freed
if is_instance_valid(target):
    target.take_damage(10.0)
```

### @onready MUST use explicit types and `as` for safe casting

```gdscript
# ❌ WRONG — If node type changes in scene, silent null at runtime
@onready var timer := $RespawnTimer
@onready var sprite := $Sprite2D

# ✅ CORRECT — Type is enforced, errors caught immediately on scene load
@onready var timer: Timer = $RespawnTimer as Timer
@onready var sprite: Sprite2D = $Sprite2D as Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D as CollisionShape2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer as AnimationPlayer
```

---

## Rule 6: Signal Declaration and Connection Standards

### Declare signals with typed parameters

```gdscript
# ❌ WRONG — Untyped signals
signal health_changed
signal player_died

# ✅ CORRECT — Typed parameters make callbacks self-documenting
signal health_changed(new_health: float, max_health: float)
signal player_died(player_id: int, killer_id: int, weapon_name: String)
signal weapon_picked_up(weapon: WeaponDefinition)
```

### Connect signals using Callable syntax (Godot 4 style)

```gdscript
# ❌ WRONG — Godot 3 syntax, will error in Godot 4
enemy.connect("died", self, "_on_enemy_died")

# ✅ CORRECT — Godot 4 Callable syntax
enemy.died.connect(_on_enemy_died)

# ✅ CORRECT — With bind for extra arguments
enemy.died.connect(_on_enemy_died.bind(enemy_id))

# ✅ Disconnect properly to avoid memory leaks
func _exit_tree() -> void:
    if enemy.died.is_connected(_on_enemy_died):
        enemy.died.disconnect(_on_enemy_died)
```

---

## Rule 7: Enum and Constant Standards

```gdscript
# ✅ Use enums instead of magic numbers
enum WeaponType { PISTOL, SHOTGUN, SMG, SNIPER, ROCKET_LAUNCHER, KNIFE }
enum PlayerState { IDLE, RUNNING, JUMPING, FALLING, JETPACKING, CROUCHING, WALL_HANGING, DEAD }
enum Team { NONE, RED, BLUE }

# ✅ Use constants for tuning values, NEVER hardcode numbers in logic
const MAX_HEALTH: float = 100.0
const JETPACK_FUEL_MAX: float = 100.0
const JETPACK_DRAIN_RATE: float = 25.0
const RESPAWN_TIME: float = 3.0
const MAX_WEAPONS: int = 2

# ❌ WRONG — Magic numbers buried in logic
if health < 30:
    retreat()
if fuel > 0:
    apply_thrust()

# ✅ CORRECT — Named constants
const LOW_HEALTH_THRESHOLD: float = 30.0
if health < LOW_HEALTH_THRESHOLD:
    retreat()
if fuel > 0.0:
    apply_thrust()
```

---

## Rule 8: Node References — Safe Patterns

```gdscript
# ❌ WRONG — Accessing nodes before they exist
var sprite: Sprite2D = $Sprite2D  # Runs at class load, node doesn't exist yet

# ✅ CORRECT — Use @onready, which runs after _ready()
@onready var sprite: Sprite2D = $Sprite2D as Sprite2D

# ❌ WRONG — Long fragile node paths
var player: Node = get_node("../../World/Players/Player1")

# ✅ CORRECT — Use groups or signals instead of long paths
var players: Array[Node] = get_tree().get_nodes_in_group("players")

# ❌ WRONG — get_node without checking
get_node("SomeNode").do_something()

# ✅ CORRECT — has_node check or null check
if has_node("SomeNode"):
    get_node("SomeNode").do_something()

# ✅ BETTER — Store reference and check once
var some_node: Node = get_node_or_null("SomeNode")
if some_node != null:
    some_node.do_something()
```

---

## Rule 9: _physics_process vs _process

```gdscript
# ✅ Use _physics_process for ALL gameplay logic (movement, physics, combat)
# It runs at a fixed rate (default 60Hz) and is deterministic
func _physics_process(delta: float) -> void:
    handle_movement(delta)
    handle_combat(delta)
    move_and_slide()

# ✅ Use _process ONLY for visual/UI updates that need to be smooth
func _process(delta: float) -> void:
    update_hud()
    update_camera(delta)
    interpolate_animations(delta)

# ❌ WRONG — Movement in _process causes inconsistent physics
func _process(delta: float) -> void:
    velocity.x = direction * speed  # NO — put this in _physics_process
    move_and_slide()                # NO
```

---

## Rule 10: Resource and Scene Loading

```gdscript
# ✅ Preload at class level for things you always need (faster, loaded at parse time)
const BulletScene: PackedScene = preload("res://src/combat/bullet.tscn")
const ExplosionEffect: PackedScene = preload("res://src/effects/explosion.tscn")

# ✅ Use load() at runtime only for conditional/dynamic content
func spawn_weapon(weapon_type: WeaponType) -> void:
    var scene_path: String = "res://src/combat/weapons/%s.tscn" % WeaponType.keys()[weapon_type].to_lower()
    var scene: PackedScene = load(scene_path) as PackedScene
    if scene != null:
        var instance: Node2D = scene.instantiate() as Node2D
        add_child(instance)

# ❌ WRONG — load() in a hot loop (loads from disk every frame)
func _process(delta: float) -> void:
    var tex = load("res://icon.png")  # NEVER do this
```

---

## Rule 11: Error-Proof Patterns

### Division by zero

```gdscript
# ❌ WRONG
var normalized_health: float = health / max_health

# ✅ CORRECT
var normalized_health: float = health / max_health if max_health > 0.0 else 0.0
```

### Array bounds

```gdscript
# ❌ WRONG
var first_player: Node = players[0]

# ✅ CORRECT
if players.size() > 0:
    var first_player: Node = players[0]
```

### Dictionary key access

```gdscript
# ❌ WRONG — Crashes if key doesn't exist
var score: int = scores[player_id]

# ✅ CORRECT
var score: int = scores.get(player_id, 0)
```

### Float comparison

```gdscript
# ❌ WRONG — Floating point comparison is unreliable
if velocity.length() == 0.0:
    pass

# ✅ CORRECT — Use is_zero_approx or is_equal_approx
if velocity.is_zero_approx():
    pass

if is_equal_approx(fuel, JETPACK_FUEL_MAX):
    pass
```

---

## Rule 12: Code Structure Standards

### File layout order (every .gd file follows this order)

```gdscript
class_name PlayerController
extends CharacterBody2D

# 1. Signals
signal health_changed(new_health: float, max_health: float)
signal player_died(player_id: int)

# 2. Enums
enum State { IDLE, RUNNING, JUMPING, FALLING }

# 3. Constants
const MAX_SPEED: float = 300.0
const JUMP_FORCE: float = -400.0

# 4. Exported variables (visible in Godot editor)
@export var move_speed: float = 300.0
@export var jump_height: float = 400.0

# 5. Public variables
var current_state: State = State.IDLE
var health: float = 100.0

# 6. Private variables (prefix with _)
var _is_initialized: bool = false
var _input_buffer: Array[Dictionary] = []

# 7. @onready variables
@onready var sprite: Sprite2D = $Sprite2D as Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D as CollisionShape2D

# 8. Built-in virtual methods (_ready, _process, etc.)
func _ready() -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

# 9. Public methods
func take_damage(amount: float, source: Node2D) -> void:
    pass

# 10. Private methods (prefix with _)
func _apply_gravity(delta: float) -> void:
    pass
```

---

## Rule 13: Naming Conventions (Enforced)

```
Classes/Nodes:     PascalCase      → PlayerController, WeaponManager, BulletProjectile
Functions:         snake_case      → take_damage(), get_nearest_enemy(), _apply_gravity()
Variables:         snake_case      → move_speed, current_weapon, is_alive
Constants:         UPPER_SNAKE     → MAX_HEALTH, GRAVITY, SPAWN_TIME
Enums:             PascalCase      → enum PlayerState { IDLE, RUNNING }
Signals:           snake_case      → signal health_changed, signal player_died
Private members:   _prefix         → var _internal_timer, func _calculate_hash()
File names:        snake_case.gd   → player_controller.gd, weapon_manager.gd
Scene files:       snake_case.tscn → player.tscn, main_menu.tscn
```

---

## Rule 14: Pre-Submission Checklist

Before writing ANY GDScript code, mentally verify:

1. [ ] Every variable has an explicit type (no bare `var x = ...`)
2. [ ] Every function has typed parameters and `-> ReturnType`
3. [ ] Every `@onready` uses `as TypeName` casting
4. [ ] No `:=` with function calls, math operations, or method returns
5. [ ] No null access without a null check or `is_instance_valid()`
6. [ ] No magic numbers — all tuning values are named constants
7. [ ] No `get_node()` without null safety
8. [ ] Arrays are typed: `Array[Type]`
9. [ ] Signals have typed parameters
10. [ ] File follows the standard layout order
11. [ ] Movement/physics code is in `_physics_process`, not `_process`
12. [ ] Scenes are `preload()`ed at class level, not `load()`ed in loops
13. [ ] Float comparisons use `is_zero_approx()` or `is_equal_approx()`
14. [ ] Dictionary access uses `.get(key, default)` not `[key]`

---

## Rule 15: Testing Before Declaring Done

After writing or modifying any `.gd` file:

1. **Syntax check:** Can Godot parse the file without errors? (Red markers in script editor = not done)
2. **Type check:** Are there any yellow warning triangles? Fix them.
3. **Run check:** Does the scene run without runtime errors in the Output panel?
4. **Logic check:** Does the behavior match the task specification?
5. **Edge cases:** What happens with zero health? Empty arrays? Null nodes? Test these.

If any check fails, fix it before moving to the next task. Broken code compounds — one unfixed error leads to five more downstream.
