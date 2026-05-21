# ==============================================================================
# LANTERN SYSTEM
# ------------------------------------------------------------------------------
# Dois modos de operação:
# - NORMAL:  OmniLight ativo — ilumina ao redor, sem dano, sem consumo
# - COMBATE: OmniLight apaga, SpotLight acende — dano contínuo, consome energia
#
# Energia só é consumida no modo combate.
# Quando energia acaba, volta ao modo normal sem possibilidade de combate.
# ==============================================================================

class_name Lantern
extends Node3D


# ==============================================================================
#region CONFIGURAÇÃO DE ENERGIA
# ==============================================================================

# DEBUG
@onready var debug_label_energia = $"Debug2/Energia"

# Energia máxima da lamparina
@export var max_energy := 100.0

# Energia consumida por segundo no modo combate
@export var energy_drain := 10.0

# Energia atual — lida pela UI
var current_energy := 100.0

# True quando está no modo combate (spotlight ativo)
var is_active := false


#endregion


# ==============================================================================
#region CONFIGURAÇÃO DE DANO
# ==============================================================================

# Dano por segundo nos inimigos dentro do cone
@export var damage_per_second := 20.0

# Fator de slow aplicado aos inimigos iluminados
# 0.4 = inimigo fica a 40% da velocidade original
@export var slow_factor := 0.4

#endregion


# ==============================================================================
#region REFERÊNCIAS DE NÓS
# ==============================================================================

# Luz direcional — modo combate
@onready var spot_light: SpotLight3D = $"../LanternPivot/SpotLight3D"

# Luz ambiente — modo normal (ilumina ao redor)
@onready var omni_light: OmniLight3D = $"../LanternPivot/OmniLight3D"

# Hitbox do cone de dano
@onready var lantern_cone: Area3D = $LanternRay

# Partículas do feixe — modo combate
@onready var beam_particles: GPUParticles3D = $"../LanternPivot/BeamParticles"

# OmniLight de combate — halo de energia ao redor da lamparina
@onready var combat_omni: OmniLight3D = $"../LanternPivot/CombatOmniLight"

#endregion


# ==============================================================================
#region RUNTIME
# ==============================================================================

# Inimigos atualmente dentro do cone de luz
var enemies_in_cone: Array = []

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready():
	current_energy = max_energy

	# Estado inicial — modo normal ligado, modo combate desligado
	is_active = false
	spot_light.visible = false
	omni_light.visible = true
	lantern_cone.monitoring = false
	beam_particles.emitting = false
	combat_omni.visible = false

	# Conecta signals do cone
	lantern_cone.body_entered.connect(_on_cone_body_entered)
	lantern_cone.body_exited.connect(_on_cone_body_exited)

#endregion


# ==============================================================================
#region PROCESS
# ==============================================================================

func _process(delta):
	handle_input()
	handle_energy(delta)
	handle_damage(delta)
	handle_flicker(delta)
	handle_spot_flicker(delta)
	debug_label_energia.text = "Energia: " + str(int(current_energy))

#endregion


# ==============================================================================
#region INPUT
# ------------------------------------------------------------------------------
# Segurar o botão ativa modo combate.
# Soltar volta ao modo normal.
# Sem energia = não pode ativar modo combate.
# ==============================================================================

func handle_input():
	if Input.is_action_pressed("lantern") and current_energy > 0:
		set_combat_mode(true)
	else:
		set_combat_mode(false)

#endregion


# ==============================================================================
#region ENERGIA
# ------------------------------------------------------------------------------
# Energia só é consumida no modo combate.
# Ao acabar, desativa o modo combate automaticamente.
# ==============================================================================

func handle_energy(delta):
	if not is_active:
		return

	current_energy -= energy_drain * delta
	current_energy = max(current_energy, 0.0)

	if current_energy <= 0:
		set_combat_mode(false)


# Chamado pela seiva (Fase 2) para reabastecer energia
func add_energy(amount: float):
	current_energy = min(current_energy + amount, max_energy)
	print("Lantern: Energia reabastecida. Atual: ", current_energy)


# Retorna porcentagem de energia (0.0 a 1.0) — usado pela UI
func get_energy_percent() -> float:
	return current_energy / max_energy

#endregion


# ==============================================================================
#region MODO COMBATE
# ------------------------------------------------------------------------------
# Alterna entre modo normal (omni) e modo combate (spot + hitbox).
# ==============================================================================

func set_combat_mode(active: bool):
	# Evita processar se o estado não mudou
	if is_active == active:
		return

	is_active = active

	if active:
		# MODO COMBATE — fecha o feixe
		omni_light.visible = false
		spot_light.visible = true
		lantern_cone.monitoring = true
		beam_particles.emitting = true
		combat_omni.visible = true
	else:
		# MODO NORMAL — abre a luz ambiente
		spot_light.visible = false
		omni_light.visible = true
		lantern_cone.monitoring = false
		beam_particles.emitting = false
		combat_omni.visible = false

		# Remove slow de todos os inimigos iluminados
		restore_all_slow()

#endregion


# ==============================================================================
#region DANO CONTÍNUO
# ==============================================================================

func handle_damage(delta: float) -> void:
	if not is_active:
		return

	# Itera de trás pra frente — evita .duplicate() e é mais eficiente
	# Remover elemento durante iteração forward corrompe os índices
	for i in range(enemies_in_cone.size() - 1, -1, -1):
		var enemy: Node3D = enemies_in_cone[i]

		if not is_instance_valid(enemy):
			enemies_in_cone.remove_at(i)
			continue

		if enemy.has_method("take_damage"):
			enemy.take_damage(damage_per_second * delta)

#endregion


# ==============================================================================
#region SLOW NOS INIMIGOS
# ==============================================================================

func apply_slow(enemy: Node3D):
	if enemy.has_method("set_slow"):
		enemy.set_slow(slow_factor)
	elif "slow_multiplier" in enemy:
		enemy.slow_multiplier = slow_factor


func remove_slow(enemy: Node3D):
	if not is_instance_valid(enemy):
		return
	if enemy.has_method("set_slow"):
		enemy.set_slow(1.0)
	elif "slow_multiplier" in enemy:
		enemy.slow_multiplier = 1.0


func restore_all_slow():
	for enemy in enemies_in_cone.duplicate():
		remove_slow(enemy)
	enemies_in_cone.clear()

#endregion


# ==============================================================================
#region SIGNALS DO CONE
# ==============================================================================

func _on_cone_body_entered(body):
	if body.is_in_group("enemy"):
		enemies_in_cone.append(body)
		apply_slow(body)


func _on_cone_body_exited(body):
	if body.is_in_group("enemy"):
		enemies_in_cone.erase(body)
		remove_slow(body)

#endregion

# ==============================================================================
#region FLICKER DA OMNILIGHT
# ------------------------------------------------------------------------------
# Simula a chama do lampião variando a intensidade da OmniLight.
# Usa sin() com variação aleatória pra parecer orgânico, não mecânico.
# ==============================================================================

# Intensidade base da OmniLight (valor central do flicker)
@export var omni_base_energy := 2.0

# Quanto a intensidade pode variar pra cima e pra baixo
@export var omni_flicker_amount := 0.4

# Acumula o tempo para o sin()
var flicker_time := 0.0

func handle_flicker(delta):
	# Só flicka no modo normal (omni ativa)
	if is_active:
		return

	flicker_time += delta

	# Atualiza a cada intervalo curtíssimo — simula tremida do fogo
	if flicker_time >= randf_range(0.02, 0.05):
		flicker_time = 0.0

		# Valor aleatório puro — sem sin(), sem suavidade
		var flicker = randf_range(-omni_flicker_amount, omni_flicker_amount)

		# Chance de 20% de dar um pulo maior de intensidade
		# simula aquele momento que o fogo "estoura"
		if randf() < 0.2:
			flicker *= 2.5

		# Aplica diretamente sem interpolação — travado mesmo
		omni_light.light_energy = omni_base_energy + flicker

#endregion

# ==============================================================================
#region FLICKER DO SPOTLIGHT
# ------------------------------------------------------------------------------
# Simula instabilidade do feixe no modo combate.
# Energia violenta e irregular — diferente do flicker suave da OmniLight.
# ==============================================================================

# Energia base do SpotLight
@export var spot_base_energy := 15.0

# Variação máxima de energia
@export var spot_flicker_amount := 4.0

var spot_flicker_time := 0.0

func handle_spot_flicker(delta):
	if not is_active:
		return

	spot_flicker_time += delta

	if spot_flicker_time >= randf_range(0.03, 0.08):
		spot_flicker_time = 0.0

		var flicker = randf_range(-spot_flicker_amount, spot_flicker_amount)

		# 25% de chance de pulo violento de energia
		if randf() < 0.25:
			flicker *= 2.0

		spot_light.light_energy = clamp(
			spot_base_energy + flicker,
			spot_base_energy * 0.4,
			spot_base_energy * 1.8
		)

#endregion
