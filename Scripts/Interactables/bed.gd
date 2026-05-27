# ==============================================================================
# BED
# ------------------------------------------------------------------------------
# Interagir avança para a próxima noite.
# Condições:
# 1. Objetivo de madeira atingido
# 2. PowerUpScreen não está visível
# Converte depósito em moedas antes de avançar.
# Madeira não depositada permanece no inventário.
# ==============================================================================

extends Interactable

func interact() -> void:
	if not GameManager.night_completed:
		DebugManager.log("Bed", "Ainda falta madeira!")
		return

	var screen: Node = get_tree().get_first_node_in_group("powerup_screen")
	if screen and screen.visible:
		DebugManager.log("Bed", "Escolha um poder antes de dormir.")
		return

	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	# Converte depósito em moedas antes de avançar
	var depot: Node = get_tree().get_first_node_in_group("wood_depot")
	if depot:
		depot.convert_to_coins()
	
	GameManager.advance_to_next_night(player)
