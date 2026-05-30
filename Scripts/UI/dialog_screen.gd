# DIALOG SCREEN
# Sistema genérico de diálogo reutilizável para qualquer NPC.
# Layout definido no editor — código cuida apenas da lógica.

extends CanvasLayer


#region NÓS

@onready var background: ColorRect            = $Background
@onready var speaker_name: Label              = $MarginContainer/VBoxContainer/SpeakerName
@onready var line_text: RichTextLabel         = $MarginContainer/VBoxContainer/LineText
@onready var advance_hint: Label              = $MarginContainer/VBoxContainer/AdvanceHint
@onready var buttons_container: HBoxContainer = $ButtonsContainer

#endregion


#region CONFIGURAÇÃO

@export var char_delay: float = 0.03

#endregion


#region ESTADO

var _data: DialogData        = null
var _npc_node: Node3D        = null
var _current_line: int       = 0
var _is_typing: bool         = false
var _skip_typing: bool       = false
var _waiting_for_input: bool = false
var _player: Node            = null
var _arm_and_lantern: Node3D = null

#endregion


#region READY

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible      = false
	SignalBus.dialog_requested.connect(_on_dialog_requested)
	SignalBus.shop_closed.connect(_on_shop_closed)

#endregion


#region ABRIR DIÁLOGO

func _on_dialog_requested(data: DialogData, npc_node: Node3D) -> void:
	_data         = data
	_npc_node     = npc_node
	_current_line = 0
	_player       = get_tree().get_first_node_in_group("player")

	if _player:
		_arm_and_lantern = _player.get_node_or_null("Visual/ArmAndLantern")
		if _arm_and_lantern:
			for child in _arm_and_lantern.get_children():
				if not child is OmniLight3D:
					child.visible = false
		_tween_camera_to_npc()

	SignalBus.player_entered_safe_zone.emit()

	speaker_name.text    = tr(data.speaker_name_key)
	advance_hint.visible = false
	_clear_buttons()

	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	SignalBus.ui_exclusive_opened.emit()

	_show_line(_current_line)

#endregion


#region CÂMERA

func _tween_camera_to_npc() -> void:
	if _player == null or _npc_node == null:
		return
	var dir: Vector3    = (_npc_node.global_position - _player.global_position).normalized()
	var target_y: float = atan2(-dir.x, -dir.z)
	var tween           := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_player, "rotation:y", target_y, 0.4)

#endregion


#region TYPEWRITER

func _show_line(index: int) -> void:
	if _data == null or index >= _data.lines.size():
		return

	_clear_buttons()
	line_text.text       = ""
	_is_typing           = true
	_skip_typing         = false
	_waiting_for_input   = false
	advance_hint.visible = false

	var full_text: String = tr(_data.lines[index])

	for i in full_text.length():
		if _skip_typing:
			break
		line_text.text += full_text[i]
		await get_tree().create_timer(char_delay).timeout

	line_text.text = full_text
	_is_typing     = false
	_skip_typing   = false

	if index == _data.lines.size() - 1:
		_show_buttons()
	else:
		_waiting_for_input   = true
		advance_hint.visible = true

#endregion


#region INPUT

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	var is_advance: bool = (
		event.is_action_pressed("interact") or
		(event is InputEventMouseButton and event.pressed
			and event.button_index == MOUSE_BUTTON_LEFT)
	)

	if not is_advance:
		return

	get_viewport().set_input_as_handled()

	if _is_typing:
		_skip_typing = true
		return

	if _waiting_for_input:
		_waiting_for_input   = false
		advance_hint.visible = false
		_current_line       += 1
		_show_line(_current_line)

#endregion


#region BOTÕES

func _show_buttons() -> void:
	_clear_buttons()
	advance_hint.visible = false

	for i in _data.choice_labels.size():
		var btn := Button.new()
		btn.text                 = tr(_data.choice_labels[i])
		btn.custom_minimum_size  = Vector2(0.0, 30.0)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var normal := StyleBoxFlat.new()
		normal.bg_color     = Color(0.08, 0.07, 0.04, 0.9)
		normal.border_color = Color(1.0, 0.78, 0.2, 0.5)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", normal)

		var hover := StyleBoxFlat.new()
		hover.bg_color     = Color(0.18, 0.14, 0.06, 0.95)
		hover.border_color = Color(1.0, 0.78, 0.2, 1.0)
		hover.set_border_width_all(1)
		hover.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("hover", hover)

		btn.add_theme_color_override("font_color",       Color(1.0, 0.78, 0.2))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6))
		btn.add_theme_font_size_override("font_size", 14)

		btn.pressed.connect(_on_choice_pressed.bind(_data.choice_ids[i]))
		buttons_container.add_child(btn)


func _clear_buttons() -> void:
	for child in buttons_container.get_children():
		child.queue_free()


func _on_choice_pressed(id: String) -> void:
	SignalBus.dialog_choice_made.emit(id)
	if id == "buy":
		visible = false
		return
	_close()

#endregion


#region FECHAR

func _close() -> void:
	visible   = false
	_data     = null
	_npc_node = null
	_clear_buttons()
	advance_hint.visible = false

	if _player and _arm_and_lantern:
		for child in _arm_and_lantern.get_children():
			child.visible = true
		_arm_and_lantern = null

	_player = null

	SignalBus.player_exited_safe_zone.emit()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SignalBus.ui_exclusive_closed.emit()
	SignalBus.dialog_closed.emit()


func _on_shop_closed() -> void:
	if _data == null:
		return
	visible = true
	_show_buttons()

#endregion
