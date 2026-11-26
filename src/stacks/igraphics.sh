# shellcheck shell=bash
# iGraphics: the OpenGL/GLUT teaching framework used in BUET CSE and many other courses.
# Newer templates ship a Linux build script (build.sh) and use SDL2_mixer for sound and
# FreeType for fonts; older ones are plain GLUT.

IG_BIN=""

ig_main_source() {
  if [ -f iMain.cpp ]; then echo iMain.cpp; return; fi
  find_files . 2 '*.cpp' | xargs -r grep -lE 'iInitialize|iOpenWindow' 2>/dev/null | head -1
}

stack_setup() {
  apt_install g++ make freeglut3-dev libglu1-mesa-dev libsdl2-dev libsdl2-mixer-dev \
    "libfreetype-dev|libfreetype6-dev" libgl1-mesa-dri
}

stack_build() {
  if [ -f build.sh ] && grep -q 'linux' build.sh; then
    info "Using the project's build.sh"
    bash build.sh
    if [ -x bin/opengl ]; then IG_BIN="bin/opengl"; fi
  fi

  if [ -z "$IG_BIN" ]; then
    local src
    src="$(ig_main_source)"
    [ -n "$src" ] || die "No iGraphics source found (looked for iMain.cpp, or a .cpp calling iInitialize/iOpenWindow)."
    if grep -qE '^\s*#\s*include\s*<windows.h>' iGraphics.h && ! grep -q '_WIN32' iGraphics.h; then
      die "This iGraphics.h is Windows-only (it includes <windows.h> unconditionally). Use the newer cross-platform iGraphics template, or set 'build:' and 'run:' yourself."
    fi
    mkdir -p "$LN_TMP/igraphics"
    local inc=(-I.)
    [ -d OpenGL/include ] && inc+=(-IOpenGL/include -IOpenGL/include/SDL2 -IOpenGL/include/Freetype)
    info "Compiling $src"
    g++ -w -fexceptions -O1 "${inc[@]}" -I/usr/include/SDL2 -I/usr/include/freetype2 "$src" \
      -o "$LN_TMP/igraphics/app" \
      -lGL -lGLU -lglut -pthread -lSDL2 -lSDL2_mixer -lfreetype
    IG_BIN="$LN_TMP/igraphics/app"
  fi
  info "Built $IG_BIN"
}

stack_run_command() {
  # Run from the project folder: iGraphics games load assets with relative paths.
  [ -n "$IG_BIN" ] || IG_BIN="bin/opengl"
  case "$IG_BIN" in
    /*) echo "\"$IG_BIN\"" ;;
    *)  echo "./$IG_BIN" ;;
  esac
}
