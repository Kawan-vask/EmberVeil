# EMBERVEIL

Survival Horror Roguelike First Person em Godot 4.6.2 / GDScript.

## Arquitetura
- 4 Autoloads: DebugManager → SignalBus → GameManager → Layers
- Comunicação cross-sistema: sempre via SignalBus (nunca referência direta)
- Dados configuráveis: sempre em Resources .tres (nunca hardcoded)
- Debug: sempre via DebugManager.log() e DebugManager.label()
- Componentes do player: HealthComponent, StaminaComponent, InventoryComponent

## Padrões obrigatórios
- Todo script usa #region / #endregion para organizar
- Type hints em todos os parâmetros e retornos
- Novos interagíveis herdam de Interactable e entram no grupo "interactable"
- UI nunca poleia valores em _process — reage a signals

## Estrutura de pastas
Scripts/Autoloads/ | Scripts/Player/Components/ | Scripts/Enemies/
Scripts/Interactables/ | Scripts/Systems/ | Scripts/UI/ | Scripts/Resources/
Resources/PowerUps/ | Resources/Lanternas/ | Resources/Shop/ | Resources/Dialogs/