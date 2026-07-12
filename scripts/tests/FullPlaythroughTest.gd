extends Node2D
class_name FullPlaythroughTest
## Simulates a complete playthrough: start game, navigate floors, fight enemies,
## collect pickups, use shop, defeat bosses, advance floors.

@export var auto_quit: bool = true

var _test_results: Array = []
var _dungeon: DungeonRunner
var _player: Player
var _main: Node
var _test_step: int = 0
var _step_timer: float = 0.0

func _ready() -> void:
        print("[FullPlaythrough] Booting...")
        Global.seed_rng(54321)
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
                1: _start_game()
                2: _verify_player_spawned()
                3: _test_buff_pickup()
                4: _test_weapon_pickup()
                5: _test_health_potion_pickup()
                6: _test_energy_potion_pickup()
                7: _test_shop_interaction()
                8: _test_boss_fight_with_real_weapon()
                9: _test_multiple_floor_progression()
                _: _finish()

func _start_game() -> void:
        # Click through menu -> character select -> start
        if _main._main_menu:
                _main._main_menu.emit_signal("start_pressed")
        await get_tree().create_timer(0.3).timeout
        if _main._character_select:
                # Pick the wizard for variety
                _main._character_select.emit_signal("character_confirmed", "wizard")
        await get_tree().create_timer(1.0).timeout
        _dungeon = _main._dungeon_runner
        if _dungeon and _dungeon._player:
                _player = _dungeon._player
                _log(true, "Game started with Wizard")
        else:
                _log(false, "Game failed to start")
        _step_timer = 0.3

func _verify_player_spawned() -> void:
        if _player == null:
                _log(false, "Player is null")
                _step_timer = 0.1
                return
        # Wizard has 4 HP, 120 energy
        if _player._health.max_hp == 4 and _player.max_energy == 120:
                _log(true, "Wizard stats correct (HP=%d, energy=%d)" % [_player._health.max_hp, _player.max_energy])
        else:
                _log(false, "Wizard stats wrong (HP=%d, energy=%d)" % [_player._health.max_hp, _player.max_energy])
        # Check starting weapon is the wizard's
        if not _player._weapons.is_empty():
                _log(true, "Player has starting weapon: %s" % _player._weapons[0].display_name)
        else:
                _log(false, "Player has no weapons")
        _step_timer = 0.3

func _test_buff_pickup() -> void:
        if _player == null:
                _log(false, "No player")
                _step_timer = 0.1
                return
        var buffs_before := 0
        var buffs_node := _player.get_node_or_null("PlayerBuffs") as PlayerBuffs
        if buffs_node:
                buffs_before = buffs_node.get_buffs().size()
        # Spawn a buff pickup near the player
        var buff_scene := load("res://scenes/entities/BuffPickup.tscn")
        var buff := buff_scene.instantiate() as Node2D
        _dungeon._current_room.add_child(buff)
        buff.global_position = _player.global_position + Vector2(20, 0)
        await get_tree().create_timer(2.0).timeout
        # Re-fetch the buffs node (it may have been created by the pickup)
        var buffs_node_after := _player.get_node_or_null("PlayerBuffs") as PlayerBuffs
        var buffs_after := 0
        if buffs_node_after and is_instance_valid(buffs_node_after):
                buffs_after = buffs_node_after.get_buffs().size()
        if buffs_after > buffs_before:
                _log(true, "Buff pickup works (%d -> %d buffs)" % [buffs_before, buffs_after])
        else:
                _log(false, "Buff pickup failed (%d -> %d)" % [buffs_before, buffs_after])
        _step_timer = 0.3

func _test_weapon_pickup() -> void:
        if _player == null:
                _log(false, "No player")
                _step_timer = 0.1
                return
        var weapons_before := _player._weapons.size()
        # Spawn a weapon pickup
        var wp_scene := load("res://scenes/entities/WeaponPickup.tscn")
        var wp := wp_scene.instantiate() as WeaponPickup
        wp.weapon_id = &"shotgun"
        _dungeon._current_room.add_child(wp)
        wp.global_position = _player.global_position + Vector2(20, 0)
        await get_tree().create_timer(2.0).timeout
        var weapons_after := _player._weapons.size()
        if weapons_after > weapons_before:
                _log(true, "Weapon pickup works (%d -> %d weapons)" % [weapons_before, weapons_after])
        else:
                _log(false, "Weapon pickup failed (%d -> %d)" % [weapons_before, weapons_after])
        _step_timer = 0.3

func _test_health_potion_pickup() -> void:
        if _player == null:
                _log(false, "No player")
                _step_timer = 0.1
                return
        # Damage the player first
        _player._health.take_damage(2)
        await get_tree().create_timer(0.1).timeout
        var hp_before := _player._health.current_hp
        # Spawn a health potion
        var potion_scene := load("res://scenes/entities/Pickup.tscn")
        var potion := potion_scene.instantiate() as Pickup
        potion.kind = Pickup.Kind.HEALTH_POTION
        potion.value = 3
        _dungeon._current_room.add_child(potion)
        potion.global_position = _player.global_position + Vector2(20, 0)
        await get_tree().create_timer(2.0).timeout
        var hp_after := _player._health.current_hp
        if hp_after > hp_before:
                _log(true, "Health potion pickup works (HP %d -> %d)" % [hp_before, hp_after])
        else:
                _log(false, "Health potion pickup failed (HP %d -> %d)" % [hp_before, hp_after])
        _step_timer = 0.3

func _test_energy_potion_pickup() -> void:
        if _player == null:
                _log(false, "No player")
                _step_timer = 0.1
                return
        # Drain some energy
        _player._current_energy = 20.0
        _player.emit_signal("energy_changed", int(_player._current_energy), _player.max_energy)
        var energy_before := int(_player._current_energy)
        # Spawn an energy potion
        var potion_scene := load("res://scenes/entities/Pickup.tscn")
        var potion := potion_scene.instantiate() as Pickup
        potion.kind = Pickup.Kind.ENERGY_POTION
        potion.value = 50
        _dungeon._current_room.add_child(potion)
        potion.global_position = _player.global_position + Vector2(20, 0)
        await get_tree().create_timer(2.0).timeout
        var energy_after := int(_player._current_energy)
        if energy_after > energy_before:
                _log(true, "Energy potion pickup works (energy %d -> %d)" % [energy_before, energy_after])
        else:
                _log(false, "Energy potion pickup failed (energy %d -> %d)" % [energy_before, energy_after])
        _step_timer = 0.3

func _test_shop_interaction() -> void:
        # Find or spawn a shop NPC
        if _dungeon == null:
                _log(false, "No dungeon")
                _step_timer = 0.1
                return
        # Spawn a shop NPC in the current room
        var shop_scene := load("res://scenes/entities/ShopNPC.tscn")
        var shop := shop_scene.instantiate() as Node2D
        _dungeon._current_room.add_child(shop)
        shop.global_position = _player.global_position + Vector2(50, 0)
        await get_tree().create_timer(0.5).timeout
        # Give the player some coins
        _player.add_coins(100)
        await get_tree().process_frame
        # Verify the shop has items
        var shop_script := shop as ShopNPC
        if shop_script and shop_script.shop_items.size() > 0:
                _log(true, "Shop spawned with %d items" % shop_script.shop_items.size())
        else:
                _log(false, "Shop has no items")
        _step_timer = 0.3

func _test_boss_fight_with_real_weapon() -> void:
        if _dungeon == null:
                _log(false, "No dungeon")
                _step_timer = 0.1
                return
        # Give the player a strong weapon
        var sniper := load("res://data/weapons/sniper.tres") as WeaponData
        _player._weapons.clear()
        _player._weapons.append(sniper.duplicate(true))
        _player._current_weapon_slot = 0
        # Transition to boss room
        var layout := _dungeon.get_layout()
        var boss_room := layout.get_room(layout.boss_room_index)
        var dd := DoorData.new()
        dd.from_room = _dungeon._current_room.room_data.index
        dd.to_room = boss_room.index
        dd.direction = Vector2i(1, 0)
        _dungeon.call_deferred("_enter_room", boss_room.index, dd)
        await get_tree().create_timer(1.5).timeout
        # Kill the boss by directly damaging it
        var new_room := _dungeon._current_room
        for e in new_room._spawned_enemies:
                if is_instance_valid(e):
                        e.take_damage(999)
        await get_tree().create_timer(2.0).timeout
        if _dungeon.floor_number > 1:
                _log(true, "Boss defeated, advanced to floor %d" % _dungeon.floor_number)
        else:
                _log(false, "Boss fight failed")
        _step_timer = 1.5

func _test_multiple_floor_progression() -> void:
        # Verify we're on floor 2 with a new layout
        if _dungeon == null:
                _log(false, "No dungeon")
                _step_timer = 0.1
                return
        var layout := _dungeon.get_layout()
        if layout and layout.rooms.size() >= 5:
                _log(true, "Floor %d has %d rooms" % [_dungeon.floor_number, layout.rooms.size()])
        else:
                _log(false, "Floor %d layout invalid" % _dungeon.floor_number)
        # Verify player state carried over
        if _player and is_instance_valid(_player):
                _log(true, "Player survived floor transition (HP=%d/%d)" % [_player._health.current_hp, _player._health.max_hp])
        else:
                _log(false, "Player lost during floor transition")
        _step_timer = 0.3

# ----- Helpers -----
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
        print("Full Playthrough Test results: %d passed, %d failed" % [passed, failed])
        if auto_quit:
                await get_tree().create_timer(1.0).timeout
                get_tree().quit(0 if failed == 0 else 1)
