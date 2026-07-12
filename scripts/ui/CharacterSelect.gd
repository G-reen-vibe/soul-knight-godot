extends Control
class_name CharacterSelect
## Character selection screen. Shows available characters, lets player pick one.

signal character_confirmed(char_id: String)
signal back_pressed

var _character_ids: Array = ["knight", "wizard", "rogue", "alchemist", "engineer"]
var _current_idx: int = 0
var _character_displays: Dictionary = {}  # id -> CharacterData
var _preview_panel: Panel
var _name_label: Label
var _desc_label: Label
var _skill_label: Label
var _stats_label: Label

func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	_load_characters()
	_build_ui()

func _load_characters() -> void:
	for id in _character_ids:
		var c := load("res://data/characters/%s.tres" % id) as CharacterData
		if c:
			_character_displays[id] = c

func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.10, 0.12, 0.16, 1.0)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)
	# Title
	var title := Label.new()
	title.text = "SELECT CHARACTER"
	title.set_anchors_preset(PRESET_CENTER_TOP)
	title.position = Vector2(-200, 30)
	title.size = Vector2(400, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.4))
	add_child(title)
	# Preview panel (left side)
	_preview_panel = Panel.new()
	_preview_panel.position = Vector2(100, 120)
	_preview_panel.size = Vector2(500, 400)
	add_child(_preview_panel)
	# Character preview rect (color of the character)
	var preview_rect := ColorRect.new()
	preview_rect.name = "PreviewRect"
	preview_rect.position = Vector2(50, 50)
	preview_rect.size = Vector2(80, 80)
	_preview_panel.add_child(preview_rect)
	# Name label
	_name_label = Label.new()
	_name_label.position = Vector2(150, 50)
	_name_label.size = Vector2(300, 40)
	_name_label.add_theme_font_size_override("font_size", 24)
	_preview_panel.add_child(_name_label)
	# Description
	_desc_label = Label.new()
	_desc_label.position = Vector2(150, 100)
	_desc_label.size = Vector2(300, 80)
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_panel.add_child(_desc_label)
	# Skill label
	_skill_label = Label.new()
	_skill_label.position = Vector2(50, 180)
	_skill_label.size = Vector2(400, 80)
	_skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_panel.add_child(_skill_label)
	# Stats
	_stats_label = Label.new()
	_stats_label.position = Vector2(50, 280)
	_stats_label.size = Vector2(400, 100)
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_panel.add_child(_stats_label)
	# Character list (right side)
	var list_container := VBoxContainer.new()
	list_container.position = Vector2(700, 120)
	list_container.size = Vector2(400, 400)
	add_child(list_container)
	for i in range(_character_ids.size()):
		var id: String = _character_ids[i]
		var c: CharacterData = _character_displays.get(id)
		if c == null:
			continue
		var btn := Button.new()
		btn.text = c.display_name
		btn.custom_minimum_size = Vector2(200, 50)
		btn.pressed.connect(func(): _select_character(id))
		list_container.add_child(btn)
	# Confirm button
	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.position = Vector2(540, 560)
	confirm_btn.size = Vector2(200, 50)
	confirm_btn.pressed.connect(_on_confirm)
	add_child(confirm_btn)
	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.position = Vector2(100, 560)
	back_btn.size = Vector2(150, 50)
	back_btn.pressed.connect(func(): emit_signal("back_pressed"))
	add_child(back_btn)
	# Initialize preview
	_select_character(_character_ids[_current_idx])

func _select_character(id: String) -> void:
	_current_idx = _character_ids.find(id)
	var c: CharacterData = _character_displays.get(id)
	if c == null:
		return
	var preview_rect := _preview_panel.get_node("PreviewRect") as ColorRect
	preview_rect.color = c.body_color
	_name_label.text = c.display_name
	_desc_label.text = c.description
	_skill_label.text = "Skill (%.0fs CD): %s" % [c.skill_cooldown, c.skill_description]
	_stats_label.text = "HP: %d\nEnergy: %d\nSpeed: %.0f\nStarting Weapon: %s" % [c.max_hp, c.max_energy, c.move_speed, c.starting_weapon_id]

func _on_confirm() -> void:
	emit_signal("character_confirmed", _character_ids[_current_idx])
