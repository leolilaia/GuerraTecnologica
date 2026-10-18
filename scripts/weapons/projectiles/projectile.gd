extends Area2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var speed: float = 600.0
var pierce: int = 3
var lifetime: float = 2.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, dmg: float, spd: float, prc: int) -> void:
	direction = dir
	damage = dmg
	speed = spd
	pierce = prc
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	body.take_damage(damage)
	if pierce == -1:
		return
	pierce -= 1
	if pierce <= 0:
		queue_free()
