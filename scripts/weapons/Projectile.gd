extends Area2D
class_name Projectile
## A bullet. Travels in a direction until it hits something or its range runs out.
## Spawned by Player._spawn_projectile / Enemy._spawn_projectile.

@export var speed: float = 500.0
@export var damage: int = 1
@export var max_range: float = 500.0
@export var pierce: int = 0
@export var knockback: float = 0.0
@export var radius: float = 4.0
@export var color: Color = Color.YELLOW
@export var lifetime_after_hit: float = 0.0  # if >0, projectile lingers briefly after a hit (for visual)
@export var faction: StringName = &"player"

var _direction: Vector2 = Vector2.RIGHT
var _distance_traveled: float = 0.0
var _visual: ColorRect
var _trail: Line2D
var _dead: bool = false

signal hit_something

func _ready() -> void:
	# Hitbox area setup
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = max(2.0, radius)
	col.shape = shape
	add_child(col)

	# Visual
	_visual = ColorRect.new()
	_visual.color = color
	_visual.size = Vector2(radius * 2, radius * 2)
	_visual.position = Vector2(-radius, -radius)
	_visual.z_index = 6
	add_child(_visual)

	# Collision setup for hitbox
	collision_layer = 0
	collision_mask = _opposing_mask(faction)
	monitoring = true

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(weapon: WeaponData, dir: Vector2, fact: StringName) -> void:
	damage = weapon.damage
	speed = weapon.projectile_speed
	max_range = weapon.projectile_range
	pierce = weapon.pierce
	knockback = weapon.knockback
	radius = weapon.projectile_radius
	color = weapon.projectile_color
	faction = fact
	_direction = dir.normalized() if dir.length_squared() > 0.001 else Vector2.RIGHT
	# Re-create visual/collision (since _ready ran with defaults)
	if is_inside_tree():
		_apply_visuals()

func _apply_visuals() -> void:
	for c in get_children():
		if c is CollisionShape2D:
			(c.shape as CircleShape2D).radius = max(2.0, radius)
			break
	if _visual:
		_visual.color = color
		_visual.size = Vector2(radius * 2, radius * 2)
		_visual.position = Vector2(-radius, -radius)
	collision_mask = _opposing_mask(faction)

func _opposing_mask(f: StringName) -> int:
	match f:
		&"player": return 2  # hit enemy layer
		&"enemy": return 1   # hit player layer
		_: return 0

func _physics_process(delta: float) -> void:
	if _dead:
		return
	var step := _direction * speed * delta
	global_position += step
	_distance_traveled += step.length()
	if _distance_traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node) -> void:
	_resolve_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_resolve_hit(area)

func _resolve_hit(node: Node) -> void:
	if _dead:
		return
	if node is TileMapLayer:
		# Wall - just disappear
		_die()
		return
	if not (node is Hurtbox):
		# Could be a wall (StaticBody2D)
		_die()
		return
	var hurtbox := node as Hurtbox
	if hurtbox.faction == faction:
		return  # same faction, ignore
	var dealt := hurtbox.take_hit(damage, get_instance_id())
	if dealt > 0:
		_apply_knockback(hurtbox)
		emit_signal("hit_something")
	if pierce > 0:
		pierce -= 1
	else:
		_die()

func _apply_knockback(hurtbox: Hurtbox) -> void:
	if knockback <= 0.0:
		return
	var target := hurtbox.get_parent()
	if target is CharacterBody2D:
		(target as CharacterBody2D).velocity += _direction * knockback

func _die() -> void:
	if _dead:
		return
	_dead = true
	# Small impact pop
	var pop := ColorRect.new()
	pop.color = Color(color.r, color.g, color.b, 0.7)
	pop.size = Vector2(radius * 4, radius * 4)
	pop.position = Vector2(-radius * 2, -radius * 2)
	pop.z_index = 7
	get_parent().add_child(pop)
	var tw := get_tree().create_tween()
	tw.tween_property(pop, "modulate:a", 0.0, 0.12)
	tw.tween_callback(pop.queue_free)
	queue_free()
