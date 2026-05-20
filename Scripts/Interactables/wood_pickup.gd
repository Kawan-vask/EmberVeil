extends Interactable

#QUANTIDADE DE MADEIRA QUE ESTE ITEM DÁ
@export var wood_amount := 1

func interact():

	#PEGA REFERÊNCIA DO PLAYER
	var player = get_tree().get_first_node_in_group("player")

	#VERIFICA SE PLAYER EXISTE
	if player:

		#VERIFICA SE AINDA PODE COLETAR
		if player.can_collect_wood(wood_amount):

			#ADICIONA MADEIRA AO INVENTÁRIO
			player.add_wood(wood_amount)

			#REMOVE OBJETO DO MUNDO
			queue_free()
