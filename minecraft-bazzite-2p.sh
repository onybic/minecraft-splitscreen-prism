#!/bin/bash
# minecraft-bazzite-2p.sh
# Improved version of onybic/minecraft-splitscreen-prism for Bazzite-Deck-NVIDIA Desktop
# 2-Player splitscreen with DualSense controllers via Controlify
# Screen: 2560x1440 (Top/Bottom split = 2560x720 each)

set -e

# ===== CONFIGURATION =====
# Prism Launcher instance names (must match your Prism installation)
INSTANCE1="1.21.5-1"
INSTANCE2="1.21.5-2"

# Paths
PRISM_LAUNCHER="${PRISM_LAUNCHER:=/usr/bin/prismlauncher}"
PRISM_CONFIG_DIR="${XDG_CONFIG_HOME:=$HOME/.config}/PrismLauncher"
PRISM_INSTANCES_DIR="${PRISM_INSTANCES_DIR:=$HOME/.local/share/PrismLauncher/instances}"

# Display/Resolution
DISPLAY="${DISPLAY:=:0}"
SCREEN_WIDTH=2560
SCREEN_HEIGHT=1440
HALF_HEIGHT=$((SCREEN_HEIGHT / 2))

# Timing (in seconds)
P1_LOAD_TIME=10      # Wait for P1 to fully init Controlify before launching P2
TILING_DELAY=6       # Wait before applying window tiling
WINDOW_SETTLE_TIME=3 # Additional settle time before checking windows

# ===== FUNCTIONS =====

log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

cleanup() {
  log "Cleaning up any existing Minecraft processes..."
  pkill -f "Minecraft 1.21" 2>/dev/null || true
  sleep 2
}

setup_dualsense_env() {
  log "Setting up DualSense environment..."

  # Force SDL to use only DualSense controllers (ignore everything else)
  export SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT="DualSense,DualSense*"

  # DualSense controller mapping for SDL
  export SDL_GAMECONTROLLERCONFIG="030000004c050000cc09000000000000=DualSense Wireless Controller,a:b0,b:b1,x:b2,y:b3,back:b4,guide:b12,start:b9,leftstick:b10,rightstick:b11,leftshoulder:b6,rightshoulder:b7,dpup:h0.1,dpdown:h0.4,dpleft:h0.8,dpright:h0.2,leftx:a0,lefty:a1,rightx:a2,righty:a5,lefttrigger:a4,righttrigger:a3,"

  log "DualSense environment configured"
}

launch_instance() {
  local instance_name="$1"
  local controller_index="$2"
  local instance_num="$3"

  log "Launching instance $instance_num: '$instance_name' (Controller Index: $controller_index)..."

  # Launch via Prism Launcher
  env -i \
    SDL_GAMECONTROLLER_IGNORE_DEVICES_EXCEPT="DualSense,DualSense*" \
    SDL_GAMECONTROLLERCONFIG="$SDL_GAMECONTROLLERCONFIG" \
    DISPLAY="$DISPLAY" \
    HOME="$HOME" \
    USER="$USER" \
    PATH="$PATH" \
    XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    QT_QPA_PLATFORM_PLUGIN_PATH="" \
    "$PRISM_LAUNCHER" \
    "$PRISM_INSTANCES_DIR/$instance_name/minecraft-instance.json" &

  local pid=$!
  log "Instance $instance_num launched with PID: $pid"
  echo "$pid"
}

tile_windows() {
  log "Waiting $WINDOW_SETTLE_TIME seconds for windows to settle..."
  sleep "$WINDOW_SETTLE_TIME"

  log "Applying TOP/BOTTOM window tiling (2560x1440)..."

  # P1 - TOP HALF (2560x720)
  log "Positioning P1 (TOP): geometry 0,0,2560,720"
  wmctrl -r "Minecraft.*1.21.5.*1" -e "0,0,0,$SCREEN_WIDTH,$HALF_HEIGHT" 2>/dev/null || \
    log "wmctrl P1 positioning (may retry)..."

  # P2 - BOTTOM HALF (2560x720)
  log "Positioning P2 (BOTTOM): geometry 0,720,2560,720"
  wmctrl -r "Minecraft.*1.21.5.*2" -e "0,0,$HALF_HEIGHT,$SCREEN_WIDTH,$HALF_HEIGHT" 2>/dev/null || \
    log "wmctrl P2 positioning (may retry)..."

  # Remove decorations
  log "Removing window decorations..."
  wmctrl -r "Minecraft.*1.21.5.*1" -b add,remove_border 2>/dev/null || true
  wmctrl -r "Minecraft.*1.21.5.*2" -b add,remove_border 2>/dev/null || true

  # Maximize
  log "Applying maximize hint..."
  wmctrl -r "Minecraft.*1.21.5.*1" -b add,maximized_vert,maximized_horz 2>/dev/null || true
  wmctrl -r "Minecraft.*1.21.5.*2" -b add,maximized_vert,maximized_horz 2>/dev/null || true

  log "Tiling complete"
}

verify_instances() {
  log "Verifying Prism instances exist..."

  for instance in "$INSTANCE1" "$INSTANCE2"; do
    local instance_path="$PRISM_INSTANCES_DIR/$instance"
    if [[ ! -d "$instance_path" ]]; then
      log_error "Instance not found: $instance_path"
      log_error "Available instances:"
      ls -la "$PRISM_INSTANCES_DIR/" 2>/dev/null || log_error "  (Cannot list instances directory)"
      return 1
    fi
    log "✓ Instance verified: $instance"
  done
  return 0
}

# ===== MAIN =====

log "=========================================="
log "Minecraft Splitscreen Launcher - Bazzite"
log "=========================================="
log "Display: $DISPLAY"
log "Resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
log "Layout: TOP/BOTTOM (P1 top, P2 bottom)"
log "Controllers: DualSense (USB)"
log "Instances: $INSTANCE1 + $INSTANCE2"
log "=========================================="

# Verify setup
if ! verify_instances; then
  log_error "Instance verification failed. Exiting."
  exit 1
fi

if ! command -v wmctrl &> /dev/null; then
  log_error "wmctrl not found. Install with: sudo dnf install wmctrl"
  exit 1
fi

# Clean up old processes
cleanup

# Setup environment
setup_dualsense_env

# Launch P1
log "=== LAUNCHING PLAYER 1 ==="
P1_PID=$(launch_instance "$INSTANCE1" 0 1)
log "Waiting ${P1_LOAD_TIME}s for P1 to fully initialize..."
sleep "$P1_LOAD_TIME"

# Launch P2
log "=== LAUNCHING PLAYER 2 ==="
P2_PID=$(launch_instance "$INSTANCE2" 1 2)

# Wait before tiling
log "Waiting ${TILING_DELAY}s before window tiling..."
sleep "$TILING_DELAY"

# Apply tiling
tile_windows

log ""
log "=========================================="
log "✓ SPLITSCREEN READY!"
log "=========================================="
log "P1 (TOP):    Controller 0 (First DualSense)"
log "P2 (BOTTOM): Controller 1 (Second DualSense)"
log ""
log "NEXT STEPS:"
log "1. Wait for both instances to fully load Minecraft menus"
log "2. In P1: Start Singleplayer → Create World"
log "3. Press ESC → Open to LAN"
log "4. In P2: Multiplayer → Join LAN Game"
log ""
log "VIDEO SETTINGS (for each instance):"
log "• Resolution: 2560x720"
log "• Fullscreen: OFF (windowed)"
log "• UI Scale: 3"
log ""
log "PIDS: P1=$P1_PID, P2=$P2_PID"
log "=========================================="
log ""

# Wait for both processes
wait $P1_PID $P2_PID
exit_code=$?

log "Minecraft instances terminated (exit code: $exit_code)"
exit $exit_code
