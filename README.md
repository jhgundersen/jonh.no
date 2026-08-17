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

Local preview needs a server rather than opening the file, for the fonts:

```sh
python3 -m http.server 8000
```
