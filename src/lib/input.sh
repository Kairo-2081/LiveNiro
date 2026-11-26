# shellcheck shell=bash
# Input script player. One command per line; '#' starts a comment.
#   wait <seconds>          pause
#   click <x> <y> [button]  click at window-relative coordinates (button: 1 left, 3 right)
#   move <x> <y>            move the mouse
#   key <name>              press and release a key (xdotool names: space, Return, Left, ctrl+s, a ...)
#   hold <key> <seconds>    hold a key down
#   type <text>             type text

play_actions() {
  local win="$1" wx="$2" wy="$3" script="$4" line cmd a b c n=0
  # Give the app keyboard focus. Without a window manager, focus follows the window we name.
  xdotool windowfocus --sync "$win" 2>/dev/null || xdotool windowfocus "$win" 2>/dev/null || true
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    read -r cmd a b c <<<"$line"
    case "$cmd" in
      wait)  sleep "${a:?line $n: wait needs seconds}" ;;
      move)  xdotool mousemove $((wx + a)) $((wy + b)) ;;
      click) xdotool mousemove $((wx + a)) $((wy + b)) sleep 0.05 click "${c:-1}" ;;
      key)   xdotool key --window "$win" --clearmodifiers "$a" 2>/dev/null || xdotool key "$a" ;;
      hold)  xdotool keydown "$a"; sleep "${b:?line $n: hold needs seconds}"; xdotool keyup "$a" ;;
      type)  xdotool type --delay 60 "${line#type }" ;;
      *)     warn "Input script line $n: unknown command '$cmd' (ignored)" ;;
    esac
  done <<<"$script"
}
