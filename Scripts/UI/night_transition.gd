# ==============================================================================
# NIGHT TRANSITION
# ==============================================================================

extends CanvasLayer


#region NÓS
@onready var fade_rect: ColorRect = $FadeRect
@onready var night_label: Label   = $NightLabel
#endregion


#region CONFIGURAÇÃO
@export var fade_duration: float = 1.0
@export var hold_duration: float = 1.5
#endregion


#region READY
func _ready() -> void:
	process_mode         = Node.PROCESS_MODE_ALWAYS
	visible              = false
	fade_rect.modulate.a = 0.0
	night_label.visible  = false
	SignalBus.night_transition_started.connect(_on_transition_started)
#endregion


#region TRANSIÇÃO
func _on_transition_started() -> void:
	visible = true
	get_tree().paused = true

	await _fade(1.0)

	night_label.text    = "NOITE " + str(GameManager.current_night)
	night_label.visible = true

	await get_tree().create_timer(hold_duration).timeout

	_reset_player()

	# EXCEÇÃO DE TIMING DOCUMENTADA — não refatorar antes da Fase 5.
	GameManager.night_changed.emit(GameManager.current_night)

	night_label.visible = false

	await _fade(0.0)

	# Despausa e reseta ANTES de emitir finished
	# Assim a PowerUpScreen recebe o jogo já despausado e pausa por conta própria
	get_tree().paused = false
	visible = false
	_reset_resources()

	# Emite por último — PowerUpScreen abre com estado limpo
	GameManager.start_night()
	SignalBus.night_transition_finished.emit()


func _fade(to: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", to, fade_duration)
	await tween.finished


func _reset_player() -> void:
	var spawn: Node  = get_tree().get_first_node_in_group("spawn_point")
	var player: Node = get_tree().get_first_node_in_group("player")
	if spawn and player:
		player.global_position = spawn.global_position
	else:
		DebugManager.log("NightTransition", "SpawnPoint não encontrado!")

	var lantern := get_tree().get_first_node_in_group("lantern")
	if lantern:
		lantern.add_energy(lantern.max_energy)


func _reset_resources() -> void:
	var resources := get_tree().get_nodes_in_group("resource_pickup")
	for r in resources:
		r.visible = true
		var body := r.get_node_or_null("StaticBody3D")
		if body:
			body.process_mode = Node.PROCESS_MODE_INHERIT
	DebugManager.log("NightTransition", "Recursos resetados: " + str(resources.size()))
#endregion
