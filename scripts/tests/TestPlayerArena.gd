extends Node2D
## Test scene for player movement and shooting.
## Run with: godot --headless --path . res://scenes/tests/TestPlayerArena.tscn
## (But for visual testing, use --display-driver x11 / a real display.)

func _ready() -> void:
	print("[TestArena] Ready. Player should be at origin.")
	print("[TestArena] Controls: WASD move, J/LMB shoot, K skill, Space dodge, U switch, Q potion.")
	# Spawn some target dummies to test shooting
	_spawn_targets()

func _spawn_targets() -> void:
	var target_scene := load("res://scenes/entities/TargetDummy.tscn")
	for i in range(5):
		var t := target_scene.instantiate() as Node2D
		t.global_position = Vector2(300 + i * 80, -100 + (i % 2) * 200)
		add_child(t)
