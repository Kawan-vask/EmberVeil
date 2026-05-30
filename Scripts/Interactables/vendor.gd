class_name Vendor
extends Interactable

@export var vendor_data: VendorData
@export var dialog_data: DialogData

#region READY
func _ready() -> void:
	_set_active(false)
	SignalBus.vendor_available.connect(_on_vendor_arrived)
	SignalBus.vendor_dismissed.connect(_on_vendor_left)
	SignalBus.night_transition_started.connect(_on_vendor_left)
	SignalBus.dialog_choice_made.connect(_on_choice_made)
#endregion

#region INTERAÇÃO
func interact() -> void:
	SignalBus.dialog_requested.emit(dialog_data, self)
#endregion

#region ESCOLHA DO DIÁLOGO
func _on_choice_made(id: String) -> void:
	if not visible:
		return
	match id:
		"buy":
			SignalBus.shop_requested.emit(vendor_data)
		"leave":
			SignalBus.vendor_dismissed.emit()
#endregion



#region LISTENERS
func _on_vendor_arrived() -> void:
	_set_active(true)
	DebugManager.log("Vendor", "Chegou na noite " + str(GameManager.current_night))

func _on_vendor_left() -> void:
	_set_active(false)
	DebugManager.log("Vendor", "Foi embora.")
#endregion

#region INTERNO
func _set_active(active: bool) -> void:
	visible = active
	var body := get_node_or_null("StaticBody3D")
	if body:
		body.process_mode = (
			Node.PROCESS_MODE_INHERIT
			if active
			else Node.PROCESS_MODE_DISABLED
		)
#endregion
