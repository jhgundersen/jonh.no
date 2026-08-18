# jonh.no
The website

## agents.html

Oh No! More Agents started here and has moved to its own site,
[oh-no-more-agents.com](https://oh-no-more-agents.com/), where it is developed
in the `oh-no-more-agents` repository and keeps the Omarchy bar plugin in sync.
What is left here is a redirect, so the old address still works.

## Working on it

```sh
./serve.sh              # http://127.0.0.1:8000
./serve.sh --lan        # reachable from a phone on the same network
./deploy.sh             # rsync to jonh:/root/website/data, after confirming
./deploy.sh --dry-run   # show what would change and stop
```

Serve rather than opening the files directly: over `file://` the Google Fonts
stylesheet is blocked so everything falls back to a system font. `serve.sh`
steps past a port that is already taken instead of dying on it.

`deploy.sh` always dry-runs first and calls out anything `--delete` would
remove from the server before asking. Neither script is deployed.
