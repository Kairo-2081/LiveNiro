# shellcheck shell=bash
# Zero-config stack detection. Prints the stack name, or nothing if unknown.
# Order matters: the most specific signals come first.

detect_stack() {
  local dir="$1"

  # iGraphics (BUET-style OpenGL/GLUT framework): iGraphics.h next to the game source.
  if [ -n "$(find_files "$dir" 2 iGraphics.h | head -1)" ]; then
    echo igraphics; return
  fi

  # JavaFX: a Gradle or Maven build that pulls in OpenJFX.
  local f
  for f in build.gradle build.gradle.kts pom.xml; do
    if [ -f "$dir/$f" ] && grep -qiE 'openjfx|javafx' "$dir/$f"; then
      echo javafx; return
    fi
  done

  # pygame: declared as a dependency, or imported by a script near the top of the repo.
  for f in requirements.txt pyproject.toml setup.py Pipfile; do
    if [ -f "$dir/$f" ] && grep -qi 'pygame' "$dir/$f"; then
      echo pygame; return
    fi
  done
  if find_files "$dir" 2 '*.py' | xargs -r grep -lE '^\s*(import|from)\s+pygame' 2>/dev/null | head -1 | grep -q .; then
    echo pygame; return
  fi
}
