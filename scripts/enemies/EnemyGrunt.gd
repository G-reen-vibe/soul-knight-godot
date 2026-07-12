extends Enemy
class_name EnemyGrunt
## Basic melee chaser. Walks toward the player and rams them.

func _ready() -> void:
	# Customize before super._ready sets up HP/visuals
	max_hp = 3
	move_speed = 90.0
	contact_damage = 1
	contact_knockback = 100.0
	invuln_after_hit = 0.15
	coins_on_death = 1
	pickup_drop_chance = 0.1
	detection_range = 500.0
	attack_range = 36.0
	attack_cooldown = 0.8
	_body_color = Color(0.85, 0.35, 0.35, 1.0)
	_body_size = Vector2(34, 34)
	super._ready()
	add_to_group("enemy")
