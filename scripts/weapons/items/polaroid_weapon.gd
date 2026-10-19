extends Weapon

## Flash de câmera em cone na direção do mouse que desintegra quem pegar.
## Cada nível abre o cone, até o limite de 180°.

@export var reach: float = 110.0
@export var cone_degrees: float = 45.0
@export var cone_per_level: float = 35.0
@export var max_cone_degrees: float = 180.0
@export var flash_color: Color = Color(1.0, 1.0, 0.9)
@export var flash_duration: float = 0.3
@export var disintegrate_duration: float = 0.4

var _flash_angle: float = 0.0
var _flash_left: float = 0.0

func _process(delta: float) -> void:
	super(delta)
	if _flash_left > 0.0:
		_flash_left -= delta
		queue_redraw()

func describe_next_level() -> String:
	return "Cone %d° → %d°" % [cone_degrees, _next_cone()]

func _attack() -> void:
	_flash_angle = _aim_angle()
	_flash_left = flash_duration
	var half := deg_to_rad(cone_degrees) / 2.0
	for enemy in _enemies_within(global_position, reach):
		var angle := global_position.direction_to(enemy.global_position).angle()
		if absf(angle_difference(_flash_angle, angle)) > half or enemy.hp <= 0:
			continue
		enemy.take_damage(damage)
		if enemy.hp <= 0:
			_disintegrate(enemy)

func _on_level_up() -> void:
	cone_degrees = _next_cone()

func _next_cone() -> float:
	return minf(cone_degrees + cone_per_level, max_cone_degrees)

# O inimigo some no mesmo frame: uma cópia do sprite estoura em branco e se desfaz subindo
func _disintegrate(enemy: Node2D) -> void:
	var source := enemy.get_node_or_null("Sprite2D") as Sprite2D
	if source == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = source.texture
	ghost.flip_h = source.flip_h
	ghost.global_transform = source.global_transform
	ghost.modulate = Color(4, 4, 4)
	get_tree().current_scene.add_child(ghost)
	var tween := ghost.create_tween().set_parallel()
	tween.tween_property(ghost, "modulate", Color(1, 1, 1, 0), disintegrate_duration)
	tween.tween_property(ghost, "scale", Vector2(ghost.scale.x * 1.4, ghost.scale.y * 0.1), disintegrate_duration)
	tween.tween_property(ghost, "position:y", ghost.position.y - 10.0, disintegrate_duration)
	tween.chain().tween_callback(ghost.queue_free)

func _draw() -> void:
	if _flash_left <= 0.0:
		return
	var alpha := _flash_left / flash_duration
	var half := deg_to_rad(cone_degrees) / 2.0
	var points := PackedVector2Array([Vector2.ZERO])
	for i in 25:
		points.append(Vector2.from_angle(_flash_angle - half + 2.0 * half * i / 24.0) * reach)
	draw_colored_polygon(points, Color(flash_color, 0.55 * alpha))
	draw_polyline(points.slice(1), Color(flash_color, alpha), 1.5)
	
func _aim_angle() -> float:
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_dir != Vector2.ZERO:
		return input_dir.angle()
	return 0.0
