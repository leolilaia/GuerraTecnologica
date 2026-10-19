class_name Player
extends CharacterBody2D

signal health_changed(hp: float, max_hp: float)
signal died
signal weapon_added(weapon: Weapon)
signal experience_changed(xp: float, xp_to_next: float)
signal leveled_up(level: int)

const GAME_OVER_SCENE := "res://scenes/ui/GameOver.tscn"

@export var speed: float = 200.0
@export var max_hp: float = 100.0
@export var character: CharacterData
## Na Base o personagem anda sem a arma inicial
@export var armed: bool = true
## XP para sair do nível 1; cada nível seguinte pede xp_growth vezes mais
@export var xp_base: float = 5.0
@export var xp_growth: float = 1.25

var hp: float
var invulnerable: bool = false
# Última direção em que andou: parado, continua valendo para quem mira por ela
var facing: Vector2 = Vector2.RIGHT
# Nível do personagem; o "level" do WaveManager é a fase
var level: int = 1
var xp: float = 0.0
var xp_to_next: float

# O raio mora no shape da PickupZone; o upgrade de ímã mexe direto nele
var pickup_radius: float:
	get:
		return ($PickupZone/CollisionShape2D.shape as CircleShape2D).radius
	set(value):
		($PickupZone/CollisionShape2D.shape as CircleShape2D).radius = value

func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	$PickupZone.area_entered.connect(_on_pickup_zone_area_entered)
	xp_to_next = _xp_for_level(level)
	if character:
		_apply_character(character)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	if direction != Vector2.ZERO:
		facing = direction.normalized()

	if direction.x != 0:
		$Sprite2D.flip_h = direction.x < 0

# A zona só puxa a orb; a coleta acontece quando ela encosta no corpo
func _on_pickup_zone_area_entered(area: Area2D) -> void:
	if area.has_method("attract_to"):
		area.attract_to(self)

func _apply_character(data: CharacterData) -> void:
	if data.sprite:
		$Sprite2D.texture = data.sprite
	if data.starting_weapon and armed:
		add_weapon(data.starting_weapon)

func add_weapon(scene: PackedScene) -> Weapon:
	var weapon := scene.instantiate() as Weapon
	$Weapons.add_child(weapon)
	weapon_added.emit(weapon)
	SavedData.registrar_arma_usada(scene.resource_path.get_file().get_basename())
	return weapon

func get_weapons() -> Array[Weapon]:
	var weapons: Array[Weapon] = []
	weapons.assign($Weapons.get_children())
	return weapons

func add_experience(amount: float) -> void:
	xp += amount
	# O boss dá XP de vários níveis de uma vez
	while xp >= xp_to_next:
		xp -= xp_to_next
		level += 1
		xp_to_next = _xp_for_level(level)
		leveled_up.emit(level)
	experience_changed.emit(xp, xp_to_next)

func _xp_for_level(n: int) -> float:
	return roundf(xp_base * pow(xp_growth, n - 1))

func increase_max_hp(amount: float) -> void:
	max_hp += amount
	hp += amount
	health_changed.emit(hp, max_hp)

func take_damage(amount: float) -> void:
	# Morto, continua levando golpes durante o fade da transição
	if invulnerable or hp <= 0:
		return
	hp -= amount
	health_changed.emit(hp, max_hp)

	if hp <= 0:
		died.emit()
		SavedData.finalizar_run()
		SceneTransistor.start_transition_to(GAME_OVER_SCENE)
		return

	invulnerable = true
	$Sprite2D.modulate = Color(1, 0.4, 0.4)
	await get_tree().create_timer(0.5, false).timeout
	invulnerable = false
	$Sprite2D.modulate = Color.WHITE
