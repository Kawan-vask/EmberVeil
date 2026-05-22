# ==============================================================================
# ENEMY DIRECTOR
# ------------------------------------------------------------------------------
# Sistema central que controla tudo relacionado a inimigos.
#
# NÃO guarda o número da noite — ouve o signal night_changed do GameManager.
# NÃO é chamado diretamente pela SafeZone — ouve o SignalBus.
#
# Pilares:
# - Object Pool     → inimigos criados uma vez, reciclados sempre
# - Wave System     → ondas com budget, cooldown e escalada por noite
# - Spawn por nest  → distância filtrada, sensação de floresta viva
# - Safe Zone       → pausa e devolve inimigos ao pool via SignalBus
# ==============================================================================

class_name EnemyDirector
extends Node

static var instance: EnemyDirector


# ==============================================================================
#region CONFIGURAÇÃO DO POOL
# ==============================================================================

@export var enemy_scene: PackedScene
@export var pool_size: int = 20

#endregion


# ==============================================================================
#region CONFIGURAÇÃO BASE DE WAVES
# ==============================================================================

@export var wave_cooldown: float       = 8.0
@export var spawn_interval: float      = 1.5
@export var min_spawn_distance: float  = 5.0
@export var max_spawn_distance: float  = 50.0

#endregion


# ==============================================================================
#region ESTADO CALCULADO DA NOITE ATUAL
# ==============================================================================

@export var night_config: NightConfig

var max_enemies_alive: int = 3
var wave_size: int         = 4

#endregion


# ==============================================================================
#region ESTADO INTERNO DAS WAVES
# ==============================================================================

var current_wave: int               = 0
var enemies_remaining_in_wave: int  = 0
var spawn_timer: float              = 0.0
var cooldown_timer: float           = 0.0

enum DirectorState { IDLE, SPAWNING, COOLDOWN }
var state: DirectorState = DirectorState.IDLE

#endregion


# ==============================================================================
#region RUNTIME
# ==============================================================================

var pool: Array           = []
var active_enemies: Array = []
var nests: Array          = []
var player: Node3D        = null
var player_inside_safe_zone: bool = false

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	instance = self

	nests  = get_tree().get_nodes_in_group("enemy_nest")
	player = get_tree().get_first_node_in_group("player")

	GameManager.night_changed.connect(_on_night_changed)
	GameManager.night_started.connect(_on_night_started)

	SignalBus.player_entered_safe_zone.connect(_on_player_entered_safe_zone)
	SignalBus.player_exited_safe_zone.connect(_on_player_exited_safe_zone)

	create_pool()
	apply_night_settings(GameManager.current_night)

#endregion


# ==============================================================================
#region LISTENERS DO GAME MANAGER
# ==============================================================================

func _on_night_changed(new_night: int) -> void:
	_reset_for_new_night()
	apply_night_settings(new_night)
	DebugManager.log("EnemyDirector", "Atualizado para noite " + str(new_night))


func _on_night_started() -> void:
	start_night()

#endregion


# ==============================================================================
#region LISTENERS DO SIGNAL BUS — SAFE ZONE
# ==============================================================================

func _on_player_entered_safe_zone() -> void:
	player_inside_safe_zone = true

	# Itera de trás pra frente — evita .duplicate() durante remoção
	for i in range(active_enemies.size() - 1, -1, -1):
		return_to_pool(active_enemies[i])

	state = DirectorState.IDLE
	DebugManager.log("EnemyDirector", "Safe zone. Inimigos devolvidos ao pool.")


func _on_player_exited_safe_zone() -> void:
	player_inside_safe_zone = false
	state = DirectorState.COOLDOWN
	cooldown_timer = 3.0
	DebugManager.log("EnemyDirector", "Saiu da safe zone. Nova wave em 3s.")

#endregion


# ==============================================================================
#region ESCALADA DE DIFICULDADE
# ==============================================================================

func apply_night_settings(night: int) -> void:
	if night_config != null:
		max_enemies_alive = night_config.get_max_alive(night)
		wave_size         = night_config.get_wave_size(night)
	else:
		max_enemies_alive = 3 + (night - 1)
		wave_size         = 4 + (night - 1) * 2
	DebugManager.log("EnemyDirector",
		"Noite " + str(night) +
		" | Max vivos: " + str(max_enemies_alive) +
		" | Wave size: " + str(wave_size)
	)
	
#endregion


# ==============================================================================
#region OBJECT POOL
# ==============================================================================

func create_pool() -> void:
	if enemy_scene == null:
		push_error("EnemyDirector: enemy_scene não atribuída no Inspector!")
		return

	for i in pool_size:
		var enemy := enemy_scene.instantiate()
		add_child(enemy)
		enemy.visible      = false
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		pool.append(enemy)

	DebugManager.log("EnemyDirector", "Pool criado com " + str(pool_size) + " inimigos.")


func get_from_pool() -> Node3D:
	for enemy in pool:
		if not enemy.visible:
			return enemy
	return null


func return_to_pool(enemy: Node3D) -> void:
	active_enemies.erase(enemy)
	enemy.global_position = Vector3(0, -100, 0)
	enemy.visible         = false
	enemy.process_mode    = Node.PROCESS_MODE_DISABLED
	if enemy.has_method("reset"):
		enemy.reset()

#endregion


# ==============================================================================
#region CONTROLE DE NOITE
# ==============================================================================

func start_night() -> void:
	current_wave   = 0
	state          = DirectorState.COOLDOWN
	cooldown_timer = 3.0
	DebugManager.log("EnemyDirector", "Primeira wave em 3 segundos.")


func _reset_for_new_night() -> void:
	for i in range(active_enemies.size() - 1, -1, -1):
		return_to_pool(active_enemies[i])
	current_wave              = 0
	enemies_remaining_in_wave = 0
	spawn_timer               = 0.0
	cooldown_timer            = 0.0
	state                     = DirectorState.IDLE

#endregion


# ==============================================================================
#region PROCESS
# ==============================================================================

func _process(delta: float) -> void:
	if player_inside_safe_zone:
		return
	match state:
		DirectorState.COOLDOWN:  _handle_cooldown(delta)
		DirectorState.SPAWNING:  _handle_spawning(delta)
		DirectorState.IDLE:      pass

#endregion


# ==============================================================================
#region WAVE SYSTEM
# ==============================================================================

func _handle_cooldown(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer <= 0:
		_start_next_wave()


func _start_next_wave() -> void:
	current_wave              += 1
	enemies_remaining_in_wave  = wave_size
	spawn_timer                = 0.0
	state                      = DirectorState.SPAWNING
	DebugManager.log("EnemyDirector",
		"Wave " + str(current_wave) + " iniciada! (" + str(wave_size) + " inimigos)"
	)


func _handle_spawning(delta: float) -> void:
	if enemies_remaining_in_wave > 0:
		spawn_timer -= delta
		if spawn_timer <= 0:
			spawn_timer = spawn_interval
			if active_enemies.size() < max_enemies_alive:
				_try_spawn_enemy()
	elif active_enemies.is_empty():
		_wave_completed()


func _wave_completed() -> void:
	DebugManager.log("EnemyDirector",
		"Wave " + str(current_wave) + " completa! Próxima em " + str(wave_cooldown) + "s."
	)
	state          = DirectorState.COOLDOWN
	cooldown_timer = wave_cooldown

#endregion


# ==============================================================================
#region SPAWN
# ==============================================================================

func _try_spawn_enemy() -> void:
	if player == null:
		return

	var valid_nests: Array = []
	for nest in nests:
		if not nest.can_spawn():
			continue
		var distance: float = nest.global_position.distance_to(player.global_position)
		if distance < min_spawn_distance or distance > max_spawn_distance:
			continue
		valid_nests.append(nest)

	if valid_nests.is_empty():
		return

	var chosen_nest: Node3D = valid_nests.pick_random()
	var enemy: Node3D       = get_from_pool()

	if enemy == null:
		return

	# Raycast de cima para baixo para encontrar o chão real
	var ray_origin: Vector3 = chosen_nest.global_position + Vector3(0, 3.0, 0)
	var ray_end: Vector3    = ray_origin + Vector3(0, -6.0, 0)

	var ray_query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	ray_query.collision_mask = Layers.GROUND
	ray_query.exclude        = [enemy.get_rid()]

	# Tipo explícito necessário — GDScript não infere PhysicsDirectSpaceState3D
	var space_state: PhysicsDirectSpaceState3D = \
		get_tree().current_scene.get_world_3d().direct_space_state
	var result: Dictionary = space_state.intersect_ray(ray_query)

	var spawn_position: Vector3
	if result:
		spawn_position = result.position + Vector3(0, 0.75, 0)
	else:
		spawn_position = chosen_nest.global_position + Vector3(0, 0.75, 0)

	enemy.global_position = spawn_position
	enemy.visible         = true
	enemy.process_mode    = Node.PROCESS_MODE_INHERIT

	if enemy.has_method("activate"):
		enemy.activate()

	active_enemies.append(enemy)
	enemies_remaining_in_wave -= 1

#endregion


# ==============================================================================
#region GERENCIAMENTO DE INIMIGOS
# ==============================================================================

func on_enemy_died(enemy: Node3D) -> void:
	return_to_pool(enemy)

#endregion
