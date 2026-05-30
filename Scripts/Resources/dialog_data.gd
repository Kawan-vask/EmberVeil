class_name DialogData
extends Resource

## Chave do nome do NPC no CSV de localização
@export var speaker_name_key: String = ""

## Linhas de diálogo — cada elemento é uma chave CSV
@export var lines: Array[String] = []

## Labels dos botões de escolha — chaves CSV
@export var choice_labels: Array[String] = ["CHOICE_CLOSE"]

## IDs internos das escolhas — emitidos pelo signal dialog_choice_made
@export var choice_ids: Array[String] = ["close"]
