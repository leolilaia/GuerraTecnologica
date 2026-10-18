extends CanvasLayer

## Ao subir de nível, pausa o jogo e oferece upgrades sorteados: armas novas,
## o próximo nível das armas que o player já tem e melhorias de atributo.

@export var weapon_scenes: Array[PackedScene] = []
@export var choices: int = 3

@export_group("Atributos")
@export var max_hp_bonus: float = 20.0
@export_range(0.0, 1.0) var speed_bonus: float = 0.1
@export_range(0.0, 1.0) var pickup_radius_bonus: float = 0.3

@onready var _title: Label = %Title
@onready var _options: HBoxContainer = %Options

var _player: Player
# O boss pode dar vários níveis de uma vez: uma escolha por nível, em sequência
var _pending: int = 0

func _ready() -> void:
	hide()
	# O player só entra no grupo em seu próprio _ready, que roda depois do deste nó
	await get_tree().process_frame
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player:
		_player.leveled_up.connect(_on_player_leveled_up)

func _on_player_leveled_up(_level: int) -> void:
	_pending += 1
	if not visible:
		_open()

func _open() -> void:
	get_tree().paused = true
	_title.text = "NÍVEL %d" % (_player.level - _pending + 1)
	for child in _options.get_children():
		_options.remove_child(child)
		child.queue_free()
	for offer in _build_offers():
		_options.add_child(_make_card(offer))
	show()
	(_options.get_child(0) as Control).grab_focus.call_deferred()

func _choose(offer: Dictionary) -> void:
	offer.apply.call()
	_pending -= 1
	if _pending > 0:
		_open()
	else:
		hide()
		get_tree().paused = false

func _build_offers() -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	var owned := {}
	for weapon in _player.get_weapons():
		owned[weapon.scene_file_path] = true
		if not weapon.is_max_level():
			pool.append({
				"title": weapon.display_name, "icon": weapon.icon,
				"description": weapon.describe_next_level(),
				"apply": weapon.level_up})
	for scene in weapon_scenes:
		if owned.has(scene.resource_path):
			continue
		# Nome e ícone só existem na arma instanciada
		var preview := scene.instantiate() as Weapon
		pool.append({
			"title": preview.display_name, "icon": preview.icon,
			"description": "Arma nova",
			"apply": _player.add_weapon.bind(scene)})
		preview.free()
	pool.append({
		"title": "Vida máxima", "description": "+%d de vida" % max_hp_bonus,
		"apply": _player.increase_max_hp.bind(max_hp_bonus)})
	pool.append({
		"title": "Velocidade", "description": "+%d%% de velocidade" % roundi(speed_bonus * 100),
		"apply": func() -> void: _player.speed *= 1.0 + speed_bonus})
	pool.append({
		"title": "Ímã", "description": "+%d%% de alcance para puxar orbes" % roundi(pickup_radius_bonus * 100),
		"apply": func() -> void: _player.pickup_radius *= 1.0 + pickup_radius_bonus})
	pool.shuffle()
	return pool.slice(0, choices)

func _make_card(offer: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = Vector2(240, 300)
	card.pressed.connect(_choose.bind(offer))
	# Opaco: o aviso de fase e a arena não podem vazar por trás do texto
	var idle := _make_card_style(Color(1, 1, 1, 0.15))
	var lit := _make_card_style(Color(1, 0.84, 0.45))
	card.add_theme_stylebox_override("normal", idle)
	card.add_theme_stylebox_override("hover", lit)
	card.add_theme_stylebox_override("focus", lit)
	card.add_theme_stylebox_override("pressed", lit)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(box)

	var icon: Texture2D = offer.get("icon")
	if icon:
		var rect := TextureRect.new()
		rect.texture = icon
		rect.custom_minimum_size = Vector2(96, 96)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(rect)
	box.add_child(_make_label(offer.title, 24, Color.WHITE))
	box.add_child(_make_label(offer.description, 16, Color(1, 1, 1, 0.75)))
	return card

func _make_card_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.12, 0.15)
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	return style

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label
