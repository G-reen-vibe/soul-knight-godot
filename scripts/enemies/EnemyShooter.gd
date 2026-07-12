extends Enemy
class_name EnemyShooter
## Ranged enemy that keeps distance and fires bullets at the player.

@export var preferred_distance: float = 250.0
@export var shot_damage: int = 1
@export var shot_speed: float = 350.0
@export var shot_range: float = 400.0
@export var fire_rate: float = 1.0  # shots per second
@export var shot_color: Color = Color(1.0, 0.4, 0.3, 1.0)

var _fire_timer: float = 0.0

func _ready() -> void:
	max_hp = 2
	move_speed = 60.0
	contact_damage = 1
	contact_knockback = 60.0
	invuln_after_hit = 0.15
	coins_on_death = 1
	pickup_drop_chance = 0.15
	detection_range = 600.0
	attack_range = 28.0
	attack_cooldown = 0.6
	_body_color = Color(0.5, 0.7, 0.9, 1.0)
	_body_size = Vector2(32, 32)
	super._ready()
	add_to_group("enemy")

func _process(delta: float) -> void:
	super._process(delta)
	if _is_dead:
		return
	_fire_timer -= delta
	if _fire_timer <= 0.0 and _target != null and is_instance_valid(_target):
		var dist := global_position.distance_to(_target.global_position)
		if dist < detection_range:
			_fire_at(_target.global_position - global_position)
			_fire_timer = 1.0 / fire_rate

func _ai_think(_delta: float) -> Vector2:
	if _target == null:
		return Vector2.ZERO
	var to_target := _target.global_position - global_position
	var dist := to_target.length()
	# Try to maintain preferred distance
	if dist > preferred_distance + 30.0:
		return to_target.normalized() * move_speed
	elif dist < preferred_distance - 30.0:
		return -to_target.normalized() * move_speed
	else:
		# Strafe slowly
		var perp := Vector2(-to_target.y, to_target.x).normalized()
		return perp * move_speed * 0.5

func _fire_at(dir: Vector2) -> void:
	if dir.length_squared() < 0.001:
		return
	var proj_scene := load("res://scenes/projectiles/Projectile.tscn")
	var proj := proj_scene.instantiate() as Projectile
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + dir.normalized() * 20.0
	# Create a temp weapon data for the projectile
	var w := WeaponData.new()
	w.damage = shot_damage
	w.projectile_speed = shot_speed
	w.projectile_range = shot_range
	w.projectile_color = shot_color
	w.projectile_radius = 5.0
	w.knockback = 30.0
	proj.setup(w, dir, &"enemy")
