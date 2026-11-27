# shellcheck shell=bash
# Java desktop apps with Swing or AWT: a Gradle 'application', a Maven project, or plain .java files.

JAVA_TOOL=""
JAVA_MAIN=""
JAVA_CLASSES="$LN_TMP/java-classes"

# java_main_class : fully qualified name of the class to start. Prefers a main() in a file that
# uses Swing/AWT, and a class called Main / App.
java_main_class() {
  local f pkg best=""
  while IFS= read -r f; do
    grep -qE 'public\s+static\s+void\s+main\s*\(' "$f" || continue
    pkg="$(grep -m1 -oE '^\s*package\s+[A-Za-z0-9_.]+' "$f" | awk '{ print $2 }')"
    local cls; cls="$(basename "$f" .java)"
    local fq="${pkg:+$pkg.}$cls" score=0
    grep -qE 'javax\.swing|java\.awt|JFrame' "$f" && score=$((score + 2))
    case "$cls" in Main|App|Application|Launcher) score=$((score + 1)) ;; esac
    best="$(printf '%s\n%d\t%s' "$best" "$score" "$fq")"
  done < <(find_files . 8 '*.java' | grep -vE '/(test|tests)/')
  sort -rn <<<"$best" | sed '/^$/d' | head -1 | cut -f2
}

java_gradle() { if [ -f gradlew ]; then chmod +x gradlew; ./gradlew "$@"; else gradle "$@"; fi; }
java_maven()  { if [ -f mvnw ]; then chmod +x mvnw; ./mvnw "$@"; else mvn "$@"; fi; }

stack_setup() {
  # AWT needs the X11 client libraries and at least one font.
  apt_install libxtst6 libxrender1 libxi6 libxext6 fontconfig fonts-dejavu-core
  java_use "$(java_version)"
  # Anti-aliased text, and no attempt at GPU pipelines on a GPU-less runner.
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dsun.java2d.opengl=false"

  if { [ -f build.gradle ] || [ -f build.gradle.kts ]; } && grep -qE "application|mainClass" build.gradle build.gradle.kts 2>/dev/null; then
    JAVA_TOOL=gradle
  elif [ -f pom.xml ]; then
    JAVA_TOOL=maven
  else
    JAVA_TOOL=plain
  fi
  info "Java build: $JAVA_TOOL"
}

stack_build() {
  case "$JAVA_TOOL" in
    gradle) retry_network java_gradle --no-daemon -q classes ;;
    maven)
      retry_network java_maven -q -B -DskipTests compile
      JAVA_MAIN="$(java_main_class)"
      ;;
    plain)
      local srcs=()
      mapfile -t srcs < <(find_files . 8 '*.java' | grep -vE '/(test|tests)/')
      [ ${#srcs[@]} -gt 0 ] || die "No .java files found."
      rm -rf "$JAVA_CLASSES"; mkdir -p "$JAVA_CLASSES"
      info "Compiling ${#srcs[@]} Java file(s)"
      javac -nowarn -encoding UTF-8 -d "$JAVA_CLASSES" "${srcs[@]}"
      JAVA_MAIN="$(java_main_class)"
      ;;
  esac
  if [ "$JAVA_TOOL" != gradle ]; then
    [ -n "$JAVA_MAIN" ] || die "No class with 'public static void main' was found. Set 'run:'."
    info "Main class: $JAVA_MAIN"
  fi
}

stack_run_command() {
  case "$JAVA_TOOL" in
    gradle) if [ -f gradlew ]; then echo "./gradlew --no-daemon -q run"; else echo "gradle --no-daemon -q run"; fi ;;
    maven)  echo "$( [ -f mvnw ] && echo ./mvnw || echo mvn ) -q -B exec:java -Dexec.mainClass=$JAVA_MAIN" ;;
    # Resources (images, sounds) are usually loaded from the project folder or src/.
    plain)  echo "java -cp \"$JAVA_CLASSES:.:src:resources:src/main/resources\" $JAVA_MAIN" ;;
  esac
}
