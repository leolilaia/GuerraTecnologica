extends Weapon

@export var area_per_level: float = 0.25

@onready var _area: Area2D = $Area

func _attack() -> void:
	for body in _area.get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(damage)

# Escala o nó Area inteiro para o sprite crescer junto com a colisão
func _on_level_up() -> void:
	_area.scale += Vector2.ONE * area_per_level
