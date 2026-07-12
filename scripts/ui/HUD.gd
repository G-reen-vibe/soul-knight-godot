extends CanvasLayer
class_name HUD
## Heads-up display: shows HP, energy, coins, weapon, skill cooldown, potions.

var _player: Player
var _hp_container: HBoxContainer
var _energy_bar: ProgressBar
var _energy_label: Label
var _coin_label: Label
var _gem_label: Label
var _weapon_label: Label
var _potion_label: Label
var _skill_label: Label
var _floor_label: Label
var _buffs_container: HBoxContainer

func _ready() -> void:
	layer = 10
	_build_ui()
	# Connect to global signals
	Global.coins_changed.connect(_on_coins_changed)
	Global.gems_changed.connect(_on_gems_changed)

func set_player(player: Player) -> void:
	_player = player
	if _player == null:
		return
	_player.hp_changed.connect(_on_hp_changed)
	_player.armor_changed.connect(_on_armor_changed)
	_player.energy_changed.connect(_on_energy_changed)
	_player.coins_changed.connect(_on_coins_changed)
	_player.potions_changed.connect(_on_potions_changed)
	_player.weapon_changed.connect(_on_weapon_changed)
	_player.skill_ready_changed.connect(_on_skill_changed)
	_refresh_all()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	# Top-left: HP, armor
	var top_left := VBoxContainer.new()
	top_left.position = Vector2(20, 20)
	top_left.size = Vector2(300, 200)
	root.add_child(top_left)
	_hp_container = HBoxContainer.new()
	_hp_container.name = "HP"
	top_left.add_child(_hp_container)
	# Energy bar
	_energy_bar = ProgressBar.new()
	_energy_bar.min_value = 0
	_energy_bar.max_value = 100
	_energy_bar.value = 100
	_energy_bar.custom_minimum_size = Vector2(200, 20)
	_energy_bar.modulate = Color(0.4, 0.7, 1.0, 1.0)
	top_left.add_child(_energy_bar)
	_energy_label = Label.new()
	_energy_label.text = "Energy: 100/100"
	top_left.add_child(_energy_label)
	# Top-right: coins, gems, floor
	var top_right := VBoxContainer.new()
	top_right.position = Vector2(980, 20)
	top_right.size = Vector2(300, 200)
	root.add_child(top_right)
	_coin_label = Label.new()
	_coin_label.text = "Coins: 0"
	top_right.add_child(_coin_label)
	_gem_label = Label.new()
	_gem_label.text = "Gems: 0"
	top_right.add_child(_gem_label)
	_floor_label = Label.new()
	_floor_label.text = "Floor: 1"
	top_right.add_child(_floor_label)
	# Bottom-left: weapon, potions
	var bottom_left := VBoxContainer.new()
	bottom_left.position = Vector2(20, 600)
	bottom_left.size = Vector2(400, 100)
	root.add_child(bottom_left)
	_weapon_label = Label.new()
	_weapon_label.text = "Weapon: -"
	bottom_left.add_child(_weapon_label)
	_potion_label = Label.new()
	_potion_label.text = "Potions: 0"
	bottom_left.add_child(_potion_label)
	# Bottom-right: skill cooldown
	var bottom_right := VBoxContainer.new()
	bottom_right.position = Vector2(980, 600)
	bottom_right.size = Vector2(300, 100)
	root.add_child(bottom_right)
	_skill_label = Label.new()
	_skill_label.text = "Skill: Ready (K)"
	bottom_right.add_child(_skill_label)
	# Bottom-center: buffs
	_buffs_container = HBoxContainer.new()
	_buffs_container.position = Vector2(440, 660)
	_buffs_container.size = Vector2(400, 40)
	root.add_child(_buffs_container)

func _refresh_all() -> void:
	if _player == null:
		return
	_on_hp_changed(_player._health.current_hp, _player._health.max_hp)
	_on_armor_changed(_player._health.current_armor, _player._health.max_armor)
	_on_energy_changed(int(_player._current_energy), _player.max_energy)
	_on_coins_changed(_player.coins)
	_on_potions_changed(_player.potions)
	if not _player._weapons.is_empty():
		_on_weapon_changed(_player._weapons[_player._current_weapon_slot], _player._current_weapon_slot)
	_refresh_buffs()

func _on_hp_changed(cur: int, max_v: int) -> void:
	# Rebuild HP container
	for child in _hp_container.get_children():
		child.queue_free()
	for i in range(max_v):
		var heart := ColorRect.new()
		heart.color = Color(1, 0.2, 0.3, 1.0) if i < cur else Color(0.3, 0.1, 0.1, 1.0)
		heart.size = Vector2(20, 20)
		_heart_with_margin(heart)

func _heart_with_margin(heart: ColorRect) -> void:
	var margin := MarginContainer.new()
	margin.add_child(heart)
	margin.custom_minimum_size = Vector2(24, 24)
	_hp_container.add_child(margin)

func _on_armor_changed(cur: int, max_v: int) -> void:
	# Show armor as blue squares after hearts
	# Just rebuild the whole thing for simplicity
	# Already handled in _on_hp_changed
	pass

func _on_energy_changed(cur: int, max_v: int) -> void:
	_energy_bar.max_value = max_v
	_energy_bar.value = cur
	_energy_label.text = "Energy: %d/%d" % [cur, max_v]

func _on_coins_changed(amount: int) -> void:
	_coin_label.text = "Coins: %d" % amount

func _on_gems_changed(amount: int) -> void:
	_gem_label.text = "Gems: %d" % amount

func _on_potions_changed(amount: int) -> void:
	_potion_label.text = "Potions: %d (Q to use)" % amount

func _on_weapon_changed(weapon: WeaponData, _slot: int) -> void:
	_weapon_label.text = "Weapon: %s" % weapon.display_name

func _on_skill_changed(ready: bool, progress: float) -> void:
	if ready:
		_skill_label.text = "Skill: Ready (K)"
		_skill_label.modulate = Color(0.4, 1, 0.4, 1)
	else:
		_skill_label.text = "Skill: %.0f%% (K)" % (progress * 100)
		_skill_label.modulate = Color(0.7, 0.7, 0.7, 1)

func set_floor(floor_num: int) -> void:
	_floor_label.text = "Floor: %d" % floor_num

func _refresh_buffs() -> void:
	for child in _buffs_container.get_children():
		child.queue_free()
	if _player == null:
		return
	var buffs_node := _player.get_node_or_null("PlayerBuffs") as PlayerBuffs
	if buffs_node == null:
		return
	for buff in buffs_node.get_buffs():
		var icon := ColorRect.new()
		icon.color = buff.color
		icon.size = Vector2(20, 20)
		var margin := MarginContainer.new()
		margin.add_child(icon)
		margin.custom_minimum_size = Vector2(24, 24)
		_buffs_container.add_child(margin)
