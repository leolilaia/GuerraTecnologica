extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	# Espera 1 frame para garantir que o player já entrou no grupo "player"
	await get_tree().process_frame
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.health_changed.connect(_on_health_changed)
	_on_health_changed(player.hp, player.max_hp)

func _on_health_changed(hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = maxf(hp, 0.0)
