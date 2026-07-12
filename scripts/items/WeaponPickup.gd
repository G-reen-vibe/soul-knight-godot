extends Pickup
class_name WeaponPickup
## A pickup that gives the player a weapon when collected.

@export var weapon_data: WeaponData = null
@export var weapon_id: StringName = &""  # if set, load from data/weapons/<id>.tres

func _ready() -> void:
	kind = Kind.WEAPON
	super._ready()
	# Load weapon if not set
	if weapon_data == null and weapon_id != &"":
		weapon_data = load("res://data/weapons/%s.tres" % weapon_id) as WeaponData

func _apply_effect() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if weapon_data == null:
		return
	_player.pickup_weapon(weapon_data.duplicate(true))
	print("[WeaponPickup] Player picked up: %s" % weapon_data.display_name)
