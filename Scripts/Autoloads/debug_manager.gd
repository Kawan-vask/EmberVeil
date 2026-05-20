# ==============================================================================
# DEBUG MANAGER
# ------------------------------------------------------------------------------
# Centraliza todo código de debug do projeto.
# Em produção, basta setar DEBUG_ENABLED = false — zero custo de performance.
#
# REGRA: nenhum script usa print() ou label.text = diretamente.
# Tudo passa por aqui.
# ==============================================================================

extends Node


# ==============================================================================
#region CONFIGURAÇÃO
# ==============================================================================

## Mude para false antes de fazer o build de produção.
const DEBUG_ENABLED := true

#endregion


# ==============================================================================
#region API PÚBLICA
# ==============================================================================

## Substitui print() direto — desligado automaticamente em produção.
func log(system: String, message: String) -> void:
	if not DEBUG_ENABLED:
		return
	print("[", system, "] ", message)


## Substitui label.text = direto — desligado automaticamente em produção.
func label(label_node: Label, text: String) -> void:
	if not DEBUG_ENABLED:
		return
	if is_instance_valid(label_node):
		label_node.text = text

#endregion
