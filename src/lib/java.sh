# shellcheck shell=bash
# Java toolchain helpers shared by the JavaFX and Java (Swing/AWT) stacks.

# java_version : the Java version the project asks for (Gradle toolchain, source/targetCompatibility,
# or Maven release/source), defaulting to 21.
java_version() {
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

java_use() {
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
