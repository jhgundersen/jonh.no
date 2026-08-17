#!/usr/bin/env bash
#
# Sim.js, Draw.js and Palette.js are shared, byte for byte, between this site
# and the Omarchy bar plugin. This site is where they are edited — the browser
# reloads in a keystroke where the bar needs the whole shell restarted — and
# this script is how they get to the plugin.
#
#   ./sync-agents.sh          copy core -> plugin
#   ./sync-agents.sh --check  fail if the two have drifted, and change nothing
#
# --check is the one to run before publishing either repo. Two checkouts of the
# same file is a standing invitation to fix a bug in one of them and ship the
# other, and the only thing that makes that safe is noticing.

set -euo pipefail

CORE=(Sim.js Draw.js Palette.js)

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$here/agents"
dst="${AGENTS_PLUGIN:-$here/../omarchy-oh-no-more-agents-plugin}"

if [[ ! -d $dst ]]; then
  echo "sync-agents: no plugin at $dst" >&2
  echo "             set AGENTS_PLUGIN=/path/to/plugin, or fix the symlink" >&2
  exit 2
fi

# The three core files land in one shared global scope when the web page loads
# them as plain <script> tags, so a name declared twice would have one file
# silently overwrite the other's function. Nothing warns about that at runtime,
# so it gets checked here every time, on both paths.
check_collisions() {
  local dupes
  dupes=$(cat "${CORE[@]/#/$src/}" \
    | grep -oE '^(function [A-Za-z0-9_]+|var [A-Za-z0-9_]+)' \
    | sed -E 's/^(function|var) //' | sort | uniq -d)
  if [[ -n $dupes ]]; then
    echo "sync-agents: top-level name declared in more than one core file:" >&2
    echo "$dupes" | sed 's/^/  /' >&2
    echo "             they share one global scope in the browser; rename one." >&2
    return 1
  fi
}

if [[ ${1:-} == --check ]]; then
  check_collisions
  status=0
  for f in "${CORE[@]}"; do
    if ! diff -q "$src/$f" "$dst/$f" >/dev/null 2>&1; then
      echo "sync-agents: $f differs between site and plugin" >&2
      status=1
    fi
  done
  [[ $status -eq 0 ]] && echo "sync-agents: core is identical in both, no duplicate names"
  exit $status
fi

check_collisions
for f in "${CORE[@]}"; do
  cp "$src/$f" "$dst/$f"
  echo "  $f -> $dst/$f"
done

echo
echo "Copied. The plugin will not pick these up from a hot reload — run"
echo "'omarchy restart shell' to see them, and not while the screen is locked."
