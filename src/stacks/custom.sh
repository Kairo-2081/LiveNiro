# shellcheck shell=bash
# Custom: any app that opens a window on Linux. You provide 'run:' (and usually 'setup:' and 'build:').

stack_setup() { :; }

stack_build() {
  info "No build step for the custom stack (set 'build:' if you need one)."
}

stack_run_command() {
  [ -n "${LN_RUN:-}" ] || die "The custom stack needs a 'run:' command."
  echo "$LN_RUN"
}
