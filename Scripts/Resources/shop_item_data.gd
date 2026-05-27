# ==============================================================================
# SHOP ITEM DATA
# ------------------------------------------------------------------------------
# Define um item vendível pelo Vendedor.
# Vendedor vende lanternas e upgrades de inventário.
# ==============================================================================

class_name ShopItemData
extends Resource

#region IDENTIFICAÇÃO
@export var display_name: String = ""
@export var description: String = ""
@export var price: int = 30
#endregion

#region EFEITO
@export_enum("lantern", "inventory_upgrade") var item_type: String = "lantern"

## ID da lanterna — busca res://Resources/Lanternas/lantern_[id].tres
@export var lantern_id: String = ""

## Bônus de slots adicionados à bolsa
@export var capacity_bonus: int = 0
#endregion
