class_name XpOrb
extends Area2D

## Começa devagar e acelera: o jogador vê a orb vindo antes de ela chegar
@export var attract_speed: float = 40.0
@export var attract_acceleration: float = 500.0
@export var radius: float = 2.5
@export var color: Color = Color(0.3, 0.9, 1.0)

var value: float = 1.0
var _target: Node2D
var _speed: float

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	_speed += attract_acceleration * delta
	global_position = global_position.move_toward(_target.global_position, _speed * delta)

# Sem sprite próprio por enquanto: núcleo sólido com halo translúcido
func _draw() -> void:
	draw_circle(Vector2.ZERO, radius * 2.0, Color(color, 0.25))
	draw_circle(Vector2.ZERO, radius, color)

func attract_to(target: Node2D) -> void:
	if _target == null:
		_target = target
		_speed = attract_speed

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_experience"):
		body.add_experience(value)
		queue_free()
