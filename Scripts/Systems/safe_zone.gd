# ==============================================================================
# SAFE ZONE
# ------------------------------------------------------------------------------
# Detecta quando o player entra ou sai da zona segura.
#
# RESPONSABILIDADE ÚNICA: detectar o player e emitir o evento.
# Não conhece EnemyDirector, não conhece nenhum outro sistema.
# Qualquer sistema que precise reagir à safe zone conecta ao SignalBus.
# ==============================================================================

class_name SafeZone
extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		SignalBus.player_entered_safe_zone.emit()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		SignalBus.player_exited_safe_zone.emit()
