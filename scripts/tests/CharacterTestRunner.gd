extends Node2D
class_name CharacterTestRunner
## Tests that each character's skill activates correctly.

@export var auto_quit: bool = true

var _test_results: Array = []
var _player: Player
var _test_step: int = 0
var _step_timer: float = 0.0
var _character_ids: Array = ["knight", "wizard", "rogue", "alchemist", "engineer"]
var _current_idx: int = 0

func _ready() -> void:
        print("[CharacterTestRunner] Booting character tests...")
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
        if _current_idx >= _character_ids.size():
                _finish()
                return
        _test_current_character()

func _test_current_character() -> void:
        var char_id: String = _character_ids[_current_idx]
        var path := "res://data/characters/%s.tres" % char_id
        var char_data := load(path) as CharacterData
        if char_data == null:
                _log(false, "Could not load character: %s" % char_id)
                _advance()
                return
        # Apply character data
        _player.character_data = char_data
        _player._apply_character_data()
        # Verify skill handler is set
        if _player._skill_handler == null:
                _log(false, "%s: skill handler not set" % char_data.display_name)
                _advance()
                return
        # Get pre-skill state
        var hp_before := _player._health.current_hp
        var pos_before := _player.global_position
        # Activate skill
        _player._activate_skill()
        await get_tree().create_timer(0.5).timeout
        # Check that the skill produced some effect
        var skill_effect_detected := _detect_skill_effect(char_id, hp_before, pos_before)
        if skill_effect_detected:
                _log(true, "%s: skill activated with effect" % char_data.display_name)
        else:
                _log(false, "%s: skill did not produce an effect" % char_data.display_name)
        # Wait for skill to finish
        await get_tree().create_timer(3.0).timeout
        _advance()

func _detect_skill_effect(char_id: String, hp_before: int, pos_before: Vector2) -> bool:
        match char_id:
                "knight":
                        # Knight gets invuln
                        return _player._health.invuln_timer > 0.5
                "wizard":
                        # Wizard spawns projectiles - check scene for projectiles
                        return _count_projectiles() > 5
                "rogue":
                        # Rogue moves (teleports)
                        return _player.global_position.distance_to(pos_before) > 50.0
                "alchemist":
                        # Alchemist spawns a poison cloud (a Node2D with a ColorRect child)
                        return _count_clouds() >= 1
                "engineer":
                        # Engineer spawns a turret
                        return _count_turrets() >= 1
        return false

func _count_projectiles() -> int:
        var count := 0
        if get_tree().current_scene == null:
                return 0
        for child in get_tree().current_scene.get_children():
                if child is Projectile:
                        count += 1
        return count

func _count_clouds() -> int:
        # Look for nodes with the "is_poison_cloud" meta
        var count := 0
        if get_tree().current_scene == null:
                return 0
        for child in get_tree().current_scene.get_children():
                if child is Node2D and child.has_meta("is_poison_cloud"):
                        count += 1
        return count

func _count_turrets() -> int:
        # Look for nodes with the "is_turret" meta
        var count := 0
        if get_tree().current_scene == null:
                return 0
        for child in get_tree().current_scene.get_children():
                if child is Node2D and child.has_meta("is_turret"):
                        count += 1
        return count

func _advance() -> void:
        _current_idx += 1
        _step_timer = 0.3

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
