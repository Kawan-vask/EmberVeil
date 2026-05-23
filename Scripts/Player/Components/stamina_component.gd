# ==============================================================================
# STAMINA COMPONENT
# ------------------------------------------------------------------------------
# Responsabilidade única: gerenciar o estado de stamina do player.
#
# - Stamina atual e máxima
# - Consumo ao correr
# - Recuperação com delay
#
# O PlayerController não armazena stamina — toda verdade está aqui.
# ==============================================================================

class_name StaminaComponent
extends Node


# ==============================================================================
#region SIGNALS
# ==============================================================================

## Emitido sempre que a stamina muda.
## Ouvido por: HUD
signal stamina_changed(new_value: float, max_value: float)

#endregion


# ==============================================================================
#region CONFIGURAÇÃO
# ==============================================================================

@export var max_stamina: float            = 100.0
@export var drain_rate: float             = 25.0
@export var recovery_rate: float          = 20.0
@export var recovery_delay: float         = 1.5

#endregion


# ==============================================================================
#region ESTADO INTERNO
# ==============================================================================

var _current_stamina: float       = 0.0
var _recovery_timer: float        = 0.0

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	_current_stamina = max_stamina

#endregion


# ==============================================================================
#region API PÚBLICA
# ==============================================================================

## Consome stamina por delta — chamado pelo PlayerController ao correr.
func consume(amount: float) -> void:
	_current_stamina -= amount
	_current_stamina = maxf(_current_stamina, 0.0)
	_recovery_timer = recovery_delay
	stamina_changed.emit(_current_stamina, max_stamina)


## Recupera stamina por delta — chamado pelo PlayerController quando não corre.
func restore(amount: float) -> void:
	var before := _current_stamina
	_current_stamina = minf(_current_stamina + amount, max_stamina)
	if _current_stamina != before:
		stamina_changed.emit(_current_stamina, max_stamina)


## Tick do delay de recuperação — chamado pelo PlayerController no _physics_process.
func tick_recovery_timer(delta: float) -> void:
	if _recovery_timer > 0.0:
		_recovery_timer -= delta


## Retorna true se pode correr (tem stamina e delay zerado).
func can_sprint() -> bool:
	return _current_stamina > 0.0


## Retorna true se o delay de recuperação ainda está ativo.
func is_in_recovery_delay() -> bool:
	return _recovery_timer > 0.0


## Retorna stamina como porcentagem (0.0 a 1.0).
func get_percent() -> float:
	if max_stamina <= 0.0:
		return 0.0
	return _current_stamina / max_stamina


## Aumenta stamina máxima — usado por power-ups
func increase_max(amount: float) -> void:
	max_stamina += amount
	stamina_changed.emit(_current_stamina, max_stamina)
	DebugManager.log("StaminaComponent", "Stamina máxima: " + str(max_stamina))


#endregion
