class_name PlayerSpawner
extends Node2D

## Cria o player na posição deste nó com o personagem escolhido nas estátuas
## da Base. `character` só vale como reserva se o Catalogo não achar nenhum.

signal player_spawned(player: Player)

@export var player_scene: PackedScene
@export var character: CharacterData
## Desligado pelo DevStart, que escolhe o personagem por conta própria
var use_saved_character: bool = true

func _ready() -> void:
	var selected := Catalogo.character_data(SavedData.personagem_atual())
	if selected and use_saved_character:
		character = selected
	if character:
		spawn(character)

func spawn(data: CharacterData) -> Player:
	var player := player_scene.instantiate() as Player
	player.character = data
	add_child(player)
	player_spawned.emit(player)
	return player
