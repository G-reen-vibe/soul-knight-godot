extends CharacterBody2D
class_name Player
## Player controller. Movement, aiming, weapon firing, dodge roll, skill.
## Visual representation is a placeholder capsule for now; art can be added later.

signal hp_changed(cur: int, max_v: int)
signal armor_changed(cur: int, max_v: int)
signal energy_changed(cur: int, max_v: int)
signal coins_changed(amount: int)
signal potions_changed(amount: int)
signal weapon_changed(weapon: WeaponData, slot: int)
signal skill_ready_changed(ready: bool, progress: float)
signal died

@export_category("Movement")
@export var move_speed: float = 240.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.28
@export var dodge_cooldown: float = 0.6
@export var dodge_invuln: float = 0.22

@export_category("Combat")
@export var max_hp: int = 5
@export var max_armor: int = 0
@export var max_energy: int = 100
@export var energy_regen: float = 25.0  # per second
@export var energy_regen_delay: float = 0.5  # seconds after last shot before regen
@export var invuln_after_hit: float = 0.8

@export_category("Inventory")
@export var potions: int = 1
@export var potion_heal_amount: int = 3
@export var starting_weapons: Array[WeaponData] = []

# ----- Internal state -----
var _health: HealthComponent
var _hurtbox: Hurtbox
var _current_hp: int = 5
var _current_armor: int = 0
var _current_energy: float = 100.0
var _energy_regen_timer: float = 0.0

var _weapons: Array = []  # Array[WeaponData] - up to 3 slots
var _current_weapon_slot: int = 0
var _fire_cooldown: float = 0.0
var _burst_remaining: int = 0
var _burst_timer: float = 0.0
var _charging: bool = false
var _charge_time: float = 0.0

var _dodge_timer: float = 0.0
var _dodge_cd_timer: float = 0.0
var _dodge_dir: Vector2 = Vector2.ZERO

var _skill_cd: float = 0.0
var _skill_max_cd: float = 5.0
var _aim_dir: Vector2 = Vector2.RIGHT
var _is_dead: bool = false

# Visual / FX
var _sprite: ColorRect
var _aim_visual: Line2D
var _weapon_pivot: Node2D
var _muzzle: Marker2D

# Skill handler (set by character subclass)
var _skill_handler: Node = null
var _test_aim_override: Vector2 = Vector2.ZERO  # if non-zero, forces aim direction (for testing)

# Public read-only
var coins: int = 0

func _ready() -> void:
        _health = $HealthComponent
        _hurtbox = $Hurtbox
        _health.max_hp = max_hp
        _health.max_armor = max_armor
        _health.invuln_time = invuln_after_hit
        _health.hp_changed.connect(func(c, m): _current_hp = c; emit_signal("hp_changed", c, m))
        _health.armor_changed.connect(func(c, m): _current_armor = c; emit_signal("armor_changed", c, m))
        _health.died.connect(_on_died)
        _hurtbox.set_faction(&"player")
        _current_energy = max_energy
        _setup_visuals()
        # Init weapons
        if starting_weapons.is_empty():
                var pistol := load("res://data/weapons/pistol.tres") as WeaponData
                if pistol:
                        starting_weapons = [pistol]
        for w in starting_weapons:
                _weapons.append(w.duplicate(true))
        if not _weapons.is_empty():
                emit_signal("weapon_changed", _weapons[0], 0)
        # Carry over from Global if set
        if Global.carry_weapon_ids.size() > 0:
                _load_weapons_from_ids(Global.carry_weapon_ids)
        var effective_max_hp: int = Global.carry_max_hp if Global.carry_max_hp > 0 else max_hp
        _health.max_hp = effective_max_hp
        _health.current_hp = Global.carry_current_hp if Global.carry_current_hp > 0 else effective_max_hp
        _health.max_armor = 9
        _health.current_armor = Global.carry_armor
        max_energy = Global.carry_max_energy
        _current_energy = Global.carry_current_energy
        potions = Global.carry_potions
        _refresh_ui_signals()

func _refresh_ui_signals() -> void:
        emit_signal("hp_changed", _health.current_hp, _health.max_hp)
        emit_signal("armor_changed", _health.current_armor, _health.max_armor)
        emit_signal("energy_changed", int(_current_energy), max_energy)
        emit_signal("potions_changed", potions)
        emit_signal("coins_changed", coins)
        if not _weapons.is_empty():
                emit_signal("weapon_changed", _weapons[_current_weapon_slot], _current_weapon_slot)

func _load_weapons_from_ids(ids: Array) -> void:
        _weapons.clear()
        for id in ids:
                var path := "res://data/weapons/%s.tres" % id
                var w := load(path) as WeaponData
                if w:
                        _weapons.append(w.duplicate(true))
                else:
                        push_warning("Could not load weapon: %s" % path)
        if _weapons.is_empty():
                var pistol := load("res://data/weapons/pistol.tres") as WeaponData
                _weapons.append(pistol.duplicate(true))
        _current_weapon_slot = 0

# ----- Visuals -----
func _setup_visuals() -> void:
        _sprite = ColorRect.new()
        _sprite.color = Color(0.3, 0.7, 0.9, 1.0)
        _sprite.size = Vector2(36, 36)
        _sprite.position = Vector2(-18, -18)
        _sprite.z_index = 5
        add_child(_sprite)

        var outline := ColorRect.new()
        outline.color = Color(0.1, 0.2, 0.3, 1.0)
        outline.size = Vector2(40, 40)
        outline.position = Vector2(-20, -20)
        outline.z_index = 4
        add_child(outline)

        _weapon_pivot = Node2D.new()
        _weapon_pivot.name = "WeaponPivot"
        add_child(_weapon_pivot)
        _weapon_pivot.z_index = 6

        _muzzle = Marker2D.new()
        _muzzle.position = Vector2(28, 0)
        _weapon_pivot.add_child(_muzzle)

        _aim_visual = Line2D.new()
        _aim_visual.width = 2.0
        _aim_visual.default_color = Color(1, 1, 0, 0.4)
        _aim_visual.z_index = 3
        add_child(_aim_visual)

        # Hitbox for body collision
        var col := CollisionShape2D.new()
        var shape := CapsuleShape2D.new()
        shape.radius = 18.0
        shape.height = 36.0
        col.shape = shape
        add_child(col)

        # Hurtbox area
        var hb_col := CollisionShape2D.new()
        var hb_shape := CircleShape2D.new()
        hb_shape.radius = 18.0
        hb_col.shape = hb_shape
        _hurtbox.add_child(hb_col)

# ----- Input/Movement -----
func _process(delta: float) -> void:
        if _is_dead:
                return
        _update_timers(delta)
        _update_aim()
        _update_movement(delta)
        _update_firing(delta)
        _update_skill_cooldown(delta)
        _update_energy_regen(delta)
        _update_dodge(delta)
        _update_visuals()

func _update_timers(delta: float) -> void:
        if _fire_cooldown > 0.0:
                _fire_cooldown -= delta
        if _burst_timer > 0.0:
                _fire_burst_tick()
        if _dodge_cd_timer > 0.0:
                _dodge_cd_timer -= delta

func _update_aim() -> void:
        if _test_aim_override.length_squared() > 0.01:
                _aim_dir = _test_aim_override.normalized()
                _weapon_pivot.rotation = _aim_dir.angle()
                return
        var mouse_pos := get_global_mouse_position()
        var to_mouse := mouse_pos - global_position
        if to_mouse.length_squared() > 1.0:
                _aim_dir = to_mouse.normalized()
        # Face the aim direction (rotate weapon pivot)
        _weapon_pivot.rotation = _aim_dir.angle()

func set_test_aim(dir: Vector2) -> void:
        _test_aim_override = dir

func _update_movement(delta: float) -> void:
        if _dodge_timer > 0.0:
                # During dodge, lock movement direction
                velocity = _dodge_dir * dodge_speed
                return
        var input_vec := Vector2.ZERO
        if Input.is_action_pressed("move_up"): input_vec.y -= 1.0
        if Input.is_action_pressed("move_down"): input_vec.y += 1.0
        if Input.is_action_pressed("move_left"): input_vec.x -= 1.0
        if Input.is_action_pressed("move_right"): input_vec.x += 1.0
        if input_vec.length_squared() > 1.0:
                input_vec = input_vec.normalized()
        velocity = input_vec * move_speed

func _update_dodge(delta: float) -> void:
        if _dodge_timer > 0.0:
                _dodge_timer -= delta
                if _dodge_timer <= 0.0:
                        _dodge_cd_timer = dodge_cooldown
                        # Clear i-frames slightly before motion ends
                        _health.invuln_timer = 0.0

        if Input.is_action_just_pressed("dash") and _dodge_cd_timer <= 0.0 and _dodge_timer <= 0.0:
                _start_dodge()

func _start_dodge() -> void:
        var input_vec := Vector2.ZERO
        if Input.is_action_pressed("move_up"): input_vec.y -= 1.0
        if Input.is_action_pressed("move_down"): input_vec.y += 1.0
        if Input.is_action_pressed("move_left"): input_vec.x -= 1.0
        if Input.is_action_pressed("move_right"): input_vec.x += 1.0
        if input_vec.length_squared() < 0.01:
                input_vec = _aim_dir  # dodge toward aim if no movement input
        _dodge_dir = input_vec.normalized()
        _dodge_timer = dodge_duration
        _health.invuln_timer = dodge_invuln

# ----- Firing -----
func _update_firing(delta: float) -> void:
        var weapon := _current_weapon()
        if weapon == null:
                return
        # Charge weapon
        if weapon.fire_mode == WeaponData.FireMode.CHARGE:
                if Input.is_action_pressed("shoot"):
                        _charging = true
                        _charge_time += delta
                else:
                        if _charging:
                                _fire_charged(weapon)
                                _charging = false
                                _charge_time = 0.0
                return

        var want_fire := false
        match weapon.fire_mode:
                WeaponData.FireMode.SINGLE, WeaponData.FireMode.SHOTGUN, WeaponData.FireMode.BURST:
                        want_fire = Input.is_action_just_pressed("shoot")
                WeaponData.FireMode.AUTO:
                        want_fire = Input.is_action_pressed("shoot")
        if want_fire and _fire_cooldown <= 0.0 and _burst_remaining == 0:
                _try_fire(weapon)

func _try_fire(weapon: WeaponData) -> void:
        if weapon.is_ranged:
                if _current_energy < weapon.energy_cost:
                        return  # not enough energy
                _current_energy -= weapon.energy_cost
                _energy_regen_timer = energy_regen_delay
                emit_signal("energy_changed", int(_current_energy), max_energy)
        if weapon.fire_mode == WeaponData.FireMode.BURST:
                _burst_remaining = weapon.burst_count
                _burst_timer = 0.0
                _fire_burst_tick()
                _fire_cooldown = 1.0 / max(0.1, weapon.fire_rate)
                return
        if weapon.fire_mode == WeaponData.FireMode.SHOTGUN and weapon.pellets > 1:
                var spread_rad := deg_to_rad(weapon.spread_degrees)
                for i in range(weapon.pellets):
                        var t := (float(i) + 0.5) / float(weapon.pellets)
                        var angle_offset := lerpf(-spread_rad * 0.5, spread_rad * 0.5, t)
                        _spawn_projectile(weapon, _aim_dir.rotated(angle_offset))
        else:
                _spawn_projectile(weapon, _aim_dir)
        _fire_cooldown = 1.0 / max(0.1, weapon.fire_rate)

func _fire_burst_tick() -> void:
        if _burst_remaining <= 0:
                return
        var weapon := _current_weapon()
        if weapon == null:
                _burst_remaining = 0
                return
        # Consume energy for the burst shot
        if weapon.is_ranged and _current_energy < weapon.energy_cost:
                _burst_remaining = 0
                return
        if weapon.is_ranged:
                _current_energy -= weapon.energy_cost
                _energy_regen_timer = energy_regen_delay
        _spawn_projectile(weapon, _aim_dir)
        _burst_remaining -= 1
        if _burst_remaining > 0:
                _burst_timer = _current_weapon().burst_delay
        else:
                _burst_timer = 0.0

func _fire_charged(weapon: WeaponData) -> void:
        if _charge_time < weapon.charge_time * 0.5:
                # Treat as a normal shot
                _try_fire(weapon)
                return
        # Charged shot
        var mult := weapon.charge_damage_multiplier
        var charged := weapon.duplicate(true)
        charged.damage = int(round(charged.damage * mult))
        charged.projectile_speed *= 1.3
        charged.projectile_radius *= 1.5
        if _current_energy < charged.energy_cost:
                return
        _current_energy -= charged.energy_cost
        _energy_regen_timer = energy_regen_delay
        _spawn_projectile(charged, _aim_dir)
        _fire_cooldown = 1.0 / max(0.1, weapon.fire_rate)

func _spawn_projectile(weapon: WeaponData, dir: Vector2) -> void:
        if dir.length_squared() < 0.001:
                dir = Vector2.RIGHT
        # Melee weapons spawn a melee swing instead of a projectile
        if weapon.category == WeaponData.WeaponCategory.MELEE:
                _spawn_melee_swing(weapon, dir)
                return
        var scene: PackedScene = weapon.bullet_scene
        if scene == null:
                # Pick a default based on weapon properties
                # Could be explosive if damage is high and range is short... but for now, use base Projectile
                scene = load("res://scenes/projectiles/Projectile.tscn")
        var proj := scene.instantiate() as Projectile
        get_tree().current_scene.add_child(proj)
        proj.global_position = _muzzle.global_position
        proj.setup(weapon, dir, &"player")
        if weapon.muzzle_flash:
                _spawn_muzzle_flash()

func _spawn_melee_swing(weapon: WeaponData, dir: Vector2) -> void:
        var scene := load("res://scenes/projectiles/MeleeSwing.tscn")
        var swing := scene.instantiate() as MeleeSwing
        get_tree().current_scene.add_child(swing)
        swing.global_position = global_position
        swing.setup(weapon, dir, &"player")

func _spawn_muzzle_flash() -> void:
        var flash := ColorRect.new()
        flash.color = Color(1, 0.9, 0.4, 0.9)
        flash.size = Vector2(16, 16)
        flash.position = _muzzle.position + Vector2(-8, -8)
        flash.z_index = 7
        _weapon_pivot.add_child(flash)
        var tw := get_tree().create_tween()
        tw.tween_property(flash, "modulate:a", 0.0, 0.06)
        tw.tween_callback(flash.queue_free)

# ----- Melee (handled within spawn_projectile for melee category) -----
# Actually we override _spawn_projectile for melee to spawn a melee swing.

# ----- Skill -----
func _update_skill_cooldown(delta: float) -> void:
        if _skill_cd > 0.0:
                _skill_cd -= delta
        var ready := _skill_cd <= 0.0
        var progress := 1.0 - clampf(_skill_cd / _skill_max_cd, 0.0, 1.0)
        emit_signal("skill_ready_changed", ready, progress)
        if Input.is_action_just_pressed("skill") and ready:
                _activate_skill()

func _activate_skill() -> void:
        if _skill_handler and _skill_handler.has_method("activate_skill"):
                _skill_handler.activate_skill(self)
                _skill_cd = _skill_max_cd
        else:
                _default_skill()

func _default_skill() -> void:
        # Default: brief invulnerability + speed boost for 2s
        _health.invuln_timer = 2.0
        var orig_speed := move_speed
        move_speed *= 1.5
        await get_tree().create_timer(2.0).timeout
        move_speed = orig_speed
        _skill_cd = _skill_max_cd

func set_skill_handler(handler: Node) -> void:
        _skill_handler = handler

func set_skill_cooldown(cd: float) -> void:
        _skill_max_cd = cd
        _skill_cd = 0.0  # ready at start

# ----- Energy -----
func _update_energy_regen(delta: float) -> void:
        if _energy_regen_timer > 0.0:
                _energy_regen_timer -= delta
                return
        if _current_energy < max_energy:
                _current_energy = min(max_energy, _current_energy + energy_regen * delta)
                emit_signal("energy_changed", int(_current_energy), max_energy)

# ----- Inventory actions -----
func _input(event: InputEvent) -> void:
        if _is_dead:
                return
        if event.is_action_pressed("switch_weapon"):
                cycle_weapon()
        elif event.is_action_pressed("use_potion"):
                use_potion()

func cycle_weapon() -> void:
        if _weapons.size() <= 1:
                return
        _current_weapon_slot = (_current_weapon_slot + 1) % _weapons.size()
        emit_signal("weapon_changed", _weapons[_current_weapon_slot], _current_weapon_slot)

func use_potion() -> void:
        if potions <= 0:
                return
        potions -= 1
        _health.heal(potion_heal_amount)
        emit_signal("potions_changed", potions)

func pickup_weapon(w: WeaponData) -> void:
        if _weapons.size() < 3:
                _weapons.append(w.duplicate(true))
                _current_weapon_slot = _weapons.size() - 1
        else:
                # Replace current
                _weapons[_current_weapon_slot] = w.duplicate(true)
        emit_signal("weapon_changed", _weapons[_current_weapon_slot], _current_weapon_slot)

func add_coins(amount: int) -> void:
        coins += amount
        emit_signal("coins_changed", coins)

func spend_coins(amount: int) -> bool:
        if coins < amount:
                return false
        coins -= amount
        emit_signal("coins_changed", coins)
        return true

# ----- Helpers -----
func _current_weapon() -> WeaponData:
        if _weapons.is_empty():
                return null
        return _weapons[_current_weapon_slot]

func _update_visuals() -> void:
        # Aim line shows where the player is shooting
        _aim_visual.clear_points()
        _aim_visual.add_point(Vector2.ZERO)
        var w := _current_weapon()
        var range_px: float = 60.0 if w == null else (w.melee_range if w.category == WeaponData.WeaponCategory.MELEE else w.projectile_range)
        _aim_visual.add_point(_aim_dir * range_px)
        # Flash sprite on damage
        if _health.is_invulnerable() and not _is_dead:
                _sprite.modulate.a = 0.5 if fmod(Time.get_ticks_msec() * 0.01, 1.0) > 0.5 else 1.0
        else:
                _sprite.modulate.a = 1.0

func _on_died() -> void:
        _is_dead = true
        velocity = Vector2.ZERO
        _sprite.color = Color(0.5, 0.1, 0.1, 1.0)
        _sprite.modulate.a = 0.4
        emit_signal("died")
        Global.change_state(Global.GameState.GAME_OVER)

func _physics_process(_delta: float) -> void:
        if _is_dead:
                return
        move_and_slide()
