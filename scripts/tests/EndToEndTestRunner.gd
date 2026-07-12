extends Node2D
class_name EndToEndTestRunner
## Comprehensive end-to-end test that simulates a player playing through a floor.
## Tests: game boot, menu, character select, dungeon enter, room navigation,
## enemy combat, pickups, shop, treasure, boss fight, floor transition.

@export var auto_quit: bool = true

var _test_results: Array = []
var _test_step: int = 0
var _step_timer: float = 0.0
var _dungeon: DungeonRunner
var _player: Player
var _main: Node

func _ready() -> void:
        print("[E2E] Booting end-to-end test...")
        # Seed the RNG for deterministic tests
        Global.seed_rng(12345)
        # Boot the main scene directly
        _main = load("res://scripts/core/Main.gd").new()
        # Actually, we need a Main node - let's instantiate it
        _main = Node2D.new()
        _main.set_script(load("res://scripts/core/Main.gd"))
        _main.name = "Main"
        add_child(_main)
        await get_tree().process_frame
        await get_tree().process_frame
        _step_timer = 0.5
        set_process(true)

func _process(delta: float) -> void:
        if _step_timer > 0.0:
                _step_timer -= delta
                if _step_timer <= 0.0:
                        _run_next_step()

func _run_next_step() -> void:
        _test_step += 1
        match _test_step:
                1: _test_main_menu_visible()
                2: _test_character_select()
                3: _test_game_starts()
                4: _test_player_in_start_room()
                5: _test_player_can_move_and_shoot()
                6: _test_player_can_use_potion()
                7: _test_player_can_use_skill()
                8: _test_explore_dungeon()
                9: _test_pickups_work()
                10: _test_kill_all_enemies()
                11: _test_defeat_boss()
                12: _test_floor_transition()
                _: _finish()

func _test_main_menu_visible() -> void:
        # Main menu should be visible
        if _main._main_menu != null and is_instance_valid(_main._main_menu):
                _log(true, "Main menu is visible")
        else:
                _log(false, "Main menu is not visible")
        _step_timer = 0.3

func _test_character_select() -> void:
        # Click "Start Game" -> character select
        if _main._main_menu:
                _main._main_menu.emit_signal("start_pressed")
        await get_tree().create_timer(0.3).timeout
        if _main._character_select != null and is_instance_valid(_main._character_select):
                _log(true, "Character select is visible")
        else:
                _log(false, "Character select is not visible")
        _step_timer = 0.3

func _test_game_starts() -> void:
        # Confirm default character (Knight)
        if _main._character_select:
                _main._character_select.emit_signal("character_confirmed", "knight")
        await get_tree().create_timer(1.0).timeout
        if _main._dungeon_runner != null and is_instance_valid(_main._dungeon_runner):
                _dungeon = _main._dungeon_runner
                _player = _dungeon._player
                _log(true, "Game started with dungeon runner and player")
        else:
                _log(false, "Game did not start (no dungeon runner)")
        _step_timer = 0.3

func _test_player_in_start_room() -> void:
        if _dungeon == null or _player == null:
                _log(false, "Cannot test - no dungeon/player")
                _step_timer = 0.1
                return
        var start_room := _dungeon.get_layout().get_room(_dungeon.get_layout().start_room_index)
        if _dungeon._current_room.room_data.index == start_room.index:
                _log(true, "Player starts in start room")
        else:
                _log(false, "Player not in start room")
        _step_timer = 0.3

func _test_player_can_move_and_shoot() -> void:
        if _player == null:
                _log(false, "Cannot test - no player")
                _step_timer = 0.1
                return
        _player.set_test_aim(Vector2.RIGHT)
        var pos_before := _player.global_position.x
        _fire_action("move_right", true)
        await get_tree().create_timer(0.3).timeout
        _fire_action("move_right", false)
        var pos_after := _player.global_position.x
        if pos_after > pos_before + 5:
                _log(true, "Player can move")
        else:
                _log(false, "Player cannot move")
        # Test shooting
        var proj_count_before := _count_projectiles()
        _fire_action("shoot", true)
        await get_tree().create_timer(0.3).timeout
        _fire_action("shoot", false)
        var proj_count_after := _count_projectiles()
        if proj_count_after > proj_count_before:
                _log(true, "Player can shoot")
        else:
                _log(false, "Player cannot shoot")
        _step_timer = 0.3

func _test_player_can_use_potion() -> void:
        if _player == null:
                _log(false, "Cannot test - no player")
                _step_timer = 0.1
                return
        var hp_before := _player._health.current_hp
        _player._health.take_damage(2)
        await get_tree().create_timer(0.1).timeout
        var potions_before := _player.potions
        _fire_action("use_potion", true)
        await get_tree().process_frame
        await get_tree().process_frame
        _fire_action("use_potion", false)
        await get_tree().create_timer(0.2).timeout
        var hp_after := _player._health.current_hp
        if hp_after > hp_before - 2 and potions_before > _player.potions:
                _log(true, "Player can use potion (hp %d -> %d)" % [hp_before, hp_after])
        else:
                _log(false, "Player cannot use potion (hp %d -> %d, potions %d -> %d)" % [hp_before, hp_after, potions_before, _player.potions])
        _step_timer = 0.3

func _test_player_can_use_skill() -> void:
        if _player == null:
                _log(false, "Cannot test - no player")
                _step_timer = 0.1
                return
        _fire_action("skill", true)
        await get_tree().process_frame
        await get_tree().process_frame
        _fire_action("skill", false)
        await get_tree().create_timer(0.1).timeout
        if _player._skill_cd > 0.0 or _player._health.invuln_timer > 0.5:
                _log(true, "Player can use skill")
        else:
                _log(false, "Player cannot use skill")
        _step_timer = 0.5  # wait for skill cooldown partially

func _test_explore_dungeon() -> void:
        # Walk the player to a door and transition
        if _dungeon == null:
                _log(false, "Cannot test - no dungeon")
                _step_timer = 0.1
                return
        var current_idx := _dungeon._current_room.room_data.index
        var door: DoorData = null
        for d in _dungeon.get_layout().doors:
                if d.from_room == current_idx:
                        door = d
                        break
        if door == null:
                _log(false, "No door from current room")
                _step_timer = 0.1
                return
        # Teleport player to door center (inside the room, at the door position)
        var half_w := Global.ROOM_PIXEL_W * 0.5
        var half_h := Global.ROOM_PIXEL_H * 0.5
        var door_pos: Vector2 = _dungeon._current_room.global_position
        match door.direction:
                Vector2i(1, 0): door_pos += Vector2(half_w - 20, 0)  # just inside the right wall
                Vector2i(-1, 0): door_pos += Vector2(-half_w + 20, 0)
                Vector2i(0, 1): door_pos += Vector2(0, half_h - 20)
                Vector2i(0, -1): door_pos += Vector2(0, -half_h + 20)
        _player.global_position = door_pos
        # Wait for body_entered to fire
        await get_tree().create_timer(0.5).timeout
        # If still not transitioned, try moving toward the door
        if _dungeon._current_room.room_data.index == current_idx:
                # Move player toward the door
                var move_dir: Vector2 = Vector2.ZERO
                match door.direction:
                        Vector2i(1, 0): move_dir = Vector2.RIGHT
                        Vector2i(-1, 0): move_dir = Vector2.LEFT
                        Vector2i(0, 1): move_dir = Vector2.DOWN
                        Vector2i(0, -1): move_dir = Vector2.UP
                _fire_action("move_right" if move_dir == Vector2.RIGHT else "move_left" if move_dir == Vector2.LEFT else "move_down" if move_dir == Vector2.DOWN else "move_up", true)
                await get_tree().create_timer(1.0).timeout
                _fire_action("move_right", false)
                _fire_action("move_left", false)
                _fire_action("move_up", false)
                _fire_action("move_down", false)
        if _dungeon._current_room.room_data.index != current_idx:
                _log(true, "Player transitioned to new room (%d -> %d)" % [current_idx, _dungeon._current_room.room_data.index])
        else:
                _log(false, "Player did not transition")
        _step_timer = 0.3

func _test_pickups_work() -> void:
        # Spawn a coin near the player and verify it's collected
        if _player == null:
                _log(false, "Cannot test - no player")
                _step_timer = 0.1
                return
        var coins_before := _player.coins
        print("[E2E] Player pos=%v hp=%d/%d, room=%d, in_player_group=%s" % [_player.global_position, _player._health.current_hp, _player._health.max_hp, _dungeon._current_room.room_data.index, _player.is_in_group("player")])
        var coin_scene := load("res://scenes/entities/Coin.tscn")
        var coin := coin_scene.instantiate() as Node2D
        _dungeon._current_room.add_child(coin)
        coin.global_position = _player.global_position + Vector2(20, 0)  # set AFTER add_child
        print("[E2E] Spawned coin at %v, player at %v" % [coin.global_position, _player.global_position])
        # Kill nearby enemies first so they don't kill the player
        for e in _dungeon._current_room._spawned_enemies:
                if is_instance_valid(e):
                        e.take_damage(999)
        await get_tree().create_timer(2.0).timeout
        var coins_after := _player.coins
        if coins_after > coins_before:
                _log(true, "Coin pickup works (coins %d -> %d)" % [coins_before, coins_after])
        else:
                _log(false, "Coin pickup failed (coins %d -> %d)" % [coins_before, coins_after])
        _step_timer = 0.3

func _test_kill_all_enemies() -> void:
        if _dungeon == null:
                _log(false, "Cannot test - no dungeon")
                _step_timer = 0.1
                return
        # Find a room with enemies and clear it
        var layout := _dungeon.get_layout()
        var target_room: RoomData = null
        for r in layout.rooms:
                if r.enemy_spawns.size() > 0 and not r.cleared:
                        target_room = r
                        break
        if target_room == null:
                _log(true, "All enemy rooms already cleared")
                _step_timer = 0.3
                return
        # Transition to that room
        var dd := DoorData.new()
        dd.from_room = _dungeon._current_room.room_data.index
        dd.to_room = target_room.index
        dd.direction = Vector2i(1, 0)
        _dungeon.call_deferred("_enter_room", target_room.index, dd)
        await get_tree().create_timer(1.5).timeout
        # Kill all enemies
        var new_room := _dungeon._current_room
        for e in new_room._spawned_enemies:
                if is_instance_valid(e):
                        e.take_damage(999)
        await get_tree().create_timer(1.5).timeout
        if new_room.is_cleared():
                _log(true, "Cleared enemy room")
        else:
                _log(false, "Failed to clear enemy room")
        _step_timer = 0.3

func _test_defeat_boss() -> void:
        if _dungeon == null:
                _log(false, "Cannot test - no dungeon")
                _step_timer = 0.1
                return
        var layout := _dungeon.get_layout()
        var boss_room := layout.get_room(layout.boss_room_index)
        if boss_room == null:
                _log(false, "No boss room")
                _step_timer = 0.1
                return
        # Transition to boss room
        var dd := DoorData.new()
        dd.from_room = _dungeon._current_room.room_data.index
        dd.to_room = boss_room.index
        dd.direction = Vector2i(1, 0)
        _dungeon.call_deferred("_enter_room", boss_room.index, dd)
        await get_tree().create_timer(1.5).timeout
        # Kill the boss
        var new_room := _dungeon._current_room
        var boss_killed := false
        for e in new_room._spawned_enemies:
                if is_instance_valid(e):
                        e.take_damage(999)
                        boss_killed = true
        await get_tree().create_timer(2.0).timeout
        # After boss is defeated, the floor should transition.
        # Check if floor_number increased.
        if _dungeon.floor_number > 1:
                _log(true, "Boss defeated (floor advanced to %d)" % _dungeon.floor_number)
        else:
                _log(false, "Failed to defeat boss or floor did not advance")
        _step_timer = 1.5

func _test_floor_transition() -> void:
        # After defeating boss, should transition to next floor
        await get_tree().create_timer(2.0).timeout
        # Check if a new dungeon runner exists with floor_number = 2
        var found := false
        for child in _main.get_children():
                if child is DungeonRunner and (child as DungeonRunner).floor_number >= 2:
                        found = true
                        _dungeon = child as DungeonRunner
                        break
        if found:
                _log(true, "Floor transition worked (now on floor %d)" % _dungeon.floor_number)
        else:
                _log(false, "Floor transition failed")
        _step_timer = 0.3

# ----- Helpers -----
func _fire_action(action: StringName, pressed: bool = true) -> void:
        var ev := InputEventAction.new()
        ev.action = action
        ev.pressed = pressed
        Input.parse_input_event(ev)

func _count_projectiles() -> int:
        # Find all Projectile instances in the entire tree
        var count := 0
        for child in get_tree().root.get_children():
                count += _count_projectiles_recursive(child)
        return count

func _count_projectiles_recursive(node: Node) -> int:
        var count := 0
        if node is Projectile:
                count += 1
        for child in node.get_children():
                count += _count_projectiles_recursive(child)
        return count

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
        print("E2E Test results: %d passed, %d failed" % [passed, failed])
        if auto_quit:
                await get_tree().create_timer(1.0).timeout
                get_tree().quit(0 if failed == 0 else 1)
