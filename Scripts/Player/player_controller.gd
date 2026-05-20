# ==============================================================================
# PLAYER CONTROLLER
# ------------------------------------------------------------------------------
# Responsabilidade: movimento, câmera, gravidade, interação. em breve sera
#fragmentado pra não se tornar um god_entity (muito código em um lugar)
#
# TODO (Refatoração 3): extrair Health, Stamina e Inventory para componentes.
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

@export var walk_speed: float     = 4.0
@export var sprint_speed: float   = 10.0
@export var gravity: float        = 20.0
@export var mouse_sensitivity: float = 0.002
@export var acceleration: float   = 30.0
@export var deceleration: float   = 45.0

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
#region STAMINA
# ------------------------------------------------------------------------------
# TODO (Refatoração 3): mover para StaminaComponent
# ==============================================================================

@export var max_stamina: float             = 100.0
@export var stamina_drain: float           = 25.0
@export var stamina_recovery: float        = 20.0
@export var stamina_recovery_delay: float  = 1.5

var current_stamina: float       = max_stamina
var stamina_recovery_timer: float = 0.0

#endregion


# ==============================================================================
#region INVENTÁRIO
# ------------------------------------------------------------------------------
# TODO (Refatoração 3): mover para InventoryComponent
# ==============================================================================

var wood_count: int = 0

#endregion


# ==============================================================================
#region SAÚDE
# ------------------------------------------------------------------------------
# TODO (Refatoração 3): mover para HealthComponent
# ==============================================================================

@export var max_health: float          = 100.0
@export var invincibility_duration: float = 1.0

var current_health: float   = max_health
var invincibility_timer: float = 0.0
var is_invincible: bool     = false
var is_dead: bool           = false

#endregion


# ==============================================================================
#region REFERÊNCIAS DE NÓS
# ==============================================================================

@onready var head: Node3D             = $Head
@onready var interaction_ray: RayCast3D = $Head/Camera/InteractionRay
@onready var interaction_ring: TextureRect = $UI/CenterContainer/InteractionRing

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interaction_ray.add_exception(self)
	current_health = max_health
	current_stamina = max_stamina

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
	_handle_camera()
	DebugManager.label(debug_label_stamina, "Stamina: " + str(int(current_stamina)))
	DebugManager.label(debug_label_madeira, "Madeira: " + str(wood_count) + "/" + str(GameManager.wood_goal))
	DebugManager.label(debug_label_health,  "Vida: "    + str(int(current_health)))

#endregion


# ==============================================================================
#region PHYSICS PROCESS — MOVIMENTO E FÍSICA
# ------------------------------------------------------------------------------
# Movimento, gravidade e interação rodam no ciclo de física.
# Câmera NÃO está aqui — está em _process.
# ==============================================================================

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_handle_gravity(delta)
	_handle_input()
	_handle_stamina(delta)
	_handle_movement(delta)
	move_and_slide()
	_handle_interaction()
	_update_crosshair()
	_handle_invincibility(delta)

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

	if is_sprinting and is_moving and current_stamina > 0:
		current_speed = sprint_speed
		current_stamina -= stamina_drain * delta
		stamina_recovery_timer = stamina_recovery_delay
	else:
		current_speed = walk_speed
		stamina_recovery_timer -= delta
		if stamina_recovery_timer <= 0:
			current_stamina += stamina_recovery * delta

	current_stamina = clamp(current_stamina, 0.0, max_stamina)

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
	wood_count += amount
	DebugManager.log("Player", "Madeira coletada. Total: " + str(wood_count))


func can_collect_wood(amount: int) -> bool:
	var total_wood: int = wood_count + GameManager.delivered_wood
	return total_wood + amount <= GameManager.wood_goal

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
# ==============================================================================

func take_damage(damage: float) -> void:
	if is_invincible or is_dead:
		return

	current_health -= damage
	current_health = max(current_health, 0.0)

	DebugManager.log("Player", "Tomou dano! Vida restante: " + str(current_health))

	is_invincible = true
	invincibility_timer = invincibility_duration

	if current_health <= 0:
		_die()


func _handle_invincibility(delta: float) -> void:
	if not is_invincible:
		return
	invincibility_timer -= delta
	if invincibility_timer <= 0:
		is_invincible = false


func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = min(current_health + amount, max_health)
	DebugManager.log("Player", "Curado! Vida atual: " + str(current_health))


func _die() -> void:
	is_dead = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Emite evento global — DeathScreen e outros sistemas reagem via SignalBus
	SignalBus.player_died.emit()

	DebugManager.log("Player", "MORREU!")

	var death_screen: Node = get_tree().get_first_node_in_group("death_screen")
	if death_screen:
		death_screen.show_death_screen()

#endregion
