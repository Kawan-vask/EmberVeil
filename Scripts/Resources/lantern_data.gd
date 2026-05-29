# ==============================================================================
# LANTERN DATA
# ------------------------------------------------------------------------------
# Parâmetros completos de uma lanterna via Resource.
# Novas lanternas = novos .tres — zero código novo.
# ==============================================================================

class_name LanternData
extends Resource

#region IDENTIFICAÇÃO
@export var id: String = "default"
@export var display_name: String = "Lamparina"
#endregion

#region ENERGIA
@export var max_energy: float = 100.0
@export var energy_drain: float = 10.0
#endregion

#region COMBATE
@export var damage_per_second: float = 20.0
@export var slow_factor: float = 0.4
#endregion

#region ULTIMATE
@export var ultimate_cost: float = 0.5
@export var ultimate_radius: float = 8.0
@export var ultimate_damage: float = 50.0
@export var ultimate_cooldown: float = 5.0
#endregion

#region MODELO 3D
## Cena do modelo 3D desta lanterna.
## null = sem troca de modelo (variantes ainda sem modelo definitivo)
## Quando definida: o equip() instancia esta cena dentro do nó LanternModel
@export var model_scene: PackedScene = null
#endregion
