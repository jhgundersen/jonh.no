#!/usr/bin/env bash
#
# Serve the site locally.
#
#   ./serve.sh            http://127.0.0.1:8000
#   ./serve.sh 9000       a port of your choosing
#   ./serve.sh --lan      reachable from other devices, for testing on a phone
#
# Opening the files directly with file:// mostly works and then quietly doesn't:
# the Google Fonts stylesheet is blocked, so everything falls back to a system
# font, and agents.html loads four scripts that a few browsers treat as
# cross-origin from a file URL. Serving it avoids both.

set -euo pipefail

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bind=127.0.0.1
port=${PORT:-8000}

for arg in "$@"; do
  case $arg in
    --lan) bind=0.0.0.0 ;;
    -h|--help) sed -n '3,12p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *[!0-9]*) echo "serve: don't know what '$arg' means" >&2; exit 2 ;;
    *) port=$arg ;;
  esac
done

# Step past a port something else already has, rather than dying on it — the
# usual reason it's taken is a copy of this script still running in another
# terminal, which is not worth stopping to think about.
tries=0
while (exec 3<>/dev/tcp/127.0.0.1/"$port") 2>/dev/null; do
  exec 3>&- 2>/dev/null || true
  port=$((port + 1))
  tries=$((tries + 1))
  if [[ $tries -gt 20 ]]; then
    echo "serve: no free port in range" >&2
    exit 1
  fi
done

host=$([[ $bind == 0.0.0.0 ]] && hostname -I 2>/dev/null | awk '{print $1}' || echo 127.0.0.1)
host=${host:-127.0.0.1}

echo "  http://$host:$port/            front page"
echo "  http://$host:$port/agents.html Oh No! More Agents"
echo "  http://$host:$port/tetris.html Tetris"
echo
echo "Ctrl-C to stop."
echo

exec python3 -m http.server "$port" --bind "$bind"
