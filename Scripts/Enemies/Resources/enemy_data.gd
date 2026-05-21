# ==============================================================================
# ENEMY DATA
# ------------------------------------------------------------------------------
# Resource que armazena todos os stats configuráveis de um inimigo.
#
# Uso:
# - Crie um .tres no Inspector herdando deste script
# - Arraste o .tres no campo "data" do enemy_base.gd
# - Para variantes futuras (rápido, tanque): crie novos .tres com valores diferentes
# ==============================================================================

class_name EnemyData
extends Resource


# ==============================================================================
#region MOVIMENTO
# ==============================================================================

## Velocidade base de movimento
@export var move_speed: float = 3.5

## Velocidade de rotação ao encarar o player
@export var rotation_speed: float = 6.0

#endregion


# ==============================================================================
#region VIDA
# ==============================================================================

## Vida máxima
@export var max_health: float = 50.0

#endregion


# ==============================================================================
#region ATAQUE
# ==============================================================================

## Dano por ataque
@export var attack_damage: float = 10.0

## Tempo entre ataques em segundos
@export var attack_cooldown: float = 1.0

#endregion


# ==============================================================================
#region DESPAWN
# ------------------------------------------------------------------------------
# IMPORTANTE: deve ser sempre maior que max_spawn_distance do EnemyDirector (50.0)
# ==============================================================================

## Distância máxima do player antes de ser devolvido ao pool
@export var despawn_distance: float = 65.0

#endregion
