#!/usr/bin/env bash
set -euo pipefail

base_dir="$HOME/.config/hypr/wallpapers"
mp4_dir="$base_dir/mp4"
gif_dir="$base_dir/gif"

mkdir -p "$gif_dir"

shopt -s nullglob
mp4_files=("$mp4_dir"/*.mp4)
if [ ${#mp4_files[@]} -eq 0 ]; then
  echo "No MP4 files found in $mp4_dir"
  exit 1
fi

for mp4 in "${mp4_files[@]}"; do
  name=$(basename "$mp4" .mp4)
  out="$gif_dir/$name-4k.gif"

  echo "Converting: $mp4"
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height,avg_frame_rate -of default=nw=1 "$mp4" || true

  ffmpeg -y -i "$mp4" -t 12 \
    -vf "fps=10,scale=-2:2160:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
    -loop 0 "$out"

  echo "Wrote: $out"
done
