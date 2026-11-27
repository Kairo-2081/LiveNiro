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
: "${LN_SCENES:=}"
: "${LN_SCENE_GIF_WIDTH:=560}"
: "${LN_MAX_TOUR:=600}"
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
source "$LN_HOME/lib/java.sh"
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
      die "Could not tell what kind of project this is. Set 'stack:' or give a 'run:' command. Supported: iGraphics, JavaFX, Java Swing/AWT, Python GUIs (pygame, tkinter, Qt, pyglet, arcade), C/C++ (CMake, Make, qmake, or sources using SFML, SDL2, raylib, GLFW, GLUT, Qt)."
    fi
  }
fi
[ -f "$LN_HOME/stacks/$stack.sh" ] || die "Unknown stack '$stack'. Supported: auto, igraphics, javafx, java, pygame, python, cpp, custom."
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
RUN_CMD="$LN_RUN"
[ -n "$RUN_CMD" ] || RUN_CMD="$(stack_run_command)"
[ -n "$RUN_CMD" ] || die "No run command. Set 'run:'."
APP_LOG="$LN_TMP/app.log"
: >"$APP_LOG"   # one log per run: earlier runs in the same job must not show up in this one's errors
trap 'stop_app; stop_display' EXIT

# launch_app : start the app in its own process group and wait for its window (sets WIN).
launch_app() {
  info "Running: $RUN_CMD"
  setsid bash -c "$RUN_CMD" >>"$APP_LOG" 2>&1 &
  APP_PID=$!
  WIN="$(wait_for_window "$LN_WINDOW" "$LN_WAIT_TIMEOUT" "$APP_PID")" || return 1
  info "Found window $WIN: \"$(window_name "$WIN")\""
}

# restart_app : used by the 'restart' script command. The recorded area stays where it is;
# apps reopen at the same place, so the clip continues seamlessly.
restart_app() {
  stop_app
  launch_app || return 1
  sleep "$LN_WARMUP"
  xdotool windowfocus "$WIN" 2>/dev/null || true
}

launch_app || {
  warn "Last lines of the app's output:"
  tail -n 40 "$APP_LOG" >&2 || true
  die "The app did not open a window within ${LN_WAIT_TIMEOUT}s."
}
sleep "$LN_WARMUP"
# Re-read the geometry after warm-up: many apps resize once they finish loading.
read -r WX WY WW WH < <(window_box "$WIN")
export WIN WX WY

# 4. Record, playing the input script at the same time
RAW="$LN_TMP/raw.mp4"
script_text="$LN_ACTIONS"
[ -n "$LN_SCENES" ] && script_text="$LN_SCENES"
# Show the pointer only when the script uses the mouse; otherwise park it off the window.
if grep -qE '^\s*(click|move)\b' <<<"$script_text"; then LN_DRAW_MOUSE=1; else LN_DRAW_MOUSE=0; xdotool mousemove "$((SCREEN_W - 1))" "$((SCREEN_H - 1))" || true; fi
export LN_DRAW_MOUSE

if [ -n "$LN_SCENES" ]; then
  info "Recording a tour of ${WW}x${WH} at ${WX},${WY}"
  start_recording "$RAW" "$WX" "$WY" "$WW" "$WH" "$LN_FPS" "$LN_MAX_TOUR"
  t0="$(date +%s.%N)"
  play_scenes "$LN_SCENES" "$t0"
  stop_recording
else
  info "Recording ${WW}x${WH} at ${WX},${WY} for ${LN_DURATION}s"
  start_recording "$RAW" "$WX" "$WY" "$WW" "$WH" "$LN_FPS" "$LN_DURATION"
  if [ -n "$LN_ACTIONS" ]; then
    play_actions "$LN_ACTIONS" || warn "The input script stopped early."
  fi
  wait_recording
fi
# What was on screen at the end: useful to check that a scripted flow (login, menu) got where it should.
info "Windows open at the end: $(list_windows | cut -f2 | sed 's/^$/(untitled)/' | paste -sd ',' | sed 's/,/, /g')"

rel() { realpath --relative-to="$REPO_ROOT" "$1"; }

# 5. Encode the outputs
group "Encode"
if [ -n "$LN_SCENES" ]; then
  MP4="$OUT_DIR/$LN_NAME-tour.mp4"
  encode_tour "$RAW" "$LN_TMP/scenes.tsv" "$OUT_DIR" "$LN_NAME" "$LN_SCENE_GIF_WIDTH" "$LN_FPS" "$MP4"
  GIF="$OUT_DIR/$(head -n1 "$LN_TMP/tour.tsv" | cut -f3)"
  POSTER="$OUT_DIR/$(head -n1 "$LN_TMP/tour.tsv" | cut -f4)"
  set_output scenes "$(wc -l <"$LN_TMP/tour.tsv")"
else
  GIF="$OUT_DIR/$LN_NAME.gif"
  MP4="$OUT_DIR/$LN_NAME.mp4"
  POSTER="$OUT_DIR/$LN_NAME.png"
  encode_outputs "$RAW" "$GIF" "$MP4" "$POSTER" "$LN_GIF_WIDTH" "$LN_FPS"
fi
endgroup

set_output gif "$(rel "$GIF")"
set_output mp4 "$(rel "$MP4")"
set_output poster "$(rel "$POSTER")"

# 6. Point the README at the GIF (or the tour gallery)
if [ -n "$LN_README" ] && [ -f "$REPO_ROOT/$LN_README" ]; then
  if [ -n "$LN_SCENES" ]; then
    update_readme_tour "$REPO_ROOT/$LN_README" "$OUT_DIR" "$LN_TMP/tour.tsv" "$MP4"
  else
    update_readme "$REPO_ROOT/$LN_README" "$GIF" "$MP4"
  fi
fi

if [ -n "$LN_SCENES" ]; then
  info "Done: $(wc -l <"$LN_TMP/tour.tsv") scenes ($(du -ch "$OUT_DIR/$LN_NAME"-[0-9][0-9]-*.gif | tail -1 | cut -f1) of GIFs), full tour $(rel "$MP4") ($(du -h "$MP4" | cut -f1))"
  summary "### LiveNiro tour\n\nStack: \`$stack\`\n\n$(awk -F'\t' '{ printf "%s. %s (%ss)\\n", $1, $2, $5 }' "$LN_TMP/tour.tsv")\nFull tour: \`$(rel "$MP4")\`"
else
  info "Done: $(rel "$GIF") ($(du -h "$GIF" | cut -f1)), $(rel "$MP4") ($(du -h "$MP4" | cut -f1))"
  summary "### LiveNiro demo\n\nStack: \`$stack\`\n\nGIF: \`$(rel "$GIF")\`, MP4: \`$(rel "$MP4")\`"
fi
