extends Enemy
class_name BossEnemy
## A boss with multiple attack patterns and high HP.

@export var phase: int = 1
@export var phase_2_threshold: float = 0.5  # 50% HP triggers phase 2
@export var phase_3_threshold: float = 0.25

@export_category("Attacks")
@export var spray_fire_rate: float = 0.4
@export var burst_fire_rate: float = 2.0
@export var charge_speed: float = 350.0
@export var charge_duration: float = 0.8

var _boss_attack_timer: float = 0.0
var _current_pattern: int = 0
var _is_charging: bool = false
var _charge_timer: float = 0.0
var _charge_dir: Vector2 = Vector2.ZERO

func _ready() -> void:
        max_hp = 25
        move_speed = 50.0
        contact_damage = 2
        contact_knockback = 150.0
        invuln_after_hit = 0.05
        coins_on_death = 10
        gems_on_death = 1
        pickup_drop_chance = 1.0  # always drops something
        detection_range = 1000.0
        attack_range = 40.0
        attack_cooldown = 0.5
        _body_color = Color(0.8, 0.2, 0.3, 1.0)
        _body_size = Vector2(64, 64)
        super._ready()
        add_to_group("enemy")
        add_to_group("boss")

func _process(delta: float) -> void:
        super._process(delta)
        if _is_dead:
                return
        # Phase transitions
        var hp_ratio: float = float(_health.current_hp) / float(_health.max_hp)
        if phase == 1 and hp_ratio < phase_2_threshold:
                phase = 2
                _body_color = Color(1.0, 0.4, 0.2, 1.0)
                _sprite.color = _body_color
        elif phase == 2 and hp_ratio < phase_3_threshold:
                phase = 3
                _body_color = Color(1.0, 0.1, 0.1, 1.0)
                _sprite.color = _body_color
        # Attack pattern logic
        _boss_attack_timer -= delta
        if _is_charging:
                _charge_timer -= delta
                if _charge_timer <= 0.0:
                        _is_charging = false
                return
        if _boss_attack_timer <= 0.0:
                _choose_attack()
                _boss_attack_timer = _get_attack_cooldown()

func _ai_think(_delta: float) -> Vector2:
        if _is_charging:
                return _charge_dir * charge_speed
        if _target == null:
                return Vector2.ZERO
        var to_target := _target.global_position - global_position
        var dist := to_target.length()
        # Maintain medium distance in phases 1-2, charge in phase 3
        if phase == 3:
                return to_target.normalized() * move_speed * 1.5
        if dist > 250.0:
                return to_target.normalized() * move_speed
        elif dist < 150.0:
                return -to_target.normalized() * move_speed
        return Vector2.ZERO

func _get_attack_cooldown() -> float:
        match phase:
                1: return spray_fire_rate
                2: return burst_fire_rate * 0.5
                3: return 0.6
                _: return 1.0

func _choose_attack() -> void:
        if _target == null or not is_instance_valid(_target):
                return
        match phase:
                1:
                        _spray_attack()
                2:
                        _burst_attack()
                3:
                        _charge_attack()

func _spray_attack() -> void:
        # Fire bullets in a circle
        var scene := load("res://scenes/projectiles/Projectile.tscn")
        var w := WeaponData.new()
        w.damage = 1
        w.projectile_speed = 250.0
        w.projectile_range = 400.0
        w.projectile_color = Color(1, 0.5, 0.3)
        w.projectile_radius = 5.0
        w.knockback = 30.0
        var count: int = 8
        for i in range(count):
                var angle := (float(i) / float(count)) * TAU
                var dir := Vector2(cos(angle), sin(angle))
                var proj := scene.instantiate() as Projectile
                get_tree().current_scene.add_child(proj)
                proj.global_position = global_position
                proj.setup(w, dir, &"enemy")

func _burst_attack() -> void:
        # Fire a burst of bullets toward the player
        if _target == null:
                return
        var scene := load("res://scenes/projectiles/Projectile.tscn")
        var w := WeaponData.new()
        w.damage = 1
        w.projectile_speed = 400.0
        w.projectile_range = 500.0
        w.projectile_color = Color(1, 0.4, 0.2)
        w.projectile_radius = 6.0
        w.knockback = 50.0
        var dir: Vector2 = (_target.global_position - global_position).normalized()
        for i in range(5):
                var spread: float = deg_to_rad(15.0)
                var t := (float(i) + 0.5) / 5.0
                var angle_offset := lerpf(-spread * 0.5, spread * 0.5, t)
                var proj := scene.instantiate() as Projectile
                get_tree().current_scene.add_child(proj)
                proj.global_position = global_position
                proj.setup(w, dir.rotated(angle_offset), &"enemy")

func _charge_attack() -> void:
        if _target == null:
                return
        _charge_dir = (_target.global_position - global_position).normalized()
        _is_charging = true
        _charge_timer = charge_duration
