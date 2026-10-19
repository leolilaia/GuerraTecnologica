extends Node2D
# Bamboleio do jogador ao andar. Anexe no Sprite2D do jogador (filho do Player).

@export var wobble_speed: float = 12.0
@export var wobble_angle: float = 0.12   # em radianos (cerca de 7 graus)
@export var bob_height: float = 3.0      # altura do pulinho, em pixels

var _t: float = 0.0
var _base_pos: Vector2
var _last_pos: Vector2

func _ready() -> void:
	_base_pos = position
	_last_pos = get_parent().global_position

func _physics_process(delta: float) -> void:
	var body := get_parent() as Node2D
	var moving := body.global_position.distance_to(_last_pos) > 0.1
	_last_pos = body.global_position
	if moving:
		_t += delta * wobble_speed
		rotation = sin(_t) * wobble_angle
		position = _base_pos + Vector2(0.0, -absf(sin(_t)) * bob_height)
	else:
		_t = 0.0
		rotation = lerpf(rotation, 0.0, 12.0 * delta)
		position = position.lerp(_base_pos, 12.0 * delta)
