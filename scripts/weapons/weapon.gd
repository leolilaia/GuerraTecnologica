extends Node2D

@export var projectile_scene: PackedScene
@export var fire_rate: float = 1.0
@export var damage: float = 10.0
@export var projectile_speed: float = 400.0
@export var pierce: int = 3  # -1 atravessa todos os inimigos
@export var hold_to_fire: bool = false

var cooldown: float = 0.0

func _process(delta: float) -> void:
	var aim_dir := (get_global_mouse_position() - global_position).normalized()
	rotation = aim_dir.angle()

	cooldown -= delta
	if cooldown > 0.0:
		return
	if hold_to_fire and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	cooldown = 1.0 / fire_rate
	_fire(aim_dir)

func _fire(dir: Vector2) -> void:
	if projectile_scene == null:
		return
	var p := projectile_scene.instantiate()
	# Filho da arena, e não do player, para o tiro não acompanhar o movimento dele
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	p.setup(dir, damage, projectile_speed, pierce)
