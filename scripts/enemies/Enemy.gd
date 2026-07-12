extends CharacterBody2D
class_name Enemy
## Base enemy class. Provides HP, hurtbox, simple AI hooks, knockback handling.
## Subclasses override _ai_think() to implement specific behavior.

signal hp_changed(cur: int, max_v: int)
signal died(enemy: Enemy)

@export_category("Stats")
@export var max_hp: int = 3
@export var move_speed: float = 80.0
@export var contact_damage: int = 1
@export var contact_knockback: float = 80.0
@export var invuln_after_hit: float = 0.2
@export var coins_on_death: int = 1
@export var gems_on_death: int = 0
@export var pickup_drop_chance: float = 0.1  # chance to drop a pickup

@export_category("AI")
@export var detection_range: float = 400.0
@export var attack_range: float = 30.0  # for melee contact
@export var attack_cooldown: float = 0.8

# ----- Internal -----
var _health: HealthComponent
var _hurtbox: Hurtbox
var _sprite: ColorRect
var _target: Node2D  # usually the Player
var _attack_timer: float = 0.0
var _is_dead: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _knockback_decay: float = 6.0  # higher = knockback stops faster
var _spawn_pos: Vector2

# Visuals
var _body_color: Color = Color(0.9, 0.3, 0.3, 1.0)
var _body_size: Vector2 = Vector2(36, 36)

func _ready() -> void:
        _health = $HealthComponent
        _hurtbox = $Hurtbox
        _health.max_hp = max_hp
        _health.current_hp = max_hp  # ensure HP matches the script's max_hp
        _health.max_armor = 0
        _health.invuln_time = invuln_after_hit
        _health.hp_changed.connect(func(c, m): emit_signal("hp_changed", c, m))
        _health.died.connect(_on_died)
        _health.damaged.connect(_on_damaged)
        _hurtbox.set_faction(&"enemy")
        _setup_visuals()
        _setup_collision()
        _spawn_pos = global_position
        # Find player
        _acquire_target()

func _setup_visuals() -> void:
        _sprite = ColorRect.new()
        _sprite.color = _body_color
        _sprite.size = _body_size
        _sprite.position = -_body_size * 0.5
        _sprite.z_index = 5
        add_child(_sprite)

func _setup_collision() -> void:
        # Body collision
        var col := CollisionShape2D.new()
        var shape := CircleShape2D.new()
        shape.radius = _body_size.x * 0.5
        col.shape = shape
        add_child(col)
        # Hurtbox
        var hb_col := CollisionShape2D.new()
        var hb_shape := CircleShape2D.new()
        hb_shape.radius = _body_size.x * 0.5
        hb_col.shape = hb_shape
        _hurtbox.add_child(hb_col)

func _acquire_target() -> void:
        var players := get_tree().get_nodes_in_group("player")
        if players.is_empty():
                _target = null
                return
        _target = players[0] as Node2D

func _physics_process(delta: float) -> void:
        if _is_dead:
                return
        if _target == null or not is_instance_valid(_target):
                _acquire_target()
        # AI think
        var ai_velocity: Vector2 = Vector2.ZERO
        if _target != null and is_instance_valid(_target):
                ai_velocity = _ai_think(delta)
        # Apply knockback decay (clamped to prevent overshoot at low FPS)
        _knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, clampf(_knockback_decay * delta, 0.0, 1.0))
        velocity = ai_velocity + _knockback_velocity
        # Contact damage
        if _target != null and is_instance_valid(_target):
                _check_contact_damage(delta)
        move_and_slide()

## Override in subclass. Returns desired velocity.
func _ai_think(_delta: float) -> Vector2:
        # Default: chase the player
        if _target == null:
                return Vector2.ZERO
        var to_target := _target.global_position - global_position
        var dist := to_target.length()
        if dist > attack_range * 0.7:
                return to_target.normalized() * move_speed
        return Vector2.ZERO

func _check_contact_damage(_delta: float) -> void:
        # attack_timer is decremented in _process
        if _attack_timer > 0.0:
                return
        # Check overlap with player
        if _target == null or not is_instance_valid(_target):
                return
        var to_target := _target.global_position - global_position
        if to_target.length() < attack_range:
                # Deal contact damage
                var health_comp = _target.get("_health")
                if health_comp is HealthComponent:
                        health_comp.take_damage(contact_damage)
                        # Apply knockback to player
                        _target.velocity += to_target.normalized() * contact_knockback
                _attack_timer = attack_cooldown

func _process(delta: float) -> void:
        if _is_dead:
                return
        if _attack_timer > 0.0:
                _attack_timer -= delta
        # Visual flash when invulnerable
        if _health.is_invulnerable():
                _sprite.modulate.a = 0.5 if fmod(Time.get_ticks_msec() * 0.01, 1.0) > 0.5 else 1.0
                _sprite.modulate.r = 2.0
                _sprite.modulate.g = 2.0
                _sprite.modulate.b = 2.0
        else:
                _sprite.modulate.a = 1.0
                _sprite.modulate.r = 1.0
                _sprite.modulate.g = 1.0
                _sprite.modulate.b = 1.0

func apply_knockback(dir: Vector2, force: float) -> void:
        _knockback_velocity = dir.normalized() * force

func _on_damaged(_amount: int, _reduced: int) -> void:
        # Brief red flash
        _sprite.modulate = Color(3, 3, 3, 1)

func _on_died() -> void:
        if _is_dead:
                return
        _is_dead = true
        _sprite.color = Color(0.3, 0.1, 0.1, 1.0)
        emit_signal("died", self)
        # Drop loot (deferred to avoid physics-state errors)
        call_deferred("_spawn_loot")
        # Death animation
        var tw := get_tree().create_tween()
        tw.tween_property(self, "modulate:a", 0.0, 0.3)
        tw.tween_callback(queue_free)

func _spawn_loot() -> void:
        # Coins
        if coins_on_death > 0:
                var coin_scene := load("res://scenes/entities/Coin.tscn")
                var num_coins: int = coins_on_death
                for i in range(num_coins):
                        var coin := coin_scene.instantiate() as Node2D
                        get_parent().add_child(coin)
                        coin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
        # Gems
        if gems_on_death > 0:
                var gem_scene := load("res://scenes/entities/Gem.tscn")
                var gem := gem_scene.instantiate() as Node2D
                get_parent().add_child(gem)
                gem.global_position = global_position
        # Random pickup drop
        if randf() < pickup_drop_chance:
                var pickup_scene := load("res://scenes/entities/Pickup.tscn")
                var pickup := pickup_scene.instantiate() as Node2D
                get_parent().add_child(pickup)
                pickup.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))

## Public method for spawners to set initial target.
func set_target(t: Node2D) -> void:
        _target = t

func take_damage(amount: int) -> int:
        return _health.take_damage(amount)
