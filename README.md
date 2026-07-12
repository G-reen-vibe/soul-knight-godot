# Soul Knight - Godot Replication

A full Godot 4.4 replication of the game Soul Knight - a top-down roguelike shooter.

## Features

### Characters (5)
- **Knight** - Defensive shield skill (2s invulnerability + speed boost)
- **Wizard** - Fireball ring (12 fireballs in all directions)
- **Rogue** - Blink teleport in aim direction
- **Alchemist** - Poison cloud (area denial for 4 seconds)
- **Engineer** - Auto-targeting turret deployment (8 seconds)

### Weapons (12)
- **Ranged:** Pistol, SMG, Sniper, Burst Rifle, Shotgun, Machine Gun, Laser Pistol, Charge Pistol, Rocket Launcher
- **Melee:** Sword, Great Sword, Dagger

### Enemies (4)
- **Grunt** - Basic melee chaser
- **Shooter** - Ranged enemy that maintains distance
- **Charger** - Fast enemy that charges at the player
- **Boss** - 3-phase boss with spray, burst, and charge attacks

### Systems
- Procedural dungeon generation (5x5 grid, random walk)
- Room types: Start, Normal, Shop, Treasure, Boss
- Door transitions with cooldown (prevent spam)
- Pickups: Coins, Gems, Health Potions, Energy Potions, Buffs, Weapons
- Shop NPC with buyable items
- Buff system (7 buffs: HP up, Damage up, Fire Rate, Multishot, Speed, Armor, Lifesteal)
- HUD with HP, energy, coins, weapon, skill cooldown, potions, buffs
- Main menu, character select, game over screen
- Floor progression with state carry-over
- Save/load progress (highest floor, coins, gems)

### Controls
- **WASD** - Move
- **Mouse** - Aim
- **J / Left Click** - Shoot
- **K** - Skill
- **Space** - Dodge roll
- **U** - Switch weapon
- **E** - Interact (shop)
- **Q** - Use potion
- **Esc** - Pause

## Running

### From source (with Godot 4.4+)
```
godot --path .
```

### Headless testing
```
godot --headless --path . res://scenes/tests/EndToEndTests.tscn
```

## Test Suites
- `PlayerTests.tscn` - Player movement, shooting, potion, skill, dodge, weapon switch (6 tests)
- `EnemyTests.tscn` - Enemy chase, combat, contact damage (3 tests)
- `DungeonTests.tscn` - Dungeon generation, room transitions, enemy clearing (7 tests)
- `WeaponTests.tscn` - All 8 weapon types fire correctly (8 tests)
- `CharacterTests.tscn` - All 5 character skills activate (5 tests)
- `EndToEndTests.tscn` - Full game flow: menu -> character select -> dungeon -> boss -> floor 2 (13 tests)
- `FullPlaythroughTests.tscn` - Pickups, shop, buffs, floor progression (11 tests)

**Total: 53 tests, all passing**
