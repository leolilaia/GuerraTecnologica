class_name DevStartConfig
extends Resource

## Atalho de desenvolvimento: com "enabled" marcado, rodar o jogo pelo editor
## (F5) pula menu, save e Base e cai direto na arena com o setup abaixo.
## Não tem efeito no jogo exportado.

@export var enabled: bool = false

@export_group("Personagem")
@export_enum("ada", "turing", "hedy") var character_id: String = "ada"
## Não leva dano
@export var invincible: bool = false

@export_group("Fase")
@export_range(1, 3) var level: int = 1
@export_range(1, 5) var wave: int = 1
## Pula as waves e começa já na luta com o boss da fase
@export var boss_now: bool = false

@export_group("Armas")
## Somadas à arma inicial do personagem
@export var extra_weapons: Array[PackedScene] = []
## Nível de todas as armas, inclusive a inicial (limitado ao máximo de cada uma)
@export_range(1, 10) var weapon_level: int = 1
