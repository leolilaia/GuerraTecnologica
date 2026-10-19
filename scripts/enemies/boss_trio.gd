extends "res://scripts/enemies/enemy_base.gd"
# Base dos bosses de tela fixa: ficam no topo, balançam de lado a lado e atacam em ciclos.

signal health_changed(hp: float, hp_max: float)
signal defeated

@export var projectile_scene: PackedScene          # enemy_projectile.tscn
@export var throwables: Array = []                 # texturas dos aparelhos pequenos
@export var big_throwables: Array = []             # texturas dos aparelhos grandes
@export var big_size: float = 1.8
@export var projectile_damage: float = 8.0
@export var top_ratio: float = 0.75
@export var sway_speed: float = 0.9
@export var sway_offset: float = 0.0               # defasagem do balanço (separa os bosses do trio)
@export var attack_interval: float = 2.4
@export var attack_interval_phase2: float = 1.7
@export var extra_bosses: Array[PackedScene] = []  # bosses extras que nascem junto (trio)

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
	active = true
	for i in range(extra_bosses.size()):
		if extra_bosses[i] != null:
			var b = extra_bosses[i].instantiate()
			get_parent().add_child(b)
			b.time = (i + 1) * 2.1   # desencontra o movimento
			b.begin_fight(c, size)
			defeated.connect(func(): if is_instance_valid(b): b.queue_free())

func in_phase2() -> bool:
	return hp < hp_max * 0.5

func _physics_process(delta: float) -> void:
	if not active or is_dead:
		return
	time += delta
	global_position = Vector2(
		center.x + sin(time * sway_speed + sway_offset) * half_size.x * 0.7,
		center.y - half_size.y * top_ratio)
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

func _attack(_index: int) -> void:
	pass

func random_throwable(big: bool = false) -> Texture2D:
	var pool: Array = big_throwables if (big and not big_throwables.is_empty()) else throwables
	if pool.is_empty():
		return null
	return pool.pick_random() as Texture2D

func shoot(from: Vector2, dir: Vector2, opts: Dictionary = {}) -> void:
	if projectile_scene == null:
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
