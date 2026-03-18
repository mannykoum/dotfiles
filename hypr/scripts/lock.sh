#!/usr/bin/env bash
set -euo pipefail

conf="$HOME/.config/hypr/hyprlock.conf"
log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/hypr"
log_file="$log_dir/hyprlock.log"

mkdir -p "$log_dir"

if pgrep -x hyprlock >/dev/null 2>&1; then
  exit 0
fi

if [ ! -f "$conf" ]; then
  conf="/usr/share/hypr/hyprlock.conf"
fi

if ! /usr/bin/hyprlock -c "$conf" 2>>"$log_file"; then
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Hyprlock failed" "See $log_file"
  fi
  /usr/bin/loginctl lock-session >/dev/null 2>&1 || true
  exit 1
fi
