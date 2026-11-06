# Lane Wars for Age of Empires IV

An original medieval-fantasy MOBA for Windows Steam. The release target is a three-lane 4v4 match with 12 draftable heroes, last-hit gold, hero levels, gear, consumables, and custom models, voices, effects, and music. All mod content ships in one Garrison player ZIP of at most 500,000,000 bytes.

## Current milestone

Proving Ground is a one-lane solo match with two playable heroes. Choose Shield Captain for melee and a self-heal, or Bow Skirmisher for ranged combat and a short sprint. The fixture includes scripted creep waves and an opponent, a tower and stronghold for each side, a 12-second hero respawn, one permanent gear purchase, and one consumable.

The Styled interface adds XAML hero cards and a match panel with health, gold, XP, cooldowns, shop controls, respawn, and the current objective. Select Compatibility in the lobby to use the basic dialog and event cues.

The lobby has a separate option for the custom audio preview. The online qualification order is two humans on the one-lane map, then eight humans on the three-lane graybox. The full roster and production media follow those gates.

The editable tower and original audio for the follow-up are under [media probe sources](authoring/media-probe).

## Build the solo ZIP

Use Garrison 0.1.16 and the AoE4 Content Editor for the installed Windows Steam game. Set the paths below to the matching Garrison extension and Content Editor. Run these commands from the repository root in PowerShell with Python 3.10 or later.

```powershell
$extension = Join-Path $env:APPDATA 'Blender Foundation/Blender/5.2/extensions/raw_githubusercontent_com/garrison'
$core = Join-Path $extension 'bin/core/garrison-core.exe'
$archiver = Join-Path $extension 'bin/sga-archiver.exe'
$project = Join-Path (Get-Location) 'Mods/aoe4_dota_mod'
$editor = 'C:/path/to/Age of Empires IV/EssenceEditor.exe'
$version = (Get-Content -Raw "$project/mod-project.json" | ConvertFrom-Json).release.version

python tools/embed_xaml.py --check
if ($LASTEXITCODE) { throw 'Embedded XAML is out of date' }
& $core mod-project cook --project $project --editor $editor --timeout 120
if ($LASTEXITCODE) { throw 'Garrison cook failed' }
& $core mod-project package --project $project
if ($LASTEXITCODE) { throw 'Garrison packaging failed' }
python tools/verify_bundle.py "$project/dist/aoe4_dota_mod-$version.zip" --archiver $archiver --solo
if ($LASTEXITCODE) { throw 'Bundle verification failed' }
```

The Garrison recipe owns the map, derived squad, and 1,100-HP tower and 1,600-HP stronghold blueprints. Both buildings spawn at full health. The cook generates its scenario and runtime helper files from the installed toolchain. The repository tracks the authored map coordinates, game-mode SCAR, localization, and project configuration. Cook outputs and local tool caches are excluded from Git. After editing a view in [authoring/ui](authoring/ui), run `python tools/embed_xaml.py` before cooking.

## Check the solo rules offline

Install `lupa==2.6` in your test Python environment and run `python tools/smoke_solo.py`. The smoke test runs the authored SCAR in Lua 5.3 with mock engine calls. It covers both interfaces, lobby preselection, repeat waves, ability cooldowns, audio lifecycle, bounty attribution, duplicate purchases, respawn, victory and defeat, and cleanup. The game test verifies XAML rendering, input, and the native damage and death events.

## Run the first solo test

1. Import and enable the freshly verified ZIP in Garrison. Launch through Garrison and open **Single Player → Skirmish**.
2. Select **Proving Ground** under Crafted Maps, **Lane Wars Solo** as the Game Mode, and **aoe4_dota_mod** as the Tuning Pack. Use one human and one opposing AI at normal speed.
3. In the Game Mode settings, use **Interface → Styled** and **Starting hero → Choose in match**. Pick Bow Skirmisher to repeat the previous test. Verify one hero spawns per side and watch two waves advance without player orders. The second wave starts about 34 seconds after the pick. On a second run, preselect Shield Captain in the lobby.
4. With your hero selected, right-click a wounded enemy creep. Check the 30-gold killing-blow bounty separately from the two-gold-per-second income. Let an allied creep or tower kill a creep after your hero hits it to check for false credit. Stay near a creep death and verify level progress.
5. Use **Second Wind** while injured or **Quickstep** while moving from the panel above the minimap. At your spawn, buy Marching Boots for 75 gold and a tonic for 30. Test the tonic while injured, die, and verify the hero respawns after about 12 seconds with its prior progress, gear, and any unused tonic.
6. Attack the opposing tower first. The stronghold can take damage once that tower falls. Finish a win and a loss, then start a fresh match and check that the draft, heroes, and waves start only once. Retain the game build, package hash, and fresh `warnings.log`. The `LANE_WARS_` lines include wave creation and attack orders, the first 12 enemy creep deaths and their damage and death ticks, and the match result.

The verifier checks the ZIP byte limit, manifest, CRC, declared SGA hashes, SGA integrity, and the required solo fixture members. Native gameplay, player input, and last-hit attribution require the solo test above.

For the audio pass, enable **Custom voices and music** in the Game Mode settings and pick Shield Captain. Listen for the music bed, the captain's spawn line, and the impact when the enemy tower falls.
