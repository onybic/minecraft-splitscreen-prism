#!/usr/bin/env python3
import sys
import subprocess
import importlib.util
from pathlib import Path

def ensure_package(pkg_name):
    """Ensure a Python package is installed, install via pip if not."""
    if importlib.util.find_spec(pkg_name) is None:
        print(f"📦 Installing missing package: {pkg_name}")
        subprocess.check_call([sys.executable, "-m", "pip", "install", pkg_name])

# Make sure vdf is installed
ensure_package("vdf")
import vdf

def find_shortcuts_files():
    """Locate Steam Deck shortcuts.vdf files (native + flatpak)."""
    possible_paths = []
    steam_paths = [
        Path.home() / ".local/share/Steam/userdata",
        Path.home() / ".var/app/com.valvesoftware.Steam/.local/share/Steam/userdata",
        ]

    for base in steam_paths:
        if base.exists():
            for userdir in base.iterdir():
                config = userdir / "config/shortcuts.vdf"
                if config.exists():
                    possible_paths.append(config)

    return possible_paths

def list_shortcuts(vdf_path):
    vdf_file = Path(vdf_path)
    print(f"\n📂 Reading: {vdf_file}")

    with open(vdf_file, "rb") as f:
        shortcuts = vdf.binary_load(f)

    if "shortcuts" not in shortcuts:
        print("⚠️ No shortcuts found in file")
        return

    for idx, data in shortcuts["shortcuts"].items():
        name = data.get("AppName", "Unnamed")
        exe = data.get("Exe", "???")
        launch_opts = data.get("LaunchOptions", "")
        print(f"▶ {name}\n   exe: {exe}\n   opts: {launch_opts}\n")

if __name__ == "__main__":
    if len(sys.argv) == 2:
        # User passed explicit path
        list_shortcuts(sys.argv[1])
    else:
        # Auto-detect only Steam Deck locations
        files = find_shortcuts_files()
        if not files:
            print("❌ No shortcuts.vdf found on Steam Deck paths.")
            sys.exit(1)

        for f in files:
            list_shortcuts(f)
