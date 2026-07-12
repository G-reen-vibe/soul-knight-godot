extends CharacterBody2D
class_name TargetDummy
## A test target. Has HP and dies. Doesn't move or attack.

@export var max_hp: int = 3

var _health: HealthComponent
var _hurtbox: Hurtbox
var _sprite: ColorRect

func _ready() -> void:
	_health = $HealthComponent
	_hurtbox = $Hurtbox
	_health.max_hp = max_hp
	_health.hp_changed.connect(_on_hp_changed)
	_health.died.connect(_on_died)
	_hurtbox.set_faction(&"enemy")
	_setup_visual()

func _setup_visual() -> void:
	_sprite = ColorRect.new()
	_sprite.color = Color(0.9, 0.3, 0.3, 1.0)
	_sprite.size = Vector2(36, 36)
	_sprite.position = Vector2(-18, -18)
	add_child(_sprite)
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	add_child(col)
	var hb_col := CollisionShape2D.new()
	var hb_shape := CircleShape2D.new()
	hb_shape.radius = 18.0
	hb_col.shape = hb_shape
	_hurtbox.add_child(hb_col)

func _on_hp_changed(cur: int, _max: int) -> void:
	if cur <= 0:
		return
	# Flash
	_sprite.modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.05).timeout
	_sprite.modulate = Color(1, 1, 1, 1)

func _on_died() -> void:
	_sprite.color = Color(0.3, 0.1, 0.1, 1.0)
	var tw := get_tree().create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.3)
	tw.tween_callback(queue_free)
