# ==============================================================================
# BED
# ------------------------------------------------------------------------------
# Interagir com a cama passa para a próxima noite.
# Só funciona se o objetivo de madeira da noite foi atingido.
# ==============================================================================

extends Interactable

func interact():
	# Verifica se a noite foi completada
	if not GameManager.night_completed:
		print("Ainda falta madeira!")
		return

	# Pega referência do player
	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	# Chama o GameManager para avançar a noite
	# (função renomeada de start_next_night para advance_to_next_night)
	GameManager.advance_to_next_night(player)

	print("Próxima noite iniciada!")
