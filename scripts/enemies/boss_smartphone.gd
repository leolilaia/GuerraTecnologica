extends "res://scripts/enemies/boss_base.gd"

# Quais ataques este boss usa (0 a 5). Dá para mudar no Inspetor de cada boss.
@export var attack_pool: Array[int] = [0, 1, 2, 3, 4, 5]
var last_attack: int = -1

func _attack(_index: int) -> void:
	var pick: int = attack_pool.pick_random()
	if attack_pool.size() > 1 and pick == last_attack:
		pick = attack_pool[(attack_pool.find(pick) + 1) % attack_pool.size()]
	last_attack = pick
	match pick:
		0: _volley()
		1: _fan()
		2: _rain()
		3: _spiral()
		4: _fountain()
		5: _bounce()

func _aim() -> Vector2:
	if is_instance_valid(player):
		return global_position.direction_to(player.global_position)
	return Vector2.DOWN

# 0. Rajada: arremessos mirados no jogador, um atrás do outro
func _volley() -> void:
	var count := 6 if in_phase2() else 4
	var tw := create_tween()
	for i in count:
		tw.tween_callback(func(): shoot(global_position, _aim(), {"speed": 380.0, "spin": 8.0}))
		tw.tween_interval(0.25)

# 1. Leque: vários aparelhos de uma vez, abrindo na direção do jogador
func _fan() -> void:
	var base_angle := _aim().angle()
	var count := 9 if in_phase2() else 7
	var spread := deg_to_rad(70.0)
	for i in count:
		var t := float(i) / (count - 1)
		var a := base_angle + lerpf(-spread / 2.0, spread / 2.0, t)
		shoot(global_position, Vector2.from_angle(a), {"speed": 320.0, "spin": 6.0})

# 2. Chuva: caem do topo da tela em alturas e velocidades diferentes
func _rain() -> void:
	var count := 12 if in_phase2() else 9
	var step := half_size.x * 2.0 / count
	for i in count:
		var x := center.x - half_size.x + step * (i + 0.5) + randf_range(-step * 0.3, step * 0.3)
		var y := center.y - half_size.y - randf_range(0.0, 220.0)
		shoot(Vector2(x, y), Vector2.DOWN, {
			"speed": randf_range(220.0, 330.0), "spin": randf_range(-6.0, 6.0),
			"big": randf() < 0.25})

# 3. Espiral: o boss gira atirando em sequência
func _spiral() -> void:
	var steps := 30 if in_phase2() else 22
	var delay := 0.06 if in_phase2() else 0.08
	var start_angle := randf() * TAU
	var tw := create_tween()
	for i in steps:
		tw.tween_callback(func(): shoot(global_position, Vector2.from_angle(start_angle + i * 0.45), {"speed": 280.0, "spin": 5.0}))
		tw.tween_interval(delay)

# 4. Chafariz: lança para cima e os aparelhos caem em arco
func _fountain() -> void:
	var count := 14 if in_phase2() else 10
	for i in count:
		var a := deg_to_rad(randf_range(-160.0, -20.0))
		shoot(global_position, Vector2.from_angle(a), {
			"speed": randf_range(280.0, 460.0), "gravity": 520.0,
			"spin": randf_range(-7.0, 7.0), "lifetime": 5.0,
			"big": i % 4 == 0})

# 5. Ricochete: aparelhos grandes que quicam nas bordas da tela
func _bounce() -> void:
	var count := 3 if in_phase2() else 2
	for i in count:
		var a := _aim().angle() + deg_to_rad(randf_range(-35.0, 35.0))
		shoot(global_position, Vector2.from_angle(a), {
			"speed": 260.0, "big": true, "spin": 3.0, "bounces": 4, "lifetime": 9.0,
			"bounds_center": center, "bounds_half": half_size})
