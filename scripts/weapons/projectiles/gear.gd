extends Area2D

@export var spawn_scale: float = 0.2
@export var grow_time: float = 0.5

var center: Node2D
var angle: float = 0.0
var radius: float = 30.0
var damage: float = 10.0

var angular_speed: float = 2.0
var expand_speed: float = 90.0
var lifetime: float = 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_grow_in()

# Escala o Area2D inteiro para a colisão crescer junto com o sprite
func _grow_in() -> void:
	scale = Vector2.ONE * spawn_scale
	modulate.a = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, grow_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, grow_time * 0.5)

func setup(c: Node2D, start_angle: float, dmg: float) -> void:
	center = c
	angle = start_angle
	damage = dmg

func _physics_process(delta: float) -> void:
	if not is_instance_valid(center):
		queue_free()
		return
	angle += angular_speed * delta
	radius += expand_speed * delta
	global_position = center.global_position + Vector2.from_angle(angle) * radius

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
