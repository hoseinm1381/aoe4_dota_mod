# Lane Wars for Age of Empires IV

An original medieval-fantasy MOBA for Windows Steam. The release target is a three-lane 4v4 match with 12 draftable heroes, last-hit gold, hero levels, gear, consumables, and custom models, voices, effects, and music. All mod content ships in one Garrison player ZIP of at most 500,000,000 bytes.

## Current milestone

Proving Ground is the first stock-art solo fixture. It contains a one-lane Crafted Map, the Lane Wars Solo Game Mode, and the companion tuning pack. Its two draft choices use stock combat animations. The fixture includes scripted creep waves and an opponent, a tower and stronghold for each side, a 12-second hero respawn, one permanent gear purchase, and one consumable.

The project must pass a solo match before adding the custom-media probe to the fixture. The online qualification order is two humans on the one-lane map, then eight humans on the three-lane graybox. The full roster and production media follow those gates.

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

& $core mod-project cook --project $project --editor $editor --timeout 120
if ($LASTEXITCODE) { throw 'Garrison cook failed' }
& $core mod-project package --project $project
if ($LASTEXITCODE) { throw 'Garrison packaging failed' }
python tools/verify_bundle.py "$project/dist/aoe4_dota_mod-$version.zip" --archiver $archiver --solo
if ($LASTEXITCODE) { throw 'Bundle verification failed' }
```

The Garrison recipe owns the map, derived squad, and 1,100-HP tower and 1,600-HP stronghold blueprints. Both buildings spawn at full health. The cook generates its scenario and runtime helper files from the installed toolchain. The repository tracks the authored map coordinates, game-mode SCAR, localization, and project configuration. Cook outputs and local tool caches are excluded from Git.

## Check the solo rules offline

Install `lupa==2.6` in your test Python environment and run `python tools/smoke_solo.py`. The smoke test runs the authored SCAR in Lua 5.3 with mock engine calls. It covers missing blueprints, draft and timeout, bounty attribution rules, duplicate purchase requests, respawn, victory and defeat, and cleanup. AoE4 still needs to establish whether its death handles and UI callbacks behave as the fixture expects.

## Run the first solo test

1. Import and enable the freshly verified ZIP in Garrison. Launch through Garrison and open **Single Player → Skirmish**.
2. Select **Proving Ground** under Crafted Maps, **Lane Wars Solo** as the Game Mode, and **aoe4_dota_mod** as the Tuning Pack. Use one human and one opposing AI at normal speed.
3. The camera should open over your western base with the tower and stronghold already visible. Choose the captain or bow skirmisher during the draft. On a second run, let the 20-second draft timer expire. Verify one hero spawns per side, no starting villagers remain, and the first waves advance and fight without player orders.
4. With your hero selected, right-click a wounded enemy creep. Check the 30-gold killing-blow bounty separately from the two-gold-per-second income. Let an allied creep or tower kill a creep after your hero hits it to check for false credit. Stay near a creep death and verify level progress.
5. At your spawn, buy Marching Boots for 75 gold and a tonic for 30. Test the tonic while injured, die, and verify the hero respawns after about 12 seconds with its prior progress, gear, and any unused tonic.
6. Attack the opposing tower first. The stronghold is protected while its tower stands and can take damage once that tower falls. Finish a win and a loss, then start a fresh match and check that the draft, heroes, and waves start only once. Retain the game build, package hash, and fresh `warnings.log`. The `LANE_WARS_` lines record building completion and health, picks, spawns, purchases, levels, last-hit credit, stronghold exposure, and the result. `LANE_WARS_LAST_HIT_DEATH_HANDLE_UNAVAILABLE` means a dead creep's handle disappeared before the script could inspect its attacker.

The verifier checks the ZIP byte limit, manifest, CRC, declared SGA hashes, SGA integrity, and the required solo fixture members. Native gameplay, player input, and last-hit attribution require the solo test above.
