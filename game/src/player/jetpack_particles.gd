## Simple particle emitter for jetpack thrust.
## Spawns downward-moving particles when jetpacking.
extends GPUParticles2D

var player: CharacterBody2D


func _ready() -> void:
	player = get_parent()
	emitting = false

	# Configure particle properties via code so no .tres file needed
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)  # particles go down
	mat.spread = 15.0
	mat.initial_velocity_min = 80.0
	mat.initial_velocity_max = 140.0
	mat.gravity = Vector3(0, 20, 0)
	mat.scale_min = 2.0
	mat.scale_max = 4.0
	mat.color = Color(1.0, 0.6, 0.1, 0.9)

	var gradient := GradientTexture1D.new()
	var grad := Gradient.new()
	grad.set_offset(0, 0.0)
	grad.set_color(0, Color(1.0, 0.7, 0.2, 1.0))
	grad.set_offset(1, 1.0)
	grad.set_color(1, Color(1.0, 0.2, 0.0, 0.0))
	gradient.gradient = grad
	mat.color_ramp = gradient

	process_material = mat
	amount = 16
	lifetime = 0.4
	speed_scale = 1.5


func _process(_delta: float) -> void:
	if not player:
		return
	emitting = player.current_state == player.State.JETPACKING
