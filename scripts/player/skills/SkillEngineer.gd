extends Node
class_name SkillEngineer
## Engineer's skill: deploys a temporary turret that fires at enemies.

const TURRET_DURATION: float = 8.0
const TURRET_FIRE_RATE: float = 3.0
const TURRET_DAMAGE: int = 1
const TURRET_RANGE: float = 350.0
const TURRET_PROJ_SPEED: float = 600.0

func activate_skill(player: Player) -> void:
        var turret := Node2D.new()
        turret.global_position = player.global_position + Vector2(40, 0)
        player.get_tree().current_scene.add_child(turret)
        turret.set_meta("is_turret", true)
        # Visual
        var body := ColorRect.new()
        body.color = Color(0.7, 0.7, 0.7, 1.0)
        body.size = Vector2(28, 28)
        body.position = Vector2(-14, -14)
        body.z_index = 5
        turret.add_child(body)
        var barrel := ColorRect.new()
        barrel.color = Color(0.3, 0.3, 0.3, 1.0)
        barrel.size = Vector2(20, 6)
        barrel.position = Vector2(0, -3)
        barrel.z_index = 6
        turret.add_child(barrel)
        # Turret behavior
        var timer: float = 0.0
        var fire_timer: float = 0.0
        var tick: float = 0.1
        while timer < TURRET_DURATION and is_instance_valid(turret):
                await player.get_tree().create_timer(tick).timeout
                timer += tick
                fire_timer += tick
                if fire_timer >= 1.0 / TURRET_FIRE_RATE:
                        fire_timer = 0.0
                        _fire_at_nearest_enemy(turret)
        # Fade out
        if is_instance_valid(turret):
                var tw := player.get_tree().create_tween()
                tw.tween_property(turret, "modulate:a", 0.0, 0.5)
                tw.tween_callback(turret.queue_free)

func _fire_at_nearest_enemy(turret: Node2D) -> void:
        var enemies := turret.get_tree().get_nodes_in_group("enemy")
        var nearest: Node2D = null
        var min_dist: float = TURRET_RANGE
        for e in enemies:
                if not is_instance_valid(e):
                        continue
                var d: float = e.global_position.distance_to(turret.global_position)
                if d < min_dist:
                        min_dist = d
                        nearest = e
        if nearest == null:
                return
        var dir: Vector2 = (nearest.global_position - turret.global_position).normalized()
        var scene := load("res://scenes/projectiles/Projectile.tscn")
        var proj := scene.instantiate() as Projectile
        turret.get_tree().current_scene.add_child(proj)
        proj.global_position = turret.global_position + dir * 20.0
        var w := WeaponData.new()
        w.damage = TURRET_DAMAGE
        w.projectile_speed = TURRET_PROJ_SPEED
        w.projectile_range = TURRET_RANGE
        w.projectile_color = Color(0.6, 0.9, 1.0, 1)
        w.projectile_radius = 4.0
        w.knockback = 20.0
        proj.setup(w, dir, &"player")
