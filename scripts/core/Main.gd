extends Node2D
## Main entry point. Manages game state transitions.
## Hosts the menu, character select, gameplay, and game-over screens.

var _main_menu: MainMenu
var _character_select: CharacterSelect
var _game_over_screen: GameOverScreen
var _dungeon_runner: DungeonRunner

func _ready() -> void:
        print("[Main] Booting Soul Knight...")
        # Load progress
        Global.load_progress()
        # Start at menu
        Global.change_state(Global.GameState.MENU)
        _show_main_menu()

func _show_main_menu() -> void:
        _clear_screens()
        _main_menu = MainMenu.new()
        _main_menu.start_pressed.connect(_on_start_pressed)
        _main_menu.quit_pressed.connect(_on_quit_pressed)
        add_child(_main_menu)

func _show_character_select() -> void:
        _clear_screens()
        _character_select = CharacterSelect.new()
        _character_select.character_confirmed.connect(_on_character_confirmed)
        _character_select.back_pressed.connect(_show_main_menu)
        add_child(_character_select)

func _start_game() -> void:
        _clear_screens()
        Global.reset_run()
        Global.change_state(Global.GameState.PLAYING)
        _dungeon_runner = load("res://scenes/dungeon/DungeonRunner.tscn").instantiate() as DungeonRunner
        _dungeon_runner.floor_number = 1
        add_child(_dungeon_runner)

func _show_game_over() -> void:
        _clear_screens()
        _game_over_screen = GameOverScreen.new()
        _game_over_screen.retry_pressed.connect(_on_retry)
        _game_over_screen.quit_pressed.connect(_show_main_menu)
        add_child(_game_over_screen)

func _clear_screens() -> void:
        if _main_menu and is_instance_valid(_main_menu):
                _main_menu.queue_free()
                _main_menu = null
        if _character_select and is_instance_valid(_character_select):
                _character_select.queue_free()
                _character_select = null
        if _game_over_screen and is_instance_valid(_game_over_screen):
                _game_over_screen.queue_free()
                _game_over_screen = null
        if _dungeon_runner and is_instance_valid(_dungeon_runner):
                _dungeon_runner.queue_free()
                _dungeon_runner = null

func _on_start_pressed() -> void:
        _show_character_select()

func _on_quit_pressed() -> void:
        get_tree().quit()

func _on_character_confirmed(char_id: String) -> void:
        Global.current_character_id = char_id
        _start_game()

func _on_retry() -> void:
        _start_game()

func _spawn_next_floor(new_floor: int) -> void:
        # Called by DungeonRunner when boss is defeated
        print("[Main] Spawning next floor: %d" % new_floor)
        _dungeon_runner = load("res://scenes/dungeon/DungeonRunner.tscn").instantiate() as DungeonRunner
        _dungeon_runner.floor_number = new_floor
        add_child(_dungeon_runner)
        # Reconnect HUD to new player
        if _dungeon_runner._player:
                # The HUD was freed with the old runner, so we need to find or create a new one
                # Actually, the HUD was a child of the old runner, so it's freed too.
                # The new runner will create its own HUD in _ready.
                pass

func _process(_delta: float) -> void:
        # Watch for state changes
        if Global.state == Global.GameState.GAME_OVER and _game_over_screen == null:
                _show_game_over()
        # Transition to next floor when boss is defeated
        if Global.state == Global.GameState.PLAYING and _dungeon_runner != null:
                # Check if player died
                if _dungeon_runner._player and _dungeon_runner._player._is_dead:
                        Global.change_state(Global.GameState.GAME_OVER)
