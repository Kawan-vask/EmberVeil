# ==============================================================================
# POWERUP SCREEN
# ------------------------------------------------------------------------------
# Exibe 3 power-ups aleatórios para o player escolher ao completar a noite.
# Layout configurado via código — independente de versão do Godot.
# ==============================================================================

extends CanvasLayer


# ==============================================================================
#region NÓS
# ==============================================================================

@onready var background: ColorRect          = $Background
@onready var title: Label                   = $Background/Title
@onready var cards_container: HBoxContainer = $Background/CardsContainer
@onready var cards: Array[Button] = [
	$Background/CardsContainer/Card1,
	$Background/CardsContainer/Card2,
	$Background/CardsContainer/Card3,
]

#endregion


# ==============================================================================
#region ESTADO
# ==============================================================================

var _choices: Array[PowerUpData]     = []
var _powerup_manager: PowerUpManager = null

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false
	_setup_layout()
	GameManager.night_changed.connect(_on_night_changed)

#endregion


# ==============================================================================
#region LAYOUT
# ==============================================================================

func _setup_layout() -> void:
	var screen := get_viewport().get_visible_rect().size

	# BACKGROUND — cobre a tela toda
	background.color = Color(0.0, 0.0, 0.0, 0.85)
	background.set_anchor_and_offset(SIDE_LEFT,   0.0, 0.0)
	background.set_anchor_and_offset(SIDE_RIGHT,  1.0, 0.0)
	background.set_anchor_and_offset(SIDE_TOP,    0.0, 0.0)
	background.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0.0)

	# TITLE — centralizado no topo
	title.text                 = "ESCOLHA UM PODER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.set_anchor_and_offset(SIDE_LEFT,   0.0,  0.0)
	title.set_anchor_and_offset(SIDE_RIGHT,  1.0,  0.0)
	title.set_anchor_and_offset(SIDE_TOP,    0.0, 40.0)
	title.set_anchor_and_offset(SIDE_BOTTOM, 0.0, 90.0)

	# CARDS CONTAINER — centralizado na tela
	var card_width:  float = 280.0
	var card_height: float = 320.0
	var spacing:     float = 32.0
	var total_width: float = card_width * 3.0 + spacing * 2.0
	var start_x:     float = (screen.x - total_width) / 2.0
	var start_y:     float = (screen.y - card_height) / 2.0

	cards_container.add_theme_constant_override("separation", int(spacing))
	cards_container.set_anchor_and_offset(SIDE_LEFT,   0.0, start_x)
	cards_container.set_anchor_and_offset(SIDE_RIGHT,  0.0, start_x + total_width)
	cards_container.set_anchor_and_offset(SIDE_TOP,    0.0, start_y)
	cards_container.set_anchor_and_offset(SIDE_BOTTOM, 0.0, start_y + card_height)

	# CARDS
	for card in cards:
		card.custom_minimum_size   = Vector2(card_width, card_height)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Name label
		var name_label: Label = card.get_node("VBoxContainer/Name")
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 22)
		name_label.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		
		name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))  # dourado

		# Description label
		var desc_label: Label = card.get_node("VBoxContainer/Description")
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.mouse_filter         = Control.MOUSE_FILTER_IGNORE

		# VBoxContainer — não captura mouse, deixa o Button receber o clique
		var vbox: Control = card.get_node("VBoxContainer")
		vbox.set_anchor_and_offset(SIDE_LEFT,   0.0,  16.0)
		vbox.set_anchor_and_offset(SIDE_RIGHT,  1.0, -16.0)
		vbox.set_anchor_and_offset(SIDE_TOP,    0.0,  24.0)
		vbox.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -24.0)
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

#endregion


# ==============================================================================
#region ABRIR TELA
# ==============================================================================

func _on_night_changed(_night: int) -> void:
	_powerup_manager = get_tree().get_first_node_in_group("powerup_manager")
	if _powerup_manager == null:
		DebugManager.log("PowerUpScreen", "PowerUpManager não encontrado!"); return

	_choices = _powerup_manager.get_random_choices(3)
	if _choices.is_empty():
		DebugManager.log("PowerUpScreen", "Nenhum power-up disponível!"); return

	for i in _choices.size():
		var card: Button = cards[i]
		card.get_node("VBoxContainer/Name").text        = _choices[i].display_name
		card.get_node("VBoxContainer/Description").text = _choices[i].description

		var vbox_container: VBoxContainer = card.get_node("VBoxContainer")
		vbox_container.add_theme_constant_override("separation", 16)
		vbox_container.alignment = BoxContainer.ALIGNMENT_CENTER

		if card.pressed.is_connected(_on_card_selected.bind(i)):
			card.pressed.disconnect(_on_card_selected.bind(i))
		card.pressed.connect(_on_card_selected.bind(i))

	# FORA do loop — executa só uma vez
	visible           = true
	get_tree().paused = true
	Input.mouse_mode  = Input.MOUSE_MODE_VISIBLE
	SignalBus.ui_exclusive_opened.emit()
	DebugManager.log("PowerUpScreen", "Tela aberta.")

#endregion


# ==============================================================================
#region SELECIONAR POWER-UP
# ==============================================================================

func _on_card_selected(index: int) -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player and _powerup_manager:
		_powerup_manager.apply(_choices[index], player)
	_close()


func _close() -> void:
	visible           = false
	get_tree().paused = false
	Input.mouse_mode  = Input.MOUSE_MODE_CAPTURED
	SignalBus.ui_exclusive_closed.emit()
	DebugManager.log("PowerUpScreen", "Power-up escolhido.")

#endregion
