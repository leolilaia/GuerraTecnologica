extends "res://scripts/enemies/enemy_base.gd"

@export var projectile_scene: PackedScene = preload("res://scenes/enemies/EnemyProjectile.tscn")
@export var projectile_tex: Texture2D
@export var stop_distance: float = 220.0 # Distância em que ele para e atira
@export var shoot_cooldown: float = 2.0

var timer: float = 0.8

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player):
		return
		
	var dist: float = global_position.distance_to(player.global_position)
	
	# Se estiver longe, anda em direção ao jogador normalmente
	if dist > stop_distance:
		super._physics_process(delta)
	else:
		# Chegou perto: para de andar e atira!
		velocity = Vector2.ZERO
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = (player.global_position.x < global_position.x)
			
		timer -= delta
		if timer <= 0.0:
			timer = shoot_cooldown
			_shoot()

func _shoot() -> void:
	if projectile_scene == null or not is_instance_valid(player):
		return
	var p = projectile_scene.instantiate()
	get_tree().current_scene.add_child(p)
	p.global_position = global_position
	
	var dir = global_position.direction_to(player.global_position)
	var opts = {"speed": 230.0, "lifetime": 3.5}
	if projectile_tex != null:
		opts["tex"] = projectile_tex
	p.setup(dir, damage, opts)
