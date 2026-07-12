extends Node
class_name SkillAlchemist
## Alchemist's skill: drops a poison bomb that damages enemies in an area over time.

const POISON_RADIUS: float = 130.0
const POISON_DURATION: float = 4.0
const POISON_TICK: float = 0.5
const POISON_DAMAGE_PER_TICK: int = 1

func activate_skill(player: Player) -> void:
        # Drop a poison cloud at player's position
        var cloud := Node2D.new()
        cloud.global_position = player.global_position
        player.get_tree().current_scene.add_child(cloud)
        # Visual
        var vis := ColorRect.new()
        vis.color = Color(0.4, 0.9, 0.3, 0.35)
        vis.size = Vector2(POISON_RADIUS * 2, POISON_RADIUS * 2)
        vis.position = Vector2(-POISON_RADIUS, -POISON_RADIUS)
        vis.z_index = 3
        cloud.add_child(vis)
        # Mark cloud with a meta so we can find it in tests
        cloud.set_meta("is_poison_cloud", true)
        # Damage tick loop using a Timer
        var timer_node := Timer.new()
        timer_node.wait_time = POISON_TICK
        timer_node.autostart = true
        cloud.add_child(timer_node)
        var time_elapsed: float = 0.0
        while time_elapsed < POISON_DURATION and is_instance_valid(cloud):
                await player.get_tree().create_timer(POISON_TICK).timeout
                time_elapsed += POISON_TICK
                if is_instance_valid(cloud):
                        _apply_damage(cloud.global_position)
        # Fade out
        if is_instance_valid(cloud):
                var tw := player.get_tree().create_tween()
                tw.tween_property(vis, "modulate:a", 0.0, 0.5)
                tw.tween_callback(cloud.queue_free)

func _apply_damage(center: Vector2) -> void:
        var enemies := player_get_enemies()
        for enemy in enemies:
                if not is_instance_valid(enemy):
                        continue
                var dist: float = enemy.global_position.distance_to(center)
                if dist <= POISON_RADIUS:
                        var health_comp = enemy.get("_health")
                        if health_comp is HealthComponent:
                                health_comp.take_damage(POISON_DAMAGE_PER_TICK)

func player_get_enemies() -> Array:
        # Helper to get all enemies in the scene
        var scene := Engine.get_main_loop() as SceneTree
        if scene == null:
                return []
        return scene.current_scene.get_tree().get_nodes_in_group("enemy")
