extends Node2D
class_name MeleeSwing
## A melee attack arc that damages enemies in front of the player.
## Lasts briefly, then disappears.

@export var arc_degrees: float = 120.0
@export var radius: float = 80.0
@export var swing_duration: float = 0.18
@export var damage: int = 2
@export var knockback: float = 120.0
@export var color: Color = Color(0.95, 0.95, 1.0, 0.6)
@export var faction: StringName = &"player"

var _direction: Vector2 = Vector2.RIGHT
var _elapsed: float = 0.0
var _hit_enemies: Array = []  # already-hit enemies
var _arc_visual: Polygon2D
var _hitbox: Area2D

func _ready() -> void:
	# Visual arc
	_arc_visual = Polygon2D.new()
	_arc_visual.color = color
	_arc_visual.z_index = 4
	add_child(_arc_visual)
	_build_arc_visual()
	# Hitbox area
	_hitbox = Area2D.new()
	_hitbox.collision_layer = 0
	_hitbox.collision_mask = _opposing_mask(faction)
	_hitbox.monitoring = true
	_hitbox.monitorable = false
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	col.shape = shape
	_hitbox.add_child(col)
	add_child(_hitbox)
	_hitbox.area_entered.connect(_on_area_entered)
	_hitbox.body_entered.connect(_on_body_entered)

func setup(weapon: WeaponData, dir: Vector2, fact: StringName) -> void:
	arc_degrees = weapon.melee_arc_degrees
	radius = weapon.melee_range
	damage = weapon.damage
	knockback = weapon.knockback
	color = weapon.melee_color
	faction = fact
	_direction = dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT
	if is_inside_tree():
		_build_arc_visual()
		if _hitbox:
			_hitbox.collision_mask = _opposing_mask(faction)
			# Update shape size
			for c in _hitbox.get_children():
				if c is CollisionShape2D and c.shape is CircleShape2D:
					(c.shape as CircleShape2D).radius = radius
					break

func _build_arc_visual() -> void:
	if _arc_visual == null:
		return
	var points: PackedVector2Array = PackedVector2Array()
	points.append(Vector2.ZERO)
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	var base_angle := _direction.angle()
	var segments: int = 12
	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var angle := base_angle + lerpf(-half_arc, half_arc, t)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	_arc_visual.polygon = points

func _opposing_mask(f: StringName) -> int:
	match f:
		&"player": return 2  # enemy layer
		&"enemy": return 1   # player layer
		_: return 0

func _process(delta: float) -> void:
	_elapsed += delta
	# Fade out
	var progress := _elapsed / swing_duration
	if _arc_visual:
		_arc_visual.modulate.a = clampf(1.0 - progress, 0.0, 1.0) * 0.6
	if _elapsed >= swing_duration:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_resolve_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_resolve_hit(area)

func _resolve_hit(node: Node) -> void:
	if node in _hit_enemies:
		return
	var hurtbox: Hurtbox = null
	if node is Hurtbox:
		hurtbox = node as Hurtbox
	elif node is CollisionObject2D:
		for child in node.get_children():
			if child is Hurtbox:
				hurtbox = child as Hurtbox
				break
	if hurtbox == null:
		return
	if hurtbox.faction == faction:
		return
	_hit_enemies.append(node)
	var dealt := hurtbox.take_hit(damage, get_instance_id())
	if dealt > 0:
		_apply_knockback(hurtbox)

func _apply_knockback(hurtbox: Hurtbox) -> void:
	if knockback <= 0.0:
		return
	var target := hurtbox.get_parent()
	if target is CharacterBody2D:
		var t := target as CharacterBody2D
		var dir: Vector2 = (t.global_position - global_position).normalized()
		if dir.length_squared() < 0.001:
			dir = _direction
		t.velocity += dir * knockback
