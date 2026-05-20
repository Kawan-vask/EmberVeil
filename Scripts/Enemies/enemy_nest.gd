class_name EnemyNest
extends Marker3D

@export var enabled := true

func can_spawn() -> bool:

	return enabled
