# Idle Typing Game 🎮⌨️

An idle game typing tool built with Godot 4.6. Every letter you type gets displayed on a conveyer belt that moves them across your screen into a book. The game tracks your typing statistics daily and globally.

## MVP Features

- **Real-time Key Tracking**  
- **Persistent Statistics**  
- **Conveyer Belt Animation**  
- **Stats Viewer**  
- **Settings Menu**  

```bash
# Windows global key capture helper (required for out-of-focus tracking)
powershell -ExecutionPolicy Bypass -File .\\tools\\build_global_helper.ps1

# To export:
# In Godot: File → Export Project → Choose platform → Export
```

On Windows, `tools/build_global_helper.ps1` compiles the keyboard hook helper and embeds it into `resources/global_key_helper.win64.b64`.
At runtime, the app extracts and launches the helper automatically, so exported distribution remains a single app executable.

## Planned Stretch Goals

- Daily statistics dashboard with trends
- Word detection and Word Dex
- Achievement/progression system with unlockables 
    + change font
    + conveyor belt skins
    + book skins
- Key press animations (like Bongo Cat)
- Interactive pet companion (tomagatchi)

## License

I own all of this don't touch please

## Contributing

The project is ready for extension! Check and add anything you want to it!

**Start typing and watch your statistics grow!**