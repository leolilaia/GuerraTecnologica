class_name UiScaler
extends Control

## As telas de menu foram desenhadas para 640x360. Dentro da arena, que roda
## em 1920x900, este nó amplia os filhos para ocuparem a tela do mesmo jeito.

@export var design_height: float = 360.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_viewport().size_changed.connect(_fit)
	_fit()

func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var factor := view.y / design_height
	position = Vector2.ZERO
	scale = Vector2(factor, factor)
	size = view / factor
