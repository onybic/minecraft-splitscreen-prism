# Minecraft Splitscreen for Steam Deck

A script to run multiple instances of Minecraft in splitscreen mode on Steam Deck using PollyMC and KDE Plasma.

## Features

- Automatically detects connected controllers
- Supports 1-4 players
- Removes window borders
- Arranges windows in a grid layout
- Works with Game Mode

## Requirements

- Steam Deck
- PollyMC (Flatpak)
- Game Mode
- Controllers (optional)
- [Steam-Deck.Auto-Disable-Steam-Controller](https://github.com/scawp/Steam-Deck.Auto-Disable-Steam-Controller) (required)

Note: This script assumes the Steam Deck's internal controller is disabled when external controllers are connected. Without this, controller indices and calculations need to be adjusted.

## Installation

1. Install PollyMC:
   ```bash
   flatpak install flathub org.fn2006.PollyMC
   ```

2. Setup Minecraft instances:
   - Launch PollyMC
   - Create a new instance named "1.20.1-1" with Minecraft 1.20.1
   - Install Forge and Framework mod
   - Add `controllable-forge-1.20.1-0.21.7-release.jar` which is https://github.com/MrCrayfish/Controllable/ with a patch to more easily select different controllers per instance
   - Copy this instance 3 times, naming them "1.20.1-2", "1.20.1-3", and "1.20.1-4"
   - For each instance:
     - Create an offline account (P1, P2, P3, P4)
     - Set controller index (0, 1, 2, 3 respectively) in the ingame settings for Controllable (controller icon in the settings menu)

3. Download `minecraft.sh`:
   ```bash
   wget https://raw.githubusercontent.com/ArnoldSmith86/Minecraft-Splitscreen/main/minecraft.sh
   chmod +x minecraft.sh
   ```

4. Add to Steam:
   - Open Steam
   - Click "Add a Game" > "Add a Non-Steam Game"
   - Click "Browse" and select the `minecraft.sh` script
   - Click "Add Selected Programs"
   - Right-click the new entry in your library
   - Select "Properties"
   - In "LAUNCH OPTIONS", add: `launchFromGameMode`

## Usage

When in Desktop Mode, just run the script:
```bash
./minecraft.sh
```

The script will:
1. Detect connected controllers
2. Launch appropriate number of Minecraft instances
3. Arrange windows in splitscreen
4. Remove window borders

When in Game Mode, launch it from the shortcut in Steam.

## License

MIT License - see LICENSE file for details 