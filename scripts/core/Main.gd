extends Node2D
## Main entry point. Routes to the appropriate scene based on game state.
## For now we just go straight to the test arena.

func _ready() -> void:
        print("[Main] Booting Soul Knight...")
        # Boot directly into the test arena for now.
        # Once we have a real menu, we'll route via state.
        var arena: Node = load("res://scenes/tests/TestPlayerArena.tscn").instantiate()
        add_child(arena)
