# Proving Ground media sources

The tower source is here. The optional solo audio preview reads its masters from the [Garrison project audio folder](../../Mods/aoe4_dota_mod/project/source/audio).

| Source | Purpose |
|---|---|
| `proving-tower.blend` | Original limestone watchtower with a recessed gate, battlements, and an oxblood banner. Blender 5.2 source with metric scale, UVs, and editable material slots. The footprint is 5.4 × 5.4 m and the height is 7.33 m. The saved source has no external libraries or images. |
| `tower-impact.wav` | Original synthesized 0.6-second positional effect, 44.1 kHz mono PCM16. |
| `crossing-watch-loop.wav` | Original synthesized 12-second music loop, 44.1 kHz stereo PCM16. |
| `shield-captain-hold-the-crossing.wav` | Original 1.12-second English command, 48 kHz mono PCM16. |

The command “Hold the crossing!” was generated offline with Qwen3-TTS-12Hz-1.7B-VoiceDesign, model revision `5ecdb67327fd37bb2e042aab12ff7391903235d3`, seed `261106`, and an original shield-captain voice description. The local model card identifies the model license as Apache-2.0. The clip uses a synthetic persona designed from text.

The tower still needs a Garrison export and an in-game fit check against the native footprint. The audio preview routes its speech, effect, and music through separate Garrison volume buses. In-game listening is part of the solo checklist.
