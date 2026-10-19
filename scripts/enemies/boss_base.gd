extends "res://scripts/enemies/enemy_base.gd"
# Base dos bosses de tela fixa: ficam no topo, se movem e atacam em ciclos.

signal health_changed(hp: float, hp_max: float)
signal defeated

enum MoveMode { SWAY, FIGURE8, CHASE }

@export var projectile_scene: PackedScene          # enemy_projectile.tscn
@export var throwables: Array[Texture2D] = []                 # texturas dos aparelhos pequenos
@export var big_throwables: Array[Texture2D] = []             # texturas dos aparelhos grandes
@export var big_size: float = 1.8
@export var projectile_damage: float = 8.0
@export var top_ratio: float = 0.75
@export var attack_interval: float = 2.4
@export var attack_interval_phase2: float = 1.7


@export_group("Movimento")
@export var move_mode: MoveMode = MoveMode.SWAY
@export var sway_speed: float = 0.9
@export var sway_range: float = 0.5                # fração da meia-largura da tela
@export var chase_speed: float = 90.0              # só no modo Chase
@export var phase2_speed_mult: float = 1.4         # acelera quando a vida cai abaixo de 50%
@export var auto_center: bool = true               # pega centro e tamanho da câmera

var hp_max: float
var center: Vector2
var half_size: Vector2
var active: bool = false
var time: float = 0.0
var attack_timer: float = 1.5
var attack_index: int = 0
var is_dead: bool = false

func _ready() -> void:
	super()
	hp_max = hp
	health_changed.emit(hp, hp_max)

func begin_fight(c: Vector2, size: Vector2) -> void:
	center = c
	half_size = size
	if auto_center:
		var cam := get_viewport().get_camera_2d()
		if cam:
			center = cam.get_screen_center_position()
			half_size = get_viewport_rect().size / cam.zoom * 0.5
	global_position = Vector2(center.x, _base_y())
	active = true

func _base_y() -> float:
	return center.y - half_size.y * top_ratio

func in_phase2() -> bool:
	return hp < hp_max * 0.5

func _physics_process(delta: float) -> void:
	if not active or is_dead:
		return
	var mult := phase2_speed_mult if in_phase2() else 1.0
	time += delta * mult
	_move(delta, mult)
	if has_node("Sprite2D"):
		$Sprite2D.rotation = sin(time * 3.0) * 0.05

	attack_timer -= delta
	if attack_timer <= 0.0:
		_attack(attack_index)
		attack_index += 1
		attack_timer = attack_interval_phase2 if in_phase2() else attack_interval

	if has_node("Hitbox"):
		for body in $Hitbox.get_overlapping_bodies():
			if body.has_method("take_damage"):
				body.take_damage(damage)

func _move(delta: float, mult: float) -> void:
	var range_x := half_size.x * sway_range
	match move_mode:
		MoveMode.SWAY:
			global_position = Vector2(
				center.x + sin(time * sway_speed) * range_x,
				_base_y())
		MoveMode.FIGURE8:
			global_position = Vector2(
				center.x + sin(time * sway_speed) * range_x,
				_base_y() + sin(time * sway_speed * 2.0) * half_size.y * 0.12)
		MoveMode.CHASE:
			var target_x := center.x
			if is_instance_valid(player):
				target_x = clampf(player.global_position.x, center.x - range_x, center.x + range_x)
			global_position = Vector2(
				move_toward(global_position.x, target_x, chase_speed * mult * delta),
				_base_y())

func _attack(_index: int) -> void:
	pass

func random_throwable(big: bool = false) -> Texture2D:
	var pool: Array = big_throwables if (big and not big_throwables.is_empty()) else throwables
	if pool.is_empty():
		return null
	return pool.pick_random() as Texture2D

func shoot(from: Vector2, dir: Vector2, opts: Dictionary = {}) -> void:
	if projectile_scene == null:
		push_warning("%s: Projectile Scene vazio, o boss não consegue atirar" % name)
		return
	var o := opts.duplicate()
	var big: bool = o.get("big", false)
	if not o.has("tex"):
		o["tex"] = random_throwable(big)
	if not o.has("size"):
		o["size"] = big_size if big else 1.0
	var p := projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = from
	p.setup(dir, projectile_damage, o)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	super(amount)
	health_changed.emit(maxf(hp, 0.0), hp_max)
	if hp <= 0.0:
		is_dead = true
		defeated.emit()
