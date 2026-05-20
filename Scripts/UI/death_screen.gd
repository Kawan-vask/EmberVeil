# ==============================================================================
# DEATH SCREEN
# ------------------------------------------------------------------------------
# Tela de morte do Emberveil.
# Fluxo: fade in escuro → texto → botão de retry
#
# Futuramente: estatísticas da run (noite atingida, inimigos mortos, etc)
# ==============================================================================

class_name DeathScreen
extends CanvasLayer


# ==============================================================================
#region REFERÊNCIAS
# ==============================================================================

# Fundo preto que faz o fade
@onready var fade_rect: ColorRect = $FadeRect

# Container do conteúdo — aparece após o fade
@onready var content: VBoxContainer = $Content

# Label da mensagem de morte
@onready var death_label: Label = $Content/DeathLabel

# Botão de retry
@onready var retry_button: Button = $Content/RetryButton

#endregion


# ==============================================================================
#region CONFIGURAÇÃO
# ==============================================================================

# Duração do fade in (segundos)
@export var fade_duration := 1.5

# Mensagens de morte — escolhe aleatória a cada vez
# Futuramente pode variar por causa da morte
var death_messages := [
	"A floresta venceu...",
	"A escuridão te consumiu...",
	"A lamparina se apagou...",
	"As criaturas venceram esta noite...",
]

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready():
	# Começa invisível
	visible = false
	fade_rect.modulate.a = 0.0
	content.visible = false

	# Sempre processa mesmo com jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

#endregion


# ==============================================================================
#region MOSTRAR TELA DE MORTE
# ------------------------------------------------------------------------------
# Chamado pelo player ao morrer.
# ==============================================================================

func show_death_screen():
	visible = true

	# Escolhe mensagem aleatória
	death_label.text = death_messages.pick_random()

	# Inicia o fade
	await fade_in()

	# Mostra o conteúdo após o fade
	content.visible = true


func fade_in():
	# Anima o alpha do fundo preto de 0 a 1
	var tween = create_tween()
	tween.tween_property(
		fade_rect,
		"modulate:a",
		1.0,
		fade_duration
	)
	await tween.finished

#endregion


# ==============================================================================
#region BOTÕES
# ==============================================================================

func _on_retry_button_pressed():
	# Despausa caso esteja pausado
	get_tree().paused = false

	# Recarrega a cena — reset roguelike completo
	get_tree().reload_current_scene()

#endregion
