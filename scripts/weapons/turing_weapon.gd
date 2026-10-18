extends Node2D

@export var gear_scene: PackedScene
@export var cooldown: float = 2.0
@export var damage: float = 10.0
@export var level: int = 1

var timer: float = 0.0

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	timer = cooldown
	_fire()

func _fire() -> void:
	if gear_scene == null:
		return
	var player := get_parent() as Node2D
	for i in level:
		var gear := gear_scene.instantiate()
		get_tree().current_scene.add_child(gear)
		gear.setup(player, TAU * i / level, damage)
