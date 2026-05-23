# ==============================================================================
# BED
# ------------------------------------------------------------------------------
# Interagir com a cama passa para a próxima noite.
# Só funciona se o objetivo de madeira foi atingido.
# Madeira excedente é convertida em moedas ao dormir.
# ==============================================================================

extends Interactable

func interact() -> void:
	if not GameManager.night_completed:
		DebugManager.log("Bed", "Ainda falta madeira!")
		return

	# Bloqueia se player ainda não escolheu o power-up
	var screen: Node = get_tree().get_first_node_in_group("powerup_screen")
	if screen and screen.visible:
		DebugManager.log("Bed", "Escolha um poder antes de dormir.")
		return

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var excess: int = player.inventory.get_wood_count()
	if excess > 0:
		GameManager.add_coins(excess)
		DebugManager.log("Bed", "Madeira excedente: " + str(excess) + " moedas")

	GameManager.advance_to_next_night(player)
