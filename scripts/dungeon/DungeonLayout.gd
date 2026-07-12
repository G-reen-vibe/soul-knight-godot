extends Resource
class_name DungeonLayout
## A complete floor layout.

@export var floor_number: int = 0
@export var rooms: Array[RoomData] = []
@export var doors: Array[DoorData] = []
@export var start_room_index: int = 0
@export var boss_room_index: int = 0

func get_room(idx: int) -> RoomData:
	for r in rooms:
		if r.index == idx:
			return r
	return null

func get_doors_for_room(idx: int) -> Array:
	var result := []
	for d in doors:
		if d.from_room == idx or d.to_room == idx:
			result.append(d)
	return result
