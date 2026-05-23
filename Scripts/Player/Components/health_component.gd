# ==============================================================================
# HEALTH COMPONENT
# ------------------------------------------------------------------------------
# Responsabilidade única: gerenciar o estado de vida do player.
#
# - Vida atual e máxima
# - I-frames após tomar dano
# - Morte
# - Cura
#
# O PlayerController não armazena vida — toda verdade está aqui.
# Sistemas externos (HUD, DeathScreen) ouvem os signals.
# ==============================================================================

class_name HealthComponent
extends Node


# ==============================================================================
#region SIGNALS
# ------------------------------------------------------------------------------
# HUD ouve health_changed para atualizar a barra.
# DeathScreen ouve player_died para exibir a tela.
# Sistemas de feedback ouvem player_damaged para efeitos visuais/sonoros.
# ==============================================================================

## Emitido sempre que a vida muda (dano ou cura).
## Ouvido por: HUD
signal health_changed(new_value: float, max_value: float)

## Emitido quando o player recebe dano (não quando cura).
## Ouvido por: sistemas de feedback visual/sonoro futuros
signal player_damaged(amount: float)

## Emitido quando a vida chega a zero.
## Ouvido por: DeathScreen, SignalBus
signal player_died

#endregion


# ==============================================================================
#region CONFIGURAÇÃO
# ==============================================================================

## Vida máxima do player.
## TODO (Refatoração 4): mover para PlayerData.tres
@export var max_health: float = 100.0

## Duração da invencibilidade após tomar dano (em segundos).
@export var invincibility_duration: float = 1.0

#endregion


# ==============================================================================
#region ESTADO INTERNO
# ------------------------------------------------------------------------------
# Toda a verdade de vida está aqui. Nenhum outro script armazena esses valores.
# ==============================================================================

var _god_mode: bool = false
var _current_health: float = 0.0
var _is_dead: bool = false
var _is_invincible: bool = false
var _invincibility_timer: float = 0.0

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	_current_health = max_health

#endregion


# ==============================================================================
#region PROCESS
# ==============================================================================

func _process(delta: float) -> void:
	_tick_invincibility(delta)

#endregion


# ==============================================================================
#region API PÚBLICA
# ==============================================================================

## Aplica dano ao player.
## Ignorado se morto ou invencível.
func take_damage(amount: float) -> void:
	if _is_dead or _is_invincible or _god_mode:
		return

	_current_health -= amount
	_current_health = maxf(_current_health, 0.0)

	# Ativa i-frames
	_is_invincible = true
	_invincibility_timer = invincibility_duration

	# Notifica sistemas externos
	player_damaged.emit(amount)
	health_changed.emit(_current_health, max_health)

	DebugManager.log("HealthComponent",
		"Dano recebido: " + str(amount) +
		" | Vida restante: " + str(_current_health)
	)

	if _current_health <= 0.0:
		_die()


## Cura o player pelo valor informado.
## Ignorado se morto. Limitado ao máximo.
func heal(amount: float) -> void:
	if _is_dead:
		return

	_current_health = minf(_current_health + amount, max_health)

	health_changed.emit(_current_health, max_health)

	DebugManager.log("HealthComponent",
		"Curado: " + str(amount) +
		" | Vida atual: " + str(_current_health)
	)


## Mata o player imediatamente, ignorando i-frames e vida atual.
## Útil para o DevConsole (kill_player) e armadilhas instakill futuras.
func kill() -> void:
	if _is_dead:
		return
	_current_health = 0.0
	_die()


## Retorna true se o player está morto.
func is_dead() -> bool:
	return _is_dead


## Retorna a vida atual como porcentagem (0.0 a 1.0).
## Usado pela HUD para atualizar a barra proporcionalmente.
func get_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return _current_health / max_health


func toggle_invincibility() -> bool:
	_god_mode = !_god_mode
	return _god_mode


## Aumenta vida máxima e cura o mesmo valor — usado por power-ups
func increase_max(amount: float) -> void:
	max_health += amount
	_current_health = minf(_current_health + amount, max_health)
	health_changed.emit(_current_health, max_health)
	DebugManager.log("HealthComponent", "Vida máxima: " + str(max_health))


#endregion


# ==============================================================================
#region INTERNO — MORTE
# ==============================================================================

func _die() -> void:
	_is_dead = true
	_is_invincible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SignalBus.player_died.emit()
	player_died.emit()
	DebugManager.log("HealthComponent", "Player morreu.")

#endregion


# ==============================================================================
#region INTERNO — I-FRAMES
# ==============================================================================

func _tick_invincibility(delta: float) -> void:
	if not _is_invincible:
		return

	_invincibility_timer -= delta

	if _invincibility_timer <= 0.0:
		_is_invincible = false

#endregion
