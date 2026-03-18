#!/usr/bin/env bash
set -euo pipefail

state_dir="${XDG_RUNTIME_DIR:-/tmp}"
state_file="$state_dir/hypr-immersive-mode"

show_layout() {
  hyprctl keyword general:gaps_in 5 >/dev/null
  hyprctl keyword general:gaps_out 20 >/dev/null
  hyprctl keyword general:border_size 2 >/dev/null
  hyprctl keyword decoration:rounding 10 >/dev/null
}

hide_layout() {
  hyprctl keyword general:gaps_in 0 >/dev/null
  hyprctl keyword general:gaps_out 0 >/dev/null
  hyprctl keyword general:border_size 0 >/dev/null
  hyprctl keyword decoration:rounding 0 >/dev/null
}

show_bar() {
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR1 -x waybar
  else
    waybar >/dev/null 2>&1 &
  fi
}

hide_bar() {
  if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR1 -x waybar
  fi
}

if [ -f "$state_file" ]; then
  rm -f "$state_file"
  show_layout
  show_bar
else
  : >"$state_file"
  hide_layout
  hide_bar
fi
