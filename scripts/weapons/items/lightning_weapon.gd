extends Weapon

## Raios caem em pontos aleatórios da tela, causam dano numa área pequena e
## congelam quem pegarem. Antes de cair a tela escurece um pouco, e cada raio
## desce com uma piscada. No nível máximo vira Para-raio: os raios caem no mouse.

@export var bolt_texture: Texture2D
@export var strike_radius: float = 28.0
@export var strikes: int = 1
@export var strikes_per_level: int = 1
@export var freeze_duration: float = 1.0
@export var freeze_tint: Color = Color(0.45, 0.7, 1.0)

@export_group("Aviso")
@export var warning_time: float = 0.2
@export_range(0.0, 1.0) var dim_strength: float = 0.12
@export var fall_time: float = 0.08
@export var fall_height: float = 160.0
@export var strike_interval: float = 0.06

@export_group("Evolução")
@export var evolved_name: String = "Para-raio"
@export var evolved_icon: Texture2D

# Camadas separadas: a piscada de um raio não pode interromper o escurecer da sequência
var _dim: ColorRect
var _flash: ColorRect

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_dim = _make_overlay(layer, Color.BLACK)
	_flash = _make_overlay(layer, Color.WHITE)

func _make_overlay(layer: CanvasLayer, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(color, 0.0)
	layer.add_child(rect)
	return rect

func describe_next_level() -> String:
	if level + 1 == max_level:
		return "Evolui para %s: os raios caem onde está o mouse" % evolved_name
	return "%d → %d raios por vez" % [strikes, strikes + strikes_per_level]

func _attack() -> void:
	_cast()

func _on_level_up() -> void:
	strikes += strikes_per_level
	if is_max_level():
		display_name = evolved_name
		if evolved_icon:
			icon = evolved_icon

func _cast() -> void:
	var tween := _dim.create_tween()
	tween.tween_property(_dim, "color:a", dim_strength, warning_time)
	await tween.finished
	for i in strikes:
		_strike(_pick_target())
		await get_tree().create_timer(strike_interval, false).timeout
	# Espera o último raio tocar o chão antes de clarear
	await get_tree().create_timer(fall_time, false).timeout
	_dim.create_tween().tween_property(_dim, "color:a", 0.0, 0.15)

func _pick_target() -> Vector2:
	if is_max_level():
		return get_global_mouse_position()
	var view := get_viewport().get_canvas_transform().affine_inverse() * get_viewport().get_visible_rect()
	return Vector2(randf_range(view.position.x, view.end.x), randf_range(view.position.y, view.end.y))

func _strike(target: Vector2) -> void:
	var bolt := Sprite2D.new()
	bolt.texture = bolt_texture
	# A ponta de baixo do sprite marca o ponto de impacto
	bolt.offset = Vector2(0, -bolt_texture.get_height() / 2.0)
	bolt.scale = Vector2(1.0, 2.0)
	bolt.global_position = target - Vector2(0, fall_height)
	get_tree().current_scene.add_child(bolt)

	var tween := bolt.create_tween()
	tween.tween_property(bolt, "global_position", target, fall_time)
	tween.tween_callback(_impact.bind(target))
	tween.tween_property(bolt, "modulate:a", 0.0, 0.2)
	tween.tween_callback(bolt.queue_free)

func _impact(target: Vector2) -> void:
	_flash.color.a = 0.3
	_flash.create_tween().tween_property(_flash, "color:a", 0.0, 0.12)
	for enemy in _enemies_within(target, strike_radius):
		enemy.stun(freeze_duration, freeze_tint)
		enemy.take_damage(damage)
