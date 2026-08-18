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
# them as plain <script> tags, so a name declared twice has one definition
# silently overwrite the other. Nothing warns about it at runtime in either
# QML or a browser, so it is checked here every time, on both paths.
#
# The check spans the files together, which means it also catches the same name
# declared twice inside one of them — which has already happened once, when a
# new placeHazard() was added next to a dead one of the same name and quietly
# lost every call to the corpse.
check_collisions() {
  local dupes
  dupes=$(cat "${CORE[@]/#/$src/}" \
    | grep -oE '^(function [A-Za-z0-9_]+|var [A-Za-z0-9_]+)' \
    | sed -E 's/^(function|var) //' | sort | uniq -d)
  if [[ -n $dupes ]]; then
    echo "sync-agents: top-level name declared more than once in the core:" >&2
    echo "$dupes" | sed 's/^/  /' >&2
    echo "             one definition silently wins; rename one of them." >&2
    return 1
  fi
}

# The opposite failure, and a worse one: a core file calling something another
# core file defines. See check-core-refs.py for what that cost.
check_cross_refs() {
  [[ -f $here/check-core-refs.py ]] || return 0
  python3 "$here/check-core-refs.py" "$src" "${CORE[@]}"
}

if [[ ${1:-} == --check ]]; then
  check_collisions
  check_cross_refs
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
check_cross_refs

# Refuse to write into the live plugin directory while the screen is locked.
#
# This is not a nicety. The Omarchy lock screen is not a separate program: it is
# a quickshell plugin, so quickshell IS the lockscreen app. Copying a file into
# ~/.config/omarchy/plugins/ makes quickshell hot-reload, and a hot-reload while
# a session lock is held destroys the lock surface. Hyprland then reports that
# the lockscreen app died and drops you on a recovery screen, and the machine is
# unusable until somebody runs
#
#   hyprctl eval 'hl.clear_crashed_lockscreen()'
#
# from another tty. That has happened once, from exactly this script, and the
# journal shows the reload and the lock coming apart in the same second.
if command -v omarchy >/dev/null 2>&1 && [[ ${1:-} != --force ]]; then
  if [[ $(omarchy shell lock isLocked 2>/dev/null) == "true" ]]; then
    echo "sync-agents: the screen is locked — not touching the plugin directory." >&2
    echo "             quickshell is the lock screen here, and writing to a plugin" >&2
    echo "             hot-reloads it, which kills the lock and strands the session." >&2
    echo "             unlock first, or pass --force if you know the screen is free." >&2
    exit 1
  fi
fi

for f in "${CORE[@]}"; do
  cp "$src/$f" "$dst/$f"
  echo "  $f -> $dst/$f"
done

echo
echo "Copied. The plugin will not pick these up from a hot reload — run"
echo "'omarchy restart shell' to see them, and not while the screen is locked."
