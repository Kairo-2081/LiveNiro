# shellcheck shell=bash
# Input script player. One command per line; '#' starts a comment.
#   wait <seconds>          pause
#   click <x> <y> [button]  click at window-relative coordinates (button: 1 left, 3 right)
#   move <x> <y>            move the mouse
#   key <name>              press and release a key (xdotool names: space, Return, Left, ctrl+s, a ...)
#   hold <key> <seconds>    hold a key down
#   type <text>             type text
#   focus <title regex>     send the following keys to another window (a dialog or popup)
#   restart                 close the app and start it again (for screens with no way back)
#   sh <command>            run a shell command in the project folder (e.g. write a save file)
#
# In a tour ('scenes:'), a line starting with '## ' starts a new scene and names it.
#
# Globals used: WIN (recorded window), WX/WY (its position), PROJECT_DIR; set by liveniro.sh.

# run_action <line> <line number>
run_action() {
  local line="$1" n="$2" cmd a b c
  line="${line%%#*}"
  line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$line" ] && return 0
  read -r cmd a b c <<<"$line"
  case "$cmd" in
    wait)    sleep "${a:?line $n: wait needs seconds}" ;;
    move)    xdotool mousemove $((WX + a)) $((WY + b)) ;;
    click)   xdotool mousemove $((WX + a)) $((WY + b)) sleep 0.05 click "${c:-1}" ;;
    key)     xdotool key --clearmodifiers "$a" ;;
    hold)    xdotool keydown "$a"; sleep "${b:?line $n: hold needs seconds}"; xdotool keyup "$a" ;;
    type)    xdotool type --delay 60 "${line#type }" ;;
    focus)   focus_window "${line#focus }" || warn "Input script line $n: no window matches '${line#focus }'" ;;
    restart) restart_app || warn "Input script line $n: the app did not come back after restart" ;;
    sh)      (cd "$PROJECT_DIR" && bash -c "${line#sh }") || warn "Input script line $n: command failed: ${line#sh }" ;;
    *)       warn "Input script line $n: unknown command '$cmd' (ignored)" ;;
  esac
}

play_actions() {
  local script="$1" line n=0
  # Give the app keyboard focus. Without a window manager, focus follows the window we name.
  xdotool windowfocus "$WIN" 2>/dev/null || true
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    run_action "$line" "$n"
  done <<<"$script"
}

# play_scenes <script> <recording start, epoch seconds> : plays a tour and writes
# "$LN_TMP/scenes.tsv" with one line per scene: index, title, start, end (seconds into the recording).
# A scene's clock restarts after any 'restart' or 'sh' at its top, so relaunch time is cut from the clip.
play_scenes() {
  local script="$1" t0="$2" line n=0 idx=0 title="" start="" fresh=0 out="$LN_TMP/scenes.tsv"
  : >"$out"
  _now() { awk -v t0="$t0" -v t="$(date +%s.%N)" 'BEGIN { printf "%.2f", t - t0 }'; }
  _close_scene() { if [ -n "$title" ]; then printf '%s\t%s\t%s\t%s\n' "$idx" "$title" "$start" "$(_now)" >>"$out"; fi; }
  xdotool windowfocus "$WIN" 2>/dev/null || true
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    if [[ "$line" =~ ^[[:space:]]*##[[:space:]]+(.+)$ ]]; then
      _close_scene
      idx=$((idx + 1))
      title="$(sed 's/[[:space:]]*$//' <<<"${BASH_REMATCH[1]}")"
      start="$(_now)"; fresh=1
      info "Scene $idx: $title"
      continue
    fi
    run_action "$line" "$n"
    if [ "$fresh" -eq 1 ]; then
      if [[ "$line" =~ ^[[:space:]]*(restart|sh)([[:space:]]|$) ]]; then
        start="$(_now)"
      elif [[ ! "$line" =~ ^[[:space:]]*(#|$) ]]; then
        fresh=0
      fi
    fi
  done <<<"$script"
  sleep 0.8
  _close_scene
  [ "$idx" -gt 0 ] || die "The scenes script has no '## Title' lines."
}

# focus_window <title regex> : give keyboard focus to the newest visible window whose title matches.
# Needed for dialogs and popups: with no window manager, a new window does not get focus by itself.
focus_window() {
  local re="$1" id="" cand name
  for _ in $(seq 1 20); do
    while IFS=$'\t' read -r cand name; do
      if grep -qE -- "$re" <<<"$name"; then id="$cand"; fi
    done < <(list_windows)
    [ -n "$id" ] && break
    sleep 0.25
  done
  [ -n "$id" ] || return 1
  xdotool windowfocus "$id" 2>/dev/null || return 1
  info "Focused \"$(window_name "$id")\""
}
