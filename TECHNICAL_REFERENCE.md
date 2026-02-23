# Technical Reference - Idle Typing Game

## System Architecture

```
┌─────────────────── Main.gd ──────────────────┐
│         Root node - Orchestrates all          │
└──────────┬──────────┬──────────┬──────────────┘
           │          │          │
      ┌────▼───┐ ┌────▼──────┐ ┌▼────────┐
      │ Stats  │ │  Input    │ │Conveyer │  ┌──────────┐
      │Manager │ │ Handler   │ │ Belt    │  │   UI     │
      └────┬───┘ └────┬──────┘ └┬────────┘  │ Manager  │
           │          │         │           └──────────┘
           └──────────┴─────────┘
           (signal: key_pressed)
```

## Signal Flow

1. **User Types Key** → InputEventKey generated
2. **Input Handler** receives event in `_input()` callback
3. **Stats Manager** records character in `record_key_press()`
4. **Signal Emission** → `key_pressed.emit(char, event)`
5. **Conveyer Belt** receives signal in `add_letter()`
6. **Visual Update** → New label added and animated

## Key Classes & Methods

### StatsManager
```gdscript
# Core Methods
load_stats()                           # Load from disk
record_key_press(event) -> String     # Record keystroke, return character
_save_stats()                          # Save to disk

# Query Methods
get_global_stats() -> Dictionary       # All-time stats
get_daily_stats() -> Dictionary        # Today's stats
get_total_keys() -> int                # Total keys ever pressed
get_key_count(key: String) -> int      # Count for specific key
```

**Data Format:**
```json
{
  "total_keys": 1000,
  "a": 150,
  "e": 200,
  " ": 100,
  ...
}
```

### InputHandler
```gdscript
signal key_pressed(char: String, event: InputEvent)

# Gets called for every input event
_input(event: InputEvent)

# Character conversion
_get_key_char(event) -> String
  # Returns:
  # - Lowercase letter for a-z
  # - Space character for KEY_SPACE
  # - Symbol based on Unicode value
  # - Empty string for invalid keys
```

### ConveyerBelt
```gdscript
# Visual Constants
belt_height: int = 100                # Height of animation area
belt_y: float                          # Y position of belt
viewport_width: int                    # Screen width
typing_speed: float = 300.0           # Pixels per second adjustment

# Key Methods
add_letter(char, event)                # Create animated character
_update_letter_positions(delta)        # Update animation each frame
_update_average_cpm()                  # Recalculate speed every 5 seconds

# CPM Calculation
# CPM = (chars typed in 5s) / (5s / 60s per minute)
# Movement per frame = (CPM / 60) * typing_speed * delta
```

### UIManager
```gdscript
# Button Creation
book_button: Button                    # Stats display button
settings_button: Button                # Settings menu button

# Menu Screens
stats_screen: Control                  # Stats display panel
settings_menu: Control                 # Settings panel

# Methods
_show_stats_screen()                   # Display global stats
_update_stats_display()                # Update stats labels
_create_panel_style() -> PanelStyleBox # Create styled panels
```

## File System Paths

**User Directory:** (platform-specific)
```
user://typing_game/stats/
├── global_stats.json          # {"total_keys": X, "a": Y, ...}
└── daily_YYYY-MM-DD.json      # Same format, one per day
```

**Godot Resources:**
```
res://                          # Project root
├── scenes/main.tscn           # Main scene file
├── scripts/*.gd               # All GDScript files
├── project.godot              # Engine config
└── icon.svg                   # Project icon
```

## Extending the System

### Adding a New Feature

1. **Create new script** in `scripts/` folder
2. **Instantiate in Main.gd:**
   ```gdscript
   var new_feature = NewFeature.new()
   new_feature.name = "NewFeature"
   add_child(new_feature)
   ```

3. **Connect signals as needed:**
   ```gdscript
   input_handler.key_pressed.connect(new_feature.on_key)
   # or
   stats_manager.connect("stats_updated", new_feature.update)
   ```

### Adding Stats Queries

In `stats_manager.gd`:
```gdscript
func get_stat_by_category(category: String) -> int:
    var total = 0
    for key in global_stats:
        if key.belongs_to(category):
            total += global_stats[key]
    return total
```

### Adding UI Elements

In `ui_manager.gd`:
```gdscript
var new_button = Button.new()
new_button.text = "New Feature"
new_button.position = Vector2(100, 100)
new_button.pressed.connect(_on_new_feature_pressed)
add_child(new_button)
```

## Animation Timing

**CPM Calculation Loop:**
- Every frame: Update letter positions
- Every 5 seconds: Recalculate average CPM
- Typing timeout: 2 seconds (stops animation after no input)
- Daily rollover: Midnight system time

**Touch Points for Modification:**
- `typing_timeout` - Time before belt stops (currently 2.0s)
- `cpm_window_duration` - CPM recalc interval (currently 5.0s)
- `typing_speed` - Base pixels/second (currently 300.0)
- `belt_height` - Height of conveyer belt (currently 100px)

## Performance Considerations

**Optimizations:**
- Letters removed when off-screen to avoid memory leaks
- CPM recalculated in 5-second intervals (not every frame)
- Typing animation pauses when not typing
- File I/O batched (saves both files at once)

**Potential Issues:**
- Very high typing speed could create many labels (mitigated by CPM smoothing)
- File I/O happens on each keystroke (acceptable for JSON, consider database for large scale)
- No object pooling (could improve if needed)

## Building for Distribution

**Export Steps:**
1. File → Export Project
2. Create new platform preset (Windows, macOS, Linux, etc.)
3. Configure application name, icon, permissions
4. Select export folder
5. Choose "Export Project" (not "Export PCK")

**Result:** Standalone executable that doesn't require Godot Engine

## Testing Checklist

- [ ] Keys appear on conveyer belt when typing
- [ ] Belt moves at appropriate speed based on typing
- [ ] Characters disappear after reaching book
- [ ] Book button opens stats screen
- [ ] Settings button opens settings menu
- [ ] Game size slider works
- [ ] Always-on-top toggle works
- [ ] Volume slider functions
- [ ] Stats persist after closing game
- [ ] Daily stats reset at midnight
- [ ] Global stats accumulate correctly

## Debugging Tips

**Enable console output:**
```gdscript
print("Debug message: ", variable_name)
```

**Check file creation:**
```gdscript
# Stats files created in:
# %APPDATA%\Local\typing_game\stats\ (Windows)
```

**Godot Debug Monitor:**
- F12 in editor to open
- Monitor memory, FPS, node count

**Common Issues:**
- Stats not saving: Check write permissions to user directory
- Keys not recorded: Verify InputHandler is getting _input() calls
- Belt not moving: Check CPM calculation (type faster to test)
- UI not appearing: Check layer values (10 for UI, 5 for belt)
