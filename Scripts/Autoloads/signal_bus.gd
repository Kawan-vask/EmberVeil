# ==============================================================================
# SIGNAL BUS
# ------------------------------------------------------------------------------
# Barramento global de eventos entre sistemas desacoplados.
#
# REGRA DE USO:
# - Sistema que dispara um evento  → SignalBus.nome_do_signal.emit()
# - Sistema que reage ao evento    → SignalBus.nome_do_signal.connect(método)
#                                    (sempre no _ready() do sistema)
#
# NUNCA adicione lógica aqui — apenas declarações de signal.
# ==============================================================================

extends Node


# ==============================================================================
#region PLAYER — ZONA SEGURA
# ==============================================================================

## Emitido pela SafeZone quando o player entra na área segura.
## Ouvido por: EnemyDirector, EnemyBase
@warning_ignore("unused_signal")
signal player_entered_safe_zone

## Emitido pela SafeZone quando o player sai da área segura.
## Ouvido por: EnemyDirector
@warning_ignore("unused_signal")
signal player_exited_safe_zone

#endregion


# ==============================================================================
#region PLAYER — ESTADO
# ==============================================================================

## Emitido pelo player quando morre.
## Ouvido por: DeathScreen, sistemas futuros
@warning_ignore("unused_signal")
signal player_died

#endregion


# ==============================================================================
#region RECURSOS — MADEIRA
# ==============================================================================

## Emitido pela Fireplace quando madeira é entregue com sucesso.
## Ouvido por: HUD, sistemas futuros de progressão
@warning_ignore("unused_signal")
signal wood_delivered(amount: int)

#endregion
