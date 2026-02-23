extends Node

# Input Handler - Listens for all key presses and emits signals
# Connected to StatsManager and TypingDisplay

class_name InputHandler

signal key_pressed(char: String, event: InputEvent)

var stats_manager: StatsManager
var use_window_input: bool = true

func _ready():
	# Get reference to stats manager (it's a sibling on the Main node)
	stats_manager = get_parent().stats_manager

func _input(event: InputEvent):
	if not use_window_input:
		return

	if event is InputEventKey and event.pressed:
		var char = stats_manager.record_key_press(event)
		if char != "":
			key_pressed.emit(char, event)

func submit_global_char(char: String):
	var recorded_char := stats_manager.record_character_press(char)
	if recorded_char != "":
		key_pressed.emit(recorded_char, InputEventKey.new())
