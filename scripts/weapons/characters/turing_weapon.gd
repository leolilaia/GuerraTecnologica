extends Weapon

@export var gear_scene: PackedScene

# Uma engrenagem por nível, distribuídas igualmente: 1 à frente, 2 a 180°, 3 a 120°...
func _attack() -> void:
	if gear_scene == null:
		return
	for i in level:
		var gear := _spawn_in_world(gear_scene)
		gear.setup(self, TAU * i / level, damage)
