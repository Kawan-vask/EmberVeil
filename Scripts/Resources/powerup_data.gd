# ==============================================================================
# POWERUP DATA
# ------------------------------------------------------------------------------
# Resource que define um power-up disponível no jogo.
# Crie um .tres para cada power-up no Inspector.
# ==============================================================================

class_name PowerUpData
extends Resource


# ==============================================================================
#region IDENTIFICAÇÃO
# ==============================================================================

## ID único — usado pelo DevConsole (give_powerup [id])
@export var id: String = ""

## Nome exibido na PowerUpScreen
@export var display_name: String = ""

## Descrição exibida na PowerUpScreen
@export var description: String = ""

#endregion


# ==============================================================================
#region EFEITO
# ==============================================================================

## Tipo do efeito aplicado ao player
@export_enum(
	"health_max",
	"stamina_max",
	"energy_max",
	"walk_speed",
	"sprint_speed",
	"lantern_damage",
	"lantern_slow",
	"ultimate_radius",
	"ultimate_cooldown",
	"energy_drain_reduction"
) var effect_type: String = "health_max"

## Valor do efeito aplicado
@export var value: float = 10.0

#endregion
