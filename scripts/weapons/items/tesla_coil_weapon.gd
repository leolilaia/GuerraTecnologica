extends Weapon

## Uma bobina flutua ao lado do player e dispara um raio que salta de inimigo
## em inimigo. Cada nível acrescenta um inimigo à cadeia.

@export var coil_texture: Texture2D
@export var bolt_texture: Texture2D
@export var coil_offset: Vector2 = Vector2(14, -12)
@export var target_range: float = 140.0
## Distância máxima de um salto entre dois inimigos da cadeia
@export var chain_range: float = 80.0
@export var chain_count: int = 3
@export var chain_per_level: int = 1
@export var bolt_duration: float = 0.18

var _coil: Sprite2D

func _ready() -> void:
	_coil = Sprite2D.new()
	_coil.texture = coil_texture
	_coil.position = coil_offset
	add_child(_coil)

func describe_next_level() -> String:
	return "Cadeia: %d → %d inimigos" % [chain_count, chain_count + chain_per_level]

func _can_attack() -> bool:
	return _nearest_enemy(_coil.global_position, target_range, {}) != null

func _attack() -> void:
	var from := _coil.global_position
	var hit := {}
	var target := _nearest_enemy(from, target_range, hit)
	while target and hit.size() < chain_count:
		hit[target] = true
		_spawn_bolt(from, target.global_position)
		target.take_damage(damage)
		from = target.global_position
		target = _nearest_enemy(from, chain_range, hit)

func _on_level_up() -> void:
	chain_count += chain_per_level

func _nearest_enemy(from: Vector2, max_distance: float, exclude: Dictionary) -> Node2D:
	var best: Node2D
	var best_distance := max_distance * max_distance
	for enemy in _enemies_within(from, max_distance):
		# Quem já morreu neste frame continua no grupo até o queue_free
		if exclude.has(enemy) or enemy.hp <= 0:
			continue
		var distance := from.distance_squared_to(enemy.global_position)
		if distance <= best_distance:
			best = enemy
			best_distance = distance
	return best

# O sprite do raio é horizontal: esticado e girado, liga um ponto ao outro
func _spawn_bolt(from: Vector2, to: Vector2) -> void:
	var bolt := Sprite2D.new()
	bolt.texture = bolt_texture
	bolt.global_position = (from + to) / 2.0
	bolt.rotation = from.angle_to_point(to)
	bolt.scale = Vector2(from.distance_to(to) / bolt_texture.get_width(), 1.0)
	bolt.flip_v = randf() < 0.5
	get_tree().current_scene.add_child(bolt)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, bolt_duration)
	tween.tween_callback(bolt.queue_free)
