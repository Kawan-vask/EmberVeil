# ==============================================================================
# CABIN DOOR
# ------------------------------------------------------------------------------
# Porta da cabana com 3 estados:
# - CLOSED: bloqueada, não deixa passar
# - OPEN:   liberada, player pode sair/entrar
# - VENDOR: vendedor presente, interagir abre a loja
#
# Transições automáticas:
# - night_transition_finished → OPEN (começa a noite, porta abre)
# - vendor_available          → VENDOR (vendedor chegou)
# - vendor_dismissed          → CLOSED (vendedor foi embora)
# ==============================================================================

class_name CabinDoor
extends Interactable


# ==============================================================================
#region ESTADOS
# ==============================================================================

enum DoorState { OPEN, CLOSED, VENDOR }

var state: DoorState = DoorState.CLOSED

#endregion


# ==============================================================================
#region NÓS
# ==============================================================================

@onready var collider: StaticBody3D = $StaticBody3D

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	SignalBus.night_transition_finished.connect(_on_night_started)
	SignalBus.vendor_available.connect(_on_vendor_arrived)
	SignalBus.vendor_dismissed.connect(_on_vendor_left)
	set_state(DoorState.CLOSED)

#endregion


# ==============================================================================
#region INTERAÇÃO
# ==============================================================================

func interact() -> void:
	match state:
		DoorState.OPEN:
			set_state(DoorState.CLOSED)
		DoorState.CLOSED:
			set_state(DoorState.OPEN)
		DoorState.VENDOR:
			# Abre a loja — ShopScreen ouve este signal
			SignalBus.shop_opened.emit()

#endregion


# ==============================================================================
#region ESTADOS
# ==============================================================================

func set_state(new_state: DoorState) -> void:
	state = new_state

	# Colisão ativa apenas quando fechada ou com vendedor
	# Quando aberta, player passa livremente
	collider.process_mode = (
		Node.PROCESS_MODE_DISABLED
		if state == DoorState.OPEN
		else Node.PROCESS_MODE_INHERIT
	)

	DebugManager.log("CabinDoor", "Estado: " + DoorState.keys()[state])

#endregion


# ==============================================================================
#region LISTENERS — SIGNALS
# ==============================================================================

func _on_night_started() -> void:
	# Noite começa — porta abre para o player sair
	set_state(DoorState.OPEN)


func _on_vendor_arrived() -> void:
	# Vendedor chegou — porta vira acesso à loja
	set_state(DoorState.VENDOR)


func _on_vendor_left() -> void:
	# Vendedor foi embora — porta fecha
	set_state(DoorState.CLOSED)

#endregion
