extends Node2D
class_name EnemyTestRunner
## Scene-based test runner for enemy AI.

@export var auto_quit: bool = true
@export var quit_delay: float = 1.0

var _test_results: Array = []
var _player: Player
var _test_step: int = 0
var _step_timer: float = 0.0
var _enemies: Array = []

func _ready() -> void:
        print("[EnemyTestRunner] Booting enemy tests...")
        # Add the player to "player" group (for enemy targeting)
        await get_tree().process_frame
        _player = get_node_or_null("Player") as Player
        if _player == null:
                print("FAIL: Player not found")
                _finish()
                return
        _player.add_to_group("player")
        # Give the player an overpowered weapon for testing
        var op_w := WeaponData.new()
        op_w.id = &"test_pistol"
        op_w.fire_mode = WeaponData.FireMode.AUTO
        op_w.damage = 5
        op_w.energy_cost = 0
        op_w.fire_rate = 8.0
        op_w.projectile_speed = 700.0
        op_w.projectile_range = 600.0
        op_w.projectile_color = Color(1, 0.5, 0.5)
        op_w.projectile_radius = 5.0
        _player._weapons.clear()
        _player._weapons.append(op_w)
        _player._current_weapon_slot = 0
        _player.set_test_aim(Vector2.RIGHT)
        # Spawn enemies
        _spawn_enemies()
        _step_timer = 1.0
        set_process(true)

func _spawn_enemies() -> void:
        var grunt_scene := load("res://scenes/entities/EnemyGrunt.tscn")
        var shooter_scene := load("res://scenes/entities/EnemyShooter.tscn")
        # Spawn grunts to the right
        for i in range(3):
                var g := grunt_scene.instantiate() as Node2D
                g.global_position = Vector2(400 + i * 80, 0)
                add_child(g)
                _enemies.append(g)
        # Spawn a shooter
        var s := shooter_scene.instantiate() as Node2D
        s.global_position = Vector2(500, -150)
        add_child(s)
        _enemies.append(s)

func _process(delta: float) -> void:
        if _step_timer > 0.0:
                _step_timer -= delta
                if _step_timer <= 0.0:
                        _run_next_step()

func _run_next_step() -> void:
        _test_step += 1
        match _test_step:
                1: _test_enemies_chase()
                2: _test_player_kills_enemies()
                3: _test_contact_damage()
                _: _finish()

func _test_enemies_chase() -> void:
        # Wait an additional second for enemies to move close
        await get_tree().create_timer(1.0).timeout
        var moved_count := 0
        for e in _enemies:
                if not is_instance_valid(e):
                        continue
                if e.global_position.x < 400.0:
                        moved_count += 1
        if moved_count >= 2:
                _log(true, "Enemies chase player (%d/%d moved closer)" % [moved_count, _enemies.size()])
        else:
                _log(false, "Enemies did not chase (%d/%d moved closer)" % [moved_count, _enemies.size()])
        _step_timer = 0.5

func _test_player_kills_enemies() -> void:
        # Player aims right and fires; grunts should die
        var alive_before := _count_alive_enemies()
        _player.set_test_aim(Vector2.RIGHT)
        var ev_press := InputEventAction.new()
        ev_press.action = "shoot"
        ev_press.pressed = true
        Input.parse_input_event(ev_press)
        await get_tree().create_timer(2.5).timeout
        var ev_release := InputEventAction.new()
        ev_release.action = "shoot"
        ev_release.pressed = false
        Input.parse_input_event(ev_release)
        await get_tree().create_timer(0.3).timeout
        var alive_after := _count_alive_enemies()
        if alive_after < alive_before:
                _log(true, "Player killed enemies (%d -> %d)" % [alive_before, alive_after])
        else:
                _log(false, "Player did not kill enemies (%d -> %d)" % [alive_before, alive_after])
        _step_timer = 0.5

func _test_contact_damage() -> void:
        # Spawn a fresh grunt right on top of the player to guarantee contact
        var hp_before := _player._health.current_hp
        var grunt_scene := load("res://scenes/entities/EnemyGrunt.tscn")
        var target_enemy: Node2D = grunt_scene.instantiate()
        target_enemy.global_position = _player.global_position + Vector2(15, 0)
        add_child(target_enemy)
        await get_tree().create_timer(1.5).timeout
        var hp_after := _player._health.current_hp
        if hp_after < hp_before:
                _log(true, "Enemy deals contact damage (hp %d -> %d)" % [hp_before, hp_after])
        else:
                _log(false, "Enemy did not deal contact damage (hp %d -> %d)" % [hp_before, hp_after])
        _step_timer = 0.5

func _count_alive_enemies() -> int:
        var count := 0
        for e in _enemies:
                if is_instance_valid(e) and not e._is_dead:
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
