extends Node

# Stats Manager - Handles tracking and persisting daily/global typing statistics
# Stats are stored as JSON files in user://typing_game/stats/

class_name StatsManager

var global_stats: Dictionary = {}
var daily_stats: Dictionary = {}
var current_date: String = ""
var midnight_timer: Timer

var stats_dir: String = ""
var global_stats_file: String = ""
var daily_stats_prefix: String = ""

func _ready():
	_initialize_paths()
	_ensure_directories()
	current_date = _get_date_string()
	load_stats()
	
	# Create timer for midnight rollover
	midnight_timer = Timer.new()
	add_child(midnight_timer)
	midnight_timer.timeout.connect(_end_day)
	
	# Schedule next midnight
	var seconds_until_midnight = _get_seconds_until_midnight()
	midnight_timer.start(seconds_until_midnight)

func _initialize_paths():
	# Get Documents folder path
	var docs_path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	stats_dir = docs_path.path_join("IdleTypingGame").path_join("stats")
	global_stats_file = stats_dir.path_join("global_stats.json")
	daily_stats_prefix = stats_dir.path_join("daily_")
	print("Stats will be saved to: ", stats_dir)

func _ensure_directories():
	DirAccess.make_dir_recursive_absolute(stats_dir)

func load_stats():
	# Load global stats
	if FileAccess.file_exists(global_stats_file):
		var file = FileAccess.open(global_stats_file, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				global_stats = json.data if json.data is Dictionary else {}
	
	# Load today's stats
	var daily_file = daily_stats_prefix + current_date + ".json"
	if FileAccess.file_exists(daily_file):
		var file = FileAccess.open(daily_file, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.new()
			if json.parse(json_string) == OK:
				daily_stats = json.data if json.data is Dictionary else {}
	
	# Initialize empty stats if needed
	if global_stats.is_empty():
		global_stats = {"total_keys": 0}
	if daily_stats.is_empty():
		daily_stats = {"total_keys": 0, "date": current_date}

func record_key_press(key_event: InputEvent) -> String:
	# Get the character representation of the key
	var char = _get_key_char(key_event)
	return record_character_press(char)

func record_character_press(char: String) -> String:
	if char == "":
		return ""

	var normalized_char := char.substr(0, 1).to_lower()

	# Update daily stats
	if normalized_char not in daily_stats:
		daily_stats[normalized_char] = 0
	daily_stats[normalized_char] += 1
	daily_stats["total_keys"] += 1

	# Update global stats
	if normalized_char not in global_stats:
		global_stats[normalized_char] = 0
	global_stats[normalized_char] += 1
	global_stats["total_keys"] += 1

	_save_stats()
	return normalized_char

func _get_key_char(event: InputEvent) -> String:
	if event is InputEventKey and event.pressed:
		var keycode = event.keycode
		
		# Handle space
		if keycode == KEY_SPACE:
			return " "
		
		# Handle alphanumeric and symbols by checking the Unicode character
		if event.unicode > 0:
			return char(event.unicode).to_lower()
	
	return ""

func _save_stats():
	# Save daily stats
	var daily_file = daily_stats_prefix + current_date + ".json"
	var file = FileAccess.open(daily_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(daily_stats))
	
	# Save global stats
	file = FileAccess.open(global_stats_file, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(global_stats))

func _end_day():
	# Called at midnight to save current day and reset daily stats
	print("Ending day: ", current_date)
	current_date = _get_date_string()
	daily_stats = {"total_keys": 0, "date": current_date}
	_save_stats()
	
	# Reschedule timer for next midnight
	var seconds_until_midnight = _get_seconds_until_midnight()
	midnight_timer.start(seconds_until_midnight)

func _get_date_string() -> String:
	var time = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [time.year, time.month, time.day]

func _get_seconds_until_midnight() -> float:
	var time_dict = Time.get_datetime_dict_from_system()
	var seconds_today = (time_dict.hour * 3600) + (time_dict.minute * 60) + time_dict.second
	var seconds_until_midnight = (24 * 3600) - seconds_today
	return float(seconds_until_midnight)

func get_global_stats() -> Dictionary:
	return global_stats.duplicate(true)

func get_daily_stats() -> Dictionary:
	return daily_stats.duplicate(true)

func get_total_keys() -> int:
	return global_stats.get("total_keys", 0)

func get_daily_total_keys() -> int:
	return daily_stats.get("total_keys", 0)

func get_most_used_key() -> String:
	var max_count = 0
	var most_used = ""
	
	for key in global_stats:
		if key != "total_keys":
			var count = global_stats[key]
			if count > max_count:
				max_count = count
				most_used = key
	
	return most_used

func get_key_count(key: String) -> int:
	return global_stats.get(key, 0)
