extends Resource
class_name DoorData
## Describes a door between two rooms.

@export var from_room: int = 0
@export var to_room: int = 0
@export var direction: Vector2i = Vector2i.ZERO  # grid direction from -> to
@export var locked: bool = false
