extends Node
class_name PlayerBuffs
## Manages buffs applied to a player. Attach as a child of Player.

var _buffs: Array[BuffData] = []
var _player: Player
var _lifesteal_counter: int = 0
var _lifesteal_threshold: int = 5  # heal every 5 kills

signal buff_added(buff: BuffData)
signal buff_removed(buff: BuffData)

func _ready() -> void:
	_player = get_parent() as Player

func add_buff(buff: BuffData) -> void:
	_buffs.append(buff)
	_apply_buff(buff)
	emit_signal("buff_added", buff)

func remove_buff(buff: BuffData) -> void:
	_buffs.erase(buff)
	# Note: removing a buff doesn't un-apply stat changes (we'd need to track and recalculate)
	emit_signal("buff_removed", buff)

func get_buffs() -> Array[BuffData]:
	return _buffs

func _apply_buff(buff: BuffData) -> void:
	if _player == null:
		return
	match buff.type:
		BuffData.BuffType.MAX_HP_UP:
			_player._health.set_max_hp(_player._health.max_hp + buff.value, false)
		BuffData.BuffType.MAX_ENERGY_UP:
			_player.max_energy += buff.value * 20
		BuffData.BuffType.ENERGY_REGEN_UP:
			_player.energy_regen += buff.value * 5.0
		BuffData.BuffType.SPEED_UP:
			_player.move_speed *= 1.0 + 0.1 * buff.value
		BuffData.BuffType.DAMAGE_UP:
			for w in _player._weapons:
				w.damage += buff.value
		BuffData.BuffType.FIRE_RATE_UP:
			for w in _player._weapons:
				w.fire_rate *= 1.0 + 0.2 * buff.value
		BuffData.BuffType.MULTI_SHOT:
			for w in _player._weapons:
				w.pellets += buff.value
		BuffData.BuffType.PIERCE_UP:
			for w in _player._weapons:
				w.pierce += buff.value
		BuffData.BuffType.ARMOR_UP:
			_player._health.max_armor += buff.value
			_player._health.current_armor += buff.value
		BuffData.BuffType.POTION_UP:
			_player.potion_heal_amount += buff.value
		BuffData.BuffType.COIN_MAGNET:
			# Apply via player's magnet range (we'd need to expose this)
			pass
		BuffData.BuffType.LIFESTEAL:
			# Mark player as having lifesteal; handled on enemy death
			_player.set_meta("lifesteal_active", true)

func on_enemy_killed() -> void:
	if not _player.has_meta("lifesteal_active"):
		return
	_lifesteal_counter += 1
	if _lifesteal_counter >= _lifesteal_threshold:
		_lifesteal_counter = 0
		_player._health.heal(1)
