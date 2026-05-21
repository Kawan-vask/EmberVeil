# ==============================================================================
# NIGHT CONFIG
# ------------------------------------------------------------------------------
# Resource que centraliza todas as fórmulas de escalada por noite.
#
# Uso:
# - Crie um .tres no Inspector herdando deste script
# - Arraste o .tres no GameManager e no EnemyDirector
# - Para dificuldades diferentes: crie novos .tres (night_config_hard.tres, etc)
# ==============================================================================

class_name NightConfig
extends Resource


# ==============================================================================
#region MADEIRA
# ==============================================================================

## Objetivo de madeira na noite 1
@export var base_wood_goal: int = 5

## Madeira adicional por noite
## Noite 1: 5 | Noite 2: 7 | Noite 3: 9...
@export var wood_per_night: int = 2

#endregion


# ==============================================================================
#region INIMIGOS — LIMITE DE VIVOS
# ==============================================================================

## Máximo de inimigos vivos simultâneos na noite 1
@export var base_max_alive: int = 3

## Inimigos vivos adicionais por noite
## Noite 1: 3 | Noite 2: 4 | Noite 3: 5...
@export var max_alive_per_night: int = 1

#endregion


# ==============================================================================
#region INIMIGOS — WAVE SIZE
# ==============================================================================

## Tamanho da wave na noite 1
@export var base_wave_size: int = 4

## Inimigos adicionais por wave a cada noite
## Noite 1: 4 | Noite 2: 6 | Noite 3: 8...
@export var wave_size_per_night: int = 2

#endregion


# ==============================================================================
#region API PÚBLICA
# ==============================================================================

## Retorna o objetivo de madeira para a noite informada
func get_wood_goal(night: int) -> int:
	return base_wood_goal + (night - 1) * wood_per_night


## Retorna o máximo de inimigos vivos para a noite informada
func get_max_alive(night: int) -> int:
	return base_max_alive + (night - 1) * max_alive_per_night


## Retorna o tamanho da wave para a noite informada
func get_wave_size(night: int) -> int:
	return base_wave_size + (night - 1) * wave_size_per_night

#endregion
