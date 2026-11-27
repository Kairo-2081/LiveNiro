# shellcheck shell=bash
# C and C++ apps and games: CMake, qmake, Make, or plain source files.
# Libraries are detected from #includes and the build files: SFML, SDL2 (+ image/mixer/ttf),
# raylib, GLFW, GLEW, OpenGL/GLUT and Qt 5/6.

CPP_BIN=""
CPP_MAKE_RUN=0
CPP_LIBS=()        # detected library names
CPP_LDFLAGS=()     # link flags for plain-source builds

# cpp_scan <regex> : true if any source or build file mentions it.
cpp_scan() {
  find_files . 4 '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp' 'CMakeLists.txt' '*.cmake' '*.pro' \
    'Makefile' 'makefile' 'GNUmakefile' | xargs -r grep -qE -- "$1" 2>/dev/null
}

cpp_detect_libs() {
  CPP_LIBS=(); CPP_LDFLAGS=()
  if cpp_scan 'SFML/|find_package\(\s*SFML'; then
    CPP_LIBS+=(sfml)
    cpp_scan 'SFML/Audio' && CPP_LDFLAGS+=(-lsfml-audio)
    cpp_scan 'SFML/Network' && CPP_LDFLAGS+=(-lsfml-network)
    CPP_LDFLAGS+=(-lsfml-graphics -lsfml-window -lsfml-system)
  fi
  if cpp_scan 'SDL2?/SDL\.h|<SDL\.h>|find_package\(\s*SDL2'; then
    CPP_LIBS+=(sdl2)
    cpp_scan 'SDL_image' && { CPP_LIBS+=(sdl2-image); CPP_LDFLAGS+=(-lSDL2_image); }
    cpp_scan 'SDL_mixer' && { CPP_LIBS+=(sdl2-mixer); CPP_LDFLAGS+=(-lSDL2_mixer); }
    cpp_scan 'SDL_ttf' && { CPP_LIBS+=(sdl2-ttf); CPP_LDFLAGS+=(-lSDL2_ttf); }
    CPP_LDFLAGS+=(-lSDL2)
  fi
  if cpp_scan 'raylib\.h|find_package\(\s*raylib'; then
    CPP_LIBS+=(raylib); CPP_LDFLAGS+=(-lraylib -lGL -lm -lpthread -ldl -lrt -lX11)
  fi
  if cpp_scan 'GL/glew\.h'; then CPP_LIBS+=(glew); CPP_LDFLAGS+=(-lGLEW); fi
  if cpp_scan 'GLFW/glfw3\.h|find_package\(\s*glfw3'; then CPP_LIBS+=(glfw); CPP_LDFLAGS+=(-lglfw); fi
  if cpp_scan 'GL/glut\.h|GL/freeglut|find_package\(\s*GLUT'; then CPP_LIBS+=(glut); CPP_LDFLAGS+=(-lglut -lGLU); fi
  if cpp_scan 'find_package\(\s*Qt6|Qt6::|QT\s*\+?=|<Q[A-Z][A-Za-z]+>|QApplication'; then
    if cpp_scan 'find_package\(\s*Qt5|Qt5::'; then CPP_LIBS+=(qt5); else CPP_LIBS+=(qt6); fi
  fi
  if cpp_scan 'GL/gl\.h|<GL/|find_package\(\s*OpenGL'; then CPP_LDFLAGS+=(-lGL); fi
  CPP_LDFLAGS+=(-lm -lpthread)
  info "Libraries: ${CPP_LIBS[*]:-none detected}"
}

cpp_has() { local l; for l in "${CPP_LIBS[@]}"; do [ "$l" = "$1" ] && return 0; done; return 1; }

# raylib is not packaged for Ubuntu: build the latest release from source and install it.
cpp_install_raylib() {
  if pkg-config --exists raylib 2>/dev/null || [ -f /usr/local/include/raylib.h ]; then return 0; fi
  apt_install libx11-dev libxrandr-dev libxinerama-dev libxcursor-dev libxi-dev libgl1-mesa-dev
  info "Building raylib from source (it isn't packaged for Ubuntu)"
  rm -rf "$LN_TMP/raylib"
  retry_network git clone -q --depth 1 --branch 5.5 https://github.com/raysan5/raylib.git "$LN_TMP/raylib"
  # raylib's own build is noisy (warnings from bundled libraries): keep it in a log, show it on failure.
  local log="$LN_TMP/raylib-build.log"
  { cmake -S "$LN_TMP/raylib" -B "$LN_TMP/raylib/build" -DBUILD_EXAMPLES=OFF -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_SHARED_LIBS=OFF \
    && cmake --build "$LN_TMP/raylib/build" -j "$(nproc)" \
    && sudo_if_needed cmake --install "$LN_TMP/raylib/build"; } >"$log" 2>&1 \
    || { tail -n 30 "$log" >&2; die "Building raylib failed."; }
}

stack_setup() {
  apt_install build-essential cmake pkg-config file libgl1-mesa-dev libglu1-mesa-dev libgl1-mesa-dri
  cpp_detect_libs
  cpp_has sfml       && apt_install libsfml-dev
  cpp_has sdl2       && apt_install libsdl2-dev
  cpp_has sdl2-image && apt_install libsdl2-image-dev
  cpp_has sdl2-mixer && apt_install libsdl2-mixer-dev
  cpp_has sdl2-ttf   && apt_install libsdl2-ttf-dev
  cpp_has glfw       && apt_install libglfw3-dev
  cpp_has glew       && apt_install libglew-dev
  cpp_has glut       && apt_install freeglut3-dev
  cpp_has qt6        && apt_install qt6-base-dev qmake6 "libxcb-cursor0" libxkbcommon-x11-0
  cpp_has qt5        && apt_install qtbase5-dev qt5-qmake libxkbcommon-x11-0
  cpp_has raylib     && cpp_install_raylib
  return 0
}

# is_elf_exe <file> : an ELF executable (not a shared library or object file).
is_elf_exe() {
  [ -f "$1" ] && [ -x "$1" ] || return 1
  file -b "$1" 2>/dev/null | grep -qE 'ELF .*(executable|pie executable|shared object.*interpreter)'
}

# cpp_newest_exe <dir> [newer-than file] : the most recently built ELF executable under dir.
cpp_newest_exe() {
  local dir="$1" ref="${2:-}" f args=(-type f -perm -u+x)
  [ -n "$ref" ] && args+=(-newer "$ref")
  find "$dir" \( -name CMakeFiles -o -name .git -o -name _deps \) -prune -o "${args[@]}" -printf '%T@ %p\n' 2>/dev/null \
    | sort -rn | cut -d' ' -f2- | while read -r f; do
        case "$f" in *.so|*.so.*|*.o|*.a|*.sh|*.py) continue ;; esac
        if is_elf_exe "$f"; then echo "$f"; break; fi
      done
}

# Build folders are per project, so several LiveNiro steps in one job don't share a CMake cache.
cpp_build_dir() { echo "$LN_TMP/$1-$(printf '%s' "$PROJECT_DIR" | cksum | cut -d' ' -f1)"; }

cpp_build_cmake() {
  local bdir name
  bdir="$(cpp_build_dir cmake-build)"
  info "CMake project"
  cmake -S . -B "$bdir" -DCMAKE_BUILD_TYPE=Release
  cmake --build "$bdir" -j "$(nproc)"
  # Prefer the first add_executable() target; fall back to the newest executable built.
  for name in $(grep -oE 'add_executable\(\s*[A-Za-z0-9_.+-]+' CMakeLists.txt | sed -E 's/add_executable\(\s*//'); do
    CPP_BIN="$(find "$bdir" -type f -name "$name" -perm -u+x | head -1)"
    [ -n "$CPP_BIN" ] && return 0
  done
  CPP_BIN="$(cpp_newest_exe "$bdir")"
}

cpp_build_qmake() {
  local pro bdir q
  bdir="$(cpp_build_dir qmake-build)"
  pro="$(find_files . 1 '*.pro' | head -1)"
  info "qmake project: $pro"
  q=qmake6; has_cmd qmake6 || q=qmake
  mkdir -p "$bdir"
  (cd "$bdir" && "$q" "$PROJECT_DIR/${pro#./}" && make -j "$(nproc)")
  CPP_BIN="$(cpp_newest_exe "$bdir")"
}

cpp_build_make() {
  local marker="$LN_TMP/make-marker"
  info "Makefile project"
  touch "$marker"; sleep 1
  make -j "$(nproc)"
  CPP_BIN="$(cpp_newest_exe . "$marker")"
  [ -n "$CPP_BIN" ] || CPP_BIN="$(cpp_newest_exe .)"
  if [ -z "$CPP_BIN" ] && grep -qE '^run\s*:' Makefile makefile GNUmakefile 2>/dev/null; then CPP_MAKE_RUN=1; fi
}

cpp_build_sources() {
  local main dir srcs=() cxx=0 out f
  out="$(cpp_build_dir cpp)/app"
  # The file with main(); its folder holds the program's sources.
  main="$(find_files . 3 '*.c' '*.cc' '*.cpp' '*.cxx' | xargs -r grep -lE '^\s*(int|void)\s+main\s*\(' 2>/dev/null \
    | awk '{ print (($0 ~ /\/main\.[a-z]+$/) ? 0 : 1) "\t" $0 }' | sort | head -1 | cut -f2)"
  [ -n "$main" ] || die "No C/C++ file with a main() function was found. Set 'build:' and 'run:'."
  dir="$(dirname "$main")"
  while IFS= read -r f; do
    srcs+=("$f")
    case "$f" in *.cc|*.cpp|*.cxx) cxx=1 ;; esac
  done < <(find_files "$dir" 1 '*.c' '*.cc' '*.cpp' '*.cxx' | sort)
  # Other folders' sources (src/, lib/) are included unless they bring a second main().
  while IFS= read -r f; do
    grep -qE '^\s*(int|void)\s+main\s*\(' "$f" && continue
    srcs+=("$f")
    case "$f" in *.cc|*.cpp|*.cxx) cxx=1 ;; esac
  done < <(find_files . 3 '*.c' '*.cc' '*.cpp' '*.cxx' | grep -v "^$dir/[^/]*$" | sort)
  mkdir -p "$(dirname "$out")"
  info "Compiling ${#srcs[@]} source file(s), entry $main"
  local inc=(-I. -I"$dir")
  [ -d include ] && inc+=(-Iinclude)
  [ -d src ] && inc+=(-Isrc)
  if [ "$cxx" -eq 1 ]; then
    g++ -std=c++17 -O2 -w "${inc[@]}" "${srcs[@]}" -o "$out" "${CPP_LDFLAGS[@]}"
  else
    gcc -std=gnu11 -O2 -w "${inc[@]}" "${srcs[@]}" -o "$out" "${CPP_LDFLAGS[@]}"
  fi
  CPP_BIN="$out"
}

stack_build() {
  [ ${#CPP_LIBS[@]} -gt 0 ] || cpp_detect_libs
  if [ -f CMakeLists.txt ]; then
    cpp_build_cmake
  elif [ -n "$(find_files . 1 '*.pro' | head -1)" ]; then
    cpp_build_qmake
  elif [ -f Makefile ] || [ -f makefile ] || [ -f GNUmakefile ]; then
    cpp_build_make
  else
    cpp_build_sources
  fi
  if [ -n "$CPP_BIN" ]; then info "Built $CPP_BIN"
  elif [ "$CPP_MAKE_RUN" -eq 1 ]; then info "No executable found; will use 'make run'"
  else die "The build finished but no executable was found. Set 'run:' to the program to start."
  fi
}

stack_run_command() {
  # Run from the project folder so relative asset paths (images, fonts, levels) resolve.
  if [ -n "$CPP_BIN" ]; then
    case "$CPP_BIN" in /*) echo "\"$CPP_BIN\"" ;; *) echo "./${CPP_BIN#./}" ;; esac
  else
    echo "make run"
  fi
}
