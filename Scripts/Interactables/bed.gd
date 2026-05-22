# ==============================================================================
# BED
# ------------------------------------------------------------------------------
# Interagir com a cama passa para a próxima noite.
# Só funciona se o objetivo de madeira da noite foi atingido.
# ==============================================================================

extends Interactable

func interact() -> void:
	if not GameManager.night_completed:
		DebugManager.log("Bed", "Ainda falta madeira!")
		return

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	GameManager.advance_to_next_night(player)
	DebugManager.log("Bed", "Próxima noite iniciada!")
