# ==============================================================================
# WOOD DEPOT
# ------------------------------------------------------------------------------
# Local fora da cabana onde o player deposita madeira excedente por moedas.
# A conversão acontece ao dormir via Bed.convert_to_coins().
#
# Narrativa: Elias Voss deixa a madeira num local acordado com o vendedor.
# Acorda com as moedas já no saldo.
# ==============================================================================

class_name WoodDepot
extends Interactable


#region ESTADO
var _deposited_wood: int = 0
#endregion


#region READY
func _ready() -> void:
	SignalBus.night_transition_started.connect(_on_night_started)
#endregion


#region INTERAÇÃO
func interact() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var wood_in_hand: int = player.inventory.get_wood_count()
	if wood_in_hand <= 0:
		DebugManager.log("WoodDepot", "Sem madeira para depositar.")
		return

	_deposited_wood += wood_in_hand
	player.inventory.remove_wood(wood_in_hand)

	DebugManager.log("WoodDepot",
		"Depositado: " + str(wood_in_hand) +
		" | Total no depósito: " + str(_deposited_wood))
#endregion


#region CONVERSÃO AO DORMIR
## Chamado pelo Bed antes de advance_to_next_night()
func convert_to_coins() -> int:
	var earned: int = _deposited_wood
	_deposited_wood = 0
	if earned > 0:
		GameManager.add_coins(earned)
		DebugManager.log("WoodDepot",
			str(earned) + " madeiras → " + str(earned) + " moedas")
	return earned
#endregion


#region RESET
func _on_night_started() -> void:
	_deposited_wood = 0
#endregion
