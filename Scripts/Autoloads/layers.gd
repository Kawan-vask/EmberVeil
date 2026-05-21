# ==============================================================================
# LAYERS
# ------------------------------------------------------------------------------
# Constantes nomeadas para todas as collision layers do projeto.
#
# REGRA: nunca use números mágicos para collision layers em cenas ou scripts.
# Sempre use Layers.NOME_DA_LAYER.
#
# Como funciona:
# Cada layer é uma potência de 2 (bit flag).
# Para combinar layers, use o operador | (OR bit a bit).
#
# Exemplos:
#   collision_layer = Layers.ENEMY
#   collision_mask  = Layers.GROUND | Layers.PLAYER
#   ray_query.collision_mask = Layers.GROUND
# ==============================================================================

extends Node


# ==============================================================================
#region LAYERS DO PROJETO
# ------------------------------------------------------------------------------
# Mapa atual das layers (espelha Project Settings → Layer Names → 3D Physics):
#
# Layer 1  (valor 1)   → GROUND       — chão e geometria estática do mundo
# Layer 2  (valor 2)   → PLAYER       — corpo físico do player
# Layer 3  (valor 4)   → ENEMY        — corpo físico dos inimigos
# Layer 4  (valor 8)   → INTERACTABLE — objetos interagíveis (madeira, lareira, cama)
# Layer 5  (valor 16)  → SAFE_ZONE    — área da safe zone
# Layer 6  (valor 32)  → ENEMY_VISION — visão dos inimigos (futuro sistema de detecção)
# Layer 7  (valor 64)  → PICKUP       — itens coletáveis no chão
# Layer 8  (valor 128) → LAMP         — cone/hitbox da lamparina
#
# Ao adicionar uma layer nova:
# 1. Configure primeiro em Project Settings → Layer Names → 3D Physics
# 2. Documente aqui com nome descritivo e valor correto
# 3. Use a constante em todos os scripts e cenas — nunca o número direto
# ==============================================================================

## Chão e geometria estática do mundo
const GROUND:       int = 1

## Corpo físico do player
const PLAYER:       int = 2

## Corpo físico dos inimigos
const ENEMY:        int = 4

## Objetos interagíveis (madeira, lareira, cama)
const INTERACTABLE: int = 8

## Área da safe zone
const SAFE_ZONE:    int = 16

## Visão dos inimigos — reservado para futuro sistema de detecção/stealth
const ENEMY_VISION: int = 32

## Itens coletáveis no chão
const PICKUP:       int = 64

## Cone e hitbox da lamparina
const LAMP:         int = 128

#endregion


# ==============================================================================
#region MÁSCARAS COMPOSTAS
# ------------------------------------------------------------------------------
# Combinações pré-definidas de layers para uso frequente.
# Evita repetir Layers.X | Layers.Y em vários lugares.
# ==============================================================================

## Máscara padrão do player — detecta chão, inimigos, interagíveis e pickups
const PLAYER_MASK: int = GROUND | ENEMY | INTERACTABLE | PICKUP

## Máscara dos inimigos — detecta chão, player e outros inimigos
const ENEMY_MASK: int = GROUND | PLAYER | ENEMY

## Máscara do raycast de spawn — detecta só o chão
const SPAWN_RAYCAST_MASK: int = GROUND

## Máscara da área de ataque do inimigo — detecta só o player
const ENEMY_ATTACK_MASK: int = PLAYER

## Máscara da safe zone — detecta só o player
const SAFE_ZONE_MASK: int = PLAYER

## Máscara do cone da lamparina — detecta só inimigos
const LANTERN_CONE_MASK: int = ENEMY

## Máscara da hurtbox dos inimigos — detecta a lamparina
const HURTBOX_MASK: int = LAMP

#endregion
