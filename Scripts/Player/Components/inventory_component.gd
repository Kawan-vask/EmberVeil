# ==============================================================================
# INVENTORY COMPONENT
# ------------------------------------------------------------------------------
# Responsabilidade única: gerenciar o inventário de madeira do player.
#
# O PlayerController não armazena wood_count — toda verdade está aqui.
# ==============================================================================

class_name InventoryComponent
extends Node


# ==============================================================================
#region SIGNALS
# ==============================================================================

## Emitido sempre que a quantidade de madeira muda.
## Ouvido por: HUD
signal wood_changed(current: int, goal: int)

#endregion


# ==============================================================================
#region ESTADO INTERNO
# ==============================================================================

var _wood_count: int = 0

#endregion


# ==============================================================================
#region API PÚBLICA
# ==============================================================================

## Adiciona madeira ao inventário.
func add_wood(amount: int) -> void:
	_wood_count += amount
	wood_changed.emit(_wood_count, GameManager.wood_goal)
	DebugManager.log("InventoryComponent", "Madeira: " + str(_wood_count))


## Remove madeira do inventário.
func remove_wood(amount: int) -> void:
	_wood_count -= amount
	_wood_count = maxi(_wood_count, 0)
	wood_changed.emit(_wood_count, GameManager.wood_goal)


## Retorna true se ainda é possível coletar mais madeira.
func can_collect_wood(amount: int) -> bool:
	var total: int = _wood_count + GameManager.delivered_wood
	return total + amount <= GameManager.wood_goal


## Retorna a quantidade atual de madeira.
func get_wood_count() -> int:
	return _wood_count


## Reseta o inventário — chamado pelo GameManager ao avançar de noite.
func reset() -> void:
	_wood_count = 0
	wood_changed.emit(_wood_count, GameManager.wood_goal)
	DebugManager.log("InventoryComponent", "Inventário resetado.")

#endregion
