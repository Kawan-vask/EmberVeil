# ==============================================================================
# APPLE PICKUP — MAÇÃ
# ------------------------------------------------------------------------------
# Recupera vida do player ao ser coletada.
# Pertence ao grupo "resource_pickup" para reset entre noites (Fase 2).
# ==============================================================================

extends Interactable

## Quantidade de vida restaurada
@export var heal_amount: float = 25.0

func interact() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	player.heal(heal_amount)
	DebugManager.log("ApplePickup", "Maçã coletada. Vida: " + str(player.health.get_percent() * player.health.max_health))

	# Esconde — será resetado ao avançar de noite
	visible = false
	var body := get_node_or_null("StaticBody3D")
	if body:
		body.process_mode = Node.PROCESS_MODE_DISABLED
