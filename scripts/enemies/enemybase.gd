extends CharacterBody2D

@export var speed: float = 80.0
@export var hp: float = 20.0
@export var damage: float = 5.0

var player: Node2D
var wobble_time: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var dir := global_position.direction_to(player.global_position)
	velocity = dir * speed
	move_and_slide()

	# Sprite estático único: o bamboleio simula a caminhada
	$Sprite2D.flip_h = dir.x < 0
	wobble_time += delta * 12.0
	$Sprite2D.rotation = sin(wobble_time) * 0.15

	for body in $Hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)

func take_damage(amount: float) -> void:
	hp -= amount

	# Modulate acima de 1 estoura o brilho para branco sem precisar de animação
	$Sprite2D.modulate = Color(10, 10, 10)
	create_tween().tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)

	if hp <= 0:
		queue_free()
