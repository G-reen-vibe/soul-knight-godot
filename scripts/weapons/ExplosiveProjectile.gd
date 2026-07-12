extends Projectile
class_name ExplosiveProjectile
## A projectile that explodes on impact, dealing area damage.

@export var explosion_radius: float = 100.0
@export var explosion_damage: int = 3
@export var explosion_knockback: float = 200.0

func _resolve_hit(node: Node) -> void:
        if _dead:
                return
        # Always explode on hit (don't pierce)
        _spawn_explosion()
        _die()

func _die() -> void:
        if _dead:
                return
        _dead = true
        # Don't queue_free yet; let the explosion finish first
        set_deferred("monitoring", false)
        # Hide the projectile
        if _visual:
                _visual.visible = false
        # Wait briefly then free
        var tw := get_tree().create_tween()
        tw.tween_interval(0.05)
        tw.tween_callback(queue_free)

func _spawn_explosion() -> void:
        if not is_instance_valid(get_parent()):
                return
        # Visual: expanding circle
        var explosion := Node2D.new()
        explosion.global_position = global_position
        get_parent().add_child(explosion)
        var vis := ColorRect.new()
        vis.color = Color(1, 0.6, 0.2, 0.7)
        vis.size = Vector2(20, 20)
        vis.position = Vector2(-10, -10)
        vis.z_index = 7
        explosion.add_child(vis)
        var tw := get_tree().create_tween()
        tw.tween_property(vis, "size", Vector2(explosion_radius * 2, explosion_radius * 2), 0.2)
        tw.parallel().tween_property(vis, "position", Vector2(-explosion_radius, -explosion_radius), 0.2)
        tw.parallel().tween_property(vis, "modulate:a", 0.0, 0.25)
        tw.tween_callback(explosion.queue_free)
        # Damage: find all enemies in radius
        var enemies := get_tree().get_nodes_in_group("enemy")
        for enemy in enemies:
                if not is_instance_valid(enemy):
                        continue
                var dist: float = enemy.global_position.distance_to(global_position)
                if dist <= explosion_radius:
                        # Apply damage with falloff
                        var falloff: float = 1.0 - (dist / explosion_radius) * 0.5
                        var dmg: int = max(1, int(round(explosion_damage * falloff)))
                        var health_comp = enemy.get("_health")
                        if health_comp is HealthComponent:
                                health_comp.take_damage(dmg)
                                # Knockback
                                var dir: Vector2 = (enemy.global_position - global_position).normalized()
                                if enemy is CharacterBody2D:
                                        (enemy as CharacterBody2D).velocity += dir * explosion_knockback * falloff
        # Also damage the player if close (and projectile is enemy)
        if faction == &"enemy":
                var players := get_tree().get_nodes_in_group("player")
                for p in players:
                        if not is_instance_valid(p):
                                continue
                        var dist: float = p.global_position.distance_to(global_position)
                        if dist <= explosion_radius:
                                var falloff: float = 1.0 - (dist / explosion_radius) * 0.5
                                var dmg: int = max(1, int(round(explosion_damage * falloff)))
                                var health_comp = p.get("_health")
                                if health_comp is HealthComponent:
                                        health_comp.take_damage(dmg)
