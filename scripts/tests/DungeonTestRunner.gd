extends Node2D
class_name DungeonTestRunner
## Tests dungeon generation and room transitions.

@export var auto_quit: bool = true

var _test_results: Array = []
var _dungeon: DungeonRunner
var _player: Player
var _test_step: int = 0
var _step_timer: float = 0.0

func _ready() -> void:
        print("[DungeonTestRunner] Booting dungeon tests...")
        # Spawn the dungeon runner
        var scene := load("res://scenes/dungeon/DungeonRunner.tscn")
        _dungeon = scene.instantiate() as DungeonRunner
        add_child(_dungeon)
        await get_tree().process_frame
        await get_tree().process_frame
        _player = _dungeon._player
        if _player == null:
                print("FAIL: Player not spawned by dungeon runner")
                _finish()
                return
        print("PASS: Dungeon spawned player")
        _step_timer = 1.0
        set_process(true)

func _process(delta: float) -> void:
        if _step_timer > 0.0:
                _step_timer -= delta
                if _step_timer <= 0.0:
                        _run_next_step()

func _run_next_step() -> void:
        _test_step += 1
        match _test_step:
                1: _test_rooms_exist()
                2: _test_player_in_start_room()
                3: _test_enemies_spawn()
                4: _test_kill_enemies_clears_room()
                5: _test_door_transition()
                _: _finish()

func _test_rooms_exist() -> void:
        var layout := _dungeon.get_layout()
        if layout == null:
                _log(false, "Layout is null")
                _step_timer = 0.1
                return
        if layout.rooms.size() >= 5:
                _log(true, "Layout has %d rooms" % layout.rooms.size())
        else:
                _log(false, "Layout has too few rooms: %d" % layout.rooms.size())
        # Verify start and boss rooms
        var has_start := false
        var has_boss := false
        for r in layout.rooms:
                if r.type == 1:  # START
                        has_start = true
                if r.type == 2:  # BOSS
                        has_boss = true
        if has_start and has_boss:
                _log(true, "Layout has start and boss rooms")
        else:
                _log(false, "Missing start or boss room (start=%s boss=%s)" % [has_start, has_boss])
        _step_timer = 0.5

func _test_player_in_start_room() -> void:
        var layout := _dungeon.get_layout()
        var start_room := layout.get_room(layout.start_room_index)
        if _dungeon._current_room.room_data.index == start_room.index:
                _log(true, "Player starts in start room")
        else:
                _log(false, "Player not in start room (in %d, expected %d)" % [_dungeon._current_room.room_data.index, start_room.index])
        _step_timer = 0.5

func _test_enemies_spawn() -> void:
        # Move to a normal room by teleporting through a door
        # For now, just check if start room has no enemies (it shouldn't)
        var current := _dungeon._current_room
        if current._spawned_enemies.is_empty():
                _log(true, "Start room has no enemies")
        else:
                _log(false, "Start room has enemies (shouldn't)")
        # Check the layout has at least one room with enemies
        var layout := _dungeon.get_layout()
        var has_enemy_room := false
        for r in layout.rooms:
                if r.enemy_spawns.size() > 0:
                        has_enemy_room = true
                        break
        if has_enemy_room:
                _log(true, "Some rooms have enemy spawns")
        else:
                _log(false, "No rooms have enemy spawns")
        _step_timer = 0.5

func _test_kill_enemies_clears_room() -> void:
        # Force-enter a room with enemies by directly calling _enter_room
        var layout := _dungeon.get_layout()
        var target_room: RoomData = null
        for r in layout.rooms:
                if r.enemy_spawns.size() > 0:
                        target_room = r
                        break
        if target_room == null:
                _log(false, "No room with enemies found")
                _step_timer = 0.1
                return
        # Directly transition to that room
        var dd := DoorData.new()
        dd.from_room = _dungeon._current_room.room_data.index
        dd.to_room = target_room.index
        dd.direction = Vector2i(1, 0)  # arbitrary
        _dungeon.call_deferred("_enter_room", target_room.index, dd)
        await get_tree().create_timer(1.0).timeout
        var new_room := _dungeon._current_room
        if new_room._spawned_enemies.is_empty():
                _log(false, "New room has no enemies")
                _step_timer = 0.5
                return
        # Directly kill all enemies (simulating the player clearing the room)
        var alive_count := 0
        for e in new_room._spawned_enemies:
                if is_instance_valid(e):
                        e.take_damage(999)
                        alive_count += 1
        await get_tree().create_timer(1.5).timeout
        if new_room.is_cleared():
                _log(true, "Killing all enemies clears the room (killed %d)" % alive_count)
        else:
                _log(false, "Room not cleared after killing enemies")
        _step_timer = 0.5

func _test_door_transition() -> void:
        # Walk the player through a real door
        var layout := _dungeon.get_layout()
        # Find a door from the current room
        var current_idx := _dungeon._current_room.room_data.index
        var door: DoorData = null
        for d in layout.doors:
                if d.from_room == current_idx:
                        door = d
                        break
        if door == null:
                _log(false, "No door from current room")
                _step_timer = 0.5
                return
        # Teleport player to door position (just inside, to trigger body_entered)
        var door_pos := _dungeon._current_room.global_position + _door_offset(door.direction) * 0.95
        _player.global_position = door_pos
        await get_tree().create_timer(1.0).timeout
        if _dungeon._current_room.room_data.index != current_idx:
                _log(true, "Player transitioned via door (room %d -> %d)" % [current_idx, _dungeon._current_room.room_data.index])
        else:
                _log(false, "Player did not transition via door")
        _step_timer = 0.5

# ----- Helpers -----
func _give_op_weapon() -> void:
        var w := WeaponData.new()
        w.id = &"test_op"
        w.fire_mode = WeaponData.FireMode.AUTO
        w.damage = 10
        w.energy_cost = 0
        w.fire_rate = 8.0
        w.projectile_speed = 800.0
        w.projectile_range = 700.0
        w.projectile_color = Color(1, 0.2, 0.2)
        w.projectile_radius = 6.0
        w.knockback = 100.0
        _player._weapons.clear()
        _player._weapons.append(w)
        _player._current_weapon_slot = 0

func _door_offset(dir: Vector2i) -> Vector2:
        var half_w := Global.ROOM_PIXEL_W * 0.5
        var half_h := Global.ROOM_PIXEL_H * 0.5
        match dir:
                Vector2i(1, 0): return Vector2(half_w + 30, 0)
                Vector2i(-1, 0): return Vector2(-half_w - 30, 0)
                Vector2i(0, 1): return Vector2(0, half_h + 30)
                Vector2i(0, -1): return Vector2(0, -half_h - 30)
                _: return Vector2.ZERO

func _log(passed: bool, msg: String) -> void:
        var status := "PASS" if passed else "FAIL"
        print("[%s] %s" % [status, msg])
        _test_results.append({"passed": passed, "msg": msg})

func _finish() -> void:
        set_process(false)
        var passed := 0
        var failed := 0
        for r in _test_results:
                if r.passed:
                        passed += 1
                else:
                        failed += 1
        print("---")
        print("Test results: %d passed, %d failed" % [passed, failed])
        if auto_quit:
                await get_tree().create_timer(1.0).timeout
                get_tree().quit(0 if failed == 0 else 1)
