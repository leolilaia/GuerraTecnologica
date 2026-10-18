extends Weapon

## Chicotada com o cabo do telefone na direção do mouse: pouco dano, muita
## frequência. Cada nível bate mais forte e mais rápido.

@export var whip_texture: Texture2D
@export var length: float = 70.0
@export var width: float = 24.0
@export var cooldown_per_level: float = 0.08
@export var min_cooldown: float = 0.25
@export var crack_time: float = 0.08

func describe_next_level() -> String:
	return "Dano %d → %d, recarga %.2fs → %.2fs" % [
		damage, damage + damage_per_level, cooldown, _next_cooldown()]

func _attack() -> void:
	var angle := _aim_angle()
	for enemy in _enemies_within(global_position, length):
		var local := (enemy.global_position - global_position).rotated(-angle)
		if local.x >= 0.0 and absf(local.y) <= width / 2.0:
			enemy.take_damage(damage)
	_play_crack(angle)

func _on_level_up() -> void:
	cooldown = _next_cooldown()

func _next_cooldown() -> float:
	return maxf(cooldown - cooldown_per_level, min_cooldown)

# O cabo estica do player até a ponta e some; fica preso ao player enquanto anima
func _play_crack(angle: float) -> void:
	var whip := Sprite2D.new()
	whip.texture = whip_texture
	whip.centered = false
	whip.offset = Vector2(0, -whip_texture.get_height() / 2.0)
	whip.rotation = angle
	# Mirando para a esquerda o sprite ficaria de cabeça para baixo
	whip.flip_v = cos(angle) < 0.0
	var full_scale := Vector2(length / whip_texture.get_width(), width / whip_texture.get_height())
	whip.scale = Vector2(full_scale.x * 0.2, full_scale.y)
	add_child(whip)
	var tween := whip.create_tween()
	tween.tween_property(whip, "scale", full_scale, crack_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(whip, "modulate:a", 0.0, 0.12)
	tween.tween_callback(whip.queue_free)
