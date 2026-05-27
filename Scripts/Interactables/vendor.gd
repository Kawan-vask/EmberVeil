# ==============================================================================
# VENDOR — O HOMEM DAS LANTERNAS
# ------------------------------------------------------------------------------
# Aparece na porta da cabana nas noites 4, 7, 10...
# Vende lanternas e upgrades de inventário.
# ==============================================================================

class_name Vendor
extends Interactable

@export var vendor_data: VendorData

#region READY
func _ready() -> void:
	visible = false
	SignalBus.vendor_available.connect(_on_vendor_arrived)
	SignalBus.vendor_dismissed.connect(_on_vendor_left)
#endregion

#region INTERAÇÃO
func interact() -> void:
	SignalBus.shop_opened.emit()
#endregion

#region LISTENERS
func _on_vendor_arrived() -> void:
	visible = true
	DebugManager.log("Vendor", "Chegou na noite " + str(GameManager.current_night))

func _on_vendor_left() -> void:
	visible = false
	DebugManager.log("Vendor", "Foi embora.")
#endregion
