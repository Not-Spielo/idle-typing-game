# Idle Typing Game - MVP

A minimalist idle typing game built with Godot 4.6 that tracks every keystroke and displays them on a conveyer belt moving toward a book.

## Features (MVP)

### Core Mechanics
- **Key Tracking**: Every key press is recorded and categorized
- **Conveyer Belt Animation**: Typed characters appear on a belt and move toward a book
- **Dynamic Speed**: Belt speed adjusts based on your actual typing speed (CPM - Characters Per Minute)
- **Auto-Stop**: Belt stops animating 2 seconds after you stop typing

### Statistics System
- **Daily Stats**: Tracks character usage per day in separate JSON files
- **Global Stats**: Accumulates all-time statistics across all days
- **Automatic Rollover**: Daily stats automatically reset at midnight
- **Persistent Storage**: All data saved to `user://typing_game/stats/` directory

### User Interface
- **Book Button (📖)**: Click to view global statistics
  - Shows total keys typed
  - Displays top 15 most-used characters with counts
- **Settings Button (⚙️)**: Click to access settings menu
  - **Game Size**: Slider to scale the entire game (0.5x - 2.0x)
  - **Always On Top**: Toggle to keep game window above other applications
  - **Sound Volume**: Slider to adjust audio (0-100%) - ready for future sound effects
  - **Run on Startup**: Toggle option to launch on system startup (requires platform integration)

## Project Structure

```
idle-typing-game/
├── scenes/
│   └── main.tscn              # Main scene file
├── scripts/
│   ├── main.gd                # Root script orchestrating all systems
│   ├── stats_manager.gd       # Statistics tracking and persistence
│   ├── input_handler.gd       # Keyboard input listener
│   ├── conveyer_belt.gd       # Animation and visual display
│   └── ui_manager.gd          # UI buttons and menus
├── resources/                 # Reserved for data files
├── assets/                    # Reserved for graphics/sounds
├── project.godot              # Godot project configuration
└── README.md                  # This file
```

## How It Works

### Architecture Overview

1. **Main.gd** - Orchestrates all systems
   - Creates and initializes StatsManager, InputHandler, ConveyerBelt, and UIManager
   - Connects signals between systems

2. **StatsManager** - Handles data persistence
   - Records keypresses to both daily and global dictionaries
   - Saves as JSON files to user home directory
   - Automatically handles daily rollover at midnight
   - Provides methods to query statistics

3. **InputHandler** - Listens for keyboard input
   - Captures all key press events
   - Forwards valid characters to StatsManager
   - Emits `key_pressed` signal for visual feedback

4. **ConveyerBelt** - Visual representation
   - Receives key press signals from InputHandler
   - Creates animated labels for each character
   - Moves characters based on calculated CPM (Characters Per Minute)
   - Removes characters when they reach the book
   - Updates speed calculation every 5 seconds based on typing speed

5. **UIManager** - User interface
   - Creates book and settings buttons
   - Manages stats display screen
   - Manages settings menu with all configuration options

## Building & Distribution

To build the game for distribution to friends:

1. In Godot Editor, go to **File > Export Project**
2. Create a new export preset for your target platform (Windows, macOS, Linux, etc.)
3. Configure export settings as needed
4. Click **Export Project** and select a destination folder
5. Share the resulting executable with your friends

## Data Storage

Stats are stored automatically in:
- **Windows**: `C:\Users\YourUsername\AppData\Local\typing_game\stats\`
- **macOS**: `~/Library/Application Support/typing_game/stats/`
- **Linux**: `~/.local/share/typing_game/stats/`

Files are organized as:
- `global_stats.json` - All-time statistics
- `daily_YYYY-MM-DD.json` - Daily statistics for each day

## Stretch Goals to Implement

1. **Daily Statistics Dashboard**
   - Chart showing days with most typing
   - Breakdown of which day of the week you type most
   - Time-based statistics (morning vs evening)

2. **Word Detection**
   - Check if typed words (separated by spaces) exist in a dictionary
   - Store unique words in a "Word Dex"
   - Display achievements for new words

3. **Progression System**
   - Points/XP for reaching typing milestones
   - Unlockable cosmetics:
     - Custom fonts for displayed characters
     - Different conveyer belt styles/colors
     - Hats or decorations for the book
     - Sound effects for key presses

4. **Key Press Animations**
   - Visual feedback similar to Bongo Cat
   - Animated character appearance on the belt
   - Particle effects for special keys

5. **Interactive Pet System**
   - Small character that "eats" letters as they arrive
   - Pet happiness/hunger based on typing activity
   - Pet customization and care mechanics

## Known Limitations (MVP)

- Sound effects not yet implemented (infrastructure ready)
- "Run on Startup" requires platform-specific code integration
- Statistics only track character frequency (not time-based)
- No word detection in current version
- No animations or visual effects beyond movement

## Controls

- **Type Any Key** - Records keystroke and adds to conveyer belt
- **Click 📖 Button** - Toggle statistics screen
- **Click ⚙️ Button** - Toggle settings menu
- **Click Close Buttons** - Close stats/settings screens

## Tips for Development

To extend this project:
- All main systems are self-contained in individual scripts
- Add new features by creating new Canvas Layers for visuals
- Extend StatsManager with new tracking methods
- Add signals to InputHandler to notify other systems
- Use UIManager patterns for additional UI elements

## Future Enhancements

Consider adding:
- Themes/skins for visual customization
- Multiplayer leaderboards
- Goal-setting and achievement system
- Backtick support for other languages/scripts
- Integration with streaming platforms
- Mobile app version

---

Enjoy typing! 🎮⌨️
