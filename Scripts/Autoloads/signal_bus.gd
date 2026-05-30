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


# ==============================================================================
#region NOITE
# ==============================================================================

## Emitido quando a transição de noite começa (fade out)
## Ouvido por: NightTransition, sistemas de reset
@warning_ignore("unused_signal")
signal night_transition_started

## Emitido quando a transição termina (fade in completo)
## Ouvido por: NightTransition, player
@warning_ignore("unused_signal")
signal night_transition_finished

## Emitido durante o blackout da transição — PowerUpScreen ouve para abrir durante a tela preta
@warning_ignore("unused_signal")
signal night_powerup_available

#endregion

# ==============================================================================
#region VENDEDOR
# ==============================================================================

## Emitido pelo GameManager quando o vendedor chega entre noites
@warning_ignore("unused_signal")
signal vendor_available

## Emitido quando o player fecha a loja
@warning_ignore("unused_signal")
signal vendor_dismissed

#endregion


#region DIÁLOGO

## Emitido pelo Vendor ao ser interagido — DialogScreen ouve e exibe o diálogo
## Ouvido por: DialogScreen
@warning_ignore("unused_signal")
signal dialog_requested(data: DialogData, npc_node: Node3D)

## Emitido pela DialogScreen quando o player escolhe uma opção
## Ouvido por: Vendor
@warning_ignore("unused_signal")
signal dialog_choice_made(id: String)

## Emitido pela DialogScreen ao fechar
## Ouvido por: sistemas que precisam saber que o diálogo terminou
@warning_ignore("unused_signal")
signal dialog_closed

## Emitido pela DialogScreen quando player escolhe "Comprar"
## ShopScreen ouve e recebe os itens do vendedor
@warning_ignore("unused_signal")
signal shop_requested(data: VendorData)

## Emitido pela ShopScreen ao fechar — DialogScreen reaparece
@warning_ignore("unused_signal")
signal shop_closed

#endregion


# ==============================================================================
#region POWER-UPS
# ==============================================================================

## Emitido pelo PowerUpManager quando um power-up é aplicado
@warning_ignore("unused_signal")
signal powerup_selected(data: PowerUpData)

## Emitido quando uma tela de UI exclusiva abre/fecha
## Sistemas que capturam input ouvem este signal para se desabilitar
@warning_ignore("unused_signal")
signal ui_exclusive_opened

@warning_ignore("unused_signal")
signal ui_exclusive_closed

#endregion
