"""Exercise the real SCAR rules in Lua 5.3 with mocked engine calls."""

from pathlib import Path

from lupa.lua53 import LuaRuntime


root = Path(__file__).resolve().parents[1]
source = root / "Mods/aoe4_dota_mod/project/source/scar"
lua = LuaRuntime()
lua.globals().layout_source = (source / "gameplay/proving_ground.scar").read_text(encoding="utf-8")
lua.globals().mode_source = (source / "winconditions/aoe4_dota_mod.scar").read_text(encoding="utf-8")
lua.execute((root / "tools/solo_smoke.lua").read_text(encoding="utf-8"))
