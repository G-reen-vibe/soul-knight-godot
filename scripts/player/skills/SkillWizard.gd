extends Node
class_name SkillWizard
## Wizard's skill: releases a ring of fireballs in all directions.

const FIREBALL_COUNT: int = 12
const FIREBALL_SPEED: float = 400.0
const FIREBALL_DAMAGE: int = 2
const FIREBALL_RANGE: float = 350.0

func activate_skill(player: Player) -> void:
	# Spawn fireballs in a circle
	var scene := load("res://scenes/projectiles/Projectile.tscn")
	var w := WeaponData.new()
	w.damage = FIREBALL_DAMAGE
	w.projectile_speed = FIREBALL_SPEED
	w.projectile_range = FIREBALL_RANGE
	w.projectile_color = Color(1, 0.4, 0.2, 1)
	w.projectile_radius = 6.0
	w.knockback = 50.0
	w.pierce = 1
	for i in range(FIREBALL_COUNT):
		var angle := (float(i) / float(FIREBALL_COUNT)) * TAU
		var dir := Vector2(cos(angle), sin(angle))
		var proj := scene.instantiate() as Projectile
		player.get_tree().current_scene.add_child(proj)
		proj.global_position = player.global_position
		proj.setup(w, dir, &"player")
	# Brief invuln during cast
	player._health.invuln_timer = 0.5
