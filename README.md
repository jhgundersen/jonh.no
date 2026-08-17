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

Local preview needs a server rather than opening the file, for the fonts:

```sh
python3 -m http.server 8000
```
