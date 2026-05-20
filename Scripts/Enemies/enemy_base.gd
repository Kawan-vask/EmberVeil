# ==============================================================================
# ENEMY BASE
# ------------------------------------------------------------------------------
# Inimigo base do Emberveil. Funciona com o sistema de Object Pool do Director.
#
# activate() → chamado pelo Director ao tirar do pool (inicializa o inimigo)
# reset()    → chamado pelo Director ao devolver ao pool (limpa o estado)
#
# Estados:
# - CHASE  → persegue o player via NavigationAgent
# - ATTACK → para e ataca quando player está no raio de ataque
# - DEAD   → morreu, aguarda ser devolvido ao pool
# ==============================================================================

class_name EnemyBase
extends CharacterBody3D


# ==============================================================================
#region ESTADOS
# ==============================================================================

enum State {
	CHASE,
	ATTACK,
	DEAD
}

var current_state: State = State.CHASE

#endregion


# ==============================================================================
#region CONFIGURAÇÃO — MOVIMENTO
# ==============================================================================

@export var move_speed: float = 3.5
@export var rotation_speed: float = 6.0

#endregion


# ==============================================================================
#region CONFIGURAÇÃO — VIDA
# ==============================================================================

@export var max_health: float = 100.0

var current_health: float = max_health

#endregion


# ==============================================================================
#region CONFIGURAÇÃO — ATAQUE
# ==============================================================================

@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0

var attack_timer: float = 0.0

#endregion


# ==============================================================================
#region CONFIGURAÇÃO — DESPAWN
# ------------------------------------------------------------------------------
# IMPORTANTE: despawn_distance DEVE ser maior que max_spawn_distance do Director
# (atualmente 50.0) para evitar que inimigos sejam despawnados logo após spawnar.
# ==============================================================================

@export var despawn_distance: float = 65.0

#endregion


# ==============================================================================
#region EFEITOS
# ------------------------------------------------------------------------------
# slow_multiplier: alimentado pelo Lantern System.
# 1.0 = velocidade normal | 0.4 = 40% da velocidade original
# ==============================================================================

var slow_multiplier: float = 1.0

func set_slow(value: float) -> void:
	slow_multiplier = value

#endregion


# ==============================================================================
#region REFERÊNCIAS DE NÓS
# ==============================================================================

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var hurtbox: Area3D = $Hurtbox
@onready var attack_area: Area3D = $EnemyAttackArea

#endregion


# ==============================================================================
#region RUNTIME
# ==============================================================================

var player: Node3D = null
var player_inside_attack: bool = false

#endregion


# ==============================================================================
#region POOL — FLAGS DE CONTROLE
# ==============================================================================

## Bloqueia o _physics_process até o activate() ser chamado
var _is_active: bool = false

## Aguarda 2 frames físicos após activate() para o Jolt registrar o corpo.
## O erro "space is null" ocorre quando move_and_slide() é chamado antes
## do Jolt ter registrado o CharacterBody3D no espaço físico.
var _frames_since_activate: int = 0

#endregion


# ==============================================================================
#region POOL — ACTIVATE E RESET
# ==============================================================================

func activate() -> void:
	player = get_tree().get_first_node_in_group("player")
	current_health = max_health
	current_state = State.CHASE
	slow_multiplier = 1.0
	player_inside_attack = false
	attack_timer = 0.0
	_frames_since_activate = 0
	_is_active = true


func reset() -> void:
	_is_active = false
	_frames_since_activate = 0
	player = null
	current_state = State.DEAD
	slow_multiplier = 1.0
	player_inside_attack = false

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	# Conecta ao SignalBus — sem acoplamento direto ao EnemyDirector
	SignalBus.player_entered_safe_zone.connect(_on_player_entered_safe_zone)

#endregion


# ==============================================================================
#region PHYSICS PROCESS
# ==============================================================================

func _physics_process(delta: float) -> void:
	if not _is_active:
		return

	_frames_since_activate += 1
	if _frames_since_activate <= 2:
		return

	if current_state == State.DEAD:
		return

	if player == null:
		return

	_check_despawn_distance()

	match current_state:
		State.CHASE:
			_handle_chase(delta)
		State.ATTACK:
			_handle_attack(delta)

	move_and_slide()

#endregion


# ==============================================================================
#region CHASE
# ==============================================================================

func _handle_chase(delta: float) -> void:
	if player_inside_attack:
		_change_state(State.ATTACK)
		return

	nav_agent.target_position = player.global_position

	var next_position: Vector3 = nav_agent.get_next_path_position()
	var direction: Vector3 = (next_position - global_position).normalized()

	velocity.x = direction.x * move_speed * slow_multiplier
	velocity.z = direction.z * move_speed * slow_multiplier

	if direction.length() > 0.01:
		var target_rotation: float = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

#endregion


# ==============================================================================
#region ATTACK
# ==============================================================================

func _handle_attack(delta: float) -> void:
	velocity = Vector3.ZERO

	if not player_inside_attack:
		_change_state(State.CHASE)
		return

	look_at(player.global_position, Vector3.UP)

	attack_timer -= delta
	if attack_timer <= 0:
		attack_timer = attack_cooldown
		_attack_player()

#endregion


# ==============================================================================
#region DANO AO PLAYER
# ==============================================================================

func _attack_player() -> void:
	if player == null:
		return
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

#endregion


# ==============================================================================
#region RECEBER DANO
# ==============================================================================

func take_damage(damage: float) -> void:
	if current_state == State.DEAD:
		return

	current_health -= damage

	if current_health <= 0:
		_die()

#endregion


# ==============================================================================
#region MORTE
# ==============================================================================

func _die() -> void:
	current_state = State.DEAD
	EnemyDirector.instance.on_enemy_died(self)

#endregion


# ==============================================================================
#region DESPAWN POR DISTÂNCIA
# ==============================================================================

func _check_despawn_distance() -> void:
	if player == null:
		return

	var distance: float = global_position.distance_to(player.global_position)
	if distance > despawn_distance:
		EnemyDirector.instance.return_to_pool(self)

#endregion


# ==============================================================================
#region ESTADOS
# ==============================================================================

func _change_state(new_state: State) -> void:
	current_state = new_state

#endregion


# ==============================================================================
#region ÁREA DE ATAQUE — SIGNALS
# ==============================================================================

func _on_enemy_attack_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside_attack = true


func _on_enemy_attack_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside_attack = false

#endregion


# ==============================================================================
#region SIGNAL BUS — SAFE ZONE
# ==============================================================================

func _on_player_entered_safe_zone() -> void:
	current_state = State.DEAD
	velocity = Vector3.ZERO

#endregion
