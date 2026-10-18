extends CanvasLayer
var new_scene: String
@onready var animation_player: AnimationPlayer = get_node("AnimationPlayer")

func _ready() -> void:
	# 🔥 FIX: garante que o visual de transição nunca bloqueie cliques
	# quando estiver invisível (alpha 0) fora da animação.
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE

func start_transition_to(path_to_scene: String) -> void:
	new_scene = path_to_scene
	animation_player.play("change_scene")

func change_scene() -> void:
	assert(get_tree().change_scene_to_file(new_scene) == OK)
