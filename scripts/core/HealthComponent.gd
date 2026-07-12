extends Node
class_name HealthComponent
## Reusable health/armor tracker for player & enemies.
## Emits signals on damage/heal/death. Parent must set max_hp before use.

@export var max_hp: int = 5
@export var max_armor: int = 0
@export var invuln_time: float = 0.6  # seconds of i-frames after taking damage
@export var is_invuln_during_flash: bool = true

signal hp_changed(current: int, maximum: int)
signal armor_changed(current: int, maximum: int)
signal damaged(amount: int, reduced: int)
signal healed(amount: int)
signal died

var current_hp: int = 5
var current_armor: int = 0
var invuln_timer: float = 0.0
var is_dead: bool = false

func _ready() -> void:
        current_hp = max_hp
        current_armor = max_armor
        emit_signal("hp_changed", current_hp, max_hp)
        emit_signal("armor_changed", current_armor, max_armor)

func _process(delta: float) -> void:
        if invuln_timer > 0.0:
                invuln_timer = max(0.0, invuln_timer - delta)

func is_invulnerable() -> bool:
        return invuln_timer > 0.0 and is_invuln_during_flash

## Apply damage. Returns the actual HP lost (after armor).
func take_damage(amount: int) -> int:
        if is_dead or amount <= 0:
                return 0
        if is_invulnerable():
                return 0

        var actual: int = amount
        var reduced: int = 0
        if current_armor > 0:
                reduced = min(current_armor, actual)
                current_armor -= reduced
                actual -= reduced
                emit_signal("armor_changed", current_armor, max_armor)

        var hp_loss: int = min(current_hp, actual)
        current_hp -= hp_loss
        emit_signal("damaged", amount, reduced)
        emit_signal("hp_changed", current_hp, max_hp)

        if invuln_time > 0.0:
                invuln_timer = invuln_time

        if current_hp <= 0:
                is_dead = true
                emit_signal("died")
        return hp_loss

func heal(amount: int) -> int:
        if is_dead or amount <= 0:
                return 0
        var before := current_hp
        current_hp = min(max_hp, current_hp + amount)
        var actual := current_hp - before
        if actual > 0:
                emit_signal("healed", actual)
                emit_signal("hp_changed", current_hp, max_hp)
        return actual

func add_armor(amount: int) -> void:
        current_armor = min(max_armor, current_armor + amount) if max_armor > 0 else current_armor + amount
        if max_armor == 0:
                max_armor = current_armor
        emit_signal("armor_changed", current_armor, max_armor)

func revive_full() -> void:
        current_hp = max_hp
        current_armor = max_armor
        is_dead = false
        invuln_timer = 0.0
        emit_signal("hp_changed", current_hp, max_hp)
        emit_signal("armor_changed", current_armor, max_armor)

func set_max_hp(new_max: int, heal_to_full: bool = false) -> void:
        max_hp = new_max
        if heal_to_full or current_hp > max_hp:
                current_hp = max_hp
        emit_signal("hp_changed", current_hp, max_hp)
