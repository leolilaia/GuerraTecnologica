extends Area2D

var center: Node2D
var angle: float = 0.0
var radius: float = 30.0
var damage: float = 10.0

var angular_speed: float = 3.0
var expand_speed: float = 120.0
var lifetime: float = 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

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
	rotation += 15.0 * delta

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
