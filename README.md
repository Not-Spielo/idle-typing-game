# Idle Typing Game 🎮⌨️

An idle game typing tool built with Godot 4.6. Every letter you type gets displayed on a conveyer belt that moves them across your screen into a book. The game tracks your typing statistics daily and globally.

## 📖 Quick Start

1. **New to the project?** → Read [SETUP_GUIDE.md](SETUP_GUIDE.md)
2. **Want to understand the features?** → Read [MVP_GUIDE.md](MVP_GUIDE.md)
3. **Building on the code?** → Read [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)

## ✨ MVP Features

- ⌨️ **Real-time Key Tracking** - Every keystroke is recorded
- 📊 **Persistent Statistics** - Daily and global stats saved automatically
- 🎨 **Conveyer Belt Animation** - Characters animated at your typing speed (CPM)
- 📖 **Stats Viewer** - Click book button to see all-time statistics
- ⚙️ **Settings Menu** - Customize size, always-on-top, volume, and more

## 🚀 Building & Distribution

The game is built with Godot 4.6 and can be exported as a standalone executable for Windows, macOS, and Linux. Share it with friends with no installation needed!

```bash
# Windows global key capture helper (required for out-of-focus tracking)
powershell -ExecutionPolicy Bypass -File .\\tools\\build_global_helper.ps1

# To export:
# In Godot: File → Export Project → Choose platform → Export
```

On Windows, `tools/build_global_helper.ps1` compiles the keyboard hook helper and embeds it into `resources/global_key_helper.win64.b64`.
At runtime, the app extracts and launches the helper automatically, so exported distribution remains a single app executable.

## 📁 Project Structure

```
idle-typing-game/
├── scenes/main.tscn         # Main scene
├── scripts/                 # GDScript source code
│   ├── main.gd             # Root orchestrator
│   ├── stats_manager.gd    # Data persistence
│   ├── input_handler.gd    # Keyboard input
│   ├── conveyer_belt.gd    # Visual animation
│   └── ui_manager.gd       # UI & menus
├── resources/              # Reserved for data files
├── assets/                 # Reserved for graphics/sounds
├── tools/                  # Build tooling (helper compile/embed script)
├── project.godot           # Godot configuration
└── SETUP_GUIDE.md         # Getting started guide
```

## 🎯 Planned Stretch Goals

- 📈 Daily statistics dashboard with trends
- 📚 Word detection and Word Dex
- 🏆 Achievement/progression system with unlockables
- 🎬 Key press animations (like Bongo Cat)
- 🐱 Interactive pet companion

## 📋 Documentation

| Document | Purpose |
|----------|---------|
| [SETUP_GUIDE.md](SETUP_GUIDE.md) | Installation, running, and first-time setup |
| [MVP_GUIDE.md](MVP_GUIDE.md) | Feature overview and how everything works |
| [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) | Architecture, code structure, and extension guide |

## 🛠️ Tech Stack

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Data**: JSON (user directory)
- **Platform**: Windows, macOS, Linux

## 📝 License

[Add your license here]

## 🤝 Contributing

The project is ready for extension! Check [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) for guidelines on adding new features.

---

**Start typing and watch your statistics grow!** 📊