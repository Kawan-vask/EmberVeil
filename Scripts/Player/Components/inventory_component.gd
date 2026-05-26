# ==============================================================================
# INVENTORY COMPONENT
# ------------------------------------------------------------------------------
# Gerencia o inventário de madeira do player.
# Limite baseado em max_capacity (bolsa), não no objetivo da noite.
# ==============================================================================

class_name InventoryComponent
extends Node


#region SIGNALS
## Emitido sempre que madeira ou capacidade mudam.
## Ouvido por: HUD
signal wood_changed(current: int, max_cap: int, goal: int)
#endregion


#region CONFIGURAÇÃO
## Capacidade base da bolsa — 5 slots
@export var max_capacity: int = 5
#endregion


#region ESTADO INTERNO
var _wood_count: int = 0
#endregion


#region API PÚBLICA

func add_wood(amount: int) -> void:
	_wood_count = mini(_wood_count + amount, max_capacity)
	_emit()
	DebugManager.log("InventoryComponent",
		"Madeira: " + str(_wood_count) + "/" + str(max_capacity))


func remove_wood(amount: int) -> void:
	_wood_count = maxi(_wood_count - amount, 0)
	_emit()


func can_collect_wood(amount: int) -> bool:
	return _wood_count + amount <= max_capacity


func get_wood_count() -> int:
	return _wood_count


func reset() -> void:
	_wood_count = 0
	_emit()
	DebugManager.log("InventoryComponent", "Inventário resetado.")


## Aumenta capacidade máxima da bolsa — chamado por upgrades
func increase_capacity(amount: int) -> void:
	max_capacity += amount
	_emit()
	DebugManager.log("InventoryComponent",
		"Capacidade: " + str(max_capacity))


func _emit() -> void:
	wood_changed.emit(_wood_count, max_capacity, GameManager.wood_goal)

#endregion
