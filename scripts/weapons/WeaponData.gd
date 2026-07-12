extends Resource
class_name WeaponData
## Static data describing a weapon. Loaded from .tres files in res://data/weapons/.

@export var id: StringName = &"pistol"
@export var display_name: String = "Pistol"
@export var description: String = "Standard sidearm."
@export_category("Type")
enum WeaponCategory { MELEE, RANGED, BEAM, SPECIAL }
enum FireMode { SINGLE, AUTO, CHARGE, SHOTGUN, BURST }
@export var category: WeaponCategory = WeaponCategory.RANGED
@export var fire_mode: FireMode = FireMode.SINGLE
@export var is_ranged: bool = true

@export_category("Stats")
@export var damage: int = 1
@export var energy_cost: int = 0
@export var fire_rate: float = 6.0  # shots per second
@export_range(0, 10000) var projectile_speed: float = 600.0
@export_range(0, 5000) var projectile_range: float = 500.0  # max bullet travel
@export_range(0, 360) var spread_degrees: float = 0.0  # total cone, divided among pellets
@export_range(1, 30) var pellets: int = 1
@export var burst_count: int = 1
@export var burst_delay: float = 0.06
@export_range(0, 50) var knockback: float = 0.0
@export var pierce: int = 0  # bullet pierces N enemies
@export_range(0, 360) var melee_arc_degrees: float = 90.0
@export var melee_range: float = 70.0
@export var charge_time: float = 0.0
@export var charge_damage_multiplier: float = 2.0

@export_category("Visuals")
@export var projectile_color: Color = Color.YELLOW
@export var projectile_radius: float = 4.0
@export var projectile_trail: bool = false
@export var melee_color: Color = Color.WHITE
@export var shake_amount: float = 0.5

@export_category("VFX")
@export var muzzle_flash: bool = true
@export var bullet_scene: PackedScene = null  # override default
@export var hit_particles: bool = true
