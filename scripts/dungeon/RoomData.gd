extends Resource
class_name RoomData
## Data describing a single room in a dungeon floor.

@export var index: int = 0
@export var grid_pos: Vector2i = Vector2i.ZERO
@export var world_position: Vector2 = Vector2.ZERO
@export var type: int = 0  # DungeonGenerator.RoomType
@export var connections: Array[int] = []  # indices of connected rooms
@export var enemy_spawns: Array = []  # Array of {"kind": String, "pos": Vector2}
@export var cleared: bool = false
@export var visited: bool = false
