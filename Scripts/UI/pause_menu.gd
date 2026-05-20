# ==============================================================================
# PAUSE MENU
# ------------------------------------------------------------------------------
# Menu de pausa básico para desenvolvimento.
# ESC → pausa o jogo e libera o mouse
# ESC novamente → retoma e trava o mouse
#
# Futuramente receberá: botão de configurações, voltar ao menu, etc.
# ==============================================================================

class_name PauseMenu
extends CanvasLayer


# ==============================================================================
#region REFERÊNCIAS
# ==============================================================================

# Painel de fundo do pause — esconde/mostra o menu
@onready var panel = $Panel

#endregion


# ==============================================================================
#region ESTADO
# ==============================================================================

# True quando o jogo está pausado
var is_paused := false

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready():
	# Começa escondido e sem pausar
	panel.visible = false

	# CanvasLayer sempre visível mesmo com o jogo pausado
	# Isso é necessário para o menu aparecer durante a pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

#endregion


# ==============================================================================
#region INPUT
# ==============================================================================

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if Input.is_action_just_pressed("ui_cancel"):
			toggle_pause()

#endregion


# ==============================================================================
#region PAUSE
# ==============================================================================

func toggle_pause():
	is_paused = !is_paused

	# Pausa ou retoma o jogo inteiro
	get_tree().paused = is_paused

	# Mostra ou esconde o painel
	panel.visible = is_paused

	# Libera ou trava o mouse
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

#endregion


# ==============================================================================
#region BOTÕES
# ==============================================================================

# Botão "Retomar" — fecha o pause
func _on_resume_button_pressed():
	toggle_pause()


# Botão "Sair" — fecha o jogo
# Útil durante desenvolvimento para sair sem Alt+F4
func _on_quit_button_pressed():
	get_tree().quit()

#endregion
