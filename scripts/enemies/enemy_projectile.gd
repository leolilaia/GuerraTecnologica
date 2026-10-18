extends Area2D
# Projétil dos bosses: pode ter textura de aparelho, girar, ter gravidade e ricochetear.

const BASE_SIZE := 32.0   # lado maior da textura, em pixels

var vel: Vector2 = Vector2.RIGHT * 300.0
var damage: float = 8.0
var lifetime: float = 6.0
var spin: float = 0.0
var fall_gravity: float = 0.0
var bounces_left: int = 0
var bounds_center: Vector2 = Vector2.ZERO
var bounds_half: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemy_projectiles")
	body_entered.connect(_on_body_entered)

# opts: speed, tex, spin, size, gravity, bounces, bounds_center, bounds_half, lifetime
func setup(dir: Vector2, dmg: float, opts: Dictionary = {}) -> void:
	damage = dmg
	vel = dir.normalized() * opts.get("speed", 300.0)
	spin = opts.get("spin", 0.0)
	gravity = opts.get("gravity", 0.0)
	bounces_left = opts.get("bounces", 0)
	bounds_center = opts.get("bounds_center", Vector2.ZERO)
	bounds_half = opts.get("bounds_half", Vector2.ZERO)
	lifetime = opts.get("lifetime", 6.0)
	scale = Vector2.ONE * opts.get("size", 1.0)
	fall_gravity = opts.get("gravity", 0.0)

	var tex: Texture2D = opts.get("tex", null)
	if tex != null and has_node("Sprite2D"):
		var sprite: Sprite2D = $Sprite2D
		sprite.texture = tex
		sprite.scale = Vector2.ONE * BASE_SIZE / maxf(tex.get_width(), tex.get_height())
		rotation = randf() * TAU
	else:
		rotation = vel.angle()

func _physics_process(delta: float) -> void:
	vel.y += gravity * delta
	global_position += vel * delta
	rotation += spin * delta
	vel.y += fall_gravity * delta

	if bounces_left > 0:
		var lo := bounds_center - bounds_half
		var hi := bounds_center + bounds_half
		if global_position.x < lo.x or global_position.x > hi.x:
			vel.x = -vel.x
			global_position.x = clampf(global_position.x, lo.x, hi.x)
			bounces_left -= 1
		if global_position.y < lo.y or global_position.y > hi.y:
			vel.y = -vel.y
			global_position.y = clampf(global_position.y, lo.y, hi.y)
			bounces_left -= 1

	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
