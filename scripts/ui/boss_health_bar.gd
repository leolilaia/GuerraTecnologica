extends CanvasLayer

@onready var bar: ProgressBar = $Bar

func _ready() -> void:
	# Barra larga no topo da tela, com margem (funciona mesmo sem o preset do editor)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 40
	bar.offset_right = -40
	bar.offset_top = 16
	bar.offset_bottom = 40

	var boss := get_parent()
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_health_changed)

func _on_health_changed(hp: float, hp_max: float) -> void:
	bar.max_value = hp_max
	bar.value = hp
