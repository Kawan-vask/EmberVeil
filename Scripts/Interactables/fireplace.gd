# ==============================================================================
# FIREPLACE
# ------------------------------------------------------------------------------
# Recebe madeira do player e entrega ao GameManager.
# Atualiza o visual automaticamente ouvindo os signals do GameManager.
# Não é mais chamada diretamente por nenhum sistema externo para se atualizar.
# ==============================================================================

extends Interactable

@onready var wood_label: Label = $SubViewport/Label


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	# Conecta aos signals do GameManager para se manter atualizada
	# O GameManager não precisa mais saber que a Fireplace existe
	GameManager.night_changed.connect(_on_night_changed)
	GameManager.night_objective_reached.connect(_on_night_objective_reached)
	update_visual()

#endregion


# ==============================================================================
#region INTERAÇÃO
# ==============================================================================

func interact() -> void:
	var player: Node3D = get_tree().get_first_node_in_group("player")

	if player == null:
		return

	if player.wood_count <= 0:
		return

	var missing_wood: int = GameManager.wood_goal - GameManager.delivered_wood
	var wood_to_deliver: int = min(player.wood_count, missing_wood)

	player.wood_count -= wood_to_deliver
	GameManager.add_delivered_wood(wood_to_deliver)

	# Emite evento global — HUD e outros sistemas podem reagir
	SignalBus.wood_delivered.emit(wood_to_deliver)

	update_visual()

	DebugManager.log("Fireplace",
		"Madeira entregue: " + str(GameManager.delivered_wood) +
		"/" + str(GameManager.wood_goal)
	)

#endregion


# ==============================================================================
#region VISUAL
# ==============================================================================

func update_visual() -> void:
	wood_label.text = (
		str(GameManager.delivered_wood) +
		"/" +
		str(GameManager.wood_goal)
	)

#endregion


# ==============================================================================
#region LISTENERS DO GAME MANAGER
# ==============================================================================

func _on_night_changed(_new_night: int) -> void:
	update_visual()


func _on_night_objective_reached() -> void:
	# Gancho para feedback visual futuro (animação, brilho, som)
	update_visual()

#endregion
