extends Node2D
class_name PlayerTestRunner
## Scene-based test runner. Attach to a Node2D that has the test scene as a sibling.
## Runs tests, prints PASS/FAIL, and quits the app after.

@export var tests_to_run: int = 10
@export var auto_quit: bool = true
@export var quit_delay: float = 1.0

var _test_results: Array = []
var _player: Player
var _test_arena: Node2D
var _test_step: int = 0
var _step_timer: float = 0.0

func _ready() -> void:
        print("[TestRunner] Booting player tests...")
        # Spawn target dummies since the inherited script's _ready was overridden.
        _spawn_dummies()
        # Wait a couple frames for the scene tree to settle
        await get_tree().process_frame
        await get_tree().process_frame
        _test_arena = self
        _player = _test_arena.get_node_or_null("Player") as Player
        if _player == null:
                print("FAIL: Player not found")
                _finish()
                return
        print("PASS: Player instantiated")
        # Run tests sequentially using a step timer
        _step_timer = 0.3
        set_process(true)

func _spawn_dummies() -> void:
        var target_scene := load("res://scenes/entities/TargetDummy.tscn")
        for i in range(5):
                var t := target_scene.instantiate() as Node2D
                t.global_position = Vector2(300 + i * 80, -100 + (i % 2) * 200)
                add_child(t)

func _process(delta: float) -> void:
        if _step_timer > 0.0:
                _step_timer -= delta
                if _step_timer <= 0.0:
                        _run_next_step()

func _run_next_step() -> void:
        _test_step += 1
        match _test_step:
                1: _test_movement()
                2: _test_firing()
                3: _test_potion()
                4: _test_skill()
                5: _test_dodge()
                6: _test_weapon_switch()
                _: _finish()

# ----- Helpers for input simulation -----
func _fire_action(action: StringName, pressed: bool = true) -> void:
        var ev := InputEventAction.new()
        ev.action = action
        ev.pressed = pressed
        Input.parse_input_event(ev)

func _hold_action_for(action: StringName, duration: float) -> void:
        _fire_action(action, true)
        await get_tree().create_timer(duration).timeout
        _fire_action(action, false)

# ----- Individual tests -----
func _test_movement() -> void:
        var x_before := _player.global_position.x
        _fire_action("move_right", true)
        await get_tree().create_timer(0.3).timeout
        _fire_action("move_right", false)
        var x_after := _player.global_position.x
        if x_after > x_before + 5.0:
                _log(true, "Player moved right (%.1f -> %.1f)" % [x_before, x_after])
        else:
                _log(false, "Player did not move right (%.1f -> %.1f)" % [x_before, x_after])
        _step_timer = 0.1

func _test_firing() -> void:
        var dummies_before := _count_dummies()
        # Force the player to aim right (since mouse position is unreliable in headless mode)
        _player.set_test_aim(Vector2.RIGHT)
        # Reposition any dummies that are off-axis so the bullet path hits them
        for child in _test_arena.get_children():
                if child is TargetDummy:
                        child.global_position.y = 0
                        child.global_position.x = 300.0 + randf() * 200.0
        await get_tree().process_frame
        await _hold_action_for("shoot", 1.5)
        var dummies_after := _count_dummies()
        if dummies_after < dummies_before:
                _log(true, "Player destroyed dummies (%d -> %d)" % [dummies_before, dummies_after])
        else:
                _log(false, "Player did not destroy dummies (%d -> %d)" % [dummies_before, dummies_after])
        _step_timer = 0.1

func _test_potion() -> void:
        var hp_before := _player._health.current_hp
        _player._health.take_damage(2)
        await get_tree().create_timer(0.2).timeout
        var hp_after_hit := _player._health.current_hp
        # Trigger the use_potion via input event
        _fire_action("use_potion", true)
        await get_tree().process_frame
        await get_tree().process_frame
        _fire_action("use_potion", false)
        await get_tree().create_timer(0.2).timeout
        var hp_after := _player._health.current_hp
        if hp_after > hp_after_hit:
                _log(true, "Potion healed (hp_before=%d, after_hit=%d, after_potion=%d)" % [hp_before, hp_after_hit, hp_after])
        else:
                _log(false, "Potion did not heal (hp_before=%d, after_hit=%d, hp_after=%d)" % [hp_before, hp_after_hit, hp_after])
        _step_timer = 0.1

func _test_skill() -> void:
        # Default skill gives 2s of invulnerability, set after a 2s await
        # So check invuln_timer is set immediately when _default_skill starts
        _fire_action("skill", true)
        await get_tree().process_frame
        await get_tree().process_frame
        _fire_action("skill", false)
        await get_tree().create_timer(0.1).timeout
        # _default_skill sets _health.invuln_timer = 2.0 synchronously at start
        if _player._health.invuln_timer > 1.5:
                _log(true, "Skill activated (invuln=%.2f)" % _player._health.invuln_timer)
        else:
                _log(false, "Skill did not activate (invuln=%.2f)" % _player._health.invuln_timer)
        _step_timer = 0.1

func _test_dodge() -> void:
        _fire_action("move_up", true)
        _fire_action("dash", true)
        await get_tree().create_timer(0.5).timeout
        _fire_action("move_up", false)
        _fire_action("dash", false)
        if _player._dodge_cd_timer > 0.0 or _player._dodge_timer > 0.0:
                _log(true, "Dodge triggered")
        else:
                _log(false, "Dodge not triggered")
        _step_timer = 0.1

func _test_weapon_switch() -> void:
        # Add a sword to inventory so we have something to switch to
        if _player._weapons.size() < 2:
                var sword := load("res://data/weapons/sword.tres") as WeaponData
                _player._weapons.append(sword.duplicate(true))
        var slot_before := _player._current_weapon_slot
        _fire_action("switch_weapon", true)
        await get_tree().process_frame
        await get_tree().process_frame
        _fire_action("switch_weapon", false)
        await get_tree().process_frame
        var slot_after := _player._current_weapon_slot
        if slot_after != slot_before:
                _log(true, "Weapon switched (slot %d -> %d)" % [slot_before, slot_after])
        else:
                _log(false, "Weapon did not switch")
        _step_timer = 0.1

# ----- Helpers -----
func _count_dummies() -> int:
        var count := 0
        if _test_arena == null:
                return 0
        for child in _test_arena.get_children():
                if child is TargetDummy:
                        count += 1
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
        print("Test results: %d passed, %d failed" % [passed, failed])
        if auto_quit:
                await get_tree().create_timer(quit_delay).timeout
                get_tree().quit(0 if failed == 0 else 1)
