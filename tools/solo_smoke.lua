-- Exercise SCAR decisions without assuming that the engine behaves like this fixture.
local now, timer, network, winner, loser, missing
local offset, focus = 0, nil
local lobbyHero, lobbyMedia, dialog, clockOrigin = "choose", false, nil, 0
local squads, buildings, cues, gold, logs, deathRules = {}, {}, {}, {}, {}, {}
local nextCue, retiredGroups, clearedStarts = 0, 0, 0
local corePrint = print
local audioCalls = {}

PLAYERS = {{id = 1}, {id = 2}}
RT_Gold, RT_Food, RT_Wood, RT_Stone = "gold", "food", "wood", "stone"
R_ENEMY, ECV_Queue, ECV_Title = "enemy", 1, 2
MAT_Entity, MUT_Multiplication, KPR_Lost, WR_CONQUEST = 1, 1, 1, 1
GE_SquadKilled = "squad killed"
DB_Button1, DB_Button2, DB_Close, DC_Default = 1, 2, 3, 4
Garrison = {mods = {aoe4_dota_mod = {blueprints = {
	sbps = {shield_captain = "captain", bow_skirmisher = "skirmisher"},
	ebps = {lane_tower = "tower", lane_stronghold = "stronghold"},
}, options = {load = function() return {solo = {hero = lobbyHero, media = lobbyMedia}} end},
audio = {
	session = function() audioCalls[#audioCalls + 1] = "session" end,
	bed = function(clip) assert(clip == "audio/crossing-watch-loop.wav"); audioCalls[#audioCalls + 1] = "bed" end,
	event = function(kind) audioCalls[#audioCalls + 1] = kind end,
	pulse = function() audioCalls[#audioCalls + 1] = "pulse" end,
	stop = function() audioCalls[#audioCalls + 1] = "stop" end,
}}}}

function print(name, ...) logs[#logs + 1] = {name, ...} end
function import(path)
	assert(path:lower() ~= "gameplay/event_cues.scar", "Solo mode must not register stock EventCues")
end
function Core_RegisterModule(name) assert(name == "LaneWarsSolo") end
function World_GetPlayerAt(index) return assert(PLAYERS[index]).id end
function World_GetPlayerCount() return #PLAYERS end
function World_GetGameTime() return now end
function World_GetHeightAt() return 0 end
function World_Pos(x, y, z) return {x = x, y = y, z = z} end
function World_GetWidth() return 144 end
function World_GetLength() return 144 end
function World_PosInBounds(position)
	return math.abs(position.x - offset) <= 72 and math.abs(position.z - offset) <= 72
end
function World_DistancePointToPoint(a, b) return ((a.x - b.x)^2 + (a.z - b.z)^2)^0.5 end
function Player_GetSlotIndex(player) return player end
function Player_GetStartingPosition() error("Crafted map startup must use authored sites") end
function Player_IsAlive(player) return player <= 2 end
function Player_IsHuman(player) return player == 1 end
function Player_ObserveRelationship(a, b) assert(a ~= b); return R_ENEMY end
function Player_GetSquads() return {} end
function Player_GetEntitiesEGroup() end
function Player_GetResource(player, resource) assert(resource == RT_Gold); return gold[player] or 0 end
function Player_SetResource(player, resource, amount) if resource == RT_Gold then gold[player] = amount end end
function AI_Enable(player, enabled) assert(player == 2 and enabled == false) end
function BP_GetSquadBlueprint(name) assert(name ~= missing and name ~= nil); return name end
BP_GetEntityBlueprint = BP_GetSquadBlueprint
function Squad_Precache(blueprint) assert(blueprint ~= nil) end
Entity_Precache = Squad_Precache
function SGroup_Create() return {} end
EGroup_Create = SGroup_Create
function SGroup_Add(group, value) group[#group + 1] = value end
function SGroup_Clear(group) for index = #group, 1, -1 do group[index] = nil end end
EGroup_Clear = SGroup_Clear
function SGroup_Destroy() retiredGroups = retiredGroups + 1 end
EGroup_Destroy = SGroup_Destroy
function SGroup_DestroyAllSquads() clearedStarts = clearedStarts + 1 end
EGroup_DestroyAllEntities = SGroup_DestroyAllSquads
function EGroup_Count(group) return #group end
function EGroup_GetEntityAt(group, index) return assert(group[index]) end
function Squad_CreateAndSpawnToward(blueprint, player, count, position)
	assert(count == 1)
	local squad = {id = #squads + 1, blueprint = blueprint, owner = player,
		position = position, health = 1, valid = true, alive = true, selectable = true}
	squad.entity = {squad = squad}
	squads[squad.id] = squad
	return squad
end
function Squad_GetFirstEntity(squad) return squad.entity end
function Squad_GetID(squad) return squad.id end
function Squad_IsValid(id) return squads[id] and squads[id].valid end
function Squad_IsAlive(squad) assert(squad.valid); return squad.alive end
function Squad_GetPosition(squad) assert(squad.alive); return squad.position end
function Squad_GetHealthPercentage(squad) return squad.health end
function Squad_SetHealth(squad, health) squad.health = health end
function Squad_GetLastEntityAttacker(squad, group)
	assert(squad.valid)
	if squad.attacker then group[#group + 1] = squad.attacker end
end
function Entity_GetSquad(entity) return entity.squad end
function Entity_Create(blueprint, player, position, snap)
	assert(snap)
	local entity = {id = #buildings + 1, blueprint = blueprint, owner = player, position = position,
		progress = 0, health = 1, maxHealth = blueprint == "tower" and 1100 or 1600, selectable = true}
	buildings[entity.id] = entity
	return entity
end
function Entity_Spawn(entity) entity.alive = true end
function Entity_ForceConstruct(entity) assert(entity.alive); entity.progress = 1 end
function Entity_SetHealth(entity, percent) assert(entity.progress == 1); entity.health = entity.maxHealth * percent end
function Entity_GetBuildingProgress(entity) return entity.progress end
function Entity_GetHealth(entity) return entity.health end
function Entity_GetHealthMax(entity) return entity.maxHealth end
function Entity_GetID(entity) return entity.id end
function Entity_IsValid(id) return buildings[id] ~= nil end
function Entity_IsAlive(entity) return entity.alive end
function Entity_SetInvulnerableMinCap(entity, cap, reset) assert(reset == -1); entity.cap = cap end
function Misc_SetSquadSelectable(unit, value) unit.selectable = value end
Misc_SetEntitySelectable = Misc_SetSquadSelectable
function Cmd_AttackMove(group, destination) assert(#group == 1); group[1].destination = destination end
function Modifier_Create(_, name, _, _, factor) assert(name == "speed_maximum_modifier"); return factor end
function Modifier_ApplyToEntity(factor, entity, duration)
	if duration == 0 then
		entity.speed = (entity.speed or 1) * factor
	else
		assert(duration == 5 and factor == 1.35 and not entity.quickstep)
		entity.quickstep = duration
	end
end
function Game_GetLocalPlayer() return 1 end
function Camera_FocusOnPosition(position) focus = position end
function LOC(text) return text end
function Loc_Empty() return "" end
local function AssertNamedCallback(callback)
	local name
	for key, value in pairs(_G) do
		if value == callback and type(key) == "string" then
			name = key
			break
		end
	end
	assert(type(callback) == "function" and name, "Can't use an unnamed function as a callback")
end
function UI_CreateEventCueClickable(...)
	local callback = select(15, ...)
	AssertNamedCallback(callback)
	nextCue = nextCue + 1
	cues[nextCue] = {title = select(5, ...), click = callback}
	return nextCue
end
function UI_MessageBoxReset() assert(not dialog); dialog = {buttons = {}} end
function UI_MessageBoxSetText(title) assert(title == "Choose your hero") end
function UI_MessageBoxSetButton(button, title) dialog.buttons[button] = title end
function UI_MessageBoxShow(kind, callback)
	assert(kind == DC_Default)
	AssertNamedCallback(callback)
	dialog.callback = callback
end
function UI_MessageBoxHide(button)
	local previous = assert(dialog)
	dialog = nil
	previous.callback(button)
end
function UI_ClearEventCueFromID(id) assert(cues[id]); cues[id] = nil end
function Network_RegisterEvent(name) assert(_G[name]); network = _G[name] end
function Network_CallEvent(name, message) assert(_G[name] == network); network(1, message) end
function Rule_AddInterval(callback, interval) assert(not timer and interval == 0.25); timer = callback end
function Rule_Remove(callback) assert(timer == callback); timer = nil end
function Rule_AddSquadEvent(callback, squad, kind, data)
	assert(kind == GE_SquadKilled and not deathRules[squad])
	deathRules[squad] = {callback = callback, data = data}
end
function Rule_RemoveSquadEvent(callback, squad)
	assert(deathRules[squad].callback == callback)
	deathRules[squad] = nil
end
function Core_SetPlayerVictorious(player) winner = player end
function Core_SetPlayerDefeated(player) loser = player end
function World_KillPlayer(player) assert(loser == player) end
function Core_OnGameOver() LaneWarsSolo_OnGameOver() end

local function tick(time)
	now = clockOrigin + time
	assert(timer)()
end

local function click(title)
	for _, cue in pairs(cues) do
		if cue.title == title then cue.click(); return end
	end
	error("Missing clickable cue " .. title)
end

local function saw(marker, value)
	for _, event in ipairs(logs) do
		if event[1] == marker and (value == nil or event[2] == value) then return true end
	end
	return false
end

local function kill(creep, attacker, notify)
	local rule = assert(deathRules[creep])
	creep.alive, creep.attacker = false, attacker
	if notify then rule.callback({victim = creep}, rule.data) end
	creep.valid = false
	deathRules[creep] = nil
end

assert(load(mode_source, "aoe4_dota_mod.scar"))()

now, missing = 0, "tower"
LaneWarsSolo_OnGameSetup()
LaneWarsSolo_Start()
assert(saw("LANE_WARS_SETUP_ERROR missing blueprint", "tower") and not timer and clearedStarts == 0)

missing = nil
LaneWarsSolo_OnGameSetup()
LaneWarsSolo_OnInit()
LaneWarsSolo_Start()
assert(saw("LANE_WARS_SETUP_ERROR Proving Ground map script was not loaded") and not timer)
assert(load(layout_source, "proving_ground.scar"))()
LaneWarsSolo_Start()
LaneWarsSolo_Start()
assert(clearedStarts == 4 and #squads == 0 and #buildings == 4)
assert(focus.x == -54 and focus.z == 0)
for _, building in ipairs(buildings) do
	assert(building.progress == 1 and building.health == building.maxHealth)
	assert(building.selectable == (building.owner == 2))
end
network(2, "captain")
assert(#squads == 0)
assert(dialog.buttons[DB_Button1] == "Shield Captain" and dialog.buttons[DB_Button2] == "Bow Skirmisher")
tick(21)
assert(#squads == 0 and dialog)
UI_MessageBoxHide(DB_Close)
tick(22)
assert(#squads == 0 and dialog)
UI_MessageBoxHide(DB_Button1)
clockOrigin = now
local hero, bot = squads[1], squads[2]
assert(hero.blueprint == "captain" and bot.blueprint == "skirmisher" and bot.destination and bot.selectable)
assert(buildings[2].cap == 1 and buildings[4].cap == 1)

tick(4)
assert(#squads == 10 and saw("LANE_WARS_FIRST_WAVE", 1) and saw("LANE_WARS_FIRST_WAVE", 2))
for index = 3, 10 do
	local creep = squads[index]
	assert(creep.selectable == (creep.owner == 2) and creep.destination)
end
local baselineGold = gold[1]
local lethal, towerKill, creepKill, missingDeath = squads[7], squads[8], squads[9], squads[10]
local home = hero.position
hero.position = lethal.position
kill(lethal, hero.entity, true)
kill(towerKill, buildings[1], true)
kill(creepKill, squads[3].entity, true)
kill(missingDeath, hero.entity, false)
tick(4.25)
assert(gold[1] == baselineGold + 30 and saw("LANE_WARS_LAST_HIT", lethal.id))
assert(saw("LANE_WARS_LAST_HIT_DEATH_HANDLE_UNAVAILABLE", missingDeath.id))
tick(4.5)
assert(gold[1] == baselineGold + 30)

gold[1] = 150
tick(4.75)
network(1, "boots")
assert(gold[1] == 150)
hero.position = home
tick(4.75)
click("Buy Marching Boots for 75 gold")
network(1, "boots")
assert(hero.entity.speed == 1.12 and gold[1] == 75)
click("Buy a tonic for 30 gold")
network(1, "buy_tonic")
assert(gold[1] == 45)
network(1, "use_tonic")
hero.health = 0.5
network(1, "use_tonic")
network(1, "use_tonic")
assert(hero.health == 0.75)
click("Second Wind | Restore health")
assert(hero.health == 1)
hero.health = 0.75
network(1, "skill")
assert(hero.health == 0.75)

hero.alive = false
tick(5)
assert(#squads == 10)
tick(16.75)
assert(#squads == 10)
tick(17)
assert(squads[11].owner == 1 and squads[11].entity.speed == 1.12)

buildings[3].alive = false
tick(17.25)
assert(buildings[4].cap == 0 and saw("LANE_WARS_STRONGHOLD_EXPOSED", 2))
buildings[4].alive = false
tick(17.5)
assert(winner == 1 and loser == 2 and not timer and next(cues) == nil and retiredGroups == 3 and next(deathRules) == nil)

squads, buildings, gold, offset = {}, {}, {}, 72
lobbyHero, lobbyMedia, clockOrigin = "bow", true, now
LaneWarsSolo_OnGameSetup()
LaneWarsSolo_Start()
assert(#buildings == 4 and focus.x == 18 and focus.z == 72 and not dialog)
assert(#squads == 2 and squads[1].blueprint == "skirmisher")
assert(audioCalls[1] == "session" and audioCalls[2] == "bed")
click("Quickstep | Move faster")
network(1, "skill")
assert(squads[1].entity.quickstep == 5)
buildings[2].alive = false
tick(.25)
assert(winner == 2 and loser == 1 and not timer and next(cues) == nil and retiredGroups == 6)
assert(audioCalls[#audioCalls - 1] == "pulse" and audioCalls[#audioCalls] == "stop")
corePrint("Solo SCAR smoke passed in mocked Lua 5.3")
