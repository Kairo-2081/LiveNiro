# shellcheck shell=bash
# pygame games and apps.

PY_ENTRY=""
PY_VENV="$LN_TMP/venv"

py_entry() {
  local f
  for f in main.py game.py app.py run.py play.py __main__.py src/main.py src/game.py; do
    if [ -f "$f" ]; then echo "$f"; return; fi
  done
  # Otherwise: a script that opens a pygame window and has a main guard.
  for f in $(find_files . 2 '*.py' | sort); do
    if grep -q 'pygame.display.set_mode' "$f" && grep -q '__main__' "$f"; then echo "${f#./}"; return; fi
  done
  for f in $(find_files . 2 '*.py' | sort); do
    if grep -q 'pygame.display.set_mode' "$f"; then echo "${f#./}"; return; fi
  done
}

stack_setup() {
  apt_install python3 python3-venv python3-pip
  python3 -m venv "$PY_VENV"
  "$PY_VENV/bin/python" -m pip install -q --upgrade pip
  if [ -f requirements.txt ]; then
    "$PY_VENV/bin/python" -m pip install -q -r requirements.txt
  elif [ -f pyproject.toml ] || [ -f setup.py ]; then
    "$PY_VENV/bin/python" -m pip install -q .
  fi
  "$PY_VENV/bin/python" -c 'import pygame' 2>/dev/null || "$PY_VENV/bin/python" -m pip install -q pygame
}

stack_build() {
  PY_ENTRY="$(py_entry)"
  [ -n "$PY_ENTRY" ] || die "Could not find the game's entry script. Name it main.py, or set 'run:'."
  info "Entry script: $PY_ENTRY"
  "$PY_VENV/bin/python" -m py_compile "$PY_ENTRY"
}

stack_run_command() {
  [ -n "$PY_ENTRY" ] || PY_ENTRY="$(py_entry)"
  echo "PYGAME_HIDE_SUPPORT_PROMPT=1 \"$PY_VENV/bin/python\" \"$PY_ENTRY\""
}
