extends Node2D
class_name ShopNPC
## An NPC that sells items (weapons, buffs, potions) for coins.
## Player interacts by pressing E while nearby.

@export var shop_items: Array = []  # Array of {type, resource, price}
@export var interact_range: float = 70.0

var _player: Player
var _interact_label: Label
var _is_player_nearby: bool = false
var _container: Node2D
var _items_ui: VBoxContainer

func _ready() -> void:
        add_to_group("shop")
        _setup_visuals()
        _setup_interact_label()
        _setup_items_ui()
        # Default shop items
        if shop_items.is_empty():
                _setup_default_items()

func _setup_visuals() -> void:
        var body := ColorRect.new()
        body.color = Color(0.6, 0.5, 0.3, 1.0)
        body.size = Vector2(40, 40)
        body.position = Vector2(-20, -20)
        body.z_index = 5
        add_child(body)
        var sign := ColorRect.new()
        sign.color = Color(0.9, 0.8, 0.2, 1.0)
        sign.size = Vector2(20, 20)
        sign.position = Vector2(-10, -45)
        sign.z_index = 6
        add_child(sign)

func _setup_interact_label() -> void:
        _interact_label = Label.new()
        _interact_label.text = "Press E to shop"
        _interact_label.position = Vector2(-50, -70)
        _interact_label.z_index = 7
        _interact_label.modulate.a = 0.0
        add_child(_interact_label)

func _setup_items_ui() -> void:
        # Use a CanvasLayer so the shop UI renders in screen space
        var canvas_layer := CanvasLayer.new()
        canvas_layer.name = "ShopCanvasLayer"
        canvas_layer.layer = 15
        add_child(canvas_layer)
        # A Control-based UI that appears when player interacts
        _items_ui = VBoxContainer.new()
        _items_ui.name = "ShopUI"
        _items_ui.position = Vector2(440, 100)
        _items_ui.size = Vector2(400, 400)
        _items_ui.visible = false
        _items_ui.modulate.a = 0.95
        # Add a background panel
        var panel := Panel.new()
        panel.size = Vector2(400, 400)
        _items_ui.add_child(panel)
        # Title
        var title := Label.new()
        title.text = "SHOP"
        title.position = Vector2(10, 10)
        title.add_theme_font_size_override("font_size", 24)
        _items_ui.add_child(title)
        # We'll add item rows in _refresh_items_ui
        canvas_layer.add_child(_items_ui)

func _setup_default_items() -> void:
        # Add some default items
        shop_items.clear()
        # Weapon
        shop_items.append({
                "type": "weapon",
                "weapon_id": "smg",
                "price": 25,
                "owned": false,
        })
        shop_items.append({
                "type": "weapon",
                "weapon_id": "shotgun",
                "price": 35,
                "owned": false,
        })
        shop_items.append({
                "type": "buff",
                "buff_id": "max_hp_up",
                "price": 20,
                "owned": false,
        })
        shop_items.append({
                "type": "buff",
                "buff_id": "damage_up",
                "price": 30,
                "owned": false,
        })
        shop_items.append({
                "type": "potion",
                "price": 15,
                "owned": false,
        })

func _process(_delta: float) -> void:
        _find_player()
        _update_proximity()

func _find_player() -> void:
        if _player == null or not is_instance_valid(_player):
                var players := get_tree().get_nodes_in_group("player")
                if not players.is_empty():
                        _player = players[0] as Player

func _update_proximity() -> void:
        if _player == null or not is_instance_valid(_player):
                _is_player_nearby = false
                _interact_label.modulate.a = 0.0
                return
        var dist: float = global_position.distance_to(_player.global_position)
        _is_player_nearby = dist < interact_range
        _interact_label.modulate.a = 1.0 if _is_player_nearby else 0.0

func _input(event: InputEvent) -> void:
        if not _is_player_nearby:
                return
        if event.is_action_pressed("interact"):
                _toggle_shop()
        elif event.is_action_pressed("pause"):
                # Close shop on escape
                if _items_ui.visible:
                        _items_ui.visible = false

func _toggle_shop() -> void:
        _items_ui.visible = not _items_ui.visible
        if _items_ui.visible:
                _refresh_items_ui()

func _refresh_items_ui() -> void:
        # Clear existing item rows (keep title and panel)
        for child in _items_ui.get_children():
                if child.name.begins_with("ItemRow_"):
                        child.queue_free()
        # Add new rows
        var y_offset: int = 50
        for i in range(shop_items.size()):
                var item: Dictionary = shop_items[i]
                var row := HBoxContainer.new()
                row.name = "ItemRow_%d" % i
                row.position = Vector2(10, y_offset)
                row.size = Vector2(380, 30)
                _items_ui.add_child(row)
                # Item name
                var name_label := Label.new()
                name_label.text = _get_item_name(item)
                name_label.custom_minimum_size = Vector2(200, 20)
                row.add_child(name_label)
                # Price
                var price_label := Label.new()
                price_label.text = "%d coins" % item.get("price", 0)
                price_label.custom_minimum_size = Vector2(80, 20)
                row.add_child(price_label)
                # Buy button
                var btn := Button.new()
                btn.text = "Buy" if not item.get("owned", false) else "Sold"
                btn.disabled = item.get("owned", false) or _player.coins < item.get("price", 999)
                btn.pressed.connect(_on_buy_button_pressed.bind(i))
                row.add_child(btn)
                y_offset += 35

func _get_item_name(item: Dictionary) -> String:
        match item.get("type", ""):
                "weapon":
                        var w := load("res://data/weapons/%s.tres" % item.get("weapon_id", "")) as WeaponData
                        return w.display_name if w else "Unknown"
                "buff":
                        var b := load("res://data/buffs/%s.tres" % item.get("buff_id", "")) as BuffData
                        return b.display_name if b else "Unknown"
                "potion":
                        return "Health Potion"
                _:
                        return "Unknown"

func _on_buy_button_pressed(idx: int) -> void:
        if _player == null:
                return
        if idx >= shop_items.size():
                return
        var item: Dictionary = shop_items[idx]
        if item.get("owned", false):
                return
        var price: int = item.get("price", 999)
        if not _player.spend_coins(price):
                return
        item["owned"] = true
        # Apply the purchase
        match item.get("type", ""):
                "weapon":
                        var w := load("res://data/weapons/%s.tres" % item.get("weapon_id", "")) as WeaponData
                        if w:
                                _player.pickup_weapon(w.duplicate(true))
                "buff":
                        var b := load("res://data/buffs/%s.tres" % item.get("buff_id", "")) as BuffData
                        if b:
                                var buffs_node := _player.get_node_or_null("PlayerBuffs") as PlayerBuffs
                                if buffs_node == null:
                                        buffs_node = PlayerBuffs.new()
                                        buffs_node.name = "PlayerBuffs"
                                        _player.add_child(buffs_node)
                                buffs_node.add_buff(b.duplicate(true))
                "potion":
                        _player.potions += 1
                        _player.emit_signal("potions_changed", _player.potions)
        _refresh_items_ui()
