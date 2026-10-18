extends Area2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 8.0
var speed: float = 300.0
var lifetime: float = 5.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func setup(dir: Vector2, dmg: float) -> void:
	direction = dir
	damage = dmg
	rotation = dir.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
