extends CharacterBody2D

@export var speed: float = 80.0
@export var hp: float = 20.0
@export var damage: float = 5.0

var player: Node2D
var wobble_time: float = 0.0

func _ready() -> void:
	# Adiciona ao grupo "enemies" para as armas encontrarem este inimigo facilmente
	add_to_group("enemies")
	if get_parent():
		player = get_parent().find_child("Player", true, false)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	# 1. Vai em linha reta até o jogador
	var dir = global_position.direction_to(player.global_position)
	velocity = dir * speed
	move_and_slide()
	
	# 2. "Animação" de caminhada com 1 único sprite estático (Bamboleio)
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = dir.x < 0
		wobble_time += delta * 12.0
		$Sprite2D.rotation = sin(wobble_time) * 0.15 # Balança de um lado pro outro
		
	for body in $Hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
func take_damage(amount: float) -> void:
	hp -= amount
	
	# Efeito visual de acerto (pisca vermelho/branco sem precisar de animação)
	if has_node("Sprite2D"):
		$Sprite2D.modulate = Color(10, 10, 10) # Estoura o brilho para branco
		var tween = create_tween()
		tween.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
		
	if hp <= 0:
		queue_free() # Morre (depois vocês colocam o drop de XP aqui)
