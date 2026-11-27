# shellcheck shell=bash
# JavaFX apps built with Gradle (org.openjfx.javafxplugin) or Maven (javafx-maven-plugin).

FX_TOOL=""

fx_java_version() {
  local v=""
  for f in build.gradle.kts build.gradle; do
    [ -f "$f" ] || continue
    v="$(grep -oE 'JavaLanguageVersion\.of\(\s*[0-9]+' "$f" | grep -oE '[0-9]+$' | head -1)"
    [ -n "$v" ] || v="$(grep -oE '(source|target)Compatibility\s*=\s*(JavaVersion\.VERSION_)?["'"'"']?[0-9]+' "$f" | grep -oE '[0-9]+$' | head -1)"
  done
  if [ -z "$v" ] && [ -f pom.xml ]; then
    v="$(grep -oE '<(maven\.compiler\.(release|source)|release)>[0-9]+' pom.xml | grep -oE '[0-9]+$' | head -1)"
  fi
  echo "${v:-21}"
}

fx_use_java() {
  local want="$1" var home
  var="JAVA_HOME_${want}_X64"
  home="${!var:-}"
  if [ -z "$home" ] && [ -d "/usr/lib/jvm/java-${want}-openjdk-amd64" ]; then
    home="/usr/lib/jvm/java-${want}-openjdk-amd64"
  fi
  if [ -z "$home" ]; then
    apt_install "openjdk-${want}-jdk"
    home="/usr/lib/jvm/java-${want}-openjdk-amd64"
  fi
  [ -d "$home" ] || die "Java $want is not available. Add 'actions/setup-java' before LiveNiro."
  export JAVA_HOME="$home"
  export PATH="$JAVA_HOME/bin:$PATH"
  info "Using Java $want at $JAVA_HOME"
}

stack_setup() {
  # Native libraries the JavaFX glass/prism toolkit loads on Linux.
  apt_install "libgtk-3-0t64|libgtk-3-0" libgl1 libgl1-mesa-dri libxtst6 libxxf86vm1 "libasound2t64|libasound2"
  fx_use_java "$(fx_java_version)"

  # Software rendering: there is no GPU on CI. Append so existing JVM options (proxies, trust stores) survive.
  export JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:-} -Dprism.order=sw -Dprism.forceGPU=false"

  if [ -f build.gradle ] || [ -f build.gradle.kts ]; then
    FX_TOOL=gradle
    if [ -f gradlew ]; then chmod +x gradlew; fi
  elif [ -f pom.xml ]; then
    FX_TOOL=maven
    if [ -f mvnw ]; then chmod +x mvnw; fi
  else
    die "JavaFX project without build.gradle(.kts) or pom.xml."
  fi
}

fx_gradle() { if [ -f gradlew ]; then ./gradlew "$@"; else gradle "$@"; fi; }
fx_maven()  { if [ -f mvnw ]; then ./mvnw "$@"; else mvn "$@"; fi; }

stack_build() {
  case "$FX_TOOL" in
    # Package servers (Maven Central, the Gradle plugin portal) rate-limit busy CI runners; retry those.
    gradle) retry_network fx_gradle --no-daemon -q classes ;;
    maven)  retry_network fx_maven -q -B -DskipTests compile ;;
  esac
}

stack_run_command() {
  case "$FX_TOOL" in
    gradle) if [ -f gradlew ]; then echo "./gradlew --no-daemon -q run"; else echo "gradle --no-daemon -q run"; fi ;;
    maven)  if [ -f mvnw ]; then echo "./mvnw -q -B javafx:run"; else echo "mvn -q -B javafx:run"; fi ;;
  esac
}
