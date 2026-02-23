extends Node

# Main - Root scene that orchestrates all game systems

class_name Main

var stats_manager: StatsManager
var input_handler: InputHandler
var global_key_bridge: GlobalKeyBridge
var conveyer_belt: ConveyerBelt
var ui_manager: UIManager

var dragging_main_window: bool = false
var main_window_drag_offset: Vector2i = Vector2i.ZERO

const MAIN_WINDOW_WIDTH: int = 1100
const MAIN_WINDOW_HEIGHT: int = 260

func _ready():
	# Set window properties
	var window = get_window()
	window.transparent_bg = true
	window.mouse_passthrough = false
	window.title = "Idle Typing Game"
	window.size = Vector2i(MAIN_WINDOW_WIDTH, MAIN_WINDOW_HEIGHT)
	
	# Initialize systems
	_initialize_systems()
	
	# Connect signals after all systems are initialized
	if input_handler and conveyer_belt:
		input_handler.key_pressed.connect(conveyer_belt.add_letter)

	if global_key_bridge and input_handler:
		global_key_bridge.global_char_received.connect(input_handler.submit_global_char)
		var bridge_started := global_key_bridge.start_bridge()
		input_handler.use_window_input = not bridge_started
		if bridge_started:
			print("Global key capture enabled.")
		else:
			print("Global key helper unavailable. Using focused window input.")
	
	# Connect belt drag signal
	if conveyer_belt:
		conveyer_belt.drag_started.connect(_on_belt_drag_started)
		conveyer_belt.drag_moved.connect(_on_belt_drag_moved)
		conveyer_belt.drag_ended.connect(_on_belt_drag_ended)

func _on_belt_drag_started():
	dragging_main_window = true
	var mouse_pos := DisplayServer.mouse_get_position()
	main_window_drag_offset = mouse_pos - get_window().position

func _on_belt_drag_moved():
	if dragging_main_window:
		var mouse_pos := DisplayServer.mouse_get_position()
		var desired_pos := mouse_pos - main_window_drag_offset
		get_window().position = _clamp_window_to_all_screens(desired_pos)

func _on_belt_drag_ended():
	dragging_main_window = false

func _clamp_window_to_all_screens(desired_pos: Vector2i) -> Vector2i:
	# Allow dragging across multiple monitors
	# Only clamp if window would be completely off all screens
	var window := get_window()
	var screen_count := DisplayServer.get_screen_count()
	
	if screen_count == 0:
		return desired_pos
	
	# Find the combined bounds of all screens
	var min_x := 999999
	var min_y := 999999
	var max_x := -999999
	var max_y := -999999
	
	for i in range(screen_count):
		var screen_rect := DisplayServer.screen_get_usable_rect(i)
		min_x = mini(min_x, screen_rect.position.x)
		min_y = mini(min_y, screen_rect.position.y)
		max_x = maxi(max_x, screen_rect.position.x + screen_rect.size.x)
		max_y = maxi(max_y, screen_rect.position.y + screen_rect.size.y)
	
	# Allow some of the window to go off-screen, but keep at least 50px visible
	var min_visible := 50
	var clamped_x := clampi(desired_pos.x, min_x - window.size.x + min_visible, max_x - min_visible)
	var clamped_y := clampi(desired_pos.y, min_y - window.size.y + min_visible, max_y - min_visible)
	
	return Vector2i(clamped_x, clamped_y)

func apply_game_scale(scale_value: float):
	var clamped_scale := clampf(scale_value, 0.5, 2.0)
	if conveyer_belt:
		conveyer_belt.scale = Vector2(clamped_scale, clamped_scale)

	var target_width := int(ceil(float(MAIN_WINDOW_WIDTH) * clamped_scale))
	var target_height := int(ceil(float(MAIN_WINDOW_HEIGHT) * clamped_scale))
	get_window().size = Vector2i(max(target_width, 560), max(target_height, 220))

	if ui_manager and ui_manager.has_method("_position_buttons_above_conveyor"):
		ui_manager._position_buttons_above_conveyor()

func _initialize_systems():
	# Create StatsManager
	stats_manager = StatsManager.new()
	stats_manager.name = "StatsManager"
	add_child(stats_manager)
	
	# Create InputHandler
	input_handler = InputHandler.new()
	input_handler.name = "InputHandler"
	add_child(input_handler)

	# Create GlobalKeyBridge for out-of-focus key capture on Windows
	global_key_bridge = GlobalKeyBridge.new()
	global_key_bridge.name = "GlobalKeyBridge"
	add_child(global_key_bridge)
	
	# Create ConveyerBelt (CanvasLayer for rendering)
	conveyer_belt = ConveyerBelt.new()
	conveyer_belt.name = "ConveyerBelt"
	add_child(conveyer_belt)
	
	# Create UIManager (CanvasLayer for UI)
	ui_manager = UIManager.new()
	ui_manager.name = "UIManager"
	add_child(ui_manager)

func _process(_delta):
	# Could add frame-rate limiting or other processing here
	pass
