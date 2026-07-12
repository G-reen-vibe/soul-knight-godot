extends Control
class_name GameOverScreen
## Game over screen. Shows stats and offers retry/quit.

signal retry_pressed
signal quit_pressed

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# Dim background
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.08, 0.85)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	# Title
	var title := Label.new()
	title.text = "GAME OVER"
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(-200, 100)
	title.size = Vector2(400, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(1, 0.2, 0.3))
	add_child(title)
	# Stats
	var stats := Label.new()
	stats.text = "Floor reached: %d\nCoins: %d" % [Global.current_run_floor, Global.coins]
	stats.set_anchors_preset(PRESET_CENTER)
	stats.position = Vector2(-150, 0)
	stats.size = Vector2(300, 80)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 20)
	add_child(stats)
	# Retry button
	var retry_btn := Button.new()
	retry_btn.text = "Retry"
	retry_btn.set_anchors_preset(PRESET_CENTER)
	retry_btn.position = Vector2(-150, 120)
	retry_btn.size = Vector2(140, 50)
	retry_btn.pressed.connect(func(): emit_signal("retry_pressed"))
	add_child(retry_btn)
	# Quit button
	var quit_btn := Button.new()
	quit_btn.text = "Main Menu"
	quit_btn.set_anchors_preset(PRESET_CENTER)
	quit_btn.position = Vector2(10, 120)
	quit_btn.size = Vector2(140, 50)
	quit_btn.pressed.connect(func(): emit_signal("quit_pressed"))
	add_child(quit_btn)
