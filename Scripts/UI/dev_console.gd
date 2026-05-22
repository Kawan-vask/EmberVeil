# ==============================================================================
# DEV CONSOLE
# ------------------------------------------------------------------------------
# Console de desenvolvimento para testar sistemas em runtime.
#
# USO:
# - Tecla ` (acento grave) → abre/fecha
# - Digite um comando e pressione Enter
# - Seta cima/baixo → navega histórico de comandos
# - Digite "help" → lista todos os comandos disponíveis
#
# ADICIONAR NOVO COMANDO:
# 1. Crie _cmd_nome(args: Array) -> void abaixo
# 2. Registre em _register_all_commands():
#    _register("nome", _cmd_nome, "descrição curta")
#
# REMOVER EM PRODUÇÃO:
# DebugManager.DEBUG_ENABLED = false → console nunca é instanciado.
# ==============================================================================
 
extends CanvasLayer
 
 
# ==============================================================================
#region NÓS
# ==============================================================================
 
@onready var panel: Panel          = $Panel
@onready var output: RichTextLabel = $Panel/VBox/Output
@onready var input: LineEdit       = $Panel/VBox/Input
 
#endregion
 
 
# ==============================================================================
#region ESTADO
# ==============================================================================
 
var _commands: Dictionary      = {}
var _history: Array[String]    = []
var _history_index: int        = -1
var _infinite_energy: bool     = false
 
const MAX_HISTORY: int      = 50
const MAX_OUTPUT_LINES: int = 100
const MAX_CONSOLE_HEIGHT_RATIO: float = 0.33  # ← adiciona esta linha
#endregion
 
 
# ==============================================================================
#region READY
# ==============================================================================
 
func _ready() -> void:
	_setup_layout()
 
	panel.visible  = false
	process_mode   = Node.PROCESS_MODE_ALWAYS
 
	input.text_submitted.connect(_on_command_submitted)
	input.gui_input.connect(_on_input_gui_input)
	
	_register_all_commands()
	_print_output("[color=yellow]DevConsole iniciado. Digite [b]help[/b] para ver os comandos.[/color]")
 
#endregion
 

# ==============================================================================
#region CONFIGURANDO TAMANHO DO CONSOLE POR CÓDIGO
# ==============================================================================

func _setup_layout() -> void:
	# PANEL — altura fixa, cresce para cima a partir do fundo esquerdo
	# Começa com altura mínima (só o input visível)
	panel.set_anchor_and_offset(SIDE_LEFT,   0.0,  8.0)
	panel.set_anchor_and_offset(SIDE_RIGHT,  0.0,  600.0)
	panel.set_anchor_and_offset(SIDE_TOP,    1.0, -72.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -8.0)

	# VBOX — preenche o panel inteiro com padding interno
	var vbox: VBoxContainer = panel.get_node("VBox")
	vbox.set_anchor_and_offset(SIDE_LEFT,   0.0,  6.0)
	vbox.set_anchor_and_offset(SIDE_RIGHT,  1.0, -6.0)
	vbox.set_anchor_and_offset(SIDE_TOP,    0.0,  6.0)
	vbox.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -6.0)

	# OUTPUT — ocupa todo o espaço disponível acima do input
	# fit_content = false é CRÍTICO — evita o output empurrar o input para fora
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.scroll_following    = true
	output.fit_content         = false
	output.bbcode_enabled      = true
	output.custom_minimum_size = Vector2(0, 0)

	# INPUT — altura fixa, nunca se move
	input.size_flags_vertical   = Control.SIZE_SHRINK_END
	input.custom_minimum_size   = Vector2(0, 32)
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.placeholder_text      = "Digite um comando..."


func _update_panel_size() -> void:
	var screen_height: float = get_viewport().get_visible_rect().size.y
	var max_height: float    = screen_height * MAX_CONSOLE_HEIGHT_RATIO

	# Calcula quantas linhas existem e estima a altura necessária
	# Cada linha tem ~18px de altura + padding do output
	var line_count: int      = output.get_line_count()
	var lines_height: float  = line_count * 20.0

	# Altura total: linhas + input(32) + padding(24)
	var content_height: float = lines_height + 32.0 + 24.0
	var target_height: float  = clampf(content_height, 72.0, max_height)

	# Cresce para cima — bottom fica fixo no fundo
	panel.set_anchor_and_offset(SIDE_TOP,    1.0, -target_height - 8.0)
	panel.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -8.0)
	
#endregion
 

# ==============================================================================
#region INPUT — TOGGLE E HISTÓRICO
# ==============================================================================

func _unhandled_input(event: InputEvent) -> void:
	# Toggle com botão lateral traseiro do mouse
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_XBUTTON1:
			_toggle()
			get_viewport().set_input_as_handled()


# Captura setas DIRETAMENTE no LineEdit — evita conflito com foco do controle
func _on_input_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_UP:
		_navigate_history(1)
		input.accept_event()
	elif event.keycode == KEY_DOWN:
		_navigate_history(-1)
		input.accept_event()

#endregion
 
# ==============================================================================
#region TOGGLE
# ==============================================================================
 
func _toggle() -> void:
	panel.visible = !panel.visible
 
	if panel.visible:
		_update_panel_size()
		get_tree().paused      = true
		Input.mouse_mode       = Input.MOUSE_MODE_VISIBLE
		input.grab_focus()
		input.clear()
		_history_index = -1
	else:
		get_tree().paused      = false
		Input.mouse_mode       = Input.MOUSE_MODE_CAPTURED
 
#endregion
 
 
# ==============================================================================
#region HISTÓRICO
# ==============================================================================
 
func _navigate_history(direction: int) -> void:
	if _history.is_empty():
		return
	_history_index = clamp(_history_index + direction, 0, _history.size() - 1)
	input.text          = _history[_history.size() - 1 - _history_index]
	input.caret_column  = input.text.length()
 
#endregion
 
 
# ==============================================================================
#region PROCESSAMENTO DE COMANDOS
# ==============================================================================
 
func _on_command_submitted(text: String) -> void:
	var trimmed: String = text.strip_edges()
	input.clear()
	_history_index = -1

	if trimmed.is_empty():
		input.grab_focus()  # ← mantém foco mesmo em submit vazio
		return

	if _history.is_empty() or _history.back() != trimmed:
		_history.append(trimmed)
		if _history.size() > MAX_HISTORY:
			_history.pop_front()

	_print_output("[color=gray]> " + trimmed + "[/color]")

	var parts: Array     = trimmed.split(" ", false)
	var cmd_name: String = parts[0].to_lower()
	var args: Array      = parts.slice(1)

	if _commands.has(cmd_name):
		_commands[cmd_name].callable.call(args)
	else:
		_print_output("[color=red]Comando desconhecido: '" + cmd_name + "'. Digite help.[/color]")

	input.grab_focus()  # ← mantém foco após executar comando
#endregion
 
 
# ==============================================================================
#region OUTPUT
# ==============================================================================
 
func _print_output(text: String) -> void:
	output.append_text(text + "\n")
	if output.get_line_count() > MAX_OUTPUT_LINES:
		output.clear()
		_print_output("[color=gray][output limpo][/color]")
	# Atualiza o tamanho do painel após nova linha
	_update_panel_size()
 
#endregion
 
 
# ==============================================================================
#region REGISTRO DE COMANDOS
# ==============================================================================
 
func _register(name: String, callable: Callable, description: String, group: String = "geral") -> void:
	_commands[name] = {
		"callable":    callable,
		"description": description,
		"group":       group
	}


func _register_all_commands() -> void:
	_register("help", _cmd_help, "lista todos os comandos", "geral")
	_register("quit", _cmd_quit, "fecha o jogo", "geral")

	# NOITE
	_register("set_night",      _cmd_set_night,      "set_night [n] — força a noite para n",          "noite")
	_register("next_night",     _cmd_next_night,     "avança para a próxima noite",                   "noite")
	_register("set_wood_goal",  _cmd_set_wood_goal,  "set_wood_goal [n] — altera objetivo de madeira","noite")
	_register("complete_night", _cmd_complete_night, "marca noite como completa",                     "noite")
	_register("reset_night",    _cmd_reset_night,    "reseta madeira entregue para zero",              "noite")

	# PLAYER
	_register("god",         _cmd_god,         "toggle de invencibilidade permanente", "player")
	_register("set_health",  _cmd_set_health,  "set_health [n] — define vida atual",   "player")
	_register("set_stamina", _cmd_set_stamina, "set_stamina [n] — define stamina",     "player")
	_register("set_energy",  _cmd_set_energy,  "set_energy [n] — define energia",      "player")
	_register("add_wood",    _cmd_add_wood,    "add_wood [n] — adiciona madeira",       "player")
	_register("kill_player", _cmd_kill_player, "mata o player imediatamente",           "player")
	_register("teleport", _cmd_teleport, "teleport [x] [y] [z] — teleporta o player", "player")

	# INIMIGOS
	_register("kill_all",        _cmd_kill_all,        "devolve todos ao pool",                        "inimigos")
	_register("disable_enemies", _cmd_disable_enemies, "pausa o EnemyDirector",                        "inimigos")
	_register("enable_enemies",  _cmd_enable_enemies,  "retoma o EnemyDirector",                       "inimigos")
	_register("spawn_wave",      _cmd_spawn_wave,      "spawn_wave [n] — spawna n inimigos",            "inimigos")
	_register("set_enemy_speed", _cmd_set_enemy_speed, "set_enemy_speed [mult] — multiplica velocidade","inimigos")

	# LAMPARINA
	_register("fill_energy",     _cmd_fill_energy,     "reabastece energia para 100%",  "lamparina")
	_register("drain_energy",    _cmd_drain_energy,    "zera energia da lamparina",      "lamparina")
	_register("infinite_energy", _cmd_infinite_energy, "toggle de energia infinita",     "lamparina")
	_register("set_damage", _cmd_set_damage, "set_damage [n] — altera dano por segundo", "lamparina")
	_register("set_slow",   _cmd_set_slow,   "set_slow [n] — altera fator de slow (0.0 a 1.0)", "lamparina")
	_register("ultimate", _cmd_ultimate, "ativa o ultimate da lamparina", "lamparina")
	
	
	# MUNDO
	_register("timescale",   _cmd_timescale,   "timescale [n] — altera Engine.time_scale", "mundo")
	_register("fps",         _cmd_fps,         "exibe FPS atual",                           "mundo")
	_register("pool_status", _cmd_pool_status, "inimigos ativos vs disponíveis no pool",    "mundo")

	# PLACEHOLDERS — descomentar quando os sistemas existirem
	# _register("add_coins",      _cmd_add_coins,      "add_coins [n]",      "economia")
	# _register("open_shop",      _cmd_open_shop,      "abre a loja",        "economia")
	# _register("give_powerup",   _cmd_give_powerup,   "give_powerup [id]",  "powerups")
	# _register("equip_lantern",  _cmd_equip_lantern,  "equip_lantern [tipo]","lanternas")
	# _register("show_nests",     _cmd_show_nests,     "mostra nests ativos", "mundo")
	# _register("show_nav",       _cmd_show_nav,       "toggle navegação",    "mundo")

#endregion
 
 
# ==============================================================================
#region COMANDOS — HELP
# ==============================================================================
 
func _cmd_help(_args: Array) -> void:
	# Agrupa comandos por categoria
	var groups: Dictionary = {}
	for key in _commands:
		var group: String = _commands[key].group
		if not groups.has(group):
			groups[group] = []
		groups[group].append(key)

	# Exibe agrupado e ordenado
	var sorted_groups: Array = groups.keys()
	sorted_groups.sort()
	for group in sorted_groups:
		_print_output("[color=yellow]── " + group.to_upper() + " ──[/color]")
		var sorted_cmds: Array = groups[group]
		sorted_cmds.sort()
		for cmd in sorted_cmds:
			_print_output("  [color=cyan]" + cmd + "[/color] — " + _commands[cmd].description)
 
#endregion
 
 
# ==============================================================================
#region COMANDOS — NOITE E LOOP
# ==============================================================================
 
func _cmd_set_night(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_night [n][/color]"); return
	var n: int = int(args[0])
	if n < 1:
		_print_output("[color=red]Noite deve ser >= 1[/color]"); return
	GameManager.current_night = n
	GameManager.night_changed.emit(n)
	_print_output("[color=green]Noite definida para " + str(n) + "[/color]")
 
 
func _cmd_next_night(_args: Array) -> void:
	GameManager.current_night += 1
	GameManager.night_changed.emit(GameManager.current_night)
	_print_output("[color=green]Avançou para noite " + str(GameManager.current_night) + "[/color]")
 
 
func _cmd_set_wood_goal(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_wood_goal [n][/color]"); return
	GameManager.wood_goal = int(args[0])
	_print_output("[color=green]Objetivo de madeira: " + str(GameManager.wood_goal) + "[/color]")
 
 
func _cmd_complete_night(_args: Array) -> void:
	GameManager.delivered_wood  = GameManager.wood_goal
	GameManager.night_completed = true
	GameManager.night_objective_reached.emit()
	_print_output("[color=green]Noite marcada como completa.[/color]")
 
 
func _cmd_reset_night(_args: Array) -> void:
	GameManager.delivered_wood  = 0
	GameManager.night_completed = false
	_print_output("[color=green]Madeira entregue resetada.[/color]")
 
#endregion
 
 
# ==============================================================================
#region COMANDOS — PLAYER
# ==============================================================================
 
func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")
 
 
func _cmd_god(_args: Array) -> void:
	var player := _get_player()
	if player == null:
		_print_output("[color=red]Player não encontrado.[/color]"); return
	var active: bool = player.health.toggle_invincibility()
	_print_output("[color=green]God mode: " + ("ON" if active else "OFF") + "[/color]")
 

func _cmd_set_health(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_health [n][/color]"); return
	var player := _get_player()
	if player == null: return
	var hc: HealthComponent = player.health
	hc._current_health = clampf(float(args[0]), 0.0, hc.max_health)
	hc.health_changed.emit(hc._current_health, hc.max_health)
	_print_output("[color=green]Vida: " + str(hc._current_health) + "[/color]")
 
 
func _cmd_set_stamina(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_stamina [n][/color]"); return
	var player := _get_player()
	if player == null: return
	var sc: StaminaComponent = player.stamina
	sc._current_stamina = clampf(float(args[0]), 0.0, sc.max_stamina)
	sc.stamina_changed.emit(sc._current_stamina, sc.max_stamina)
	_print_output("[color=green]Stamina: " + str(sc._current_stamina) + "[/color]")
 
 
func _cmd_set_energy(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_energy [n][/color]"); return
	var lantern := get_tree().get_first_node_in_group("lantern")
	if lantern == null:
		_print_output("[color=red]Lanterna não encontrada. Adicione ao grupo 'lantern'.[/color]"); return
	lantern.current_energy = clampf(float(args[0]), 0.0, lantern.max_energy)
	_print_output("[color=green]Energia: " + str(lantern.current_energy) + "[/color]")
 
 
func _cmd_add_wood(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: add_wood [n][/color]"); return
	var player := _get_player()
	if player == null: return
	player.inventory.add_wood(int(args[0]))
	_print_output("[color=green]Madeira adicionada: " + args[0] + "[/color]")
 
 
func _cmd_kill_player(_args: Array) -> void:
	var player := _get_player()
	if player == null: return
	player.health.kill()
	_print_output("[color=red]Player morreu.[/color]")


func _cmd_teleport(args: Array) -> void:
	if args.size() < 3:
		_print_output("[color=red]Uso: teleport [x] [y] [z][/color]"); return
	var player := _get_player()
	if player == null: return
	player.global_position = Vector3(float(args[0]), float(args[1]), float(args[2]))
	_print_output("[color=green]Player teleportado para " +
		str(player.global_position) + "[/color]") 
#endregion
 
 
# ==============================================================================
#region COMANDOS — INIMIGOS
# ==============================================================================
 
func _cmd_kill_all(_args: Array) -> void:
	for i in range(EnemyDirector.instance.active_enemies.size() - 1, -1, -1):
		EnemyDirector.instance.return_to_pool(EnemyDirector.instance.active_enemies[i])
	_print_output("[color=green]Todos os inimigos devolvidos ao pool.[/color]")
 
 
func _cmd_disable_enemies(_args: Array) -> void:
	EnemyDirector.instance.state = EnemyDirector.DirectorState.IDLE
	EnemyDirector.instance.player_inside_safe_zone = true
	_print_output("[color=green]EnemyDirector pausado.[/color]")
 
 
func _cmd_enable_enemies(_args: Array) -> void:
	EnemyDirector.instance.player_inside_safe_zone = false
	EnemyDirector.instance.state = EnemyDirector.DirectorState.COOLDOWN
	EnemyDirector.instance.cooldown_timer = 3.0
	_print_output("[color=green]EnemyDirector retomado.[/color]")
 
 
func _cmd_spawn_wave(args: Array) -> void:
	var n: int = 1 if args.is_empty() else int(args[0])
	EnemyDirector.instance.enemies_remaining_in_wave += n
	EnemyDirector.instance.state = EnemyDirector.DirectorState.SPAWNING
	_print_output("[color=green]Spawnando " + str(n) + " inimigos.[/color]")
 
 
func _cmd_set_enemy_speed(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_enemy_speed [multiplicador][/color]"); return
	var mult: float = float(args[0])
	for enemy in EnemyDirector.instance.active_enemies:
		if is_instance_valid(enemy):
			enemy.move_speed *= mult
	_print_output("[color=green]Velocidade multiplicada por " + str(mult) + "[/color]")
 
#endregion
 
 
# ==============================================================================
#region COMANDOS — LAMPARINA
# ==============================================================================
 
func _get_lantern() -> Node:
	return get_tree().get_first_node_in_group("lantern")
 
 
func _cmd_fill_energy(_args: Array) -> void:
	var lantern := _get_lantern()
	if lantern == null:
		_print_output("[color=red]Lanterna não encontrada.[/color]"); return
	lantern.current_energy = lantern.max_energy
	_print_output("[color=green]Energia reabastecida.[/color]")
 
 
func _cmd_drain_energy(_args: Array) -> void:
	var lantern := _get_lantern()
	if lantern == null:
		_print_output("[color=red]Lanterna não encontrada.[/color]"); return
	lantern.current_energy = 0.0
	lantern.set_combat_mode(false)
	_print_output("[color=green]Energia zerada.[/color]")
 
 
func _cmd_infinite_energy(_args: Array) -> void:
	var lantern := _get_lantern()
	if lantern == null:
		_print_output("[color=red]Lanterna não encontrada.[/color]"); return
	_infinite_energy = !_infinite_energy
	lantern.energy_drain = 0.0 if _infinite_energy else 10.0
	_print_output("[color=green]Energia infinita: " + ("ON" if _infinite_energy else "OFF") + "[/color]")
 

func _cmd_set_damage(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_damage [n][/color]"); return
	var lantern := _get_lantern()
	if lantern == null: return
	lantern.damage_per_second = float(args[0])
	_print_output("[color=green]Dano por segundo: " + args[0] + "[/color]")


func _cmd_set_slow(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: set_slow [n][/color]"); return
	var lantern := _get_lantern()
	if lantern == null: return
	lantern.slow_factor = clampf(float(args[0]), 0.0, 1.0)
	_print_output("[color=green]Slow factor: " + args[0] + "[/color]")


func _cmd_ultimate(_args: Array) -> void:
	var lantern := _get_lantern()
	if lantern == null: return
	lantern.use_ultimate()
	_print_output("[color=green]Ultimate ativado.[/color]")



#endregion
 
 
# ==============================================================================
#region COMANDOS — MUNDO E DEBUG
# ==============================================================================
 
func _cmd_timescale(args: Array) -> void:
	if args.is_empty():
		_print_output("[color=red]Uso: timescale [n][/color]"); return
	Engine.time_scale = clampf(float(args[0]), 0.01, 10.0)
	_print_output("[color=green]Time scale: " + str(Engine.time_scale) + "[/color]")
 
 
func _cmd_fps(_args: Array) -> void:
	_print_output("[color=green]FPS: " + str(Engine.get_frames_per_second()) + "[/color]")
 
 
func _cmd_pool_status(_args: Array) -> void:
	var active: int = EnemyDirector.instance.active_enemies.size()
	var total: int  = EnemyDirector.instance.pool.size()
	_print_output("[color=green]Pool — Ativos: " + str(active) +
		" | Livres: " + str(total - active) +
		" | Total: " + str(total) + "[/color]")

func _cmd_quit(_args: Array) -> void:
	_print_output("[color=red]Fechando o jogo...[/color]")
	get_tree().quit()
 
#endregion
