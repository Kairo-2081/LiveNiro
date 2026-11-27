# shellcheck shell=bash
# Zero-config stack detection. Prints the stack name, or nothing if unknown.
# Order matters: the most specific signals come first.

# Imports that mean "this Python project opens a window".
PY_GUI_IMPORTS='pygame|pyglet|arcade|tkinter|Tkinter|turtle|customtkinter|ttkbootstrap|PyQt5|PyQt6|PySide2|PySide6|kivy|dearpygui'
# Includes / CMake packages that mean "this C or C++ project opens a window".
CPP_GUI_MARKERS='SFML/|SDL2?/SDL\.h|<SDL\.h>|raylib\.h|GLFW/glfw3\.h|GL/glut\.h|GL/freeglut|<Q[A-Z][A-Za-z]+>|QApplication|QtWidgets|find_package\(\s*(SFML|SDL2|raylib|glfw3|GLUT|OpenGL|Qt[56])'

detect_stack() {
  local dir="$1" f

  # iGraphics (BUET-style OpenGL/GLUT framework): iGraphics.h next to the game source.
  if [ -n "$(find_files "$dir" 2 iGraphics.h | head -1)" ]; then
    echo igraphics; return
  fi

  # JavaFX: a Gradle or Maven build that pulls in OpenJFX.
  for f in build.gradle build.gradle.kts pom.xml; do
    if [ -f "$dir/$f" ] && grep -qiE 'openjfx|javafx' "$dir/$f"; then
      echo javafx; return
    fi
  done

  # Java Swing / AWT: Gradle, Maven or plain .java sources that use a desktop GUI.
  if find_files "$dir" 6 '*.java' | xargs -r grep -lE 'javax\.swing|java\.awt' 2>/dev/null | head -1 | grep -q .; then
    echo java; return
  fi

  # Python with a GUI library: pygame keeps its own name, everything else is "python".
  for f in requirements.txt pyproject.toml setup.py Pipfile; do
    if [ -f "$dir/$f" ] && grep -qiE '(^|[^a-z-])pygame' "$dir/$f"; then echo pygame; return; fi
  done
  if find_files "$dir" 2 '*.py' | xargs -r grep -lE '^\s*(import|from)\s+pygame' 2>/dev/null | head -1 | grep -q .; then
    echo pygame; return
  fi
  for f in requirements.txt pyproject.toml setup.py Pipfile; do
    if [ -f "$dir/$f" ] && grep -qiE "$PY_GUI_IMPORTS" "$dir/$f"; then echo python; return; fi
  done
  if find_files "$dir" 2 '*.py' | xargs -r grep -lE "^\s*(import|from)\s+($PY_GUI_IMPORTS)" 2>/dev/null | head -1 | grep -q .; then
    echo python; return
  fi

  # C / C++: a CMake, qmake or Make project, or plain sources that include a GUI library.
  if [ -f "$dir/CMakeLists.txt" ] || [ -n "$(find_files "$dir" 1 '*.pro' | head -1)" ]; then
    echo cpp; return
  fi
  if { [ -f "$dir/Makefile" ] || [ -f "$dir/makefile" ] || [ -f "$dir/GNUmakefile" ]; } \
    && find_files "$dir" 3 '*.c' '*.cc' '*.cpp' '*.cxx' | head -1 | grep -q .; then
    echo cpp; return
  fi
  if find_files "$dir" 3 '*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hpp' | xargs -r grep -lE "$CPP_GUI_MARKERS" 2>/dev/null | head -1 | grep -q .; then
    echo cpp; return
  fi
}
