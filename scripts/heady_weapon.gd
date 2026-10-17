extends Area2D

@export var damage: float = 3.0
@export var tick: float = 0.5   # dano a cada 0,5 s

var timer: float = 0.0

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	timer = tick
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)
