extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
	# Lê as setas do teclado (Funciona direto sem precisar configurar nada!)
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = direction * speed
	move_and_slide()
	
	# Vira o sprite para a esquerda ou direita dependendo de para onde está andando
	if direction.x != 0 and has_node("Sprite2D"):
		$Sprite2D.flip_h = direction.x < 0
