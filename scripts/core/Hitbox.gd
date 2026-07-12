extends Area2D
class_name Hitbox
## Deals damage to Hurtboxes it overlaps. Attach to bullets, melee swings, etc.
## Player weapons should set faction="player"; enemy attacks set faction="enemy".

@export var damage: int = 1
@export var faction: StringName = &"enemy"
@export var knockback: float = 80.0
@export var lifetime: float = 5.0  # auto-disable after this
@export var pierce: int = 0  # how many enemies it can hit before dying (0 = single hit)
@export var cooldown_per_target: float = 0.0  # if >0, can hit same target repeatedly

var _hits: Dictionary = {}  # hurtbox -> time until can hit again
var _pierce_remaining: int = 0
var _lifetime_left: float = 5.0
var _active: bool = true

signal hit_landed(hurtbox: Hurtbox, amount: int)
signal depleted

func _ready() -> void:
        _pierce_remaining = pierce
        _lifetime_left = lifetime
        # Hitbox on faction layer N, mask for opposing faction.
        collision_layer = 0
        collision_mask = _opposing_mask(faction)
        monitoring = true
        monitorable = false
        body_entered.connect(_on_body_entered)
        area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
        if not _active:
                return
        # Decay per-target cooldowns
        if not _hits.is_empty():
                var expired := []
                for key in _hits:
                        _hits[key] -= delta
                        if _hits[key] <= 0.0:
                                expired.append(key)
                for k in expired:
                        _hits.erase(k)
        if lifetime > 0.0:
                _lifetime_left -= delta
                if _lifetime_left <= 0.0:
                        deactivate()

func set_faction(f: StringName) -> void:
        faction = f
        collision_mask = _opposing_mask(f)

func activate() -> void:
        _active = true
        _lifetime_left = lifetime
        _pierce_remaining = pierce
        _hits.clear()
        monitoring = true
        set_deferred("monitoring", true)

func deactivate() -> void:
        _active = false
        monitoring = false
        set_deferred("monitoring", false)
        emit_signal("depleted")

func _opposing_mask(f: StringName) -> int:
        match f:
                &"player": return 2  # hit enemies (layer 2)
                &"enemy": return 1   # hit player (layer 1)
                _: return 0

func _on_body_entered(body: Node) -> void:
        _try_hit(body)

func _on_area_entered(area: Area2D) -> void:
        _try_hit(area)

func _try_hit(node: Node) -> void:
        if not _active:
                return
        if not (node is Hurtbox):
                return
        var hurtbox := node as Hurtbox
        if _hits.has(hurtbox) and cooldown_per_target > 0.0:
                return
        var attacker_id := get_instance_id()
        var dealt := hurtbox.take_hit(damage, attacker_id)
        if dealt > 0:
                emit_signal("hit_landed", hurtbox, dealt)
                _apply_knockback(hurtbox)
                if cooldown_per_target > 0.0:
                        _hits[hurtbox] = cooldown_per_target
                if _pierce_remaining > 0:
                        _pierce_remaining -= 1
                else:
                        deactivate()

func _apply_knockback(hurtbox: Hurtbox) -> void:
        if knockback <= 0.0:
                return
        var target := hurtbox.get_parent()
        if target is CharacterBody2D:
                var dir := (target.global_position - global_position).normalized()
                if dir.length_squared() < 0.001:
                        dir = Vector2.RIGHT
                (target as CharacterBody2D).velocity += dir * knockback
        elif target is RigidBody2D:
                var dir := (target.global_position - global_position).normalized()
                if dir.length_squared() < 0.001:
                        dir = Vector2.RIGHT
                (target as RigidBody2D).apply_impulse(dir * knockback * 2.0)
