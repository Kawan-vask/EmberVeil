# ==============================================================================
# GAME MANAGER
# ------------------------------------------------------------------------------
# Controlador central do jogo. É a ÚNICA fonte da verdade para:
# - Número da noite atual
# - Progresso de madeira
# - Estado geral do loop (noite ativa, completada, etc)
#
# Quando a noite avança, emite signals para que TODOS os sistemas se atualizem.
# O GameManager não conhece nenhum objeto de cena específico — apenas emite.
# ==============================================================================

extends Node


# ==============================================================================
#region SIGNALS
# ==============================================================================

## Emitido quando a noite avança — todos os sistemas que dependem da noite ouvem
signal night_changed(new_night: int)

## Emitido quando o player sai da cabana e a noite começa de fato
signal night_started

## Emitido quando o objetivo de madeira da noite é atingido
signal night_objective_reached

#endregion


# ==============================================================================
#region NOITE
# ==============================================================================

## Noite atual — ÚNICA fonte da verdade de todo o jogo.
## Nunca modifique diretamente de fora — use as funções abaixo.
var current_night: int = 1

#endregion


# ==============================================================================
#region MADEIRA
# ==============================================================================

## Quantidade de madeira necessária para completar a noite atual
var wood_goal: int = 0

## Madeira já entregue na lareira nesta noite
var delivered_wood: int = 0

#endregion


# ==============================================================================
#region ESTADO DA NOITE
# ==============================================================================

## True quando o player entregou madeira suficiente para dormir
var night_completed: bool = false

## True enquanto a noite está em andamento
var night_active: bool = false

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	_apply_night_settings()

#endregion


# ==============================================================================
#region CONFIGURAÇÃO DE NOITE
# ------------------------------------------------------------------------------
# Centraliza todos os valores que mudam a cada noite.
# TODO (Refatoração 4): mover fórmulas para NightConfig.tres (Resource).
# ==============================================================================

func _apply_night_settings() -> void:
	# Noite 1: 5 | Noite 2: 7 | Noite 3: 9...
	wood_goal = 3 + (current_night * 2)

	delivered_wood = 0
	night_completed = false

	DebugManager.log("GameManager",
		"Noite " + str(current_night) +
		" | Objetivo de madeira: " + str(wood_goal)
	)


## Retorna um valor escalado pela noite.
## Exemplo: get_scaled_value(10.0, 0.2) na noite 3 = 14.0
func get_scaled_value(base_value: float, scale_per_night: float) -> float:
	return base_value + ((current_night - 1) * scale_per_night * base_value)

#endregion


# ==============================================================================
#region CONTROLE DE NOITE
# ==============================================================================

## Chamado quando o player sai da cabana e a noite começa de fato
func start_night() -> void:
	night_active = true
	night_started.emit()
	DebugManager.log("GameManager", "Noite " + str(current_night) + " iniciada!")


## Chamado pela cama quando o player vai dormir.
## Recebe referência do player para resetar inventário.
## TODO (Refatoração 3): substituir player.wood_count = 0 por player.inventory.reset()
func advance_to_next_night(player: Node) -> void:
	if not night_completed:
		DebugManager.log("GameManager", "Ainda falta madeira!")
		return

	current_night += 1

	# TODO (Refatoração 3): player.inventory.reset()
	player.wood_count = 0

	night_active = false
	_apply_night_settings()

	# Avisa todos os sistemas que a noite mudou.
	# Fireplace, EnemyDirector, HUD — todos ouvem este signal.
	# O GameManager não chama ninguém diretamente.
	night_changed.emit(current_night)

	DebugManager.log("GameManager", "Avançou para noite " + str(current_night))

#endregion


# ==============================================================================
#region SISTEMA DE MADEIRA
# ==============================================================================

func add_delivered_wood(amount: int) -> void:
	delivered_wood += amount
	delivered_wood = clamp(delivered_wood, 0, wood_goal)
	_check_night_completion()


func _check_night_completion() -> void:
	if delivered_wood >= wood_goal:
		night_completed = true
		night_objective_reached.emit()
		DebugManager.log("GameManager", "NOITE COMPLETADA!")

#endregion
