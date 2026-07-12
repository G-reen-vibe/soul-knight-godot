extends Node
## Global game state and helpers.
## Autoloaded as `Global`.

# ----- Game state -----
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER, VICTORY }

var state: int = GameState.MENU
var current_character_id: String = "knight"
var current_run_floor: int = 0
var coins: int = 0
var gems: int = 0

# Cross-scene transfer: player enters next floor with current HP/energy.
var carry_max_hp: int = 5
var carry_current_hp: int = 5
var carry_max_energy: int = 100
var carry_current_energy: int = 100
var carry_armor: int = 0
var carry_potions: int = 1
var carry_weapon_ids: Array = ["pistol"]
var carry_buffs: Array = []  # Array of buff resource paths strings

# Persistent unlock state (saved to user://save.cfg)
var unlocked_characters: Array = ["knight"]
var unlocked_weapons: Array = ["pistol", "sword"]
var highest_floor: int = 0

# ----- Constants -----
const TILE_SIZE: int = 64
const ROOM_GRID_W: int = 16  # tiles per room width
const ROOM_GRID_H: int = 11  # tiles per room height
const ROOM_PIXEL_W: int = 16 * 64  # 1024
const ROOM_PIXEL_H: int = 11 * 64  # 704

# ----- Signals -----
signal state_changed(new_state: int)
signal coins_changed(amount: int)
signal gems_changed(amount: int)

# ----- RNG -----
# Per-run deterministic-ish RNG so we can reproduce issues.
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func seed_rng(seed_val: int) -> void:
        _rng.seed = seed_val

func rng() -> RandomNumberGenerator:
        return _rng

func random_int(min_val: int, max_val: int) -> int:  # inclusive
        return _rng.randi_range(min_val, max_val)

func random_float(min_val: float, max_val: float) -> float:
        return _rng.randf_range(min_val, max_val)

func random_choice(arr: Array):
        if arr.is_empty():
                return null
        return arr[_rng.randi() % arr.size()]

# ----- Save / Load -----
const SAVE_PATH := "user://save.cfg"

func save_progress() -> void:
        var cfg := ConfigFile.new()
        cfg.set_value("progress", "unlocked_characters", unlocked_characters)
        cfg.set_value("progress", "unlocked_weapons", unlocked_weapons)
        cfg.set_value("progress", "highest_floor", highest_floor)
        cfg.set_value("progress", "coins", coins)
        cfg.set_value("progress", "gems", gems)
        cfg.save(SAVE_PATH)

func load_progress() -> void:
        var cfg := ConfigFile.new()
        if cfg.load(SAVE_PATH) == OK:
                unlocked_characters = cfg.get_value("progress", "unlocked_characters", ["knight"])
                unlocked_weapons = cfg.get_value("progress", "unlocked_weapons", ["pistol", "sword"])
                highest_floor = cfg.get_value("progress", "highest_floor", 0)
                coins = cfg.get_value("progress", "coins", 0)
                gems = cfg.get_value("progress", "gems", 0)

# ----- Helpers -----
func change_state(new_state: int) -> void:
        if state == new_state:
                return
        state = new_state
        emit_signal("state_changed", new_state)

func add_coins(amount: int) -> void:
        coins += amount
        emit_signal("coins_changed", coins)

func add_gems(amount: int) -> void:
        gems += amount
        emit_signal("gems_changed", gems)

func reset_run() -> void:
        carry_max_hp = 0
        carry_current_hp = 0
        carry_max_energy = 100
        carry_current_energy = 100
        carry_armor = 0
        carry_potions = 1
        carry_weapon_ids = []  # empty so character's starting weapon is used on floor 1
        carry_buffs = []
        current_run_floor = 0

func _ready() -> void:
        load_progress()
        seed_rng(int(Time.get_unix_time_from_system()))
