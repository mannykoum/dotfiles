#!/usr/bin/env bash
set -euo pipefail

base_dir="$HOME/.config/hypr/wallpapers"

if ! command -v walker >/dev/null 2>&1; then
  echo "walker is not installed"
  exit 1
fi

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
  swww-daemon >/dev/null 2>&1 &
  sleep 0.2
fi

mapfile -t files < <(
  find -L "$base_dir" -type f \
    \( -iname '*.gif' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) \
    ! -path "$base_dir/mp4/*" \
    | sort
)

if [ ${#files[@]} -eq 0 ]; then
  echo "No compatible wallpapers found in $base_dir"
  exit 1
fi

menu_list=$(printf '%s\n' "${files[@]}" | sed "s#^$base_dir/##")

selection=$(printf '%s\n' "$menu_list" | walker --dmenu --placeholder "Pick wallpaper (stills + GIFs)")
if [ -z "${selection:-}" ]; then
  exit 0
fi

wallpaper="$base_dir/$selection"
if [ ! -f "$wallpaper" ]; then
  echo "Selection not found: $wallpaper"
  exit 1
fi

swww img "$wallpaper" \
  --transition-type random \
  --transition-duration 1.2 \
  --transition-fps 60
