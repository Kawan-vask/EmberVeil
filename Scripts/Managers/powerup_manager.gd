# ==============================================================================
# POWERUP MANAGER
# ------------------------------------------------------------------------------
# Gerencia a aplicação de power-ups ao player.
#
# - Mantém lista de power-ups ativos da run atual
# - Aplica efeitos via API pública dos componentes — nunca acessa internals
# - Reseta ao morrer (roguelike)
#
# Instanciar como filho da main.tscn, grupo "powerup_manager"
# ==============================================================================

class_name PowerUpManager
extends Node


# ==============================================================================
#region CONFIGURAÇÃO
# ==============================================================================

## Pool de power-ups disponíveis para sorteio
## Arraste os .tres criados no Inspector
@export var available_powerups: Array[PowerUpData] = []

#endregion


# ==============================================================================
#region ESTADO
# ==============================================================================

## Power-ups aplicados na run atual
var active_powerups: Array[PowerUpData] = []

#endregion


# ==============================================================================
#region SIGNALS
# ==============================================================================

## Emitido quando um power-up é aplicado — ouvido pela HUD
signal powerup_applied(data: PowerUpData)

#endregion


# ==============================================================================
#region API PÚBLICA
# ==============================================================================

## Retorna N power-ups aleatórios do pool disponível
## Garante que não repete power-ups já ativos (se pool permitir)
func get_random_choices(count: int) -> Array[PowerUpData]:
	if available_powerups.is_empty():
		DebugManager.log("PowerUpManager", "Pool vazio!")
		return []

	var pool: Array[PowerUpData] = available_powerups.duplicate()
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))


## Aplica o efeito do power-up ao player via API pública
func apply(data: PowerUpData, player: Node) -> void:
	var h: HealthComponent  = player.health
	var s: StaminaComponent = player.stamina
	var l: Lantern          = get_tree().get_first_node_in_group("lantern")

	match data.effect_type:
		"health_max":
			h.increase_max(data.value)
		"stamina_max":
			s.increase_max(data.value)
		"energy_max":
			if l: l.max_energy += data.value
		"walk_speed":
			player.walk_speed += data.value
		"sprint_speed":
			player.sprint_speed += data.value
		"lantern_damage":
			if l: l.damage_per_second += data.value
		"lantern_slow":
			if l: l.slow_factor = maxf(l.slow_factor - data.value, 0.05)
		"ultimate_radius":
			if l: l.ultimate_radius += data.value
		"ultimate_cooldown":
			if l: l.ultimate_cooldown = maxf(l.ultimate_cooldown - data.value, 1.0)
		"energy_drain_reduction":
			if l: l.energy_drain = maxf(l.energy_drain - data.value, 1.0)

	active_powerups.append(data)
	powerup_applied.emit(data)
	DebugManager.log("PowerUpManager", "Aplicado: " + data.display_name)


## Reseta todos os power-ups — chamado ao morrer (roguelike reset)
func reset() -> void:
	active_powerups.clear()
	DebugManager.log("PowerUpManager", "Power-ups resetados.")

#endregion
