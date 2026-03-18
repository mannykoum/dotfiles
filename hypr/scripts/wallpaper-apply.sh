#!/usr/bin/env bash
set -euo pipefail

cache_root="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-picker"

if ! pgrep -x swww-daemon >/dev/null 2>&1; then
  swww-daemon >/dev/null 2>&1 &
  sleep 0.2
fi

wallpaper=""
if [ "${1:-}" = "--hash" ] && [ -n "${2:-}" ]; then
  map_file="$cache_root/map/wallpaper-picker-$2.path"
  if [ -f "$map_file" ]; then
    wallpaper="$(cat "$map_file")"
  fi
elif [ -n "${1:-}" ]; then
  wallpaper="$1"
fi

if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
  echo "Wallpaper not found: $wallpaper"
  exit 1
fi

case "${wallpaper##*.}" in
  png|PNG|webp|WEBP)
    # Clear first so alpha channels don't blend with the previous wallpaper.
    swww clear 000000ff
    ;;
esac

swww img "$wallpaper" \
  --transition-type random \
  --transition-duration 1.2 \
  --transition-fps 60
