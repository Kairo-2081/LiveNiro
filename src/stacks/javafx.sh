# shellcheck shell=bash
# JavaFX apps built with Gradle (org.openjfx.javafxplugin) or Maven (javafx-maven-plugin).

FX_TOOL=""

stack_setup() {
  # Native libraries the JavaFX glass/prism toolkit loads on Linux.
  apt_install "libgtk-3-0t64|libgtk-3-0" libgl1 libgl1-mesa-dri libxtst6 libxxf86vm1 "libasound2t64|libasound2"
  java_use "$(java_version)"

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
