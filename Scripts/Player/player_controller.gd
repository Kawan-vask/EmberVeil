# ==============================================================================
# PLAYER CONTROLLER
# ------------------------------------------------------------------------------
# Responsabilidade: movimento, câmera, gravidade, interação. em breve sera
#fragmentado pra não se tornar um god_entity (muito código em um lugar)
#
# Separação de ciclos:
# - _process       → câmera (roda no framerate real, sem jitter)
# - _physics_process → movimento, física, interação (roda no ciclo de física)
# ==============================================================================

extends CharacterBody3D


# ==============================================================================
#region DEBUG
# ==============================================================================

@onready var debug_label_stamina: Label = $"./Debug/VBoxContainer/Stamina"
@onready var debug_label_madeira: Label = $"./Debug/VBoxContainer/Madeira"
@onready var debug_label_health: Label  = $"./Debug/VBoxContainer/Health"

#endregion


# ==============================================================================
#region MOVIMENTO
# ==============================================================================

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 10.0
@export var gravity: float = 20.0
@export var mouse_sensitivity: float = 0.002
@export var acceleration: float = 30.0
@export var deceleration: float   = 45.0

@export var jump_velocity: float = 4.5

var current_speed: float      = walk_speed
var input_direction: Vector2  = Vector2.ZERO

#endregion


# ==============================================================================
#region CÂMERA
# ==============================================================================

# Limites de pitch da câmera em radianos — constantes evitam cálculo todo frame
const MAX_PITCH: float = 1.3963  # deg_to_rad(80)
const MIN_PITCH: float = -1.3963 # deg_to_rad(-80)

var mouse_delta: Vector2 = Vector2.ZERO

#endregion


# ==============================================================================
#region CAMERA BOB
# ==============================================================================

## Frequência da oscilação
@export var bob_frequency: float  = 2.0

## Amplitude da oscilação andando
@export var bob_amplitude: float  = 0.03

## Multiplicador ao correr
@export var sprint_multiplier: float = 2.0

var _bob_time: float = 0.0

var _camera_base_y: float = 0.0


func _handle_camera_bob(delta: float) -> void:
	var is_moving: bool    = input_direction != Vector2.ZERO
	var is_sprinting: bool = Input.is_action_pressed("sprint") and stamina.can_sprint()

	if not is_moving or not is_on_floor():
		camera.position.y = lerp(camera.position.y, _camera_base_y, delta * 8.0)
		_bob_time = 0.0
		return

	var freq: float = bob_frequency * (sprint_multiplier if is_sprinting else 1.0)
	var amp: float  = bob_amplitude * (sprint_multiplier if is_sprinting else 1.0)

	_bob_time += delta * freq
	camera.position.y = _camera_base_y + sin(_bob_time * TAU) * amp
	camera.position.x = sin(_bob_time * PI) * amp * 0.5  # ← oscilação lateral mais sutil
	
	
#endregion

# ==============================================================================
#region NODE REFERENCES
# ==============================================================================

@onready var head: Node3D = $Head
@onready var interaction_ray: RayCast3D = $Head/Camera/InteractionRay
@onready var interaction_ring: TextureRect = $UI/CenterContainer/InteractionRing

@onready var health: HealthComponent = $Components/HealthComponent
@onready var stamina: StaminaComponent = $Components/StaminaComponent
@onready var inventory: InventoryComponent = $Components/InventoryComponent

@onready var lantern: Lantern = $Head/Camera/LanternHitbox

@onready var camera: Camera3D = $Head/Camera


#endregion


# ==============================================================================
#region READY
# ==============================================================================

var _dialog_active: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interaction_ray.add_exception(self)
	_camera_base_y = camera.position.y
	process_mode = Node.PROCESS_MODE_PAUSABLE

	SignalBus.ui_exclusive_opened.connect(func(): _dialog_active = true)
	SignalBus.ui_exclusive_closed.connect(func(): _dialog_active = false)
	
#endregion


# ==============================================================================
#region INPUT — MOUSE
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_delta += event.relative

#endregion


# ==============================================================================
#region PROCESS — CÂMERA E DEBUG
# ------------------------------------------------------------------------------
# Câmera roda no framerate real para evitar jitter durante strafe.
# Debug labels atualizam aqui — nunca no _physics_process.
# ==============================================================================

func _process(_delta: float) -> void:
	if health.is_dead():
		return
	if _dialog_active:
		return

	_handle_camera()
	_handle_camera_bob(_delta)
	DebugManager.label(debug_label_stamina, "Stamina: " + str(int(stamina.get_percent() * stamina.max_stamina)))
	DebugManager.label(debug_label_madeira,
	"Madeira: " + str(inventory.get_wood_count()) + "/" + str(GameManager.wood_goal))
	
	DebugManager.label(
	debug_label_health,
	"Vida: " + str(int(health.get_percent() * health.max_health))
	)

#endregion


# ==============================================================================
#region PHYSICS PROCESS — MOVIMENTO E FÍSICA
# ------------------------------------------------------------------------------
# Movimento, gravidade e interação rodam no ciclo de física.
# Câmera NÃO está aqui — está em _process.
# ==============================================================================

func _physics_process(delta: float) -> void:
	
	if health.is_dead():
		return
	if _dialog_active:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)
		move_and_slide()
		return
	
	_handle_gravity(delta)
	_handle_input()
	_handle_stamina(delta)
	_handle_movement(delta)
	move_and_slide()
	_handle_interaction()
	_update_crosshair()
	
	# Ultimate da lamparina
	if Input.is_action_just_pressed("lantern_ultimate"):
		lantern.use_ultimate()

#endregion


# ==============================================================================
#region CÂMERA
# ==============================================================================

func _handle_camera() -> void:
	if mouse_delta == Vector2.ZERO:
		return

	rotate_y(-mouse_delta.x * mouse_sensitivity)

	head.rotate_x(-mouse_delta.y * mouse_sensitivity)
	head.rotation.x = clamp(head.rotation.x, MIN_PITCH, MAX_PITCH)

	mouse_delta = Vector2.ZERO

#endregion


# ==============================================================================
#region MOVIMENTO
# ==============================================================================

func _handle_input() -> void:
	input_direction = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_backward"
	)


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity


func _handle_movement(delta: float) -> void:
	var direction: Vector3 = (
		transform.basis * Vector3(input_direction.x, 0, input_direction.y)
	).normalized()

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0, deceleration * delta)

#endregion


# ==============================================================================
#region STAMINA
# ==============================================================================

func _handle_stamina(delta: float) -> void:
	var is_sprinting: bool = Input.is_action_pressed("sprint")
	var is_moving: bool    = input_direction != Vector2.ZERO

	stamina.tick_recovery_timer(delta)

	if is_sprinting and is_moving and stamina.can_sprint():
		current_speed = sprint_speed
		stamina.consume(stamina.drain_rate * delta)
	else:
		current_speed = walk_speed
		if not stamina.is_in_recovery_delay():
			stamina.restore(stamina.recovery_rate * delta)

#endregion


# ==============================================================================
#region INTERAÇÃO
# ==============================================================================

func _handle_interaction() -> void:
	if not Input.is_action_just_pressed("interact"):
		return
	if not interaction_ray.is_colliding():
		return

	# Sobe na hierarquia procurando um nó do grupo "interactable"
	# Funciona independente de quantos níveis de hierarquia existam
	var node: Node = interaction_ray.get_collider()
	while node != null:
		if node.is_in_group("interactable") and node.has_method("interact"):
			node.interact()
			return
		node = node.get_parent()

func add_wood(amount: int) -> void:
	inventory.add_wood(amount)

func can_collect_wood(amount: int) -> bool:
	return inventory.can_collect_wood(amount)

#endregion


# ==============================================================================
#region CROSSHAIR
# ==============================================================================

func _update_crosshair() -> void:
	if not interaction_ray.is_colliding():
		interaction_ring.visible = false
		return

	var collider: Node = interaction_ray.get_collider()
	if collider == null:
		interaction_ring.visible = false
		return

	# Sobe na hierarquia — mesma lógica robusta da interação
	var node: Node = collider
	while node != null:
		if node.is_in_group("interactable") and node.has_method("interact"):
			interaction_ring.visible = true
			return
		node = node.get_parent()

	interaction_ring.visible = false

#endregion


# ==============================================================================
#region SAÚDE
# ------------------------------------------------------------------------------
# Fachadas públicas — delegam ao HealthComponent.
# Nenhum estado de vida é armazenado aqui.
# ==============================================================================

func take_damage(amount: float) -> void:
	health.take_damage(amount)

func heal(amount: float) -> void:
	health.heal(amount)

#endregion
