extends Area2D
class_name Hurtbox
## Receives damage from Hitboxes. Attach to any entity that can be hit.
## Forwards damage to a HealthComponent (assigned via `health_path` NodePath).

@export var health_path: NodePath = ^"../HealthComponent"
@export var faction: StringName = &"enemy"  # "player" or "enemy"
@export var hit_cooldown: float = 0.0  # 0 means every hit lands; > 0 enables per-attacker cooldown

var _health: HealthComponent
var _recent_hits: Dictionary = {}  # attacker_id -> time remaining

func _ready() -> void:
	if health_path != NodePath():
		_health = get_node_or_null(health_path)
	monitorable = true
	monitoring = false  # hurtboxes don't detect, they're detected by hitboxes
	collision_layer = _faction_layer(faction)
	collision_mask = 0

func _process(delta: float) -> void:
	if _recent_hits.is_empty():
		return
	var expired := []
	for key in _recent_hits:
		_recent_hits[key] -= delta
		if _recent_hits[key] <= 0.0:
			expired.append(key)
	for key in expired:
		_recent_hits.erase(key)

func set_faction(f: StringName) -> void:
	faction = f
	collision_layer = _faction_layer(f)

func _faction_layer(f: StringName) -> int:
	match f:
		&"player": return 1  # layer 1
		&"enemy": return 2   # layer 2
		_: return 4

func take_hit(amount: int, attacker_id: int = 0) -> int:
	if _health == null:
		_health = get_node_or_null(health_path)
	if _health == null:
		push_warning("Hurtbox has no HealthComponent at %s" % str(health_path))
		return 0
	if hit_cooldown > 0.0 and attacker_id != 0:
		if _recent_hits.has(attacker_id):
			return 0
		_recent_hits[attacker_id] = hit_cooldown
	return _health.take_damage(amount)
