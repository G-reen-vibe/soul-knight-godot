extends Control
class_name MainMenu
## Main menu screen. Shows title, "Start Game", "Quit" buttons.

signal start_pressed
signal quit_pressed

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.14, 0.18, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	# Title
	var title := Label.new()
	title.text = "SOUL KNIGHT"
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(-200, 100)
	title.size = Vector2(400, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.7, 0.3))
	add_child(title)
	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "A Godot Replication"
	subtitle.set_anchors_preset(PRESET_CENTER_TOP)
	subtitle.position = Vector2(-100, 180)
	subtitle.size = Vector2(200, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(subtitle)
	# Start button
	var start_btn := Button.new()
	start_btn.text = "Start Game"
	start_btn.set_anchors_preset(PRESET_CENTER)
	start_btn.position = Vector2(-100, 0)
	start_btn.size = Vector2(200, 50)
	start_btn.pressed.connect(func(): emit_signal("start_pressed"))
	add_child(start_btn)
	# Quit button
	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.set_anchors_preset(PRESET_CENTER)
	quit_btn.position = Vector2(-100, 70)
	quit_btn.size = Vector2(200, 50)
	quit_btn.pressed.connect(func(): emit_signal("quit_pressed"))
	add_child(quit_btn)
	# Footer
	var footer := Label.new()
	footer.text = "v0.1 - Made with Godot 4.4"
	footer.set_anchors_preset(PRESET_BOTTOM_WIDE)
	footer.position = Vector2(0, -30)
	footer.size = Vector2(get_viewport_rect().size.x, 20)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	add_child(footer)
