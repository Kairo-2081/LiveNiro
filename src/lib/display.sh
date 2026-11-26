# shellcheck shell=bash
# Virtual screen (Xvfb) and window discovery.

start_display() {
  local screen="$1" n
  for n in 99 98 97 96 95; do
    if [ ! -e "/tmp/.X11-unix/X$n" ] && [ ! -e "/tmp/.X$n-lock" ]; then break; fi
  done
  export DISPLAY=":$n"
  Xvfb "$DISPLAY" -screen 0 "${screen}x24" -nolisten tcp >"$LN_TMP/xvfb.log" 2>&1 &
  XVFB_PID=$!

  for _ in $(seq 1 60); do
    xdpyinfo >/dev/null 2>&1 && break
    kill -0 "$XVFB_PID" 2>/dev/null || { tail -5 "$LN_TMP/xvfb.log" >&2; die "The virtual screen crashed on start."; }
    sleep 0.5
  done
  xdpyinfo >/dev/null 2>&1 || die "The virtual screen did not start within 30s."
  SCREEN_W="${screen%x*}"; SCREEN_H="${screen#*x}"
  export SCREEN_W SCREEN_H
  # Software rendering: CI machines have no GPU.
  export LIBGL_ALWAYS_SOFTWARE=1
  # No sound card on CI: audio libraries must not fail.
  export SDL_AUDIODRIVER="${SDL_AUDIODRIVER:-dummy}"
  info "Virtual screen $DISPLAY at $screen"
}

stop_display() {
  if [ -n "${XVFB_PID:-}" ]; then kill "$XVFB_PID" 2>/dev/null || true; fi
}

# window_box <id> : prints "x y w h", clipped to the screen, with even width/height (needed by H.264).
window_box() {
  local info x y w h
  info="$(xwininfo -id "$1" 2>/dev/null)" || return 1
  x="$(awk '/Absolute upper-left X/ {print $NF}' <<<"$info")"
  y="$(awk '/Absolute upper-left Y/ {print $NF}' <<<"$info")"
  w="$(awk '/^ *Width:/ {print $NF}' <<<"$info")"
  h="$(awk '/^ *Height:/ {print $NF}' <<<"$info")"
  [ "$x" -lt 0 ] && { w=$((w + x)); x=0; }
  [ "$y" -lt 0 ] && { h=$((h + y)); y=0; }
  [ $((x + w)) -gt "$SCREEN_W" ] && w=$((SCREEN_W - x))
  [ $((y + h)) -gt "$SCREEN_H" ] && h=$((SCREEN_H - y))
  echo "$x $y $((w / 2 * 2)) $((h / 2 * 2))"
}

# list_windows : prints "id<TAB>name" for every mapped top-level window.
# Uses xwininfo rather than 'xdotool search', which misses some toolkits' windows
# (SDL, for one) when no window manager is running.
list_windows() {
  local id name
  xwininfo -root -children 2>/dev/null \
    | grep -oE '^\s+0x[0-9a-f]+ ("[^"]*"|\(has no name\))' \
    | while read -r id name; do
        if xwininfo -id "$id" 2>/dev/null | grep -q 'Map State: IsViewable'; then
          name="${name#\"}"; name="${name%\"}"
          printf '%s\t%s\n' "$id" "$name"
        fi
      done
}

# wait_for_window <title regex or ""> <timeout s> <app pid> : prints the id of the largest
# visible window (at least 100x100) whose title matches the regex.
wait_for_window() {
  local re="$1" timeout="$2" pid="$3" start best area id name w h a
  start=$(date +%s)
  while [ $(( $(date +%s) - start )) -lt "$timeout" ]; do
    if ! kill -0 "$pid" 2>/dev/null; then
      warn "The app exited before opening a window."
      return 1
    fi
    best=""; area=0
    while IFS=$'\t' read -r id name; do
      [ -n "$id" ] || continue
      if [ -n "$re" ] && ! grep -qE -- "$re" <<<"$name"; then continue; fi
      read -r _ _ w h < <(window_box "$id" || echo "0 0 0 0")
      if [ "${w:-0}" -ge 100 ] && [ "${h:-0}" -ge 100 ]; then
        a=$((w * h))
        if [ "$a" -gt "$area" ]; then area=$a; best=$id; fi
      fi
    done < <(list_windows)
    if [ -n "$best" ]; then echo "$best"; return 0; fi
    sleep 1
  done
  return 1
}

window_name() {
  xwininfo -id "$1" 2>/dev/null | sed -nE 's/^xwininfo: Window id: [^ ]+ "(.*)"$/\1/p'
}
