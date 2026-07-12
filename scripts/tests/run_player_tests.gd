extends SceneTree
## Test runner that simulates player actions to verify functionality.
## Usage: godot --headless --script res://scripts/tests/run_player_tests.gd

func _init() -> void:
	print("=== Running Player Tests ===")
	var scene := load("res://scenes/tests/TestPlayerArena.tscn").instantiate() as Node2D
	root.add_child(scene)
	# Wait for ready
	await process_frame
	await process_frame
	var player := scene.get_node_or_null("Player") as Player
	if player == null:
		print("FAIL: Player not found in test scene.")
		quit(1)
		return
	print("PASS: Player instantiated")
	print("  position: ", player.global_position)
	print("  HP: %d/%d" % [player._health.current_hp, player._health.max_hp])
	print("  Energy: %d/%d" % [int(player._current_energy), player.max_energy])
	# Simulate movement input
	Input.action_press("move_right")
	await process_frame
	await process_frame
	await process_frame
	var pos_after := player.global_position.x
	if pos_after > 0.0:
		print("PASS: Player moves right (x=%.1f)" % pos_after)
	else:
		print("FAIL: Player did not move right (x=%.1f)" % pos_after)
	Input.action_release("move_right")
	# Test firing
	var dummies := get_nodes_in_group("dummy") if false else []
	# Actually let's count target dummies in scene
	var dummy_count := 0
	for child in scene.get_children():
		if child is TargetDummy:
			dummy_count += 1
	print("  Target dummies in scene: ", dummy_count)
	# Press shoot
	Input.action_press("shoot")
	for i in range(60):
		await process_frame
	Input.action_release("shoot")
	# Check if any dummies died (didn't queue_free yet or are gone)
	var dummy_count_after := 0
	for child in scene.get_children():
		if child is TargetDummy:
			dummy_count_after += 1
	print("  Target dummies after 1s firing: ", dummy_count_after)
	if dummy_count_after < dummy_count:
		print("PASS: Player can destroy targets")
	else:
		print("FAIL: No targets destroyed")
	# Test potion use
	var hp_before := player._health.current_hp
	player._health.take_damage(2)
	Input.action_press("use_potion")
	await process_frame
	Input.action_release("use_potion")
	await process_frame
	var hp_after := player._health.current_hp
	if hp_after > hp_before - 2:
		print("PASS: Potion heals (hp_before=%d, after_hit=%d, after_potion=%d)" % [hp_before, hp_before-2, hp_after])
	else:
		print("FAIL: Potion did not heal (hp_before=%d, hp_after=%d)" % [hp_before, hp_after])
	# Test skill
	Input.action_press("skill")
	await process_frame
	Input.action_release("skill")
	await process_frame
	if player._skill_cd > 0.0:
		print("PASS: Skill activated (cooldown=%.2f)" % player._skill_cd)
	else:
		print("FAIL: Skill not activated")
	# Test dodge
	Input.action_press("move_up")
	Input.action_press("dash")
	for i in range(20):
		await process_frame
	Input.action_release("move_up")
	Input.action_release("dash")
	if player._dodge_cd_timer > 0.0:
		print("PASS: Dodge executed (cooldown=%.2f)" % player._dodge_cd_timer)
	else:
		print("FAIL: Dodge not executed")
	print("=== Tests complete ===")
	quit(0)
