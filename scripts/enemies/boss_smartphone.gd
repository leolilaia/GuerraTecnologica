extends "res://scripts/enemies/boss_base.gd"
# Boss Smartphone: seis ataques, sorteados da attack_pool.
# 0 rajada mirada | 1 leque | 2 chuva | 3 espiral | 4 chafariz | 5 ricochete


@export_flags("Rajada mirada", "Leque", "Chuva", "Espiral", "Chafariz", "Ricochete") var attack_flags: int = 63
@export var proj_speed: float = 240.0

func _attack(index: int) -> void:
	var enabled: Array[int] = []
	for i in 6:
		if attack_flags & (1 << i):
			enabled.append(i)
	if enabled.is_empty():
		return
	match enabled[index % enabled.size()]:
		0: _aimed_burst()
		1: _fan()
		2: _rain()
		3: _spiral()
		4: _fountain()
		5: _ricochet()

func _dir_to_player() -> Vector2:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p == null:
		return Vector2.DOWN
	return (p.global_position - global_position).normalized()

func _alive() -> bool:
	return is_inside_tree() and not is_dead

func _aimed_burst() -> void:
	for i in 5:
		if not _alive():
			return
		shoot(global_position, _dir_to_player(), {"speed": proj_speed * 1.3, "spin": 6.0})
		await get_tree().create_timer(0.12).timeout

func _fan() -> void:
	var base := _dir_to_player()
	for i in 9:
		var a := deg_to_rad(lerpf(-50.0, 50.0, i / 8.0))
		shoot(global_position, base.rotated(a), {"speed": proj_speed})

func _rain() -> void:
	for i in 12:
		if not _alive():
			return
		var x := center.x + randf_range(-half_size.x, half_size.x)
		var from := Vector2(x, center.y - half_size.y)
		shoot(from, Vector2.DOWN, {"speed": proj_speed * 1.1, "spin": 4.0})
		await get_tree().create_timer(0.1).timeout

func _spiral() -> void:
	var angle := randf() * TAU
	for i in 24:
		if not _alive():
			return
		shoot(global_position, Vector2.from_angle(angle), {"speed": proj_speed * 0.9, "spin": 3.0})
		angle += deg_to_rad(22.0)
		await get_tree().create_timer(0.06).timeout

func _fountain() -> void:
	for i in 10:
		var a := deg_to_rad(randf_range(-70.0, 70.0))
		shoot(global_position, Vector2.DOWN.rotated(a),
			{"speed": randf_range(220.0, 340.0), "gravity": 300.0, "spin": 5.0})

func _ricochet() -> void:
	for i in 3:
		if not _alive():
			return
		shoot(global_position, _dir_to_player().rotated(deg_to_rad(randf_range(-15.0, 15.0))),
			{"speed": proj_speed * 1.2, "bounces": 3,
			"bounds_center": center, "bounds_half": half_size, "lifetime": 8.0})
		await get_tree().create_timer(0.25).timeout
