class_name CharacterData
extends Resource

## Define um personagem jogável. A arma base é só a inicial: qualquer
## personagem pode adquirir as armas dos outros depois.

@export var display_name: String = ""
@export var sprite: Texture2D
@export var starting_weapon: PackedScene
