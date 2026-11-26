# shellcheck shell=bash
# Screen recording and encoding with ffmpeg.

start_recording() {
  local out="$1" x="$2" y="$3" w="$4" h="$5" fps="$6" dur="$7"
  ffmpeg -loglevel error -y \
    -f x11grab -draw_mouse "${LN_DRAW_MOUSE:-0}" -framerate "$fps" -video_size "${w}x${h}" -i "${DISPLAY}+${x},${y}" \
    -t "$dur" -c:v libx264 -preset veryfast -crf 18 -pix_fmt yuv420p "$out" \
    >"$LN_TMP/ffmpeg.log" 2>&1 </dev/null &
  REC_PID=$!
}

wait_recording() {
  wait "$REC_PID" || { cat "$LN_TMP/ffmpeg.log" >&2; die "Recording failed."; }
}

# encode_outputs <raw> <gif> <mp4> <poster> <gif width> <fps>
encode_outputs() {
  local raw="$1" gif="$2" mp4="$3" poster="$4" gw="$5" fps="$6"
  local gfps=$(( fps < 12 ? fps : 12 ))
  local filters="fps=${gfps},scale=${gw}:-1:flags=lanczos"

  # MP4 for people who want sharp video (GitHub plays it inline when dragged into an issue/README).
  ffmpeg -loglevel error -y -i "$raw" -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p \
    -movflags +faststart "$mp4"

  # GIF with a palette built from the clip itself: far smaller and cleaner than a default GIF.
  ffmpeg -loglevel error -y -i "$raw" -vf "${filters},palettegen=stats_mode=diff:max_colors=128" \
    "$LN_TMP/palette.png"
  ffmpeg -loglevel error -y -i "$raw" -i "$LN_TMP/palette.png" \
    -lavfi "${filters}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" \
    -loop 0 "$gif"

  # Poster frame from the middle of the clip.
  local dur mid
  dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$raw" 2>/dev/null || echo 2)"
  mid="$(awk -v d="$dur" 'BEGIN { printf "%.2f", d / 2 }')"
  ffmpeg -loglevel error -y -ss "$mid" -i "$raw" -frames:v 1 -vf "scale=${gw}:-1:flags=lanczos" "$poster"

  local size_kb
  size_kb=$(( $(stat -c %s "$gif") / 1024 ))
  if [ "$size_kb" -gt 10240 ]; then
    warn "The GIF is $((size_kb / 1024)) MB. Lower 'duration', 'fps' or 'gif-width' to make the README load faster."
  fi
}
