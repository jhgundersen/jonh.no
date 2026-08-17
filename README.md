# jonh.no
The website

## agents.html

An ambient Lemmings parody that plays itself: a level carves itself out of
solid earth and a dozen-odd agents with no supervisor work out how to get
through it. Nobody plays it, including you.

`agents/Sim.js`, `agents/Draw.js` and `agents/Palette.js` are shared byte for
byte with the Omarchy bar plugin that runs the same simulation, and are edited
here because a browser reloads in a keystroke. `./sync-agents.sh` copies them
to the plugin; `./sync-agents.sh --check` fails if the two have drifted.
`agents/web.js` is the only web-only part.

The theme buttons are the real Omarchy themes, so the page doubles as the
development tool the plugin never had: it renders the board under any theme in
a second, where the bar needs a full shell restart for each one.

## Working on it

```sh
./serve.sh              # http://127.0.0.1:8000
./serve.sh --lan        # reachable from a phone on the same network
./deploy.sh             # rsync to jonh:/root/website/data, after confirming
./deploy.sh --dry-run   # show what would change and stop
```

Serve rather than opening the files directly: over `file://` the Google Fonts
stylesheet is blocked so everything falls back to a system font, and some
browsers treat `agents.html`'s scripts as cross-origin. `serve.sh` steps past a
port that is already taken instead of dying on it.

`deploy.sh` always dry-runs first and calls out anything `--delete` would
remove from the server before asking. It also runs `sync-agents.sh --check`, so
a core that has drifted from the plugin is caught before the website becomes
the published version of the disagreement. Neither script is deployed.
