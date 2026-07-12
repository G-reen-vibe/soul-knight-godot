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

func _spawn_player() -> void:
        var player_scene := load("res://scenes/entities/Player.tscn")
        _player = player_scene.instantiate() as Player

func _on_room_cleared(room: Room) -> void:
        print("[Dungeon] Room %d cleared!" % room.room_data.index)

func _process(_delta: float) -> void:
        # Center camera on current room
        if _current_room:
                var cam := _player.get_node_or_null("Camera2D") as Camera2D
                if cam:
                        cam.global_position = _current_room.global_position
