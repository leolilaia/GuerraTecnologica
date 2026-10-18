extends Weapon

## Solta uma onda de alta frequência que paralisa quem estiver em volta.
## Não causa dano: é controle de multidão.

@export var wave_texture: Texture2D
@export var radius: float = 70.0
@export var stun_duration: float = 1.5
@export var stun_per_level: float = 0.4
@export var cooldown_per_level: float = 0.5
@export var min_cooldown: float = 1.0
@export var stun_tint: Color = Color(1.0, 1.0, 0.55)
@export var wave_duration: float = 0.4

var _wave_age: float = -1.0

func _process(delta: float) -> void:
	super(delta)
	if _wave_age >= 0.0:
		_wave_age += delta
		if _wave_age > wave_duration:
			_wave_age = -1.0
		queue_redraw()

func describe_next_level() -> String:
	return "Recarga %.1fs → %.1fs, paralisia %.1fs → %.1fs" % [
		cooldown, _next_cooldown(), stun_duration, stun_duration + stun_per_level]

func _attack() -> void:
	for enemy in _enemies_within(global_position, radius):
		enemy.stun(stun_duration, stun_tint)
		if damage > 0.0:
			enemy.take_damage(damage)
	_wave_age = 0.0

func _on_level_up() -> void:
	cooldown = _next_cooldown()
	stun_duration += stun_per_level

func _next_cooldown() -> float:
	return maxf(cooldown - cooldown_per_level, min_cooldown)

# O sprite da descarga no centro e um anel que abre até o raio de alcance
func _draw() -> void:
	if _wave_age < 0.0:
		return
	var t := _wave_age / wave_duration
	var fade := 1.0 - t
	var ring := radius * (1.0 - pow(1.0 - t, 2.0))
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 48, Color(stun_tint, 0.8 * fade), 2.0)
	draw_circle(Vector2.ZERO, ring, Color(stun_tint, 0.12 * fade))
	if wave_texture:
		var size := wave_texture.get_size() * lerpf(1.0, 2.5, t)
		draw_texture_rect(wave_texture, Rect2(-size / 2.0, size), false, Color(1, 1, 1, fade))
