extends CharacterBody2D

signal health_changed(hp: float, max_hp: float)
signal died

@export var speed: float = 200.0
@export var max_hp: float = 100.0
@export var starting_weapon: PackedScene

var hp: float
var invulnerable: bool = false

func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	if starting_weapon:
		add_weapon(starting_weapon)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	if direction.x != 0:
		$Sprite2D.flip_h = direction.x < 0

func add_weapon(scene: PackedScene) -> Weapon:
	var weapon := scene.instantiate() as Weapon
	$Weapons.add_child(weapon)
	return weapon

func get_weapons() -> Array[Weapon]:
	var weapons: Array[Weapon] = []
	weapons.assign($Weapons.get_children())
	return weapons

func take_damage(amount: float) -> void:
	if invulnerable:
		return
	hp -= amount
	health_changed.emit(hp, max_hp)

	if hp <= 0:
		died.emit()
		get_tree().reload_current_scene()
		return

	invulnerable = true
	$Sprite2D.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.5).timeout
	invulnerable = false
	$Sprite2D.modulate = Color.WHITE
