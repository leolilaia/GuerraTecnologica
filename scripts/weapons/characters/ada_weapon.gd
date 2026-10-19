extends Weapon

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 400.0
@export var pierce: int = 3  # -1 atravessa todos os inimigos
@export var hold_to_fire: bool = false
@export var area_per_level: float = 0.2

var projectile_scale: float = 1.0
var _player: Player

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player

func _process(delta: float) -> void:
	rotation = _aim_direction().angle()
	super(delta)

func _can_attack() -> bool:
	return not hold_to_fire or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _attack() -> void:
	if projectile_scene == null:
		return
	var p := _spawn_in_world(projectile_scene)
	p.global_position = global_position
	p.scale = Vector2.ONE * projectile_scale
	p.setup(_aim_direction(), damage, projectile_speed, pierce)

func _on_level_up() -> void:
	projectile_scale += area_per_level

# Clicando, mira no mouse; sem clicar, atira para onde o personagem anda
func _aim_direction() -> Vector2:
	return global_position.direction_to(get_global_mouse_position())
