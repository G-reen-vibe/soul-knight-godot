extends Node2D
class_name DungeonRunner
## Manages the active floor: spawns rooms, moves player between rooms.
## This is the in-game scene that hosts a single floor.

@export var floor_number: int = 1

var _layout: DungeonLayout
var _current_room: Room
var _player: Player
var _rooms_by_index: Dictionary = {}
var _hud: HUD

func _ready() -> void:
        # Generate layout
        _layout = DungeonGenerator.generate(floor_number)
        # Spawn HUD
        var hud_script := load("res://scripts/ui/HUD.gd")
        var hud_node := CanvasLayer.new()
        hud_node.set_script(hud_script)
        hud_node.name = "HUD"
        add_child(hud_node)
        _hud = hud_node as HUD
        _hud.set_floor(floor_number)
        # Spawn the start room (which creates the player)
        _enter_room(_layout.start_room_index, null)
        # Now connect player to HUD
        if _player:
                _hud.set_player(_player)

func get_layout() -> DungeonLayout:
        return _layout

func _on_door_entered(door: DoorData) -> void:
        print("[Dungeon] Player entered door -> room %d" % door.to_room)
        # Defer the actual transition to avoid physics-state errors (we're inside body_entered)
        call_deferred("_enter_room", door.to_room, door)

func _enter_room(room_idx: int, from_door: DoorData) -> void:
        # Cleanup previous room
        if _current_room:
                _current_room.deactivate()
        # Spawn or reuse the new room
        if _rooms_by_index.has(room_idx):
                _current_room = _rooms_by_index[room_idx]
        else:
                var room_scene := load("res://scenes/dungeon/Room.tscn")
                var room := room_scene.instantiate() as Room
                add_child(room)
                var rdata := _layout.get_room(room_idx)
                room.setup(rdata, floor_number)
                room.room_cleared.connect(_on_room_cleared)
                room.door_entered.connect(_on_door_entered)
                _rooms_by_index[room_idx] = room
                _current_room = room
        # Make sure the player exists
        if _player == null:
                _spawn_player()
        # Position player at entrance opposite to from_door
        var player_start := Vector2.ZERO
        if from_door:
                # Place player on opposite side
                var offset: float = Global.ROOM_PIXEL_W * 0.4
                match from_door.direction:
                        Vector2i(1, 0): player_start = Vector2(-offset, 0)  # came from left, place left? no, opposite
                        Vector2i(-1, 0): player_start = Vector2(offset, 0)
                        Vector2i(0, 1): player_start = Vector2(0, -offset)
                        Vector2i(0, -1): player_start = Vector2(0, offset)
        else:
                player_start = Vector2.ZERO
        # Move player to room's local position + offset
        if _player.get_parent() != null:
                _player.get_parent().remove_child(_player)
        _current_room.add_child(_player)
        _player.global_position = _current_room.global_position + player_start
        _player.add_to_group("player")
        _current_room.activate(_player)
        # Set door cooldown to prevent immediate back-transition
        _current_room.set_door_cooldown(0.5)

func _spawn_player() -> void:
        var player_scene := load("res://scenes/entities/Player.tscn")
        _player = player_scene.instantiate() as Player

func _on_room_cleared(room: Room) -> void:
        print("[Dungeon] Room %d cleared!" % room.room_data.index)
        # If this is the boss room, advance to the next floor
        if room.room_data.type == 2:  # BOSS
                call_deferred("_advance_to_next_floor")

func _advance_to_next_floor() -> void:
        print("[Dungeon] Boss defeated! Advancing to next floor...")
        # Carry over player state
        if _player:
                Global.carry_max_hp = _player._health.max_hp
                Global.carry_current_hp = _player._health.current_hp
                Global.carry_armor = _player._health.current_armor
                Global.carry_max_energy = _player.max_energy
                Global.carry_current_energy = int(_player._current_energy)
                Global.carry_potions = _player.potions
                var weapon_ids: Array = []
                for w in _player._weapons:
                        weapon_ids.append(String(w.id))
                Global.carry_weapon_ids = weapon_ids
        Global.current_run_floor += 1
        # Save progress
        if Global.current_run_floor > Global.highest_floor:
                Global.highest_floor = Global.current_run_floor
                Global.save_progress()
        # Regenerate the floor in-place (deferred to allow physics to settle)
        floor_number += 1
        call_deferred("_regenerate_floor")

func _regenerate_floor() -> void:
        # Free old rooms
        for room in _rooms_by_index.values():
                if is_instance_valid(room):
                        room.queue_free()
        _rooms_by_index.clear()
        # Remove the player from its current parent so it doesn't get freed with the room
        if _player and _player.get_parent() != null:
                _player.get_parent().remove_child(_player)
        # Generate new layout
        _layout = DungeonGenerator.generate(floor_number)
        # Update HUD
        if _hud:
                _hud.set_floor(floor_number)
        # Enter the new start room
        _enter_room(_layout.start_room_index, null)
        # Reconnect HUD to player (player was recreated by _enter_room)
        if _player and _hud:
                _hud.set_player(_player)

func _process(_delta: float) -> void:
        # Center camera on current room
        if _current_room and _player and is_instance_valid(_player):
                var cam := _player.get_node_or_null("Camera2D") as Camera2D
                if cam:
                        cam.global_position = _current_room.global_position
