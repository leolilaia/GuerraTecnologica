extends Weapon

## Dois sinais: um pulso de 360° em volta da Hedy e um leque mais longo
## direcionado pelo mouse. Cada onda acerta um inimigo uma única vez, quando
## passa por ele, e o dano enfraquece com a distância, como um sinal de Wi-Fi.

@export_group("Pulso base")
@export var radius: float = 72.0
@export var radius_per_level: float = 18.0
@export var pulse_duration: float = 1.0

@export_group("Pulso direcionado")
@export var beam_range: float = 170.0
@export var beam_range_per_level: float = 25.0
@export_range(10.0, 180.0) var beam_angle_degrees: float = 60.0
@export var beam_damage: float = 6.0
@export var beam_damage_per_level: float = 2.0
@export var beam_cooldown: float = 1.2
@export var beam_duration: float = 0.8

@export_group("Sinal")
## Fração do dano que ainda chega no fim do alcance
@export_range(0.0, 1.0) var edge_damage_ratio: float = 0.4
@export var signal_color: Color = Color(0.35, 0.95, 1.0)
@export var ring_width: float = 2.0
## Arcos mais finos que seguem cada onda, imitando as barras do ícone de Wi-Fi
@export var trailing_rings: int = 2
@export var trailing_gap: float = 7.0

# Cada onda guarda a própria forma, idade e quem já atingiu, para não acertar duas vezes
var _waves: Array[Dictionary] = []
var _beam_timer: float = 0.0

func _process(delta: float) -> void:
	super(delta)

	_beam_timer -= delta
	if _beam_timer <= 0.0:
		_beam_timer = beam_cooldown
		var aim := get_global_mouse_position() - global_position
		_emit(aim.angle(), deg_to_rad(beam_angle_degrees) / 2.0, beam_range, beam_duration, beam_damage)

	for wave in _waves:
		wave.age += delta
		_hit_enemies(wave)
	_waves.assign(_waves.filter(func(wave: Dictionary) -> bool: return wave.age < wave.duration))
	queue_redraw()

func _attack() -> void:
	_emit(0.0, PI, radius, pulse_duration, damage)

func _on_level_up() -> void:
	radius += radius_per_level
	beam_range += beam_range_per_level
	beam_damage += beam_damage_per_level

# A direção fica fixa no disparo: mexer o mouse depois não entorta a onda
func _emit(direction: float, half_angle: float, reach: float, duration: float, dmg: float) -> void:
	_waves.append({
		"direction": direction, "half_angle": half_angle, "reach": reach,
		"duration": duration, "damage": dmg, "age": 0.0, "hit": {},
	})

# Quem está dentro da onda e ainda não foi atingido acabou de cruzar a frente dela
func _hit_enemies(wave: Dictionary) -> void:
	var front := _wave_radius(wave)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if wave.hit.has(enemy):
			continue
		var offset: Vector2 = enemy.global_position - global_position
		var distance := offset.length()
		if distance > front:
			continue
		if wave.half_angle < PI and absf(angle_difference(wave.direction, offset.angle())) > wave.half_angle:
			continue
		wave.hit[enemy] = true
		enemy.take_damage(wave.damage * lerpf(1.0, edge_damage_ratio, distance / wave.reach))

# Começa rápido e desacelera no fim, como um sinal perdendo força
func _wave_radius(wave: Dictionary) -> float:
	var t := clampf(wave.age / wave.duration, 0.0, 1.0)
	return wave.reach * (1.0 - pow(1.0 - t, 2.0))

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(signal_color, 0.05))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(signal_color, 0.15), 1.0)

	for wave in _waves:
		var fade: float = 1.0 - wave.age / wave.duration
		var front := _wave_radius(wave)
		var from: float = wave.direction - wave.half_angle
		var to: float = wave.direction + wave.half_angle
		draw_arc(Vector2.ZERO, front, from, to, 64, Color(signal_color, 0.8 * fade), ring_width)
		for i in range(1, trailing_rings + 1):
			var r := front - trailing_gap * i
			if r <= 0.0:
				break
			draw_arc(Vector2.ZERO, r, from, to, 64, Color(signal_color, 0.4 * fade / i), 1.0)
