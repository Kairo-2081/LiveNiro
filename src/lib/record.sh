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

# stop_recording : end an open-ended (tour) recording. 'q' on stdin isn't available because
# ffmpeg runs in the background, so send SIGINT, which makes ffmpeg finish the file properly.
stop_recording() {
  kill -INT "$REC_PID" 2>/dev/null || true
  wait "$REC_PID" 2>/dev/null || true
  ffprobe -v error -show_entries format=duration -of csv=p=0 "$RAW" >/dev/null 2>&1 \
    || { cat "$LN_TMP/ffmpeg.log" >&2; die "Recording failed."; }
}

# slugify <text> : "Level 1 – Spikes!" -> "level-1-spikes"
slugify() {
  echo "$1" | iconv -f utf-8 -t ascii//TRANSLIT 2>/dev/null | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-40
}

# encode_tour <raw> <scenes.tsv> <out dir> <name> <gif width> <fps> <tour mp4>
# For each scene writes <name>-NN-<slug>.gif and .png; then the full tour MP4 with a title card
# at the start of each scene and chapter markers. Writes "$LN_TMP/tour.tsv":
# index, title, gif file, poster file, duration (s).
encode_tour() {
  local raw="$1" scenes="$2" out="$3" name="$4" gw="$5" fps="$6" mp4="$7"
  local gfps=$(( fps < 12 ? fps : 12 )) filters total idx title start end len base font meta draw=""
  filters="fps=${gfps},scale=${gw}:-1:flags=lanczos"
  total="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$raw")"
  : >"$LN_TMP/tour.tsv"

  # Scenes from an earlier run may have had other names: clear this tour's old files first.
  find "$out" -maxdepth 1 -type f -name "$name-[0-9][0-9]-*" -delete

  apt_install fonts-dejavu-core >/dev/null 2>&1 || true
  font="$(fc-match -f '%{file}' 'DejaVu Sans:bold' 2>/dev/null || true)"

  meta="$LN_TMP/chapters.txt"
  printf ';FFMETADATA1\n' >"$meta"
  : >"$LN_TMP/concat.txt"
  # The full tour is the scene clips joined end to end, so restarts and other gaps are cut out
  # and chapters line up exactly with scenes. 'at' is where this scene starts in that video.
  local at=0 next

  while IFS=$'\t' read -r idx title start end; do
    # Clamp to the recording (ffmpeg started a moment before the clock, so ends can overshoot a little).
    end="$(awk -v e="$end" -v t="$total" 'BEGIN { printf "%.2f", (e > t ? t : e) }')"
    len="$(awk -v s="$start" -v e="$end" 'BEGIN { printf "%.2f", e - s }')"
    if awk -v l="$len" 'BEGIN { exit !(l < 0.5) }'; then warn "Scene '$title' is shorter than half a second; skipped."; continue; fi
    base="$(printf '%s-%02d-%s' "$name" "$idx" "$(slugify "$title")")"
    info "Scene $idx: $title (${len}s) -> $base.gif"

    ffmpeg -nostdin -loglevel error -y -ss "$start" -to "$end" -i "$raw" -c:v libx264 -preset veryfast -crf 18 \
      -pix_fmt yuv420p -r "$fps" "$LN_TMP/scene.mp4"
    # Use the clip's real length from here on: frame rounding makes it differ slightly from end - start.
    len="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$LN_TMP/scene.mp4" | awk '{ printf "%.3f", $1 }')"
    cp "$LN_TMP/scene.mp4" "$LN_TMP/scene-$idx.mp4"
    printf "file '%s'\n" "$LN_TMP/scene-$idx.mp4" >>"$LN_TMP/concat.txt"
    ffmpeg -nostdin -loglevel error -y -i "$LN_TMP/scene.mp4" -vf "${filters},palettegen=stats_mode=diff:max_colors=128" \
      "$LN_TMP/palette.png"
    ffmpeg -nostdin -loglevel error -y -i "$LN_TMP/scene.mp4" -i "$LN_TMP/palette.png" \
      -lavfi "${filters}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=4:diff_mode=rectangle" -loop 0 "$out/$base.gif"
    ffmpeg -nostdin -loglevel error -y -ss "$(awk -v l="$len" 'BEGIN { printf "%.2f", l / 2 }')" -i "$LN_TMP/scene.mp4" \
      -frames:v 1 -vf "scale=${gw}:-1:flags=lanczos" "$out/$base.png"
    printf '%s\t%s\t%s\t%s\t%s\n' "$idx" "$title" "$base.gif" "$base.png" "$len" >>"$LN_TMP/tour.tsv"

    # Chapter marker, and a title card for the first 2.5 s of the scene in the full video.
    next="$(awk -v a="$at" -v l="$len" 'BEGIN { printf "%.3f", a + l }')"
    printf '[CHAPTER]\nTIMEBASE=1/1000\nSTART=%d\nEND=%d\ntitle=%s\n' \
      "$(awk -v s="$at" 'BEGIN { printf "%d", s * 1000 }')" "$(awk -v e="$next" 'BEGIN { printf "%d", e * 1000 }')" \
      "$(sed 's/[=;#\\]/\\&/g' <<<"$title")" >>"$meta"
    printf '%s · %s' "$idx" "$title" >"$LN_TMP/title-$idx.txt"
    if [ -n "$font" ]; then
      draw+="${draw:+,}drawtext=fontfile=${font}:textfile=${LN_TMP}/title-${idx}.txt:fontsize=h/20:fontcolor=white"
      # shellcheck disable=SC2089  # the quotes are for ffmpeg's filter parser, not the shell
      draw+=":box=1:boxcolor=black@0.6:boxborderw=14:x=24:y=h-text_h-28:enable='between(t,${at},${at}+2.5)'"
    fi
    at="$next"
  done <"$scenes"

  [ -s "$LN_TMP/tour.tsv" ] || die "No scene was long enough to record."

  local vf=()
  [ -n "$draw" ] && vf=(-vf "$draw")
  ffmpeg -nostdin -loglevel error -y -f concat -safe 0 -i "$LN_TMP/concat.txt" -i "$meta" -map 0:v -map_metadata 1 -map_chapters 1 \
    "${vf[@]}" -c:v libx264 -preset veryfast -crf 23 -pix_fmt yuv420p -movflags +faststart "$mp4"

  local size_kb
  size_kb=$(( $(du -ck "$out/$name"-[0-9][0-9]-*.gif | tail -1 | cut -f1) ))
  if [ "$size_kb" -gt 25600 ]; then
    warn "The tour's GIFs add up to $((size_kb / 1024)) MB. Shorten scenes or lower 'scene-gif-width' so the README loads quickly."
  fi
}
