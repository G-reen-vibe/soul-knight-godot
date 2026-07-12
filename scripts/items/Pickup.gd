extends Area2D
class_name Pickup
## Base pickup. Player walks over to collect. Subclass or set pickup_kind.

enum Kind { COIN, GEM, HEALTH_POTION, ENERGY_POTION, BUFF, WEAPON }

@export var kind: Kind = Kind.COIN
@export var value: int = 1
@export var magnet_range: float = 80.0
@export var collect_range: float = 22.0
@export var magnet_speed: float = 280.0
@export var bob_height: float = 4.0
@export var bob_speed: float = 3.0

var _player: Node2D
var _being_magnetized: bool = false
var _being_collected: bool = false
var _spawn_y: float = 0.0
var _time: float = 0.0
var _sprite: ColorRect

signal collected(kind: int, value: int)

func _ready() -> void:
        # Collision: pickup is on layer 8, mask = 1 (player)
        collision_layer = 8
        collision_mask = 1
        monitoring = true
        monitorable = false
        var col := CollisionShape2D.new()
        var shape := CircleShape2D.new()
        shape.radius = collect_range
        col.shape = shape
        add_child(col)
        _sprite = ColorRect.new()
        _sprite.color = _color_for_kind()
        _sprite.size = Vector2(14, 14)
        _sprite.position = Vector2(-7, -7)
        _sprite.z_index = 5
        add_child(_sprite)
        _spawn_y = global_position.y
        body_entered.connect(_on_body_entered)

func _color_for_kind() -> Color:
        match kind:
                Kind.COIN: return Color(1, 0.85, 0.2, 1)
                Kind.GEM: return Color(0.4, 1, 0.8, 1)
                Kind.HEALTH_POTION: return Color(1, 0.3, 0.4, 1)
                Kind.ENERGY_POTION: return Color(0.4, 0.7, 1, 1)
                Kind.BUFF: return Color(0.9, 0.6, 1, 1)
                _: return Color.WHITE

func _process(delta: float) -> void:
        _time += delta
        # Bob up and down
        if _sprite:
                _sprite.position.y = -7 + sin(_time * bob_speed) * bob_height
        # Find player if needed
        if _player == null or not is_instance_valid(_player):
                var players := get_tree().get_nodes_in_group("player")
                if not players.is_empty():
                        _player = players[0] as Node2D
                return
        var to_player := _player.global_position - global_position
        var dist := to_player.length()
        if dist < collect_range:
                _collect()
        elif dist < magnet_range or _being_magnetized:
                _being_magnetized = true
                global_position += to_player.normalized() * magnet_speed * delta

func _on_body_entered(body: Node) -> void:
        if body.is_in_group("player"):
                _collect()

func _collect() -> void:
        if _being_collected:
                return
        _being_collected = true
        emit_signal("collected", kind, value)
        _apply_effect()
        _play_collect_anim()

func _apply_effect() -> void:
        if _player == null or not is_instance_valid(_player):
                return
        match kind:
                Kind.COIN:
                        _player.add_coins(value)
                        Global.add_coins(value)
                Kind.GEM:
                        Global.add_gems(value)
                Kind.HEALTH_POTION:
                        var health_comp = _player.get("_health")
                        if health_comp is HealthComponent:
                                health_comp.heal(value)
                Kind.ENERGY_POTION:
                        _player._current_energy = min(_player.max_energy, _player._current_energy + value)
                        _player.emit_signal("energy_changed", int(_player._current_energy), _player.max_energy)
                Kind.BUFF:
                        _apply_buff()
                Kind.WEAPON:
                        # Handled by spawning a weapon pickup that the player can interact with
                        pass

func _apply_buff() -> void:
        # Placeholder: add max HP
        if _player and is_instance_valid(_player):
                _player._health.set_max_hp(_player._health.max_hp + value, false)
                _player._health.heal(value)

func _play_collect_anim() -> void:
        if _sprite == null:
                queue_free()
                return
        # Quick pop and fade
        set_deferred("monitoring", false)
        set_deferred("collision_layer", 0)
        set_deferred("collision_mask", 0)
        var tw := get_tree().create_tween()
        tw.tween_property(_sprite, "scale", Vector2(2.5, 2.5), 0.1)
        tw.tween_property(_sprite, "modulate:a", 0.0, 0.15)
        tw.tween_callback(queue_free)
