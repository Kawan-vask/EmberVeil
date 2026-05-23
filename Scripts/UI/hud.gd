# ==============================================================================
# HUD — DIEGÉTICA
# ------------------------------------------------------------------------------
# Infraestrutura de signals para a HUD diegética do Emberveil.
#
# NÃO usa elementos 2D tradicionais.
# Toda informação é exibida através do modelo 3D do player.
#
# Conecta signals dos componentes e os redistribui para
# os elementos visuais diegéticos quando implementados.
#
# ADICIONAR NOVO ELEMENTO DIEGÉTICO:
# 1. Conecta o signal do componente no _ready()
# 2. Cria o método _on_X_changed() correspondente
# 3. Implementa o feedback visual no modelo 3D
# ==============================================================================

extends CanvasLayer


# ==============================================================================
#region REFERÊNCIAS
# ==============================================================================

# Componentes do player — cacheados no _ready()
var _health: HealthComponent     = null
var _stamina: StaminaComponent   = null
var _inventory: InventoryComponent = null
var _lantern: Lantern            = null

#endregion


# ==============================================================================
#region READY
# ==============================================================================

func _ready() -> void:
	# Aguarda um frame para garantir que o player está na árvore
	await get_tree().process_frame
	_connect_signals()


func _connect_signals() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if player == null:
		DebugManager.log("HUD", "Player não encontrado!")
		return

	_health    = player.health
	_stamina   = player.stamina
	_inventory = player.inventory
	_lantern   = get_tree().get_first_node_in_group("lantern")

	# Conecta signals — UI reage a eventos, nunca poleia
	_health.health_changed.connect(_on_health_changed)
	_health.player_damaged.connect(_on_player_damaged)
	_stamina.stamina_changed.connect(_on_stamina_changed)
	_inventory.wood_changed.connect(_on_wood_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.night_objective_reached.connect(_on_night_objective_reached)

	if _lantern != null:
		_lantern.energy_changed.connect(_on_energy_changed)
	else:
		DebugManager.log("HUD", "Lanterna não encontrada! Adicione ao grupo 'lantern'.")
	
	if _lantern != null:
		_lantern.energy_changed.connect(_on_energy_changed)
		_lantern.ultimate_used.connect(_on_ultimate_used)  # ← adiciona

	DebugManager.log("HUD", "Signals conectados.")

#endregion


# ==============================================================================
#region CALLBACKS — VIDA
# ------------------------------------------------------------------------------
# Futuramente: acionar animação de runas/pulseira no braço do player
# ==============================================================================

func _on_health_changed(current: float, max_value: float) -> void:
	DebugManager.log("HUD", "Vida: " + str(current) + "/" + str(max_value))
	# TODO: atualizar elemento diegético de vida no braço


func _on_player_damaged(_amount: float) -> void:
	DebugManager.log("HUD", "Player tomou dano — feedback visual aqui")
	# TODO: vinheta de dano, som, shake de câmera

#endregion


# ==============================================================================
#region CALLBACKS — STAMINA
# ------------------------------------------------------------------------------
# Futuramente: acionar elemento diegético no braço
# ==============================================================================

func _on_stamina_changed(current: float, max_value: float) -> void:
	DebugManager.log("HUD", "Stamina: " + str(current) + "/" + str(max_value))
	# TODO: atualizar elemento diegético de stamina no braço

#endregion


# ==============================================================================
#region CALLBACKS — ENERGIA DA LAMPARINA
# ------------------------------------------------------------------------------
# Futuramente: atualizar medidor integrado ao modelo 3D da lanterna
# ==============================================================================

func _on_energy_changed(current: float, max_value: float) -> void:
	DebugManager.log("HUD", "Energia: " + str(current) + "/" + str(max_value))
	# TODO: atualizar medidor diegético na lanterna

func _on_ultimate_used() -> void:
	DebugManager.log("HUD", "Ultimate usado — feedback visual aqui")
	# TODO: flash de luz, som, shockwave visual

#endregion


# ==============================================================================
#region CALLBACKS — INVENTÁRIO
# ------------------------------------------------------------------------------
# Madeira não tem contador permanente na tela.
# Informação contextualizada apenas na lareira.
# ==============================================================================

func _on_wood_changed(current: int, goal: int) -> void:
	DebugManager.log("HUD", "Madeira: " + str(current) + "/" + str(goal))
	# Sem elemento visual permanente — lareira comunica o progresso

func _on_coins_changed(amount: int) -> void:
	DebugManager.log("HUD", "Moedas: " + str(amount))
	# TODO: atualizar elemento diegético (contador na cabana)

#endregion


# ==============================================================================
#region CALLBACKS — OBJETIVO DA NOITE
# ------------------------------------------------------------------------------
# Futuramente: lareira comunica visualmente que o objetivo foi concluído
# ==============================================================================

func _on_night_objective_reached() -> void:
	DebugManager.log("HUD", "Objetivo da noite concluído!")
	# TODO: feedback visual na lareira (brilho, partículas, som)

#endregion
