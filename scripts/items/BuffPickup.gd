extends Pickup
class_name BuffPickup
## A pickup that grants a random buff when collected.

@export var buff_pool: Array[BuffData] = []

func _ready() -> void:
	# Override kind
	kind = Kind.BUFF
	value = 1
	super._ready()
	# Load buff pool if empty
	if buff_pool.is_empty():
		_load_default_pool()

func _load_default_pool() -> void:
	var paths := [
		"res://data/buffs/max_hp_up.tres",
		"res://data/buffs/damage_up.tres",
		"res://data/buffs/fire_rate_up.tres",
		"res://data/buffs/multi_shot.tres",
		"res://data/buffs/speed_up.tres",
		"res://data/buffs/armor_up.tres",
		"res://data/buffs/lifesteal.tres",
	]
	for p in paths:
		var b := load(p) as BuffData
		if b:
			buff_pool.append(b)

func _apply_effect() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	# Pick a random buff
	if buff_pool.is_empty():
		_load_default_pool()
	if buff_pool.is_empty():
		return
	var buff: BuffData = buff_pool[Global.rng().randi() % buff_pool.size()]
	# Apply to player's buff manager
	var buffs_node := _player.get_node_or_null("PlayerBuffs") as PlayerBuffs
	if buffs_node == null:
		buffs_node = PlayerBuffs.new()
		buffs_node.name = "PlayerBuffs"
		_player.add_child(buffs_node)
	buffs_node.add_buff(buff.duplicate(true))
	print("[BuffPickup] Player gained buff: %s" % buff.display_name)
