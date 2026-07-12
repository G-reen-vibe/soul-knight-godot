extends Node2D
class_name WeaponTestRunner
## Tests that each weapon type functions correctly.

@export var auto_quit: bool = true

var _test_results: Array = []
var _player: Player
var _test_step: int = 0
var _step_timer: float = 0.0

# Weapons to test
var _weapon_paths: Array = [
        "res://data/weapons/pistol.tres",
        "res://data/weapons/sword.tres",
        "res://data/weapons/shotgun.tres",
        "res://data/weapons/smg.tres",
        "res://data/weapons/sniper.tres",
        "res://data/weapons/burst_rifle.tres",
        "res://data/weapons/rocket_launcher.tres",
        "res://data/weapons/charge_pistol.tres",
]
var _current_weapon_idx: int = 0
var _dummies_before: int = 0

func _ready() -> void:
        print("[WeaponTestRunner] Booting weapon tests...")
        await get_tree().process_frame
        _player = get_node_or_null("Player") as Player
        if _player == null:
                print("FAIL: Player not found")
                _finish()
                return
        _player.add_to_group("player")
        _step_timer = 0.5
        set_process(true)

func _process(delta: float) -> void:
        if _step_timer > 0.0:
                _step_timer -= delta
                if _step_timer <= 0.0:
                        _run_next_step()

func _run_next_step() -> void:
        if _current_weapon_idx >= _weapon_paths.size():
                _finish()
                return
        _test_current_weapon()

func _test_current_weapon() -> void:
        var path: String = _weapon_paths[_current_weapon_idx]
        var weapon := load(path) as WeaponData
        if weapon == null:
                _log(false, "Could not load weapon: %s" % path)
                _advance()
                return
        # Equip the weapon
        _player._weapons.clear()
        _player._weapons.append(weapon.duplicate(true))
        _player._current_weapon_slot = 0
        _player.set_test_aim(Vector2.RIGHT)
        # Clear existing dummies and spawn fresh ones in a line to the right
        _clear_dummies()
        _spawn_dummies()
        _dummies_before = _count_dummies()
        # Fire for 2 seconds (or use charge if applicable)
        if weapon.fire_mode == WeaponData.FireMode.CHARGE:
                # Hold to charge, release
                _fire_action("shoot", true)
                await get_tree().create_timer(1.2).timeout
                _fire_action("shoot", false)
                await get_tree().create_timer(0.5).timeout
        else:
                _fire_action("shoot", true)
                await get_tree().create_timer(2.0).timeout
                _fire_action("shoot", false)
                await get_tree().create_timer(0.3).timeout
        var dummies_after := _count_dummies()
        if dummies_after < _dummies_before:
                _log(true, "%s destroyed dummies (%d -> %d)" % [weapon.display_name, _dummies_before, dummies_after])
        else:
                _log(false, "%s did not destroy any dummies (%d -> %d)" % [weapon.display_name, _dummies_before, dummies_after])
        _advance()

func _advance() -> void:
        _current_weapon_idx += 1
        _step_timer = 0.3

# ----- Helpers -----
func _fire_action(action: StringName, pressed: bool = true) -> void:
        var ev := InputEventAction.new()
        ev.action = action
        ev.pressed = pressed
        Input.parse_input_event(ev)

func _clear_dummies() -> void:
        for child in get_children():
                if child is TargetDummy:
                        child.queue_free()
        await get_tree().process_frame

func _spawn_dummies() -> void:
        var scene := load("res://scenes/entities/TargetDummy.tscn")
        for i in range(5):
                var d := scene.instantiate() as Node2D
                d.global_position = Vector2(200 + i * 60, 0)
                add_child(d)

func _count_dummies() -> int:
        var count := 0
        for child in get_children():
                if child is TargetDummy:
                        # Check if dummy is still "alive" via its health component
                        var dummy := child as TargetDummy
                        var health := dummy.get_node_or_null("HealthComponent") as HealthComponent
                        if health and not health.is_dead:
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
                await get_tree().create_timer(1.0).timeout
                get_tree().quit(0 if failed == 0 else 1)
