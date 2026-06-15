#!/bin/bash
set -euo pipefail

APP="/Applications/Queue Populator.app"
OLD_BIN="$HOME/.local/bin/queue-populator"
PLIST="$HOME/Library/LaunchAgents/com.noizu.queue-populator.plist"
CONFIG_DIR="$HOME/.config/queue-populator"

if pgrep -f "queue-populator" >/dev/null 2>&1; then
    echo "Queue Populator is currently running."
    printf "Stop it and continue with uninstall? [y/N] "
    read -r answer
    case "$answer" in
        [yY]|[yY][eE][sS])
            pkill -f "queue-populator" 2>/dev/null || true
            sleep 1
            echo "Process stopped."
            ;;
        *)
            echo "Uninstall cancelled."
            exit 0
            ;;
    esac
fi

if [ -f "$PLIST" ]; then
    launchctl unload "$PLIST" 2>/dev/null || true
    rm -f "$PLIST"
    echo "LaunchAgent removed"
fi

if [ -d "$APP" ]; then
    rm -rf "$APP"
    echo "App removed"
fi

if [ -f "$OLD_BIN" ]; then
    rm -f "$OLD_BIN"
    echo "Old binary removed"
fi

echo "Config at $CONFIG_DIR left intact."
echo "Done."
