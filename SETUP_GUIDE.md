# Setup & Getting Started Guide

## Prerequisites

- **Godot Engine 4.6+** - Download from [godotengine.org](https://godotengine.org/)
- **Git** (optional, for version control)
- **Windows, macOS, or Linux**

## Installation

### Step 1: Clone or Open the Project

**Option A: Clone from Git**
```bash
git clone https://github.com/yourusername/idle-typing-game.git
cd idle-typing-game
```

**Option B: Download ZIP**
- Download the project files
- Extract to a folder of your choice

### Step 2: Open in Godot

1. Launch Godot Engine
2. Click "Open" → Navigate to the `idle-typing-game` folder
3. Select the folder and click "Open"
4. Godot will import the project and show `main.tscn`

### Step 3: Run the Game

**In Godot Editor:**
- Press **F5** to play from current scene
- Or click the Play button (▶️) in the top right

**Expected Output:**
- Game window appears with gray background
- Two buttons in top right: 📖 (book) and ⚙️ (settings)
- Conveyer belt area at bottom (darker gray rectangle)
- Ready for keyboard input

## First Time Testing

1. **Type some characters** - You should see them appear on the conveyer belt at the bottom
2. **Type faster** - The belt should move characters faster based on your typing speed
3. **Click the 📖 button** - Stats screen appears showing all typed characters
4. **Click the ⚙️ button** - Settings menu opens with sliders and toggles
5. **Close the game** - Stats are automatically saved

## File Locations

After running the game, stats files are created at:

**Windows:**
```
C:\Users\YourUsername\AppData\Local\typing_game\stats\
```

**macOS:**
```
~/Library/Application Support/typing_game/stats/
```

**Linux:**
```
~/.local/share/typing_game/stats/
```

You can browse these folders to see the JSON files being created.

## Project Structure Quick Start

```
idle-typing-game/
├── scenes/main.tscn              ← Main scene (start here)
├── scripts/
│   ├── main.gd                   ← Root orchestrator
│   ├── stats_manager.gd          ← Data management
│   ├── input_handler.gd          ← Keyboard listening
│   ├── conveyer_belt.gd          ← Visual animation
│   └── ui_manager.gd             ← Menu & buttons
├── resources/                    ← For future data files
├── assets/                       ← For graphics & sounds
├── project.godot                 ← Engine configuration
├── MVP_GUIDE.md                  ← Feature documentation
├── TECHNICAL_REFERENCE.md        ← Developer guide
├── SETUP_GUIDE.md                ← This file
└── README.md                     ← Original notes
```

## How to Play

### Basic Controls

| Action | Result |
|--------|--------|
| Type any key | Appears on conveyer belt |
| Stop typing for 2 seconds | Belt animation stops |
| Click 📖 button | Shows global statistics |
| Click ⚙️ button | Opens settings menu |
| Drag size slider | Scales entire game |
| Toggle "Always On Top" | Window stays above others |
| Drag volume slider | Adjusts sound volume |

### Understanding the Display

```
                                      [📖] [⚙️]
Your typing                          Stats Settings
A B C D E F G H I J K...  ────────►  
                                    [BOOK📖]
```

- **Left side**: Characters you type
- **Conveyer belt**: Dark gray area at bottom
- **Right side**: Book visual - destination for your characters
- **Top right**: Control buttons

### Stats Screen

Shows your all-time typing statistics:
- **Total Keys Typed**: Overall count
- **Top 15 Keys**: Most frequently used characters with counts
- Example:
  ```
  Total Keys Typed: 5,234
  
  Top Keys:
  E: 687
  A: 456
  T: 412
  ...
  ```

### Settings Menu

**Game Size** (0.5x to 2.0x)
- Slider to make the game larger or smaller
- Useful for visibility or reduced screen space

**Always On Top**
- Toggle on: Game window stays above all other windows
- Toggle off: Game can be covered by other windows

**Sound Volume** (0-100%)
- Adjust master volume
- Currently ready for future sound effects

**Run on Startup**
- Toggle on: Game attempts to start with system (requires setup)
- Toggle off: Manual launch only

## Keyboard Input

All standard keyboard keys are supported:
- Letters: a-z (recorded as lowercase)
- Numbers: 0-9
- Symbols: !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
- Space: Recorded as "[space]" or similar
- Special keys: Tab, Enter, Backspace, etc.

⚠️ **Note:** Some keys like Control, Shift, Alt trigger events but are not recorded as characters.

### Global Input on Windows

- If helper embedding is set up (see build section), the app tracks keys even when the game window is not focused.
- If helper startup fails, the game automatically falls back to focused-window input.

## Troubleshooting

### Keys Not Appearing on Belt
**Solution:** 
- Make sure the game window has focus (click on it)
- Type more characters
- Check that belt is visible at bottom of screen

### Stats Not Saving
**Solution:**
- Check that the stats directory exists: See "File Locations" above
- Verify write permissions to user directory
- Close and reopen game to trigger save

### Game Won't Start
**Solution:**
- Ensure Godot Engine is version 4.6 or newer
- Try deleting `.godot/` folder and reopening project
- Check console for error messages (View → Toggle BottomPanel in editor)

### Settings Not Working
**Solution:**
- Size slider: Changes appear after dragging, re-run game to persist
- Always On Top: Requires system support (Windows/Linux works better)
- Volume: Only affects future sound effects (none in MVP)

## Performance Tips

### For Smooth Performance
- Close other CPU-intensive applications
- Update your graphics drivers
- Keep OS up to date

### Reduce Resource Usage
- Use size slider to reduce game size if needed
- Close stats screen when not using it (it updates every frame currently)
- Consider disabling "Always On Top" if it causes issues

## Development Workflow

### Making Changes

1. Edit any script file in `scripts/` folder
2. Godot automatically reloads on save
3. Click Play button to test changes
4. Check the Output console for errors

### Common Editing Tasks

**Add a new statistic type:**
- Edit `stats_manager.gd` - Add new tracking variable
- Edit `ui_manager.gd` - Update stats display

**Change animation speed:**
- Edit `conveyer_belt.gd` - Modify `typing_speed` variable
- Change `cpm_window_duration` to adjust calculation interval

**Modify button positions:**
- Edit `ui_manager.gd` - Change Button.position values

**Add new settings:**
- Edit `ui_manager.gd` - Add controls in `_create_settings_menu()`

## Building for Friends

### Export as Standalone Executable

#### Windows: Enable Out-of-Focus Key Tracking (before export)

Run this command once per release build:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_global_helper.ps1
```

This compiles the global keyboard helper and embeds it into project resources so distribution remains a single executable.

1. In Godot Editor: **File → Export Project**
2. Click **Add...** to create new export preset
3. Choose your platform (Windows, macOS, or Linux)
4. Click **Export Project**
5. Select output folder
6. Share the resulting `.exe` / `.app` / binary file

### System Requirements for Players
- No installation needed
- No Godot Engine required
- Windows 10+, macOS 10.9+, or modern Linux distribution
- ~50 MB disk space for the executable

## Next Steps

### For Using the Game
1. Play it! Start typing and watch stats accumulate
2. Check back daily to see daily/global statistics
3. Experiment with settings

### For Developing Features
1. Read [MVP_GUIDE.md](MVP_GUIDE.md) for feature overview
2. Read [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) for architecture
3. Choose a stretch goal to implement
4. Modify the relevant script file
5. Test with F5
6. Iterate and improve

## Getting Help

### In Godot Editor
- **F1**: Opens Godot documentation
- **View → BottomPanel → Output**: Error messages and print() output
- **Debug → Monitor**: Performance metrics

### Online Resources
- [Godot Documentation](https://docs.godotengine.org/en/stable/)
- [GDScript Reference](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/index.html)
- [Godot Community Discord](https://discord.gg/godotengine)

### Debugging Tips
```gdscript
# Add to any script to see messages in Output
print("Value is: ", variable_name)

# Check if function was called
print("Function called!")

# Watch dictionary contents
print("Stats: ", stats_manager.get_global_stats())
```

## Version History

- **v0.1.0 (MVP)** - Initial release with core features
  - Key tracking and display
  - Stats persistence
  - Settings menu
  - UI for stats viewing

---

**Ready to start?** Press F5 in Godot Editor and start typing! 🎮⌨️
