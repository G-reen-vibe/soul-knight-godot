extends Node
class_name SkillRogue
## Rogue's skill: blink (teleport) a short distance in the aim direction.

const BLINK_DISTANCE: float = 220.0

func activate_skill(player: Player) -> void:
	# Save current position for visual
	var old_pos := player.global_position
	# Teleport
	var dir := player._aim_dir
	player.global_position += dir * BLINK_DISTANCE
	# Brief invuln
	player._health.invuln_timer = 0.4
	# Visual: trail from old to new
	_spawn_trail(player, old_pos, player.global_position)

func _spawn_trail(player: Player, from: Vector2, to: Vector2) -> void:
	var trail := Line2D.new()
	trail.width = 8.0
	trail.default_color = Color(0.7, 0.4, 1.0, 0.8)
	trail.z_index = 4
	trail.add_point(from)
	trail.add_point(to)
	player.get_tree().current_scene.add_child(trail)
	var tw := player.get_tree().create_tween()
	tw.tween_property(trail, "modulate:a", 0.0, 0.3)
	tw.tween_callback(trail.queue_free)
