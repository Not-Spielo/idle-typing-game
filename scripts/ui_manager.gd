extends CanvasLayer

# UI Manager - Handles book button, settings button, stats screen, and settings menu

class_name UIManager

var stats_manager: StatsManager

var sort_mode: int = 0

var book_button: Button
var settings_button: Button
var stats_screen: Control
var settings_menu: Control
var stats_window: Window
var settings_window: Window

var is_stats_open: bool = false
var is_settings_open: bool = false
var dragging_stats: bool = false
var dragging_settings: bool = false
var stats_drag_offset: Vector2i = Vector2i.ZERO
var settings_drag_offset: Vector2i = Vector2i.ZERO

var settings_file: String
var settings_data: Dictionary = {
	"size_scale": 1.0,
	"always_on_top": false,
	"volume": 50,
	"run_on_startup": false
}

var size_slider: HSlider
var always_top_check: CheckButton
var volume_slider: HSlider
var startup_check: CheckButton

const UI_ICON_SCALE: float = 3.0

func _ready():
	layer = 10  # Above game layer
	
	# Get reference to stats manager
	stats_manager = get_parent().stats_manager
	
	# Initialize settings file path
	var settings_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("IdleTypingGame")
	settings_file = settings_dir.path_join("settings.json")
	_load_settings()
	
	# Create book button
	book_button = Button.new()
	book_button.icon = _load_scaled_texture("res://resources/stats.png", UI_ICON_SCALE)
	book_button.expand_icon = true
	book_button.custom_minimum_size = book_button.icon.get_size() if book_button.icon else Vector2(180, 180)
	book_button.pressed.connect(_on_book_pressed)
	add_child(book_button)
	
	# Create settings button
	settings_button = Button.new()
	settings_button.icon = _load_scaled_texture("res://resources/settings.png", UI_ICON_SCALE)
	settings_button.expand_icon = true
	settings_button.custom_minimum_size = settings_button.icon.get_size() if settings_button.icon else Vector2(180, 180)
	settings_button.pressed.connect(_on_settings_pressed)
	add_child(settings_button)

	# Position buttons on right side above the conveyor belt
	_position_buttons_above_conveyor()
	
	# Create stats screen (initially hidden)
	_create_stats_screen()
	
	# Create settings menu (initially hidden)
	_create_settings_menu()

	# Apply settings after UI is fully built so scaling/layout can update safely
	_apply_settings()

func _position_buttons_above_conveyor():
	var left_margin := 20.0
	var button_vertical_gap := 8.0
	var stats_x := left_margin
	var stats_y := 20.0
	var settings_x := left_margin
	var settings_y := 20.0
	var parent_main = get_parent()
	if parent_main != null and parent_main.has_method("get"):
		var belt = parent_main.get("conveyer_belt")
		if belt != null:
			stats_y = belt.belt_y + (belt.belt_height - book_button.custom_minimum_size.y) * 0.5

	settings_x = stats_x + (book_button.custom_minimum_size.x - settings_button.custom_minimum_size.x) * 0.5
	settings_y = stats_y - settings_button.custom_minimum_size.y - button_vertical_gap

	stats_y = max(12.0, stats_y)
	settings_y = max(12.0, settings_y)

	settings_button.position = Vector2(
		settings_x,
		settings_y
	)
	book_button.position = Vector2(
		stats_x,
		stats_y
	)

func _create_stats_screen():
	stats_window = Window.new()
	stats_window.title = "Stats"
	stats_window.size = Vector2i(600, 700)
	stats_window.min_size = Vector2i(600, 700)
	stats_window.visible = false
	stats_window.unresizable = true
	stats_window.close_requested.connect(_hide_stats_screen)
	add_child(stats_window)

	stats_screen = Control.new()
	stats_screen.visible = true
	stats_screen.mouse_filter = Control.MOUSE_FILTER_PASS
	stats_window.add_child(stats_screen)

	# Background panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 700)
	panel.size = Vector2(600, 700)
	panel.position = Vector2.ZERO
	# Transparent background, will use clipboard texture instead
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color.TRANSPARENT
	panel.add_theme_stylebox_override("panel", transparent_style)
	panel.name = "StatsPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	stats_screen.add_child(panel)

	# Clipboard background
	var bg_texture = TextureRect.new()
	bg_texture.texture = load("res://resources/clipboard.png")
	bg_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
	bg_texture.custom_minimum_size = Vector2(600, 700)
	bg_texture.size = Vector2(600, 700)
	bg_texture.position = Vector2(0, 0)
	bg_texture.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(bg_texture)
	
	# Content container constrained to (30,100) → (560,660)
	var vbox = VBoxContainer.new()
	vbox.name = "StatsVBox"
	vbox.position = Vector2(30, 100)
	vbox.custom_minimum_size = Vector2(530, 560) # 560-30=530 width, 660-100=560 height
	vbox.clip_contents = true
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(vbox)
	
	# Add a spacer at the top
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 100) # 100px top margin
	top_spacer.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(top_spacer)

	# Create a container with left padding (3px)
	var content_h = HBoxContainer.new()
	content_h.name = "ContentH"
	content_h.custom_minimum_size = Vector2(530, 0)
	content_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_h.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Add left spacer
	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(30, 0) # 3px left margin
	left_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	content_h.add_child(left_spacer)
	
	# Create a vbox to hold all the actual content
	var content_v = VBoxContainer.new()
	content_v.name = "ContentV"
	content_v.custom_minimum_size = Vector2(527, 0)
	content_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_v.mouse_filter = Control.MOUSE_FILTER_PASS
	content_h.add_child(content_v)
	vbox.add_child(content_h)
	
	# Title with close button
	var title_h = HBoxContainer.new()
	title_h.custom_minimum_size = Vector2(527, 32)
	title_h.mouse_filter = Control.MOUSE_FILTER_STOP
	title_h.gui_input.connect(_on_stats_title_gui_input)

	var title = Label.new()
	title.text = "Stats"
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	title.add_theme_font_size_override("font_sizes", 26)
	title.add_theme_color_override("font_color", Color.BLACK)
	title_h.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(450, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	title_h.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 28)
	close_btn.offset_left = -30
	close_btn.pressed.connect(_on_stats_close)
	title_h.add_child(close_btn)

	content_v.add_child(title_h)

	# Total keys label
	var total_label = Label.new()
	total_label.name = "TotalLabel"
	total_label.mouse_filter = Control.MOUSE_FILTER_PASS
	total_label.add_theme_font_size_override("font_sizes", 18)
	total_label.add_theme_color_override("font_color", Color.BLACK)
	total_label.custom_minimum_size = Vector2(527, 24)
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_label.text = "Total Keys Typed: 0"
	content_v.add_child(total_label)

	# Top 5 keys
	var top5_h = HBoxContainer.new()
	top5_h.name = "Top5"
	top5_h.custom_minimum_size = Vector2(527, 40)
	top5_h.mouse_filter = Control.MOUSE_FILTER_PASS
	content_v.add_child(top5_h)

	var top5_title = Label.new()
	top5_title.text = "5 Most Used Keys:"
	top5_title.mouse_filter = Control.MOUSE_FILTER_PASS
	top5_title.add_theme_font_size_override("font_sizes", 16)
	top5_title.add_theme_color_override("font_color", Color.BLACK)
	top5_title.custom_minimum_size = Vector2(180, 30)
	top5_h.add_child(top5_title)

	for i in range(5):
		var lbl = Label.new()
		lbl.name = "Top%d" % i
		lbl.mouse_filter = Control.MOUSE_FILTER_PASS
		lbl.add_theme_color_override("font_color", Color.BLACK)
		lbl.custom_minimum_size = Vector2(70, 30) # distribute width evenly
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top5_h.add_child(lbl)

	# Sort options
	var sort_h = HBoxContainer.new()
	sort_h.custom_minimum_size = Vector2(527, 28)
	sort_h.mouse_filter = Control.MOUSE_FILTER_PASS
	content_v.add_child(sort_h)

	var sort_label = Label.new()
	sort_label.text = "Sort:"
	sort_label.mouse_filter = Control.MOUSE_FILTER_PASS
	sort_label.add_theme_color_override("font_color", Color.BLACK)
	sort_h.add_child(sort_label)

	var sort_option = OptionButton.new()
	sort_option.name = "SortOption"
	sort_option.add_item("Most Used")
	sort_option.add_item("Least Used")
	sort_option.add_item("Letters Only")
	sort_option.add_item("Special Characters")
	sort_option.select(0)
	sort_option.item_selected.connect(_on_sort_changed)
	sort_h.add_child(sort_option)

	# Scrollable grid (fills remaining space inside content_v)
	var scroll = ScrollContainer.new()
	scroll.name = "StatsScroll"
	scroll.custom_minimum_size = Vector2(527, 400) # remaining height
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_v.add_child(scroll)

	var grid = GridContainer.new()
	grid.name = "StatsGrid"
	grid.columns = 5
	grid.custom_minimum_size = Vector2(527, 400)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(grid)

func _create_settings_menu():
	settings_window = Window.new()
	settings_window.title = "Settings"
	settings_window.size = Vector2i(600, 700)
	settings_window.min_size = Vector2i(600, 700)
	settings_window.visible = false
	settings_window.unresizable = true
	settings_window.close_requested.connect(_hide_settings_menu)
	add_child(settings_window)

	settings_menu = Control.new()
	settings_menu.visible = true
	settings_menu.mouse_filter = Control.MOUSE_FILTER_PASS
	settings_window.add_child(settings_menu)

	# Background panel
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 700)
	panel.size = Vector2(600, 700)
	panel.position = Vector2.ZERO
	# Transparent background, will use clipboard texture instead
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color.TRANSPARENT
	panel.add_theme_stylebox_override("panel", transparent_style)
	panel.name = "SettingsPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_menu.add_child(panel)

	# Clipboard background
	var bg_texture = TextureRect.new()
	bg_texture.texture = load("res://resources/clipboard.png")
	bg_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_SCALE
	bg_texture.custom_minimum_size = Vector2(600, 700)
	bg_texture.size = Vector2(600, 700)
	bg_texture.position = Vector2(0, 0)
	bg_texture.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(bg_texture)
	
	# Content container constrained to (30,100) → (560,660)
	var vbox = VBoxContainer.new()
	vbox.name = "SettingsVBox"
	vbox.position = Vector2(30, 100)
	vbox.custom_minimum_size = Vector2(530, 560) # 560-30=530 width, 660-100=560 height
	vbox.clip_contents = true
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(vbox)
	
	# Add a spacer at the top
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 100) # 100px top margin
	top_spacer.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_child(top_spacer)

	# Create a container with left padding (30px)
	var content_h = HBoxContainer.new()
	content_h.name = "ContentH"
	content_h.custom_minimum_size = Vector2(530, 0)
	content_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_h.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Add left spacer
	var left_spacer = Control.new()
	left_spacer.custom_minimum_size = Vector2(30, 0) # 30px left margin
	left_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	content_h.add_child(left_spacer)
	
	# Create a vbox to hold all the actual content
	var content_v = VBoxContainer.new()
	content_v.name = "ContentV"
	content_v.custom_minimum_size = Vector2(500, 0)
	content_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_v.mouse_filter = Control.MOUSE_FILTER_PASS
	content_h.add_child(content_v)
	vbox.add_child(content_h)
	
	# Title with close button
	var title_h = HBoxContainer.new()
	title_h.custom_minimum_size = Vector2(500, 32)
	title_h.mouse_filter = Control.MOUSE_FILTER_STOP
	title_h.gui_input.connect(_on_settings_title_gui_input)

	var title = Label.new()
	title.text = "Settings"
	title.mouse_filter = Control.MOUSE_FILTER_PASS
	title.add_theme_font_size_override("font_sizes", 26)
	title.add_theme_color_override("font_color", Color.BLACK)
	title_h.add_child(title)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(430, 0)
	spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	title_h.add_child(spacer)

	var close_btn = Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 28)
	close_btn.offset_left = -30
	close_btn.pressed.connect(_on_settings_close)
	title_h.add_child(close_btn)

	content_v.add_child(title_h)
	
	# Size slider
	var size_h = HBoxContainer.new()
	size_h.custom_minimum_size = Vector2(500, 40)
	size_h.mouse_filter = Control.MOUSE_FILTER_PASS
	content_v.add_child(size_h)
	
	var size_label = Label.new()
	size_label.text = "Game Size"
	size_label.mouse_filter = Control.MOUSE_FILTER_PASS
	size_label.add_theme_color_override("font_color", Color.BLACK)
	size_h.add_child(size_label)
	
	var size_spacer = Control.new()
	size_spacer.custom_minimum_size = Vector2(90, 0)
	size_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	size_h.add_child(size_spacer)
	
	var size_slider = HSlider.new()
	size_slider.min_value = 0.5
	size_slider.max_value = 2.0
	size_slider.value = settings_data.get("size_scale", 1.0)
	size_slider.step = 0.1
	size_slider.custom_minimum_size = Vector2(350, 40)
	size_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_slider.value_changed.connect(_on_size_changed)
	size_h.add_child(size_slider)
	self.size_slider = size_slider
	
	# Always on top toggle
	var always_top_h = HBoxContainer.new()
	always_top_h.custom_minimum_size = Vector2(500, 32)
	always_top_h.mouse_filter = Control.MOUSE_FILTER_PASS
	content_v.add_child(always_top_h)
	
	var always_top_label = Label.new()
	always_top_label.text = "Always On Top"
	always_top_label.mouse_filter = Control.MOUSE_FILTER_PASS
	always_top_label.add_theme_color_override("font_color", Color.BLACK)
	always_top_h.add_child(always_top_label)
	
	var always_top_spacer = Control.new()
	always_top_spacer.custom_minimum_size = Vector2(375, 0)
	always_top_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	always_top_h.add_child(always_top_spacer)
	
	var always_top_check = CheckButton.new()
	always_top_check.button_pressed = settings_data.get("always_on_top", false)
	always_top_check.custom_minimum_size = Vector2(36, 28)
	always_top_check.offset_left = -30
	always_top_check.toggled.connect(_on_always_on_top_changed)
	always_top_h.add_child(always_top_check)
	self.always_top_check = always_top_check
	
	# Volume slider
	var volume_h = HBoxContainer.new()
	volume_h.custom_minimum_size = Vector2(500, 40)
	volume_h.mouse_filter = Control.MOUSE_FILTER_PASS
	content_v.add_child(volume_h)
	
	var volume_label = Label.new()
	volume_label.text = "Sound Volume"
	volume_label.mouse_filter = Control.MOUSE_FILTER_PASS
	volume_label.add_theme_color_override("font_color", Color.BLACK)
	volume_h.add_child(volume_label)
	
	var volume_spacer = Control.new()
	volume_spacer.custom_minimum_size = Vector2(60, 0)
	volume_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	volume_h.add_child(volume_spacer)
	
	var volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.value = settings_data.get("volume", 50)
	volume_slider.custom_minimum_size = Vector2(350, 40)
	volume_slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	volume_slider.value_changed.connect(_on_volume_changed)
	volume_h.add_child(volume_slider)
	self.volume_slider = volume_slider
	
	# Run on startup toggle
	var startup_h = HBoxContainer.new()
	startup_h.custom_minimum_size = Vector2(500, 32)
	startup_h.mouse_filter = Control.MOUSE_FILTER_PASS
	content_v.add_child(startup_h)
	
	var startup_label = Label.new()
	startup_label.text = "Run on Startup"
	startup_label.mouse_filter = Control.MOUSE_FILTER_PASS
	startup_label.add_theme_color_override("font_color", Color.BLACK)
	startup_h.add_child(startup_label)
	
	var startup_spacer = Control.new()
	startup_spacer.custom_minimum_size = Vector2(373, 0)
	startup_spacer.mouse_filter = Control.MOUSE_FILTER_PASS
	startup_h.add_child(startup_spacer)
	
	var startup_check = CheckButton.new()
	startup_check.button_pressed = settings_data.get("run_on_startup", false)
	startup_check.custom_minimum_size = Vector2(36, 28)
	startup_check.offset_left = -30
	startup_check.toggled.connect(_on_startup_changed)
	startup_h.add_child(startup_check)
	self.startup_check = startup_check

	# Close app button
	var close_app_h = HBoxContainer.new()
	close_app_h.custom_minimum_size = Vector2(300, 44)
	close_app_h.mouse_filter = Control.MOUSE_FILTER_PASS
	content_v.add_child(close_app_h)

	var close_app_btn = Button.new()
	close_app_btn.text = "Close App"
	close_app_btn.custom_minimum_size = Vector2(150, 36)
	close_app_btn.pressed.connect(_on_close_app_pressed)
	close_app_h.add_child(close_app_btn)

func _load_scaled_texture(path: String, scale: float) -> Texture2D:
	var source = load(path) as Texture2D
	if source == null:
		return null

	var img = source.get_image()
	if img == null:
		return source

	var target_w = max(1, int(round(img.get_width() * scale)))
	var target_h = max(1, int(round(img.get_height() * scale)))
	img.resize(target_w, target_h, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)

func _on_book_pressed():
	if is_stats_open:
		_hide_stats_screen()
	else:
		_show_stats_screen()

func _on_settings_pressed():
	if is_settings_open:
		_hide_settings_menu()
	else:
		_show_settings_menu()

func _on_stats_close():
	_hide_stats_screen()

func _on_settings_close():
	_hide_settings_menu()

func _on_close_app_pressed():
	get_tree().quit()

func _show_stats_screen():
	if stats_window:
		stats_window.visible = true
		stats_window.grab_focus()
	is_stats_open = true
	_update_stats_display()

func _hide_stats_screen():
	if stats_window:
		stats_window.visible = false
	is_stats_open = false

func _show_settings_menu():
	if settings_window:
		settings_window.visible = true
		settings_window.grab_focus()
	is_settings_open = true

func _hide_settings_menu():
	if settings_window:
		settings_window.visible = false
	is_settings_open = false

func _update_stats_display():
	var stats = stats_manager.get_global_stats()

	# Update total
	var total_label = stats_screen.get_node("StatsPanel/StatsVBox/ContentH/ContentV/TotalLabel")
	total_label.text = "Total Keys Typed: %d" % stats.get("total_keys", 0)

	# Build list of key entries (unfiltered for top-5)
	var all_entries = []
	for key in stats:
		if key == "total_keys":
			continue
		all_entries.append({"char": key, "count": stats[key]})

	# Sort all entries for top-5 (always most used)
	all_entries.sort_custom(func(a, b): return a["count"] > b["count"])

	# Update Top 5 labels (always from most-used, unfiltered)
	for i in range(5):
		var lbl_path = "StatsPanel/StatsVBox/ContentH/ContentV/Top5/Top%d" % i
		var lbl = stats_screen.get_node(lbl_path)
		if i < all_entries.size():
			var kd = all_entries[i]
			var ch = kd["char"] if kd["char"] != " " else "SPACE"
			lbl.text = "%s: %d" % [ch.to_upper(), kd["count"]]
		else:
			lbl.text = ""

	# Build entries for grid with filtering/sorting
	var entries = []
	for key in stats:
		if key == "total_keys":
			continue
		entries.append({"char": key, "count": stats[key]})

	# Filter based on sort_mode
	if sort_mode == 2:
		entries = entries.filter(func(e): return _is_letter_char(e["char"]))
	elif sort_mode == 3:
		entries = entries.filter(func(e): return not _is_letter_char(e["char"]))

	# Sort entries
	if sort_mode == 1:
		entries.sort_custom(func(a, b): return a["count"] < b["count"])
	else:
		entries.sort_custom(func(a, b): return a["count"] > b["count"])

	# Populate grid with filtered/sorted entries
	var grid = stats_screen.get_node("StatsPanel/StatsVBox/ContentH/ContentV/StatsScroll/StatsGrid")
	for child in grid.get_children():
		grid.remove_child(child)
		child.free()

	for e in entries:
		var ch = e["char"] if e["char"] != " " else "SPACE"
		var lbl = Label.new()
		lbl.text = "%s: %d" % [ch.to_upper(), e["count"]]
		lbl.add_theme_color_override("font_color", Color.BLACK)
		lbl.custom_minimum_size = Vector2(100, 40)
		grid.add_child(lbl)

func _is_letter_char(ch: String) -> bool:
	if ch == null or ch.length() == 0:
		return false
	var re = RegEx.new()
	if re.compile("^[A-Za-z0-9]$") != OK:
		return false
	return re.search(ch) != null

func _on_sort_changed(index: int):
	sort_mode = index
	_update_stats_display()
func _create_panel_style() -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color.DARK_SLATE_GRAY
	style.border_color = Color.WHITE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	return style

func _on_size_changed(value: float):
	# Scale game and resize main window so content never clips
	var main_scene = get_parent()
	if main_scene and main_scene.has_method("apply_game_scale"):
		main_scene.apply_game_scale(value)
	else:
		var conveyer_belt = main_scene.get_node("ConveyerBelt") if main_scene else null
		if conveyer_belt:
			conveyer_belt.scale = Vector2(value, value)
			_position_buttons_above_conveyor()
	settings_data["size_scale"] = value
	_save_settings()

func _on_always_on_top_changed(toggled: bool):
	# In Godot, we can set the window flag
	get_window().always_on_top = toggled
	settings_data["always_on_top"] = toggled
	_save_settings()

func _on_volume_changed(value: float):
	AudioServer.set_bus_volume_db(0, linear_to_db(value / 100.0))
	settings_data["volume"] = value
	_save_settings()

func _on_startup_changed(toggled: bool):
	# This would require platform-specific code
	# For now, just log the intent
	if toggled:
		print("Run on startup enabled (requires system integration)")
	else:
		print("Run on startup disabled")
	settings_data["run_on_startup"] = toggled
	_save_settings()

func _load_settings():
	if FileAccess.file_exists(settings_file):
		var json_str = FileAccess.get_file_as_string(settings_file)
		var json = JSON.new()
		if json.parse(json_str) == OK:
			settings_data = json.data
	else:
		# Save defaults if file doesn't exist
		_save_settings()

func _save_settings():
	# Ensure directory exists
	var dir = settings_file.get_basename().get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir)
	
	# Save settings to JSON
	var json_str = JSON.stringify(settings_data)
	var file = FileAccess.open(settings_file, FileAccess.WRITE)
	if file:
		file.store_string(json_str)

func _apply_settings():
	# Apply size scale
	if settings_data.has("size_scale"):
		var main_scene = get_parent()
		if main_scene and main_scene.has_method("apply_game_scale"):
			main_scene.apply_game_scale(float(settings_data["size_scale"]))
		elif main_scene:
			var conveyer_belt = main_scene.get_node("ConveyerBelt")
			if conveyer_belt:
				conveyer_belt.scale = Vector2(settings_data["size_scale"], settings_data["size_scale"])
				_position_buttons_above_conveyor()
	
	# Apply always on top
	if settings_data.has("always_on_top"):
		get_window().always_on_top = settings_data["always_on_top"]
	
	# Apply volume
	if settings_data.has("volume"):
		AudioServer.set_bus_volume_db(0, linear_to_db(settings_data["volume"] / 100.0))

func _clamp_window_to_screen(target_window: Window, desired_pos: Vector2i) -> Vector2i:
	if target_window == null:
		return desired_pos

	var screen_index := target_window.current_screen
	if screen_index < 0:
		screen_index = DisplayServer.window_get_current_screen()

	var usable_rect := DisplayServer.screen_get_usable_rect(screen_index)
	var max_x := usable_rect.position.x + usable_rect.size.x - target_window.size.x
	var max_y := usable_rect.position.y + usable_rect.size.y - target_window.size.y

	var clamped_x := clampi(desired_pos.x, usable_rect.position.x, max_x)
	var clamped_y := clampi(desired_pos.y, usable_rect.position.y, max_y)
	return Vector2i(clamped_x, clamped_y)

func _begin_window_drag(target_window: Window, for_stats: bool):
	if target_window == null:
		return

	var mouse_pos := DisplayServer.mouse_get_position()
	if for_stats:
		dragging_stats = true
		stats_drag_offset = mouse_pos - target_window.position
	else:
		dragging_settings = true
		settings_drag_offset = mouse_pos - target_window.position

func _update_window_drag(target_window: Window, drag_offset: Vector2i):
	if target_window == null:
		return

	var mouse_pos := DisplayServer.mouse_get_position()
	var desired_pos := mouse_pos - drag_offset
	target_window.position = _clamp_window_to_screen(target_window, desired_pos)

func _on_stats_title_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_window_drag(stats_window, true)
			else:
				dragging_stats = false
	elif event is InputEventMouseMotion and dragging_stats:
		_update_window_drag(stats_window, stats_drag_offset)

func _on_stats_screen_gui_input(event: InputEvent):
	pass

func _on_settings_title_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_begin_window_drag(settings_window, false)
			else:
				dragging_settings = false
	elif event is InputEventMouseMotion and dragging_settings:
		_update_window_drag(settings_window, settings_drag_offset)

func _on_settings_screen_gui_input(event: InputEvent):
	pass
