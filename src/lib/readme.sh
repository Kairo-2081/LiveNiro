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

# update_readme_tour <readme> <out dir> <tour.tsv> <tour mp4> : the marker block becomes a gallery,
# two scenes per row, followed by a link to the full walkthrough.
update_readme_tour() {
  local readme="$1" out="$2" tour="$3" mp4="$4" dir rel_out rel_mp4 total mins secs block row="" col=0 tmp
  local idx title gif _png _len
  dir="$(dirname "$readme")"
  rel_out="$(realpath --relative-to="$dir" "$out")"
  rel_mp4="$(realpath --relative-to="$dir" "$mp4")"
  total="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$mp4" | cut -d. -f1)"
  mins=$((total / 60)); secs=$((total % 60))

  block="<!-- liveniro:start -->
<table>"
  while IFS=$'\t' read -r idx title gif _png _len; do
    [ $col -eq 0 ] && row="<tr>"
    row+="
<td width=\"50%\" valign=\"top\" align=\"center\">
<img src=\"$rel_out/$gif\" alt=\"$idx. $title, recorded by LiveNiro\" width=\"100%\"><br>
<b>$idx · $title</b>
</td>"
    col=$((col + 1))
    if [ $col -eq 2 ]; then block+="
$row
</tr>"; col=0; fi
  done <"$tour"
  if [ $col -eq 1 ]; then block+="
$row
<td></td>
</tr>"; fi
  block+="
</table>
<p align=\"center\">
  <a href=\"$rel_mp4\"><b>▶ Watch the full walkthrough</b></a> (MP4 · $(printf '%d:%02d' "$mins" "$secs") · chapters)
  <br><sub>Recorded automatically by <a href=\"https://github.com/Kairo-2081/LiveNiro\">LiveNiro</a> on every push</sub>
</p>
<!-- liveniro:end -->"

  tmp="$LN_TMP/readme.tmp"
  if grep -q '<!-- liveniro:start -->' "$readme" && grep -q '<!-- liveniro:end -->' "$readme"; then
    BLOCK="$block" awk '
      /<!-- liveniro:start -->/ { print ENVIRON["BLOCK"]; skip = 1; next }
      /<!-- liveniro:end -->/   { skip = 0; next }
      !skip { print }
    ' "$readme" >"$tmp"
  elif grep -qE '^#{1,2} ' "$readme"; then
    BLOCK="$block" awk '
      !done && /^#{1,2} / { print; print ""; print ENVIRON["BLOCK"]; done = 1; next }
      { print }
    ' "$readme" >"$tmp"
  else
    { echo "$block"; echo; cat "$readme"; } >"$tmp"
  fi
  cat "$tmp" >"$readme"
  info "Updated the tour gallery in $(basename "$readme")."
}
