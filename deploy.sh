#!/usr/bin/env bash
#
# Push the site to jonh.no.
#
#   ./deploy.sh             show what would change, then ask before doing it
#   ./deploy.sh --yes       don't ask
#   ./deploy.sh --dry-run   show what would change and stop
#
# An rsync to jonh:/root/website/data, which is what the web server serves.
# Everything in this directory goes except the repository plumbing and these
# scripts — see EXCLUDES.

set -euo pipefail

TARGET=${DEPLOY_TARGET:-jonh:/root/website/data}

# Kept out of the deploy: the git directory, and the scripts, which are for
# working on the site rather than part of it. There is no reason for a server
# to hand anybody deploy.sh, and a couple of good reasons not to.
EXCLUDES=(
  --exclude '.git'
  --exclude '.gitignore'
  --exclude 'README.md'
  --exclude '*.sh'
)

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

assume_yes=0
dry_only=0
for arg in "$@"; do
  case $arg in
    -y|--yes) assume_yes=1 ;;
    -n|--dry-run) dry_only=1 ;;
    -h|--help) sed -n '3,9p' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "deploy: don't know what '$arg' means" >&2; exit 2 ;;
  esac
done

# The core files are shared with the bar plugin, and the two drifting apart is
# the failure this whole arrangement is set up to avoid. Better to hear about
# it before the website becomes the published version of the disagreement.
if [[ -x ./sync-agents.sh ]]; then
  ./sync-agents.sh --check || {
    echo
    echo "deploy: the shared core has drifted from the plugin (see above)."
    echo "        run ./sync-agents.sh, or deploy anyway with --yes."
    [[ $assume_yes -eq 1 ]] || exit 1
  }
fi

echo "==> $TARGET (dry run)"
if ! out=$(rsync -az --delete --itemize-changes --dry-run "${EXCLUDES[@]}" ./ "$TARGET/" 2>&1); then
  echo "$out" | sed 's/^/    /'
  echo
  case $out in
    *"Permission denied"*|*"publickey"*)
      echo "deploy: the server refused the key. If it has a passphrase, load it first:"
      echo "        ssh-add ~/.ssh/id_ed25519" ;;
    *"Could not resolve"*|*"No route to host"*|*"Connection timed out"*)
      echo "deploy: couldn't reach the host. Check 'ssh jonh' works on its own." ;;
  esac
  exit 1
fi

if [[ -z $out ]]; then
  echo "    already up to date, nothing to do"
  exit 0
fi
echo "$out" | sed 's/^/    /'

# Deletions get called out separately. rsync --delete is the right thing for a
# static site and also the one flag here that can remove something nobody meant
# to remove, so it should never go by unread.
deletions=$(echo "$out" | grep -c '^\*deleting' || true)
[[ $deletions -gt 0 ]] && echo && echo "    $deletions file(s) would be DELETED on the server"

[[ $dry_only -eq 1 ]] && exit 0

if [[ $assume_yes -eq 0 ]]; then
  echo
  read -r -p "Deploy to $TARGET? [y/N] " reply
  [[ $reply == [yY] ]] || { echo "nothing sent"; exit 0; }
fi

echo
echo "==> $TARGET"
rsync -az --delete --itemize-changes "${EXCLUDES[@]}" ./ "$TARGET/" | sed 's/^/    /'
echo
echo "Live at https://jonh.no"
