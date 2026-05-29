# ==============================================================================
# CABIN DOOR
# ------------------------------------------------------------------------------
# Porta física da cabana com abertura/fechamento animado.
#
# Hierarquia esperada na cena:
#   CabinDoor (este script, grupo "interactable")
#   └── DoorPivot (Node3D) ← pivot posicionado na dobradiça
#       ├── MeshInstance3D  ← offset +0.5 X em relação ao pivot
#       └── StaticBody3D    ← colisão; rotaciona junto com o pivot automaticamente
#           └── CollisionShape3D
#
# A colisão NUNCA é desativada — ela acompanha a rotação do DoorPivot.
# Quando aberta (85°), o vão fica livre naturalmente pela geometria.
# Quando fechada (0°), bloqueia a passagem e é detectável pelo raycast.
#
# Estados:
#   CLOSED  — porta fechada, bloqueia passagem
#   OPEN    — porta aberta (85°), vão liberado
#   VENDOR  — vendedor presente; player abre a porta e inicia o fluxo
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
#region CONFIGURAÇÃO
# ==============================================================================

## Ângulo de abertura em graus
@export var open_angle_deg: float = 85.0

## Duração da animação de abrir/fechar em segundos
@export var animation_duration: float = 0.4

#endregion


# ==============================================================================
#region NÓS
# ==============================================================================

@onready var door_pivot: Node3D = $DoorPivot

#endregion


# ==============================================================================
#region RUNTIME
# ==============================================================================

var _tween: Tween = null

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	SignalBus.night_transition_finished.connect(_on_night_transition_finished)
	SignalBus.vendor_available.connect(_on_vendor_arrived)
	SignalBus.vendor_dismissed.connect(_on_vendor_left)
	set_state(DoorState.CLOSED)

#endregion


# ==============================================================================
#region INTERAÇÃO
# ==============================================================================

func interact() -> void:
	match state:
		DoorState.CLOSED:
			set_state(DoorState.OPEN)
		DoorState.OPEN:
			set_state(DoorState.CLOSED)
		DoorState.VENDOR:
			# Abre a porta fisicamente antes de iniciar o fluxo do vendedor
			# A porta permanece em estado VENDOR até vendor_dismissed ser emitido
			_animate_door(open_angle_deg)
			# Placeholder até Passo E (DialogSystem)
			# Será: SignalBus.dialog_requested.emit(dialog_data, self)
			SignalBus.shop_opened.emit()

#endregion


# ==============================================================================
#region ESTADOS
# ==============================================================================

func set_state(new_state: DoorState) -> void:
	state = new_state

	match state:
		DoorState.OPEN:
			_animate_door(open_angle_deg)
		DoorState.CLOSED:
			_animate_door(0.0)
		DoorState.VENDOR:
			# Porta fechada enquanto vendedor espera
			_animate_door(0.0)

	DebugManager.log("CabinDoor", "Estado: " + DoorState.keys()[state])

#endregion


# ==============================================================================
#region ANIMAÇÃO
# ==============================================================================

func _animate_door(target_angle_deg: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(
		door_pivot,
		"rotation:y",
		deg_to_rad(target_angle_deg),
		animation_duration
	)

#endregion


# ==============================================================================
#region LISTENERS — SIGNALS
# ==============================================================================

func _on_night_transition_finished() -> void:
	# start_night() já foi chamado pela NightTransition antes deste signal
	set_state(DoorState.CLOSED)


func _on_vendor_arrived() -> void:
	set_state(DoorState.VENDOR)


func _on_vendor_left() -> void:
	# Fecha a porta e libera para uso normal
	set_state(DoorState.CLOSED)

#endregion
