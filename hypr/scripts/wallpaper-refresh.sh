#!/usr/bin/env bash
set -euo pipefail

base_dir="$HOME/.config/hypr/wallpapers"

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

wallpaper=$(printf '%s\n' "${files[@]}" | shuf -n 1)

swww img "$wallpaper" \
  --transition-type random \
  --transition-duration 1.2 \
  --transition-fps 60
