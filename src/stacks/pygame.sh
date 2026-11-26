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
  # Prefer the distro's Python: runner images put a very new Python first on PATH,
  # and pygame often has no prebuilt wheel for it yet (pip then tries to compile SDL bindings).
  local py=python3
  if [ -x /usr/bin/python3 ]; then py=/usr/bin/python3; fi
  "$py" -m venv "$PY_VENV"
  info "Python: $("$PY_VENV/bin/python" --version 2>&1)"
  local pip=("$PY_VENV/bin/python" -m pip install -q)
  "${pip[@]}" --upgrade pip

  if [ -f requirements.txt ]; then
    if ! "${pip[@]}" -r requirements.txt; then
      warn "Installing requirements.txt failed; retrying with pygame-ce in place of pygame."
      grep -viE '^\s*pygame\s*([<>=!~;\[]|$)' requirements.txt >"$LN_TMP/requirements.txt" || true
      "${pip[@]}" -r "$LN_TMP/requirements.txt"
    fi
  elif [ -f pyproject.toml ] || [ -f setup.py ]; then
    "${pip[@]}" . || warn "Could not install the project package; continuing with pygame only."
  fi

  if ! "$PY_VENV/bin/python" -c 'import pygame' 2>/dev/null; then
    # pygame-ce installs the same 'pygame' module and ships wheels for newer Pythons.
    "${pip[@]}" --only-binary=:all: pygame || "${pip[@]}" pygame-ce
  fi
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
