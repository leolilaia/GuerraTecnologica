class_name PlayerSpawner
extends Node2D

## Cria o player na posição deste nó com o personagem escolhido.
## O futuro seletor de personagens só precisa definir `character` (ou chamar
## spawn()) antes de a arena entrar na árvore.

signal player_spawned(player: Player)

@export var player_scene: PackedScene
@export var character: CharacterData

func _ready() -> void:
	if character:
		spawn(character)

func spawn(data: CharacterData) -> Player:
	var player := player_scene.instantiate() as Player
	player.character = data
	add_child(player)
	player_spawned.emit(player)
	return player
