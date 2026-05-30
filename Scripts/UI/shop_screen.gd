# SHOP SCREEN
# Tela de compra do vendedor.
# Abre após o player escolher "Comprar" no diálogo.
# Fecha emitindo shop_closed — DialogScreen reaparece com as escolhas.

extends CanvasLayer


#region NÓS

@onready var coins_label: Label             = $Background/CoinsLabel
@onready var items_container: VBoxContainer = $Background/ItemsContainer
@onready var status_label: Label            = $Background/StatusLabel
@onready var close_button: Button           = $Background/CloseButton

#endregion


#region ESTADO

var _purchased: Array[int] = []

#endregion


#region READY

func _ready() -> void:
	process_mode             = Node.PROCESS_MODE_ALWAYS
	visible                  = false
	close_button.text        = tr("SHOP_CLOSE")
	close_button.pressed.connect(_close)
	GameManager.coins_changed.connect(_on_coins_changed)
	SignalBus.shop_requested.connect(_on_shop_requested)

#endregion


#region ABRIR

func _on_shop_requested(data: VendorData) -> void:
	_purchased.clear()
	_build_items(data)
	coins_label.text  = "Moedas: " + str(GameManager.coins)
	status_label.text = ""
	visible           = true
	Input.mouse_mode  = Input.MOUSE_MODE_VISIBLE
	SignalBus.ui_exclusive_opened.emit()

#endregion


#region ITENS

func _build_items(data: VendorData) -> void:
	for child in items_container.get_children():
		child.queue_free()

	for i in data.items.size():
		var item: ShopItemData = data.items[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.text = item.display_name
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.2))

		var desc_label := Label.new()
		desc_label.text       = item.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.68, 0.64))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

		info.add_child(name_label)
		info.add_child(desc_label)

		var btn := Button.new()
		btn.text                = str(item.price) + " moedas"
		btn.custom_minimum_size = Vector2(110.0, 36.0)

		var normal := StyleBoxFlat.new()
		normal.bg_color     = Color(0.08, 0.07, 0.04, 0.9)
		normal.border_color = Color(1.0, 0.78, 0.2, 0.5)
		normal.set_border_width_all(1)
		normal.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("normal", normal)

		var hover := StyleBoxFlat.new()
		hover.bg_color     = Color(0.22, 0.18, 0.08, 0.95)
		hover.border_color = Color(1.0, 0.78, 0.2, 1.0)
		hover.set_border_width_all(1)
		hover.set_corner_radius_all(3)
		btn.add_theme_stylebox_override("hover", hover)

		btn.add_theme_color_override("font_color",       Color(1.0, 0.78, 0.2))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6))
		btn.add_theme_font_size_override("font_size", 13)

		if _purchased.has(i):
			btn.disabled = true
			btn.text     = tr("SHOP_PURCHASED")

		btn.pressed.connect(_on_buy_pressed.bind(i, item, btn))

		row.add_child(info)
		row.add_child(btn)
		items_container.add_child(row)

#endregion


#region COMPRA

func _on_buy_pressed(index: int, item: ShopItemData, btn: Button) -> void:
	if not GameManager.spend_coins(item.price):
		_show_status(tr("SHOP_NO_COINS"), Color(1.0, 0.4, 0.4))
		return

	_purchased.append(index)
	btn.disabled = true
	btn.text     = tr("SHOP_PURCHASED")
	_show_status(item.display_name + " — " + tr("SHOP_PURCHASED"), Color(0.4, 1.0, 0.5))

	match item.item_type:
		"lantern":
			var path: String = "res://Resources/Lanterns/lantern_" + item.lantern_id + ".tres"
			var data: LanternData = load(path)
			if data == null:
				DebugManager.log("ShopScreen", "LanternData não encontrada: " + path)
				return
			var lantern: Lantern = get_tree().get_first_node_in_group("lantern")
			if lantern:
				lantern.equip(data)
				DebugManager.log("ShopScreen", "Lanterna equipada: " + item.display_name)
		"inventory_upgrade":
			var player: Node = get_tree().get_first_node_in_group("player")
			if player:
				player.inventory.increase_capacity(item.capacity_bonus)
				DebugManager.log("ShopScreen", "Bolsa expandida: +" + str(item.capacity_bonus))

#endregion


#region FEEDBACK

func _show_status(text: String, color: Color) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", color)

#endregion


#region MOEDAS

func _on_coins_changed(amount: int) -> void:
	if visible:
		coins_label.text = "Moedas: " + str(amount)

#endregion


#region FECHAR

func _close() -> void:
	status_label.text = ""
	visible           = false
	Input.mouse_mode  = Input.MOUSE_MODE_VISIBLE
	SignalBus.shop_closed.emit()
	SignalBus.ui_exclusive_closed.emit()

#endregion
