# shellcheck shell=bash
# Python desktop apps and games: pygame, tkinter / turtle (and customtkinter, ttkbootstrap),
# PyQt / PySide, pyglet, arcade, kivy, Dear PyGui.

PY_ENTRY=""
PY_VENV="$LN_TMP/venv"
# Calls that open a window or start a GUI event loop.
PY_STARTS='pygame\.display\.set_mode|\.mainloop\(|turtle\.(done|mainloop|exitonclick)\(|\.exec_?\(\)|arcade\.run\(|pyglet\.app\.run\(|\)\.run\(\)|dpg\.start_dearpygui\('

py_entry() {
  local f
  for f in main.py game.py app.py run.py play.py gui.py __main__.py src/main.py src/game.py src/app.py; do
    if [ -f "$f" ]; then echo "$f"; return; fi
  done
  # Otherwise: a script that starts a GUI and has a main guard, then any script that starts one.
  for f in $(find_files . 2 '*.py' | sort); do
    if grep -qE "$PY_STARTS" "$f" && grep -q '__main__' "$f"; then echo "${f#./}"; return; fi
  done
  for f in $(find_files . 2 '*.py' | sort); do
    if grep -qE "$PY_STARTS" "$f"; then echo "${f#./}"; return; fi
  done
}

# py_uses <regex> : true if the project's code or dependency files mention it.
py_uses() {
  find_files . 3 '*.py' 'requirements*.txt' 'pyproject.toml' 'setup.py' 'Pipfile' | xargs -r grep -qiE -- "$1" 2>/dev/null
}

stack_setup() {
  apt_install python3 python3-venv python3-pip
  # tkinter ships with Python but needs Tk from the system.
  if py_uses '(import|from)\s+(tkinter|Tkinter|turtle)|customtkinter|ttkbootstrap'; then apt_install python3-tk; fi
  # Qt's xcb platform plugin needs these on a minimal system.
  if py_uses 'PyQt5|PyQt6|PySide2|PySide6'; then
    apt_install libxkbcommon-x11-0 libxcb-cursor0 libxcb-icccm4 libxcb-keysyms1 libxcb-image0 \
      libxcb-render-util0 libxcb-xinerama0 libxcb-randr0 libxcb-shape0 libegl1 libdbus-1-3 libfontconfig1
  fi
  if py_uses 'pyglet|arcade|kivy|dearpygui'; then apt_install libgl1 libglu1-mesa libgl1-mesa-dri; fi

  # Prefer the distro's Python: runner images put a very new Python first on PATH,
  # and GUI libraries often have no prebuilt wheel for it yet.
  local py=python3 cand
  if [ -x /usr/bin/python3 ]; then py=/usr/bin/python3; fi
  # Tk is built for one specific Python: if the default can't import tkinter, use one that can.
  if py_uses '(import|from)\s+(tkinter|Tkinter|turtle)|customtkinter|ttkbootstrap' && ! "$py" -c 'import tkinter' 2>/dev/null; then
    for cand in /usr/bin/python3.[0-9]*; do
      case "$cand" in *-config) continue ;; esac
      if "$cand" -c 'import tkinter' 2>/dev/null; then py="$cand"; break; fi
    done
  fi
  rm -rf "$PY_VENV"
  "$py" -m venv "$PY_VENV"
  info "Python: $("$PY_VENV/bin/python" --version 2>&1)"
  local pip=(retry_network "$PY_VENV/bin/python" -m pip install -q)
  "${pip[@]}" --upgrade pip

  if [ -f requirements.txt ]; then
    if ! "${pip[@]}" -r requirements.txt; then
      warn "Installing requirements.txt failed; retrying with pygame-ce in place of pygame."
      grep -viE '^\s*pygame\s*([<>=!~;\[]|$)' requirements.txt >"$LN_TMP/requirements.txt" || true
      "${pip[@]}" -r "$LN_TMP/requirements.txt"
    fi
  elif [ -f pyproject.toml ] || [ -f setup.py ]; then
    "${pip[@]}" . || warn "Could not install the project package; continuing with what the code imports."
  fi

  # Anything the code imports but nothing installed yet (no requirements file, or an incomplete one).
  local mod pkg
  for mod in pygame:pygame pyglet:pyglet arcade:arcade customtkinter:customtkinter ttkbootstrap:ttkbootstrap \
             PyQt5:PyQt5 PyQt6:PyQt6 PySide2:PySide2 PySide6:PySide6 kivy:kivy dearpygui:dearpygui; do
    pkg="${mod#*:}"; mod="${mod%%:*}"
    if py_uses "^\s*(import|from)\s+$mod\b" && ! "$PY_VENV/bin/python" -c "import $mod" 2>/dev/null; then
      if [ "$mod" = pygame ]; then
        # pygame-ce installs the same 'pygame' module and ships wheels for newer Pythons.
        "${pip[@]}" --only-binary=:all: pygame || "${pip[@]}" pygame-ce
      else
        "${pip[@]}" "$pkg"
      fi
    fi
  done
}

stack_build() {
  PY_ENTRY="$(py_entry)"
  [ -n "$PY_ENTRY" ] || die "Could not find the app's entry script. Name it main.py, or set 'run:'."
  info "Entry script: $PY_ENTRY"
  "$PY_VENV/bin/python" -m py_compile "$PY_ENTRY"
}

stack_run_command() {
  [ -n "$PY_ENTRY" ] || PY_ENTRY="$(py_entry)"
  echo "PYGAME_HIDE_SUPPORT_PROMPT=1 QT_QPA_PLATFORM=xcb \"$PY_VENV/bin/python\" \"$PY_ENTRY\""
}
