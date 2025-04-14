# Minecraft Splitscreen

A script to run multiple instances of Minecraft in splitscreen mode on Linux using PollyMC and KDE Plasma.

## Features

- Automatically detects connected controllers
- Supports 1-4 players
- Removes window borders
- Arranges windows in a grid layout
- Works with Game Mode

## Requirements

- Linux with KDE Plasma
- PollyMC (Flatpak)
- Game Mode
- Controllers (optional)

## Installation

1. Clone this repository
2. Make the script executable:
   ```bash
   chmod +x minecraft.sh
   ```

## Usage

Run the script:
```bash
./minecraft.sh
```

The script will:
1. Detect connected controllers
2. Launch appropriate number of Minecraft instances
3. Arrange windows in splitscreen
4. Remove window borders

## License

MIT License - see LICENSE file for details 