extends Node2D
class_name Room
## A single room instance in the dungeon. Renders walls, floor, doors, enemies.
## Loaded by DungeonRunner when the player enters.

signal room_cleared(room: Room)
signal door_entered(door: DoorData)

@export var room_data: RoomData
@export var floor_number: int = 0

var _walls: Node2D
var _floor: ColorRect
var _doors_container: Node2D
var _enemies_container: Node2D
var _player: Player
var _spawned_enemies: Array = []
var _is_active: bool = false
var _cleared: bool = false
var _door_cooldown: float = 0.0  # prevents door trigger spam after entering

func _ready() -> void:
        _build_visuals()
        _build_walls()
        # Doors and enemies are built in setup() once room_data is assigned.

func setup(data: RoomData, floor_num: int) -> void:
        room_data = data
        floor_number = floor_num
        global_position = data.world_position
        _build_doors()

func _build_visuals() -> void:
        # Floor background
        _floor = ColorRect.new()
        _floor.color = Color(0.13, 0.16, 0.20, 1.0)
        _floor.size = Vector2(Global.ROOM_PIXEL_W, Global.ROOM_PIXEL_H)
        _floor.position = Vector2(-Global.ROOM_PIXEL_W * 0.5, -Global.ROOM_PIXEL_H * 0.5)
        _floor.z_index = -2
        add_child(_floor)
        # Decorative border
        var border := ColorRect.new()
        border.color = Color(0.05, 0.06, 0.08, 1.0)
        border.size = Vector2(Global.ROOM_PIXEL_W + 20, Global.ROOM_PIXEL_H + 20)
        border.position = Vector2(-Global.ROOM_PIXEL_W * 0.5 - 10, -Global.ROOM_PIXEL_H * 0.5 - 10)
        border.z_index = -3
        add_child(border)

func _build_walls() -> void:
        _walls = Node2D.new()
        _walls.name = "Walls"
        add_child(_walls)
        var wall_thickness: float = 20.0
        var half_w := Global.ROOM_PIXEL_W * 0.5
        var half_h := Global.ROOM_PIXEL_H * 0.5
        # Top, Bottom, Left, Right walls (with a gap for doors)
        var door_gap: float = 100.0  # door width
        for side in ["top", "bottom", "left", "right"]:
                var is_horizontal: bool = side in ["top", "bottom"]
                var wall_length := Global.ROOM_PIXEL_W if is_horizontal else Global.ROOM_PIXEL_H
                var side_thickness := wall_thickness
                # Split into two segments around the door gap
                var seg_length: float = (wall_length - door_gap) * 0.5
                for sub in range(2):
                        var wall := StaticBody2D.new()
                        var shape := RectangleShape2D.new()
                        if is_horizontal:
                                shape.size = Vector2(seg_length, side_thickness)
                        else:
                                shape.size = Vector2(side_thickness, seg_length)
                        var col := CollisionShape2D.new()
                        col.shape = shape
                        wall.add_child(col)
                        # Visual
                        var vis := ColorRect.new()
                        vis.color = Color(0.25, 0.27, 0.32, 1.0)
                        vis.size = shape.size
                        vis.position = -shape.size * 0.5
                        wall.add_child(vis)
                        wall.collision_layer = 4
                        wall.collision_mask = 0
                        # Position
                        match side:
                                "top":
                                        var x_offset: float = -wall_length * 0.5 + seg_length * 0.5 if sub == 0 else wall_length * 0.5 - seg_length * 0.5
                                        wall.position = Vector2(x_offset, -half_h)
                                "bottom":
                                        var x_offset: float = -wall_length * 0.5 + seg_length * 0.5 if sub == 0 else wall_length * 0.5 - seg_length * 0.5
                                        wall.position = Vector2(x_offset, half_h)
                                "left":
                                        var y_offset: float = -wall_length * 0.5 + seg_length * 0.5 if sub == 0 else wall_length * 0.5 - seg_length * 0.5
                                        wall.position = Vector2(-half_w, y_offset)
                                "right":
                                        var y_offset: float = -wall_length * 0.5 + seg_length * 0.5 if sub == 0 else wall_length * 0.5 - seg_length * 0.5
                                        wall.position = Vector2(half_w, y_offset)
                        _walls.add_child(wall)

func _build_doors() -> void:
        _doors_container = Node2D.new()
        _doors_container.name = "Doors"
        add_child(_doors_container)
        if room_data == null:
                return
        for door in room_data.connections:
                var neighbor_idx: int = door
                # Find the door direction from room_data
                var dir := _direction_to(neighbor_idx)
                if dir == Vector2i.ZERO:
                        continue
                var door_node := _make_door_node(dir, neighbor_idx)
                _doors_container.add_child(door_node)

func _direction_to(neighbor_idx: int) -> Vector2i:
        # Find which direction leads to neighbor
        # Need to look at the door data; but we have only connections in room_data.
        # Direction is inferred from grid_pos difference.
        var layout := _get_layout()
        if layout == null:
                return Vector2i.ZERO
        var neighbor := layout.get_room(neighbor_idx)
        if neighbor == null:
                return Vector2i.ZERO
        var diff := neighbor.grid_pos - room_data.grid_pos
        if diff == Vector2i(1, 0): return Vector2i(1, 0)
        if diff == Vector2i(-1, 0): return Vector2i(-1, 0)
        if diff == Vector2i(0, 1): return Vector2i(0, 1)
        if diff == Vector2i(0, -1): return Vector2i(0, -1)
        return Vector2i.ZERO

func _get_layout() -> DungeonLayout:
        var parent_room_manager := get_parent()
        while parent_room_manager:
                if parent_room_manager.has_method("get_layout"):
                        return parent_room_manager.get_layout()
                parent_room_manager = parent_room_manager.get_parent()
        return null

func _make_door_node(dir: Vector2i, neighbor_idx: int) -> Node2D:
        var door := Area2D.new()
        door.collision_layer = 16  # door layer
        door.collision_mask = 1    # player layer
        door.monitoring = true
        door.monitorable = false
        var shape := RectangleShape2D.new()
        shape.size = Vector2(60, 60)
        var col := CollisionShape2D.new()
        col.shape = shape
        door.add_child(col)
        # Visual
        var vis := ColorRect.new()
        vis.color = Color(0.5, 0.4, 0.2, 0.7)
        vis.size = Vector2(80, 80)
        vis.position = Vector2(-40, -40)
        door.add_child(vis)
        # Position based on direction
        var half_w := Global.ROOM_PIXEL_W * 0.5
        var half_h := Global.ROOM_PIXEL_H * 0.5
        match dir:
                Vector2i(1, 0): door.position = Vector2(half_w, 0)
                Vector2i(-1, 0): door.position = Vector2(-half_w, 0)
                Vector2i(0, 1): door.position = Vector2(0, half_h)
                Vector2i(0, -1): door.position = Vector2(0, -half_h)
        # Store destination
        door.set_meta("neighbor_idx", neighbor_idx)
        door.set_meta("direction", dir)
        door.body_entered.connect(_on_door_body_entered.bind(door))
        return door

func _on_door_body_entered(body: Node, door: Area2D) -> void:
        if not body.is_in_group("player"):
                return
        if not _is_active:
                return
        if not _cleared:
                # Cannot leave until cleared
                return
        if _door_cooldown > 0.0:
                return
        var neighbor_idx: int = door.get_meta("neighbor_idx")
        var dir: Vector2i = door.get_meta("direction")
        var dd := DoorData.new()
        dd.from_room = room_data.index
        dd.to_room = neighbor_idx
        dd.direction = dir
        # Set cooldown on both this room and the destination
        _door_cooldown = 0.5
        emit_signal("door_entered", dd)

func set_door_cooldown(time: float) -> void:
        _door_cooldown = time

func _process(delta: float) -> void:
        if _door_cooldown > 0.0:
                _door_cooldown -= delta

func activate(player: Player) -> void:
        _is_active = true
        _player = player
        # Spawn enemies if not cleared
        if room_data == null:
                return
        if room_data.cleared:
                _cleared = true
                emit_signal("room_cleared", self)
                return
        # Decide based on room type
        match room_data.type:
                0, 5:  # NORMAL or ELITE - spawn enemies, doors lock until cleared
                        _spawn_enemies()
                1:  # START - no enemies, doors open
                        _cleared = true
                        room_data.cleared = true
                        emit_signal("room_cleared", self)
                3:  # SHOP - spawn shop NPC, doors open
                        _spawn_shop()
                        _cleared = true
                        room_data.cleared = true
                        emit_signal("room_cleared", self)
                4:  # TREASURE - spawn a treasure (weapon/buff), doors open
                        _spawn_treasure()
                        _cleared = true
                        room_data.cleared = true
                        emit_signal("room_cleared", self)
                2:  # BOSS - spawn boss, doors lock until cleared
                        _spawn_boss()

func _spawn_enemies() -> void:
        _enemies_container = Node2D.new()
        _enemies_container.name = "Enemies"
        add_child(_enemies_container)
        for spawn in room_data.enemy_spawns:
                var scene_path := "res://scenes/entities/EnemyGrunt.tscn" if spawn.kind == "grunt" else "res://scenes/entities/EnemyShooter.tscn"
                var scene := load(scene_path)
                var enemy := scene.instantiate() as Enemy
                _enemies_container.add_child(enemy)
                enemy.global_position = global_position + spawn.pos
                _spawned_enemies.append(enemy)
                enemy.died.connect(_on_enemy_died)

func _spawn_boss() -> void:
        _enemies_container = Node2D.new()
        _enemies_container.name = "Enemies"
        add_child(_enemies_container)
        var boss_scene := load("res://scenes/entities/BossEnemy.tscn")
        var boss := boss_scene.instantiate() as Enemy
        _enemies_container.add_child(boss)
        boss.global_position = global_position + Vector2(200, 0)
        _spawned_enemies.append(boss)
        boss.died.connect(_on_enemy_died)

func _spawn_shop() -> void:
        var shop_scene := load("res://scenes/entities/ShopNPC.tscn")
        var shop := shop_scene.instantiate() as Node2D
        add_child(shop)
        shop.global_position = global_position + Vector2(0, -100)

func _spawn_treasure() -> void:
        # Spawn a treasure chest-like pickup: either a weapon or a buff
        var rng := RandomNumberGenerator.new()
        rng.randomize()
        var roll := rng.randi() % 3
        match roll:
                0:  # Weapon pickup
                        var weapon_pickup_scene := load("res://scenes/entities/WeaponPickup.tscn")
                        var pickup := weapon_pickup_scene.instantiate() as WeaponPickup
                        # Pick a random weapon
                        var weapon_ids := ["smg", "shotgun", "sniper", "burst_rifle", "rocket_launcher", "charge_pistol", "sword"]
                        pickup.weapon_id = weapon_ids[rng.randi() % weapon_ids.size()]
                        add_child(pickup)
                        pickup.global_position = global_position + Vector2(0, 0)
                1:  # Buff pickup
                        var buff_pickup_scene := load("res://scenes/entities/BuffPickup.tscn")
                        var pickup := buff_pickup_scene.instantiate() as Node2D
                        add_child(pickup)
                        pickup.global_position = global_position + Vector2(0, 0)
                2:  # Health potion
                        var potion_scene := load("res://scenes/entities/Pickup.tscn")
                        var pickup := potion_scene.instantiate() as Pickup
                        pickup.kind = Pickup.Kind.HEALTH_POTION
                        pickup.value = 3
                        add_child(pickup)
                        pickup.global_position = global_position + Vector2(0, 0)

func _on_enemy_died(enemy: Enemy) -> void:
        # Notify player's buff system (for lifesteal, etc.)
        if _player and is_instance_valid(_player):
                var buffs_node := _player.get_node_or_null("PlayerBuffs") as PlayerBuffs
                if buffs_node:
                        buffs_node.on_enemy_killed()
        # Check if all enemies are dead
        var alive := 0
        for e in _spawned_enemies:
                if is_instance_valid(e) and not e._is_dead:
                        alive += 1
        if alive == 0 and not _cleared:
                _cleared = true
                if room_data:
                        room_data.cleared = true
                emit_signal("room_cleared", self)

func is_cleared() -> bool:
        return _cleared

func deactivate() -> void:
        _is_active = false
