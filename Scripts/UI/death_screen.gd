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

func _ready() -> void:
	visible = false
	fade_rect.modulate.a = 0.0
	content.visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Ouve SignalBus — completamente desacoplado do player
	SignalBus.player_died.connect(show_death_screen)

#endregion


# ==============================================================================
#region MOSTRAR TELA DE MORTE
# ------------------------------------------------------------------------------
# Chamado pelo player ao morrer.
# ==============================================================================

func show_death_screen() -> void:
	visible = true
	# Esconde o cursor do jogo (crosshair) ao mostrar a tela de morte
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	death_label.text = death_messages.pick_random()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var ring := player.get_node_or_null("UI/CenterContainer/InteractionRing")
		var dot := player.get_node_or_null("UI/CenterContainer/CrosshairDot")
		if ring: ring.visible = false
		if dot: dot.visible = false
	await fade_in()
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
