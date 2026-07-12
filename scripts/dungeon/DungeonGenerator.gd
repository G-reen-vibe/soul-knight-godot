extends Node
class_name DungeonGenerator
## Generates a floor layout: rooms connected by doors.
##
## Algorithm: place rooms on a grid, connect adjacent rooms with doors,
## pick one as the start and one (far away) as the boss room.
##
## Output: a DungeonLayout resource describing all rooms and connections.

const GRID_W: int = 5  # 5x5 grid max
const GRID_H: int = 5

enum RoomType { NORMAL, START, BOSS, SHOP, TREASURE, ELITE }

static func generate(floor_num: int) -> DungeonLayout:
        var layout := DungeonLayout.new()
        layout.floor_number = floor_num
        # Number of rooms scales with floor
        var target_rooms: int = 6 + min(floor_num, 4)
        # Seed RNG
        var rng := RandomNumberGenerator.new()
        rng.seed = Global._rng.seed + floor_num * 7919
        # Place rooms via random walk on the grid
        var placed: Dictionary = {}  # "x,y" -> RoomData
        var walk_pos := Vector2i(int(GRID_W / 2), int(GRID_H / 2))
        placed[_key(walk_pos)] = _make_room(walk_pos, RoomType.NORMAL, 0)
        for i in range(target_rooms - 1):
                var tries := 0
                while tries < 20:
                        tries += 1
                        var dir := _random_dir(rng)
                        var next_pos := walk_pos + dir
                        if next_pos.x < 0 or next_pos.x >= GRID_W or next_pos.y < 0 or next_pos.y >= GRID_H:
                                continue
                        if not placed.has(_key(next_pos)):
                                var room := _make_room(next_pos, RoomType.NORMAL, placed.size())
                                placed[_key(next_pos)] = room
                                layout.rooms.append(room)
                                walk_pos = next_pos
                                break
                        else:
                                walk_pos = next_pos  # walk through existing rooms
        # Assign special types: start at first room, boss at farthest
        var all_rooms: Array = placed.values()
        all_rooms.sort_custom(func(a, b): return a.index < b.index)
        # Find the room farthest from start
        var start_room: RoomData = all_rooms[0]
        start_room.type = RoomType.START
        var farthest: RoomData = start_room
        var max_dist := 0
        for r in all_rooms:
                var d := _grid_distance(start_room.grid_pos, r.grid_pos)
                if d > max_dist:
                        max_dist = d
                        farthest = r
        farthest.type = RoomType.BOSS
        # Place a shop midway if we have enough rooms
        if all_rooms.size() >= 6:
                var mid: RoomData = all_rooms[int(all_rooms.size() * 0.5)]
                if mid.type == RoomType.NORMAL:
                        mid.type = RoomType.SHOP
        # Place a treasure room
        if all_rooms.size() >= 5:
                for r in all_rooms:
                        if r.type == RoomType.NORMAL and r != farthest:
                                r.type = RoomType.TREASURE
                                break
        # Connect adjacent rooms with doors
        for r in all_rooms:
                for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
                        var dir_vec: Vector2i = dir
                        var neighbor_pos: Vector2i = r.grid_pos + dir_vec
                        if placed.has(_key(neighbor_pos)):
                                var neighbor: RoomData = placed[_key(neighbor_pos)]
                                if not r.connections.has(neighbor.index):
                                        r.connections.append(neighbor.index)
                                if not neighbor.connections.has(r.index):
                                        neighbor.connections.append(r.index)
                                # Only add one door per pair (avoid duplicates)
                                if r.index < neighbor.index:
                                        var door := DoorData.new()
                                        door.from_room = r.index
                                        door.to_room = neighbor.index
                                        door.direction = dir_vec
                                        layout.doors.append(door)
        # Store rooms (typed array)
        var typed_rooms: Array[RoomData] = []
        for r in all_rooms:
                typed_rooms.append(r as RoomData)
        layout.rooms = typed_rooms
        layout.start_room_index = start_room.index
        layout.boss_room_index = farthest.index
        # Generate enemy spawns for each non-start room
        for r in all_rooms:
                if r.type == RoomType.NORMAL or r.type == RoomType.ELITE:
                        _populate_enemies(r, floor_num, rng)
        return layout

static func _make_room(pos: Vector2i, type: int, idx: int) -> RoomData:
        var r := RoomData.new()
        r.grid_pos = pos
        r.type = type
        r.index = idx
        r.world_position = Vector2(pos.x * Global.ROOM_PIXEL_W, pos.y * Global.ROOM_PIXEL_H)
        return r

static func _random_dir(rng: RandomNumberGenerator) -> Vector2i:
        var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
        return dirs[rng.randi() % dirs.size()]

static func _key(pos: Vector2i) -> String:
        return "%d,%d" % [pos.x, pos.y]

static func _grid_distance(a: Vector2i, b: Vector2i) -> int:
        return abs(a.x - b.x) + abs(a.y - b.y)

static func _populate_enemies(room: RoomData, floor_num: int, rng: RandomNumberGenerator) -> void:
        var count: int = 3 + rng.randi() % 3 + min(2, floor_num / 2)
        for i in range(count):
                var kind: int = rng.randi() % 3  # 0,1,2 -> grunt; 3+ -> shooter
                var enemy_kind: String = "grunt" if kind < 2 else "shooter"
                var pos := Vector2(
                        rng.randf_range(-300, 300),
                        rng.randf_range(-200, 200)
                )
                room.enemy_spawns.append({"kind": enemy_kind, "pos": pos})
