#!/usr/bin/env python3
"""Refuse a core file that reaches into another core file.

The three shared files have no imports between them, deliberately: that is what
lets the identical files run in QML and in a browser. It also means they cannot
call each other. In a browser all three land in one global scope, so a call
across files resolves and looks perfectly fine; in QML each .js is its own
scope, and the same call throws a ReferenceError at runtime.

Draw.js calling Sim.js's specialSpec() did exactly this. The web version was
flawless and the bar plugin drew no agents at all on any level that had a
special, because the exception came out of drawActors before the loop that
draws them. Nothing warned about it anywhere.

Anything one file needs from another travels on the world object instead —
see `w.k` for the geometry constants and `w.specialSpec` for this case.
"""

import re
import sys
import pathlib


def strip(text):
    """Remove comments and string bodies so they can't look like code."""
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    text = re.sub(r'"[^"\n]*"', '""', text)
    text = re.sub(r"'[^'\n]*'", "''", text)
    return text


def main():
    root = pathlib.Path(sys.argv[1])
    files = sys.argv[2:]

    defines, uses = {}, {}
    for name in files:
        text = strip((root / name).read_text())
        defines[name] = set(re.findall(r"^(?:function|var)\s+([A-Za-z_]\w*)", text, re.M))
        local = set(re.findall(r"\b(?:var|function)\s+([A-Za-z_]\w*)", text))
        # The lookbehind matters: `k.CELL` and `ctx.fillRect(` are property
        # accesses on something that was passed in, not references to another
        # file's globals. Without it every constant Draw.js reads off `w.k`
        # reports as a cross-file reach.
        called = set(re.findall(r"(?<![.\w])([A-Za-z_]\w*)\s*\(", text))
        shouted = set(re.findall(r"(?<![.\w])([A-Z][A-Z0-9_]{2,})\b", text))
        uses[name] = (called | shouted) - local

    problems = []
    for name in files:
        for other in files:
            if other == name:
                continue
            for ref in sorted(uses[name] & defines[other]):
                problems.append("  %s uses %s, which only %s defines" % (name, ref, other))

    if problems:
        print("check-core-refs: a core file reaches into another:", file=sys.stderr)
        print("\n".join(problems), file=sys.stderr)
        print("                 that resolves in a browser and throws in QML.", file=sys.stderr)
        print("                 pass it on the world object instead (see w.k).", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
