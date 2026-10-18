class_name Weapon
extends Node2D

## Base de todas as armas: cada arma só implementa _attack() e, se tiver
## upgrade além de dano, _on_level_up().

signal leveled_up(level: int)

@export var display_name: String = ""
@export var icon: Texture2D
@export var damage: float = 10.0
@export var cooldown: float = 1.0
@export var max_level: int = 5
@export var damage_per_level: float = 0.0

var level: int = 1
var _timer: float = 0.0

func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0 or not _can_attack():
		return
	_timer = cooldown
	_attack()

func level_up() -> void:
	if level >= max_level:
		return
	level += 1
	damage += damage_per_level
	_on_level_up()
	leveled_up.emit(level)

func is_max_level() -> bool:
	return level >= max_level

## Texto do card de upgrade; armas com efeito próprio sobrescrevem
func describe_next_level() -> String:
	return "Nível %d → %d" % [level, level + 1]

func _can_attack() -> bool:
	return true

func _attack() -> void:
	pass

func _on_level_up() -> void:
	pass

func _enemies_within(center: Vector2, radius: float) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for enemy: Node2D in get_tree().get_nodes_in_group("enemies"):
		if enemy.global_position.distance_squared_to(center) <= radius * radius:
			result.append(enemy)
	return result

func _aim_angle() -> float:
	return (get_global_mouse_position() - global_position).angle()

# Tiros ficam na arena, e não na arma, para não acompanharem o movimento do player
func _spawn_in_world(scene: PackedScene) -> Node:
	var node := scene.instantiate()
	get_tree().current_scene.add_child(node)
	return node
