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
@warning_ignore("unused_signal")
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
@export var night_config: NightConfig
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
	if night_config == null:
		night_config = load("res://Resources/night_config_normal.tres")
	_apply_night_settings()

#endregion


# ==============================================================================
#region CONFIGURAÇÃO DE NOITE
# ------------------------------------------------------------------------------
# Centraliza todos os valores que mudam a cada noite.
# TODO (Refatoração 4): mover fórmulas para NightConfig.tres (Resource).
# ==============================================================================

func _apply_night_settings() -> void:
	if night_config != null:
		wood_goal = night_config.get_wood_goal(current_night)
	else:
		wood_goal = 3 + (current_night * 2) # fallback
	delivered_wood  = 0
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
func advance_to_next_night(player: Node) -> void:
	if not night_completed:
		DebugManager.log("GameManager", "Ainda falta madeira!")
		return

	current_night += 1
	player.inventory.reset()
	night_active  = false
	_apply_night_settings()

	# NightTransition cuida do resto — ouve night_transition_started
	# e emite night_transition_finished quando termina
	SignalBus.night_transition_started.emit()

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

# ==============================================================================
#region MOEDAS
# ==============================================================================

## Saldo atual de moedas — persiste entre noites, reseta ao morrer
var coins: int = 0

## Emitido sempre que o saldo muda — ouvido pela HUD
signal coins_changed(new_amount: int)


func add_coins(amount: int) -> void:
	coins += amount
	coins_changed.emit(coins)
	DebugManager.log("GameManager", "Moedas: " + str(coins))


## Retorna false se saldo insuficiente — nunca vai negativo
func spend_coins(amount: int) -> bool:
	if coins < amount:
		DebugManager.log("GameManager", "Moedas insuficientes.")
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true

#endregion
