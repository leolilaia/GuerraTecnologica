class_name Enemy
extends CharacterBody2D

signal died

const XP_ORB_SCENE := preload("res://scenes/pickups/xp_orb.tscn")

@export var speed: float = 80.0
@export var hp: float = 20.0
@export var damage: float = 5.0
@export var xp_value: float = 1.0

var player: Node2D
var wobble_time: float = 0.0
var _stun_time: float = 0.0
var _tint_tween: Tween

func _ready() -> void:
	add_to_group("enemies")
	player = get_tree().get_first_node_in_group("player") as Node2D

func _physics_process(delta: float) -> void:
	if _stun_time > 0.0:
		_stun_time -= delta
		return
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
	# Vários acertos no mesmo frame chegam antes do queue_free e contariam a morte duas vezes
	if hp <= 0:
		return
	hp -= amount

	# Modulate acima de 1 estoura o brilho para branco sem precisar de animação
	$Sprite2D.modulate = Color(10, 10, 10)
	create_tween().tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)

	if hp <= 0:
		_drop_xp_orb()
		died.emit()
		queue_free()

func _drop_xp_orb() -> void:
	var orb := XP_ORB_SCENE.instantiate() as XpOrb
	orb.value = xp_value
	orb.position = global_position
	# A morte chega no meio da checagem de colisão, quando não dá para criar áreas
	get_parent().add_child.call_deferred(orb)

# Parado também não causa dano de contato. A cor marca quem está travado e
# vai no nó inteiro para não brigar com o flash de dano, que é no Sprite2D.
func stun(duration: float, tint: Color = Color.WHITE) -> void:
	_stun_time = maxf(_stun_time, duration)
	if tint == Color.WHITE:
		return
	if _tint_tween:
		_tint_tween.kill()
	modulate = tint
	_tint_tween = create_tween()
	_tint_tween.tween_interval(duration)
	_tint_tween.tween_property(self, "modulate", Color.WHITE, 0.15)
