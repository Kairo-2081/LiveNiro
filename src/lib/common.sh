# shellcheck shell=bash
# Shared helpers: logging, GitHub Action plumbing, package installs.

in_actions() { [ "${GITHUB_ACTIONS:-}" = "true" ]; }

info() { echo "[liveniro] $*" >&2; }
warn() { if in_actions; then echo "::warning title=LiveNiro::$*" >&2; else echo "[liveniro] warning: $*" >&2; fi; }
die()  { if in_actions; then echo "::error title=LiveNiro::$*" >&2; else echo "[liveniro] error: $*" >&2; fi; exit 1; }

group()    { if in_actions; then echo "::group::$*"; else echo "== $*" >&2; fi; }
endgroup() { if in_actions; then echo "::endgroup::"; fi; }

set_output() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "$1=$2" >>"$GITHUB_OUTPUT"; fi
}

summary() {
  if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then printf '%b\n' "$1" >>"$GITHUB_STEP_SUMMARY"; fi
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

sudo_if_needed() {
  if [ "$(id -u)" -eq 0 ]; then "$@"; else sudo "$@"; fi
}

# apt_install pkg... : installs whichever of the packages exist (names differ across Ubuntu releases,
# so "a|b" means: try a, fall back to b).
apt_install() {
  local want=() p alt
  for p in "$@"; do
    for alt in ${p//|/ }; do
      if apt-cache show "$alt" >/dev/null 2>&1; then want+=("$alt"); break; fi
    done
  done
  [ ${#want[@]} -eq 0 ] && return 0
  info "Installing: ${want[*]}"
  sudo_if_needed env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "${want[@]}" >/dev/null
}

stop_app() {
  if [ -n "${APP_PID:-}" ]; then
    # The app was started with setsid, so it leads its own process group: stop the whole tree.
    kill -TERM -- "-$APP_PID" 2>/dev/null || true
    sleep 1
    kill -KILL -- "-$APP_PID" 2>/dev/null || true
  fi
}

# find_files <dir> <maxdepth> <name pattern>... : prints matches, skipping build and VCS folders.
find_files() {
  local dir="$1" depth="$2"; shift 2
  local expr=() first=1 n
  for n in "$@"; do
    if [ $first -eq 1 ]; then first=0; else expr+=(-o); fi
    expr+=(-name "$n")
  done
  find "$dir" -maxdepth "$depth" \
    \( -name .git -o -name node_modules -o -name build -o -name target -o -name .gradle -o -name venv -o -name .venv -o -name __pycache__ \) -prune -o \
    -type f \( "${expr[@]}" \) -print 2>/dev/null
}
