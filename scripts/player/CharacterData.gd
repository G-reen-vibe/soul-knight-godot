extends Resource
class_name CharacterData
## Static data describing a playable character.

@export var id: StringName = &"knight"
@export var display_name: String = "Knight"
@export var description: String = "A balanced fighter."
@export var max_hp: int = 5
@export var max_armor: int = 0
@export var max_energy: int = 100
@export var energy_regen: float = 25.0
@export var move_speed: float = 240.0
@export var skill_cooldown: float = 6.0
@export var skill_description: String = "Default skill"
@export var starting_weapon_id: StringName = &"pistol"
@export var body_color: Color = Color(0.3, 0.7, 0.9, 1.0)
@export var skill_script_path: String = ""  # path to a GDScript with activate_skill(player) method
