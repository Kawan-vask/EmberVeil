# ==============================================================================
# SAP PICKUP — SEIVA
# ------------------------------------------------------------------------------
# Reabastece energia da lamparina ao ser coletada.
# Pertence ao grupo "resource_pickup" para reset entre noites (Fase 2).
# ==============================================================================

extends Interactable

## Quantidade de energia restaurada
@export var energy_amount: float = 30.0

func interact() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var lantern: Lantern = get_tree().get_first_node_in_group("lantern")
	if lantern == null:
		return

	lantern.add_energy(energy_amount)
	DebugManager.log("SapPickup", "Seiva coletada. Energia: " + str(lantern.current_energy))

	# Esconde — será resetado ao avançar de noite
	visible = false
	# Desativa colisão
	var body := get_node_or_null("StaticBody3D")
	if body:
		body.process_mode = Node.PROCESS_MODE_DISABLED
