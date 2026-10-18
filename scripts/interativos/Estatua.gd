# Estatua.gd
extends Interagivel

const PAINEL := preload("res://scenes/ui/PainelPersonagem.tscn")

@export_enum("ada", "turing", "hedy") var personagem_id: String = "ada"

@onready var sprite: Sprite2D = $Sprite   # o nó precisa se chamar exatamente "Sprite"


func _ready() -> void:
	super._ready()
	var caminho: String = Catalogo.PERSONAGENS[personagem_id]["estatua"]
	if ResourceLoader.exists(caminho):
		sprite.texture = load(caminho)
	atualizar_visual()


func atualizar_visual() -> void:
	# Silhueta preta enquanto o personagem estiver bloqueado
	var livre := SavedData.personagem_desbloqueado(personagem_id)
	sprite.modulate = Color.WHITE if livre else Color.BLACK


func interagir() -> void:
	bloquear()
	get_tree().paused = true
	var p := PAINEL.instantiate()
	get_tree().current_scene.add_child(p)
	p.fechado.connect(_ao_fechar)
	p.abrir(personagem_id)


func _ao_fechar() -> void:
	get_tree().paused = false
	liberar()
	atualizar_visual()
