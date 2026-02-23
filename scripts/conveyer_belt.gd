extends CanvasLayer

# Conveyer Belt - Displays and animates typing characters
# Characters move from left to right at typing speed (CPM-based)

class_name ConveyerBelt

signal drag_started
signal drag_moved
signal drag_ended

var letter_container: Node2D
var belt_links: Array[TextureRect] = []
var output_visual: TextureRect
var book_visual: Control
var drag_area: Control
var active_letters: Array = []
var typing_speed: float = 300.0  # pixels per second base speed
var is_typing: bool = false
var last_key_time: float = 0.0
var typing_timeout: float = 2.0  # seconds before stopping animation
var conveyor_speed: float = 120.0
var is_dragging: bool = false

var viewport_width: int
var viewport_height: int
var belt_height: int = 100
var belt_y: float = 0
var belt_end_x: float = 0.0
var belt_link_width: float = 0.0
var belt_visual_speed: float = 120.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var letter_spawn_base_x: float = -50.0

# CPM calculations
var average_cpm: float = 60.0  # characters per minute, start with default
var keys_typed_in_window: int = 0
var cpm_update_timer: float = 0.0
var cpm_window_duration: float = 5.0  # Update CPM every 5 seconds

const ICON_SCALE: float = 3.0
const BELT_TILE_SCALE: float = 8.0
const OUTPUT_SCALE_MULTIPLIER: float = 1.25
const BOOK_SCALE_MULTIPLIER: float = 2.0
const LETTER_FONT_SIZE: int = 38
const BELT_LINK_BUFFER: int = 2
const LETTER_SPAWN_X_VARIATION: float = 3.0
const LETTER_SPAWN_Y_VARIATION: float = 10.0
const LETTER_ROTATION_VARIATION_DEG: float = 360.0
const BELT_LENGTH_RATIO: float = 0.5
const BELT_BOTTOM_INSET: float = 28.0

func _ready():
	layer = 5  # Below UI layer
	rng.randomize()
	
	viewport_width = int(get_viewport().get_visible_rect().size.x)
	viewport_height = int(get_viewport().get_visible_rect().size.y)
	var book_texture = _load_scaled_texture("res://resources/book.png", ICON_SCALE * BOOK_SCALE_MULTIPLIER)
	var book_width = book_texture.get_size().x if book_texture else 100.0
	var book_right_margin = 20.0
	var book_gap = 24.0
	var full_belt_width = max(100.0, viewport_width - book_width - book_right_margin - book_gap)
	var belt_width = int(max(100.0, full_belt_width * BELT_LENGTH_RATIO))
	belt_end_x = float(belt_width)

	var belt_texture = _load_scaled_texture("res://resources/conveyor-belt.png", BELT_TILE_SCALE)
	if belt_texture:
		var texture_size = belt_texture.get_size()
		if texture_size.y > 0:
			belt_height = int(texture_size.y)
		if texture_size.x > 0:
			belt_link_width = texture_size.x
			belt_end_x += belt_link_width
	belt_y = viewport_height - belt_height - BELT_BOTTOM_INSET
	
	# Create belt as individual link images
	_create_belt_links(belt_texture)
	
	# Create book visual
	_create_book_visual(book_texture)
	
	# Create the letter container
	letter_container = Node2D.new()
	letter_container.name = "LetterContainer"
	add_child(letter_container)

	# Create output visual above letters at conveyor start
	_create_output_visual()
	
	# Create draggable area over the belt
	_create_drag_area()

func _create_drag_area():
	drag_area = Control.new()
	drag_area.name = "DragArea"
	# Calculate the actual visible belt width (excluding the extra link_width padding)
	var visible_belt_width = belt_end_x - belt_link_width if belt_link_width > 0 else belt_end_x
	drag_area.position = Vector2(0, belt_y)
	drag_area.custom_minimum_size = Vector2(visible_belt_width, belt_height)
	drag_area.size = Vector2(visible_belt_width, belt_height)
	drag_area.mouse_filter = Control.MOUSE_FILTER_STOP
	drag_area.gui_input.connect(_on_drag_area_gui_input)
	add_child(drag_area)

func _on_drag_area_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_started.emit()
			else:
				is_dragging = false
				drag_ended.emit()
	elif event is InputEventMouseMotion and is_dragging:
		drag_moved.emit()

func _create_book_visual(book_texture: Texture2D = null):
	var texture_rect = TextureRect.new()
	if book_texture == null:
		book_texture = _load_scaled_texture("res://resources/book.png", ICON_SCALE * BOOK_SCALE_MULTIPLIER)
	texture_rect.texture = book_texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
	texture_rect.custom_minimum_size = book_texture.get_size() if book_texture else Vector2(100, 80)
	var book_gap = 24.0
	texture_rect.position = Vector2(
		belt_end_x + book_gap,
		belt_y + (belt_height - texture_rect.custom_minimum_size.y) * 0.5
	)
	book_visual = texture_rect
	add_child(book_visual)

func _create_output_visual():
	var output_texture = _load_scaled_texture("res://resources/output.png", BELT_TILE_SCALE * OUTPUT_SCALE_MULTIPLIER)
	if output_texture == null:
		return

	var texture_rect = TextureRect.new()
	texture_rect.texture = output_texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP
	texture_rect.size = output_texture.get_size()
	var left_offset = belt_link_width if belt_link_width > 0.0 else output_texture.get_size().x
	texture_rect.position = Vector2(
		-left_offset,
		belt_y + (belt_height - texture_rect.size.y) * 0.5
	)
	texture_rect.z_index = 100
	output_visual = texture_rect
	add_child(output_visual)

	# Spawn letters near the output image so they look emitted from it
	letter_spawn_base_x = output_visual.position.x + (output_visual.size.x * 0.35)

func _physics_process(delta):
	# Update CPM timer
	cpm_update_timer += delta
	if cpm_update_timer >= cpm_window_duration:
		_update_average_cpm()
		cpm_update_timer = 0.0

	_update_belt_visual(delta)

	# Keep conveyor movement constant at a slow rate
	_update_letter_positions(delta)

func _create_belt_links(link_texture: Texture2D):
	for link in belt_links:
		if is_instance_valid(link):
			link.queue_free()
	belt_links.clear()
	if link_texture == null:
		return

	if belt_link_width <= 0.0:
		belt_link_width = max(1.0, link_texture.get_size().x)

	var required_links = int(ceil((belt_end_x + belt_link_width) / belt_link_width)) + BELT_LINK_BUFFER
	required_links = max(required_links, 1)

	for i in range(required_links):
		var link = TextureRect.new()
		link.texture = link_texture
		link.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		link.stretch_mode = TextureRect.STRETCH_KEEP
		link.size = link_texture.get_size()
		# Overlap links by 3 pixels to cover any gaps
		var overlap = 2.0
		link.position = Vector2(float(i) * (belt_link_width - overlap), belt_y)
		add_child(link)
		belt_links.append(link)

func _update_belt_visual(delta):
	if belt_links.is_empty() or belt_link_width <= 0.0:
		return

	var overlap = 3.0
	var move_x = belt_visual_speed * delta
	var recycle_x = belt_end_x + belt_link_width
	var leftmost_x = belt_links[0].position.x
	for link in belt_links:
		link.position.x += move_x
		if link.position.x < leftmost_x:
			leftmost_x = link.position.x

	for link in belt_links:
		if link.position.x >= recycle_x:
			link.position.x = leftmost_x - (belt_link_width - overlap)
			leftmost_x = link.position.x

func add_letter(char: String, event: InputEvent):
	keys_typed_in_window += 1
	is_typing = true
	last_key_time = Time.get_ticks_msec() / 1000.0
	
	# Create letter label
	var label = Label.new()
	label.text = char if char != " " else "⎵"
	label.add_theme_font_size_override("font_sizes", LETTER_FONT_SIZE)
	var base_spawn_y = belt_y + (belt_height * 0.5) - (LETTER_FONT_SIZE * 0.5) + 12
	var spawn_x = letter_spawn_base_x + rng.randf_range(-LETTER_SPAWN_X_VARIATION, LETTER_SPAWN_X_VARIATION)
	var spawn_y = base_spawn_y + rng.randf_range(-LETTER_SPAWN_Y_VARIATION, LETTER_SPAWN_Y_VARIATION)
	label.position = Vector2(spawn_x, spawn_y)
	label.rotation_degrees = rng.randf_range(-LETTER_ROTATION_VARIATION_DEG, LETTER_ROTATION_VARIATION_DEG)
	label.modulate = Color.WHITE
	
	letter_container.add_child(label)
	
	var letter_data = {
		"label": label,
		"char": char,
		"x": spawn_x,
	}
	active_letters.append(letter_data)

func _update_letter_positions(delta):
	var movement = conveyor_speed * delta
	
	for i in range(len(active_letters) - 1, -1, -1):
		var letter = active_letters[i]
		letter["x"] += movement
		letter["label"].position.x = letter["x"]
		
		# Remove when off-screen to the right (or entered the book)
		var book_x = book_visual.position.x if book_visual else (viewport_width - 150)
		if letter["x"] > book_x:
			letter["label"].queue_free()
			active_letters.remove_at(i)

func _update_average_cpm():
	if keys_typed_in_window > 0:
		# CPM = (characters typed / window duration in minutes)
		var window_minutes = cpm_window_duration / 60.0
		average_cpm = float(keys_typed_in_window) / window_minutes
		keys_typed_in_window = 0

func set_typing_speed(speed: float):
	typing_speed = speed

func get_active_letter_count() -> int:
	return len(active_letters)

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
