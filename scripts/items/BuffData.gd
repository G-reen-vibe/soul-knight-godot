extends Resource
class_name BuffData
## A buff/passive effect that modifies player stats.

enum BuffType {
	MAX_HP_UP,       # +1 max HP
	MAX_ENERGY_UP,   # +20 max energy
	ENERGY_REGEN_UP, # +5 energy regen
	SPEED_UP,        # +10% move speed
	DAMAGE_UP,       # +1 damage to all weapons
	FIRE_RATE_UP,    # +20% fire rate
	MULTI_SHOT,      # +1 pellet to all weapons
	PIERCE_UP,       # +1 pierce to all weapons
	ARMOR_UP,        # +1 armor
	POTION_UP,       # +1 potion heal amount
	COIN_MAGNET,     # increases coin pickup range
	LIFESTEAL,       # heal 1 HP per N kills
}

@export var id: StringName = &"max_hp_up"
@export var display_name: String = "Max HP +1"
@export var description: String = "Increases maximum HP by 1."
@export var type: BuffType = BuffType.MAX_HP_UP
@export var value: int = 1
@export var color: Color = Color(0.4, 1, 0.4, 1)
