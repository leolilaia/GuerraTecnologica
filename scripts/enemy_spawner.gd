extends Node

@export var enemy_scene: PackedScene   # arraste enemybase.tscn aqui no Inspetor
@export var spawn_interval: float = 1.0
@export var spawn_radius: float = 600.0

var timer: float = 0.0

func _process(delta: float) -> void:
	timer += delta
	if timer < spawn_interval:
		return
	timer = 0.0
	
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null or enemy_scene == null:
		return
	
	var enemy := enemy_scene.instantiate() as Node2D
	get_parent().add_child(enemy)
	enemy.global_position = player.global_position + Vector2.from_angle(randf() * TAU) * spawn_radius
