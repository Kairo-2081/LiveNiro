# shellcheck shell=bash
# README update. Everything between the two markers is owned by LiveNiro:
#   <!-- liveniro:start -->
#   <!-- liveniro:end -->
# If the markers are missing, a block is inserted after the first Markdown heading
# (or at the top of the file when there is none).

update_readme() {
  local readme="$1" gif="$2" mp4="$3" dir rel_gif rel_mp4 block tmp
  dir="$(dirname "$readme")"
  rel_gif="$(realpath --relative-to="$dir" "$gif")"
  rel_mp4="$(realpath --relative-to="$dir" "$mp4")"
  block="<!-- liveniro:start -->
<p align=\"center\">
  <a href=\"$rel_mp4\"><img src=\"$rel_gif\" alt=\"Live demo of this project, recorded by LiveNiro\" width=\"800\"></a>
  <br><sub>Recorded automatically by <a href=\"https://github.com/Kairo-2081/LiveNiro\">LiveNiro</a> on every push · <a href=\"$rel_mp4\">watch the MP4</a></sub>
</p>
<!-- liveniro:end -->"
  tmp="$(mktemp)"

  if grep -q '<!-- liveniro:start -->' "$readme" && grep -q '<!-- liveniro:end -->' "$readme"; then
    BLOCK="$block" awk '
      /<!-- liveniro:start -->/ { print ENVIRON["BLOCK"]; skip = 1; next }
      /<!-- liveniro:end -->/   { skip = 0; next }
      !skip { print }
    ' "$readme" >"$tmp"
    info "Updated the demo block in $(basename "$readme")."
  elif grep -qE '^#{1,2} ' "$readme"; then
    BLOCK="$block" awk '
      !done && /^#{1,2} / { print; print ""; print ENVIRON["BLOCK"]; done = 1; next }
      { print }
    ' "$readme" >"$tmp"
    info "Added a demo block under the first heading of $(basename "$readme")."
  else
    { echo "$block"; echo; cat "$readme"; } >"$tmp"
    info "Added a demo block at the top of $(basename "$readme")."
  fi
  cat "$tmp" >"$readme"
  rm -f "$tmp"
}
