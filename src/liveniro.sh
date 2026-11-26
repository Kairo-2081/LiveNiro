#!/usr/bin/env bash
# LiveNiro: build a desktop project, run it on a virtual screen, record it.
# Works inside the GitHub Action and locally (see README, "Run it locally").
set -euo pipefail

LN_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(pwd)"

: "${LN_PATH:=.}"
: "${LN_STACK:=auto}"
: "${LN_SETUP:=}"
: "${LN_BUILD:=}"
: "${LN_RUN:=}"
: "${LN_WINDOW:=}"
: "${LN_WAIT_TIMEOUT:=300}"
: "${LN_WARMUP:=2}"
: "${LN_DURATION:=12}"
: "${LN_ACTIONS:=}"
: "${LN_SCREEN:=1600x900}"
: "${LN_FPS:=15}"
: "${LN_GIF_WIDTH:=800}"
: "${LN_OUTPUT_DIR:=.liveniro}"
: "${LN_NAME:=demo}"
LN_README="${LN_README-README.md}"   # empty means: leave the README alone

LN_TMP="${RUNNER_TEMP:-/tmp}/liveniro"
mkdir -p "$LN_TMP"
export LN_TMP

# shellcheck source=lib/common.sh
source "$LN_HOME/lib/common.sh"
source "$LN_HOME/lib/detect.sh"
source "$LN_HOME/lib/display.sh"
source "$LN_HOME/lib/input.sh"
source "$LN_HOME/lib/record.sh"
source "$LN_HOME/lib/readme.sh"

PROJECT_DIR="$(cd "$REPO_ROOT/$LN_PATH" && pwd)" || die "Project folder not found: $LN_PATH"
OUT_DIR="$REPO_ROOT/$LN_OUTPUT_DIR"
mkdir -p "$OUT_DIR"

# 1. Work out the stack
stack="$LN_STACK"
if [ "$stack" = "auto" ]; then
  stack="$(detect_stack "$PROJECT_DIR")"
  [ -n "$stack" ] || {
    if [ -n "$LN_RUN" ]; then stack="custom"; else
      die "Could not tell what kind of project this is. Set 'stack:' or give a 'run:' command. Supported stacks: igraphics, javafx, pygame."
    fi
  }
fi
[ -f "$LN_HOME/stacks/$stack.sh" ] || die "Unknown stack '$stack'. Supported: auto, igraphics, javafx, pygame, custom."
info "Stack: $stack"
set_output stack "$stack"
# shellcheck disable=SC1090
source "$LN_HOME/stacks/$stack.sh"

cd "$PROJECT_DIR"

# 2. Set up and build
group "Set up $stack"
stack_setup
if [ -n "$LN_SETUP" ]; then bash -euo pipefail -c "$LN_SETUP"; fi
endgroup

group "Build"
if [ -n "$LN_BUILD" ]; then bash -euo pipefail -c "$LN_BUILD"; else stack_build; fi
endgroup

# 3. Start the virtual screen and the app
start_display "$LN_SCREEN"
run_cmd="$LN_RUN"
[ -n "$run_cmd" ] || run_cmd="$(stack_run_command)"
[ -n "$run_cmd" ] || die "No run command. Set 'run:'."
info "Running: $run_cmd"
APP_LOG="$LN_TMP/app.log"
setsid bash -c "$run_cmd" >"$APP_LOG" 2>&1 &
APP_PID=$!
trap 'stop_app; stop_display' EXIT

win="$(wait_for_window "$LN_WINDOW" "$LN_WAIT_TIMEOUT" "$APP_PID")" || {
  warn "Last lines of the app's output:"
  tail -n 40 "$APP_LOG" >&2 || true
  die "The app did not open a window within ${LN_WAIT_TIMEOUT}s."
}
info "Found window $win: \"$(window_name "$win")\""
sleep "$LN_WARMUP"
# Re-read the geometry after warm-up: many apps resize once they finish loading.
read -r WX WY WW WH < <(window_box "$win")
info "Recording ${WW}x${WH} at ${WX},${WY} for ${LN_DURATION}s"

# 4. Record, playing the input script at the same time
RAW="$LN_TMP/raw.mp4"
# Show the pointer only when the script uses the mouse; otherwise park it off the window.
if grep -qE '^\s*(click|move)\b' <<<"$LN_ACTIONS"; then LN_DRAW_MOUSE=1; else LN_DRAW_MOUSE=0; xdotool mousemove "$((SCREEN_W - 1))" "$((SCREEN_H - 1))" || true; fi
export LN_DRAW_MOUSE
start_recording "$RAW" "$WX" "$WY" "$WW" "$WH" "$LN_FPS" "$LN_DURATION"
if [ -n "$LN_ACTIONS" ]; then
  play_actions "$win" "$WX" "$WY" "$LN_ACTIONS" || warn "The input script stopped early."
fi
wait_recording
# What was on screen at the end: useful to check that a scripted flow (login, menu) got where it should.
info "Windows open at the end: $(list_windows | cut -f2 | sed 's/^$/(untitled)/' | paste -sd ',' | sed 's/,/, /g')"

# 5. Encode the outputs
group "Encode"
GIF="$OUT_DIR/$LN_NAME.gif"
MP4="$OUT_DIR/$LN_NAME.mp4"
POSTER="$OUT_DIR/$LN_NAME.png"
encode_outputs "$RAW" "$GIF" "$MP4" "$POSTER" "$LN_GIF_WIDTH" "$LN_FPS"
endgroup

rel() { realpath --relative-to="$REPO_ROOT" "$1"; }
set_output gif "$(rel "$GIF")"
set_output mp4 "$(rel "$MP4")"
set_output poster "$(rel "$POSTER")"

# 6. Point the README at the GIF
if [ -n "$LN_README" ] && [ -f "$REPO_ROOT/$LN_README" ]; then
  update_readme "$REPO_ROOT/$LN_README" "$GIF" "$MP4"
fi

info "Done: $(rel "$GIF") ($(du -h "$GIF" | cut -f1)), $(rel "$MP4") ($(du -h "$MP4" | cut -f1))"
summary "### LiveNiro demo\n\nStack: \`$stack\`\n\nGIF: \`$(rel "$GIF")\`, MP4: \`$(rel "$MP4")\`"
