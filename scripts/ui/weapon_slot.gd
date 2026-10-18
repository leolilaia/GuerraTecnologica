extends PanelContainer

@onready var _icon: TextureRect = %Icon
@onready var _level_label: Label = %LevelLabel

var _weapon: Weapon

func bind(weapon: Weapon) -> void:
	_weapon = weapon
	_icon.texture = weapon.icon
	tooltip_text = weapon.display_name
	weapon.leveled_up.connect(_on_leveled_up)
	weapon.tree_exited.connect(queue_free)
	_refresh()

func _on_leveled_up(_level: int) -> void:
	_refresh()
	pivot_offset = size / 2.0
	scale = Vector2.ONE * 1.15
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh() -> void:
	if _weapon.is_max_level():
		_level_label.text = "MAX"
		_level_label.modulate = Color(1, 0.84, 0.45)
	else:
		_level_label.text = "Nv %d" % _weapon.level
