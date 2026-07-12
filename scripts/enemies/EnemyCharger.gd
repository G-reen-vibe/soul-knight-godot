extends Enemy
class_name EnemyCharger
## Fast enemy that charges at the player.

@export var charge_speed: float = 280.0
@export var charge_duration: float = 0.6
@export var charge_cooldown: float = 2.5

var _charge_timer: float = 0.0
var _charge_cd_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO
var _is_charging: bool = false

func _ready() -> void:
	max_hp = 4
	move_speed = 70.0
	contact_damage = 2
	contact_knockback = 150.0
	invuln_after_hit = 0.1
	coins_on_death = 2
	pickup_drop_chance = 0.15
	detection_range = 600.0
	attack_range = 32.0
	attack_cooldown = 0.4
	_body_color = Color(0.9, 0.5, 0.2, 1.0)
	_body_size = Vector2(32, 32)
	super._ready()
	add_to_group("enemy")

func _process(delta: float) -> void:
	super._process(delta)
	if _is_dead:
		return
	if _is_charging:
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_is_charging = false
			_charge_cd_timer = charge_cooldown
	else:
		_charge_cd_timer -= delta
		if _charge_cd_timer <= 0.0 and _target != null and is_instance_valid(_target):
			var dist := global_position.distance_to(_target.global_position)
			if dist < detection_range:
				_start_charge()

func _start_charge() -> void:
	if _target == null:
		return
	_charge_dir = (_target.global_position - global_position).normalized()
	_is_charging = true
	_charge_timer = charge_duration

func _ai_think(_delta: float) -> Vector2:
	if _is_charging:
		return _charge_dir * charge_speed
	if _target == null:
		return Vector2.ZERO
	var to_target := _target.global_position - global_position
	return to_target.normalized() * move_speed
