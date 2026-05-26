# ==============================================================================
# WOOD PICKUP
# ------------------------------------------------------------------------------
# NÃO usa queue_free(). Fica invisível ao ser coletado.
# Resetado pelo NightTransition via grupo "resource_pickup".
# ==============================================================================

extends Interactable

@export var wood_amount: int = 1


func interact() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	if not player.can_collect_wood(wood_amount):
		DebugManager.log("WoodPickup", "Bolsa cheia!")
		return

	player.add_wood(wood_amount)

	visible = false
	var body := get_node_or_null("StaticBody3D")
	if body:
		body.process_mode = Node.PROCESS_MODE_DISABLED

	DebugManager.log("WoodPickup", "Coletada. Total: " +
		str(player.inventory.get_wood_count()) + "/" +
		str(player.inventory.max_capacity))
