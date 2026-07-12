extends Node
class_name SkillKnight
## Knight's skill: temporary shield (invulnerability + speed boost) for 2s.

func activate_skill(player: Player) -> void:
	var health: HealthComponent = player._health
	health.invuln_timer = 2.0
	var orig_speed := player.move_speed
	player.move_speed *= 1.5
	# Visual effect: blue aura
	_spawn_aura(player, Color(0.3, 0.7, 1.0, 0.4))
	await player.get_tree().create_timer(2.0).timeout
	if is_instance_valid(player):
		player.move_speed = orig_speed

func _spawn_aura(player: Player, color: Color) -> void:
	var aura := ColorRect.new()
	aura.color = color
	aura.size = Vector2(60, 60)
	aura.position = Vector2(-30, -30)
	aura.z_index = 3
	player.add_child(aura)
	var tw := player.get_tree().create_tween()
	tw.tween_property(aura, "modulate:a", 0.0, 2.0)
	tw.tween_callback(aura.queue_free)
