# ==============================================================================
# INVENTORY UPGRADE
# ------------------------------------------------------------------------------
# Item raro encontrado na floresta.
# Aumenta permanentemente a capacidade da bolsa do player na run atual.
# ==============================================================================

class_name InventoryUpgrade
extends Interactable

@export var capacity_bonus: int = 1
@export var display_name: String = "Pochete de Couro"

func interact() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	player.inventory.increase_capacity(capacity_bonus)

	visible = false
	var body := get_node_or_null("StaticBody3D")
	if body:
		body.process_mode = Node.PROCESS_MODE_DISABLED

	DebugManager.log("InventoryUpgrade",
		display_name + " coletada. Capacidade: " +
		str(player.inventory.max_capacity))
