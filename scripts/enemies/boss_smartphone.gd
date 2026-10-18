extends "res://scripts/enemies/enemy_base.gd"

enum State { CHASE, TELEGRAPH, DASH, SHOOT }

@export var projectile_scene: PackedScene   # arraste enemy_projectile.tscn
@export var chase_time: float = 2.5
@export var telegraph_time: float = 0.6
@export var dash_time: float = 0.4
@export var dash_speed: float = 600.0
@export var shoot_pause: float = 0.8
@export var shots_per_burst: int = 5
@export var spread_degrees: float = 50.0
@export var projectile_damage: float = 8.0

var state: State = State.CHASE
var state_timer: float = 0.0
var dash_dir: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
	state_timer += delta
	var to_player := global_position.direction_to(player.global_position)

	match state:
		State.CHASE:
			velocity = to_player * speed
			_face(to_player)
			if state_timer >= chase_time:
				_change_state(State.TELEGRAPH)
		State.TELEGRAPH:
			velocity = Vector2.ZERO
			if has_node("Sprite2D"):
				$Sprite2D.position.x = randf_range(-4.0, 4.0)   # treme avisando o golpe
			if state_timer >= telegraph_time:
				_change_state(State.DASH)
		State.DASH:
			velocity = dash_dir * dash_speed
			if state_timer >= dash_time:
				_change_state(State.SHOOT)
		State.SHOOT:
			velocity = Vector2.ZERO
			if state_timer >= shoot_pause:
				_change_state(State.CHASE)

	move_and_slide()

	# Dano de contato (a versão base foi substituída, então repetimos aqui)
	if has_node("Hitbox"):
		for body in $Hitbox.get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(damage)

func _change_state(new_state: State) -> void:
	state = new_state
	state_timer = 0.0
	if has_node("Sprite2D"):
		$Sprite2D.position.x = 0.0
	match state:
		State.DASH:
			dash_dir = global_position.direction_to(player.global_position)
			_face(dash_dir)
		State.SHOOT:
			_fire_burst()

func _face(dir: Vector2) -> void:
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = dir.x < 0.0

func _fire_burst() -> void:
	if projectile_scene == null or not is_instance_valid(player):
		return
	var base_angle := global_position.direction_to(player.global_position).angle()
	var spread := deg_to_rad(spread_degrees)
	for i in shots_per_burst:
		var t := 0.5 if shots_per_burst == 1 else float(i) / (shots_per_burst - 1)
		var angle := base_angle + lerpf(-spread / 2.0, spread / 2.0, t)
		var p := projectile_scene.instantiate()
		get_tree().current_scene.add_child(p)
		p.global_position = global_position
		p.setup(Vector2.from_angle(angle), projectile_damage)
		
		
