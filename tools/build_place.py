#!/usr/bin/env python3
"""Build NorilskLastShift.rbxlx from src/ without needing Rojo.

Mirrors default.project.json:
  src/shared  -> ReplicatedStorage.Shared         (ModuleScripts)
  src/server  -> ServerScriptService               (*.server.luau = Script, else ModuleScript)
  src/client  -> StarterPlayer.StarterPlayerScripts (*.client.luau = LocalScript, else ModuleScript)

Usage: python3 tools/build_place.py [output.rbxlx]
"""
import itertools
import sys
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "src"
_ids = itertools.count(1)


def ref():
    return f"RBX{next(_ids):08X}"


def cdata(text):
    # A literal "]]>" would end the CDATA section early; split it.
    return "<![CDATA[" + text.replace("]]>", "]]]]><![CDATA[>") + "]]>"


def script_item(path: Path):
    name = path.name
    if name.endswith(".server.luau"):
        cls, inst = "Script", name[: -len(".server.luau")]
    elif name.endswith(".client.luau"):
        cls, inst = "LocalScript", name[: -len(".client.luau")]
    else:
        cls, inst = "ModuleScript", path.stem
    source = path.read_text(encoding="utf-8")
    return (
        f'<Item class="{cls}" referent="{ref()}"><Properties>'
        f'<string name="Name">{escape(inst)}</string>'
        f'<ProtectedString name="Source">{cdata(source)}</ProtectedString>'
        f"</Properties></Item>"
    )


def item(cls, name, children="", props=""):
    return (
        f'<Item class="{cls}" referent="{ref()}"><Properties>'
        f'<string name="Name">{escape(name)}</string>{props}'
        f"</Properties>{children}</Item>"
    )


def scripts_in(folder: Path):
    return "".join(script_item(p) for p in sorted(folder.glob("*.luau")))


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "NorilskLastShift.rbxlx"
    body = "".join(
        [
            # Streaming off: the client scripts need every lamp, poster and person loaded.
            item("Workspace", "Workspace", props='<bool name="StreamingEnabled">false</bool>'),
            # Future lighting: real shadows from streetlights, lamps and windows.
            item(
                "Lighting",
                "Lighting",
                props='<token name="Technology">4</token>'
                '<float name="ClockTime">23.4</float>'
                '<float name="Brightness">0.4</float>',
            ),
            item("ReplicatedStorage", "ReplicatedStorage", item("Folder", "Shared", scripts_in(SRC / "shared"))),
            item("ServerScriptService", "ServerScriptService", scripts_in(SRC / "server")),
            item(
                "StarterPlayer",
                "StarterPlayer",
                item("StarterPlayerScripts", "StarterPlayerScripts", scripts_in(SRC / "client"))
                + item("StarterCharacterScripts", "StarterCharacterScripts"),
                props='<token name="CameraMode">1</token>'
                '<float name="CharacterWalkSpeed">10</float>'
                '<bool name="CharacterUseJumpPower">false</bool>'
                '<float name="CharacterJumpHeight">3.5</float>',
            ),
        ]
    )
    xml = (
        '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
        f"{body}</roblox>\n"
    )
    out.write_text(xml, encoding="utf-8")
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
