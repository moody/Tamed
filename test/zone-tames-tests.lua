--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")
local Matchers = require("test/matchers")

-- ============================================================================
-- Setup
-- ============================================================================

--- The map the NPCs are on, unless a test says otherwise.
local MAP_ID = 1439

--- A map that none of the NPCs are on.
local OTHER_MAP_ID = 1411

--- A player level above every NPC, for tests that are not about the player's level.
local HIGH_LEVEL = 20

--- Returns `ZoneTames` from a new context, with `TameableNPCs` set to the given NPCs.
--- @param npcs table<string, table>
--- @return ZoneTames ZoneTames
local function setupContext(npcs)
  local Context = Harness:NewContext()
  Context:SetModule("TameableNPCs", npcs)
  Context:Load("src/zone-tames.lua")
  return Context:GetModule("ZoneTames")
end

--- Returns an NPC on `MAP_ID` with the given name and minimum level, teaching `{ ability, rank }` entries.
--- @param name string
--- @param minLevel integer
--- @param abilities { ability: table, rank: integer }[]
--- @return table
local function mockNpc(name, minLevel, abilities)
  return { name = name, min_level = minLevel, ui_map_id = MAP_ID, abilities = abilities }
end

--- Returns the names of the NPCs in `zoneTames`, in the order listed.
--- @param zoneTames ZoneTame[]
--- @return string[]
local function getNames(zoneTames)
  local names = {}
  for i, zoneTame in ipairs(zoneTames) do names[i] = zoneTame.npc.name end
  return names
end

-- ============================================================================
-- Tests - ZoneTames:Get()
-- ============================================================================

-- Test: lists only NPCs on the given map.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Here", 10, { { ability = claw, rank = 1 } }),
    ["2"] = { name = "Other Map", min_level = 10, ui_map_id = OTHER_MAP_ID, abilities = { { ability = claw, rank = 1 } } },
    ["3"] = { name = "No Map", min_level = 10, abilities = { { ability = claw, rank = 1 } } },
  })

  assert(Matchers:IsDeepEqual(getNames(ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })), { "Here" }))
end

-- Test: lists NPCs on every map, and those on none, without a map filter.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Here", 10, { { ability = claw, rank = 1 } }),
    ["2"] = { name = "Other Map", min_level = 10, ui_map_id = OTHER_MAP_ID, abilities = { { ability = claw, rank = 1 } } },
    ["3"] = { name = "No Map", min_level = 10, abilities = { { ability = claw, rank = 1 } } },
  })

  local names = getNames(ZoneTames:Get({ level = HIGH_LEVEL }))
  table.sort(names)
  assert(Matchers:IsDeepEqual(names, { "Here", "No Map", "Other Map" }))
end

-- Test: lists NPCs at the player's level, not above it.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("At Level", 13, { { ability = claw, rank = 1 } }),
    ["2"] = mockNpc("Above Level", 14, { { ability = claw, rank = 2 } }),
  })

  assert(Matchers:IsDeepEqual(getNames(ZoneTames:Get({ level = 13, uiMapId = MAP_ID })), { "At Level" }))
end

-- Test: lists only the NPCs teaching the highest rank of an ability.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Rank 1", 10, { { ability = claw, rank = 1 } }),
    ["2"] = mockNpc("Rank 3", 10, { { ability = claw, rank = 3 } }),
    ["3"] = mockNpc("Rank 2", 10, { { ability = claw, rank = 2 } }),
  })

  assert(Matchers:IsDeepEqual(getNames(ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })), { "Rank 3" }))
end

-- Test: falls back to a lower rank when the NPC teaching a higher rank is above the player's level.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Rank 1", 10, { { ability = claw, rank = 1 } }),
    ["2"] = mockNpc("Rank 2", 12, { { ability = claw, rank = 2 } }),
    ["3"] = mockNpc("Rank 3", 16, { { ability = claw, rank = 3 } }),
  })

  assert(Matchers:IsDeepEqual(getNames(ZoneTames:Get({ level = 13, uiMapId = MAP_ID })), { "Rank 2" }))
end

-- Test: lists every NPC tied for the highest rank.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("First", 10, { { ability = claw, rank = 2 } }),
    ["2"] = mockNpc("Second", 10, { { ability = claw, rank = 2 } }),
  })

  assert(Matchers:IsDeepEqual(getNames(ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })), { "First", "Second" }))
end

-- Test: compares ranks of different abilities separately.
do
  local claw = { name = "Claw" }
  local bite = { name = "Bite" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Claw 1", 10, { { ability = claw, rank = 1 } }),
    ["2"] = mockNpc("Bite 2", 10, { { ability = bite, rank = 2 } }),
  })

  assert(Matchers:IsDeepEqual(getNames(ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })), { "Bite 2", "Claw 1" }))
end

-- Test: lists every ability of an NPC in order, with the best ones flagged.
do
  local claw = { name = "Claw" }
  local bite = { name = "Bite" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Mixed", 10, { { ability = bite, rank = 1 }, { ability = claw, rank = 3 } }),
    ["2"] = mockNpc("Bite Leader", 10, { { ability = bite, rank = 2 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })
  local mixed = zoneTames[1]

  assert(mixed.npc.name == "Mixed")
  assert(#mixed.abilities == 2)
  assert(mixed.abilities[1].ability == bite)
  assert(mixed.abilities[1].rank == 1)
  assert(mixed.abilities[1].isBest == false)
  assert(mixed.abilities[2].ability == claw)
  assert(mixed.abilities[2].rank == 3)
  assert(mixed.abilities[2].isBest == true)
end

-- Test: the lead ability is the best ability with the highest rank.
do
  local claw = { name = "Claw" }
  local bite = { name = "Bite" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Three", 10, { { ability = bite, rank = 1 }, { ability = claw, rank = 3 }, { ability = dash, rank = 2 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })

  assert(zoneTames[1].lead.ability == claw)
  assert(zoneTames[1].lead.rank == 3)
end

-- Test: the lead ability is the first by name when the best ranks are tied.
do
  local claw = { name = "Claw" }
  local bite = { name = "Bite" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Both", 10, { { ability = bite, rank = 2 }, { ability = claw, rank = 2 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })

  assert(zoneTames[1].lead.ability == bite)
end

-- Test: sorts by lead rank, then lead ability name, then level, then name.
do
  local claw = { name = "Claw" }
  local bite = { name = "Bite" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Dash 1 B", 10, { { ability = dash, rank = 1 } }),
    ["2"] = mockNpc("Bite 1", 11, { { ability = bite, rank = 1 } }),
    ["3"] = mockNpc("Dash 1 A", 10, { { ability = dash, rank = 1 } }),
    ["4"] = mockNpc("Dash 1 Higher Level", 12, { { ability = dash, rank = 1 } }),
    ["5"] = mockNpc("Claw 2", 8, { { ability = claw, rank = 2 } }),
    ["6"] = mockNpc("Bite 1 And Claw 2", 9, { { ability = bite, rank = 1 }, { ability = claw, rank = 2 } }),
  })

  assert(Matchers:IsDeepEqual(getNames(ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID })), {
    "Bite 1 And Claw 2",
    "Claw 2",
    "Bite 1",
    "Dash 1 Higher Level",
    "Dash 1 A",
    "Dash 1 B"
  }))
end

-- ============================================================================
-- Tests - ZoneTames:Get() with ability filters
-- ============================================================================

-- Test: lists only NPCs that teach every filtered ability.
do
  local claw = { name = "Claw" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Both", 10, { { ability = claw, rank = 1 }, { ability = dash, rank = 1 } }),
    ["2"] = mockNpc("Claw Only", 10, { { ability = claw, rank = 1 } }),
    ["3"] = mockNpc("Dash Only", 10, { { ability = dash, rank = 1 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, abilities = { claw, dash } })

  assert(Matchers:IsDeepEqual(getNames(zoneTames), { "Both" }))
end

-- Test: finds the highest ranks among the NPCs that teach every filtered ability.
do
  local claw = { name = "Claw" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Claw 3 Only", 10, { { ability = claw, rank = 3 } }),
    ["2"] = mockNpc("Dash 3 Only", 10, { { ability = dash, rank = 3 } }),
    ["3"] = mockNpc("Both Low", 10, { { ability = claw, rank = 1 }, { ability = dash, rank = 1 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, abilities = { claw, dash } })

  assert(Matchers:IsDeepEqual(getNames(zoneTames), { "Both Low" }))
end

-- Test: lists an NPC with the highest rank of at least one filtered ability.
do
  local claw = { name = "Claw" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Dash 3 Claw 1", 10, { { ability = claw, rank = 1 }, { ability = dash, rank = 3 } }),
    ["2"] = mockNpc("Dash 2 Claw 3", 10, { { ability = claw, rank = 3 }, { ability = dash, rank = 2 } }),
    ["3"] = mockNpc("Dash 1 Claw 1", 10, { { ability = claw, rank = 1 }, { ability = dash, rank = 1 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, abilities = { claw, dash } })

  assert(Matchers:IsDeepEqual(getNames(zoneTames), { "Dash 2 Claw 3", "Dash 3 Claw 1" }))
end

-- Test: ignores the highest ranks of abilities that are not filtered.
do
  local claw = { name = "Claw" }
  local cower = { name = "Cower" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Claw 1 Cower 3", 10, { { ability = claw, rank = 1 }, { ability = cower, rank = 3 } }),
    ["2"] = mockNpc("Claw 2", 10, { { ability = claw, rank = 2 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, abilities = { claw } })

  assert(Matchers:IsDeepEqual(getNames(zoneTames), { "Claw 2" }))
end

-- Test: the lead ability is a filtered ability.
do
  local claw = { name = "Claw" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Both", 10, { { ability = claw, rank = 2 }, { ability = dash, rank = 3 } }),
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, abilities = { claw } })

  assert(zoneTames[1].lead.ability == claw)
end

-- Test: filters by ability within the map filter.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Here", 10, { { ability = claw, rank = 1 } }),
    ["2"] = { name = "Other Map", min_level = 10, ui_map_id = OTHER_MAP_ID, abilities = { { ability = claw, rank = 2 } } },
  })

  local zoneTames = ZoneTames:Get({ level = HIGH_LEVEL, uiMapId = MAP_ID, abilities = { claw } })

  assert(Matchers:IsDeepEqual(getNames(zoneTames), { "Here" }))
end

-- ============================================================================
-- Tests - ZoneTames:GetBestRanks()
-- ============================================================================

-- Test: returns the ranks of the NPCs that can be tamed at the level.
do
  local claw = { name = "Claw" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Low", 10, { { ability = claw, rank = 1 } }),
    ["2"] = mockNpc("High", 14, { { ability = dash, rank = 1 } }),
  })

  local bestRanks = ZoneTames:GetBestRanks({ level = 13 })

  assert(Matchers:IsDeepEqual(bestRanks, { [claw] = 1 }))
end

-- Test: returns the highest rank of an ability among the matching NPCs.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Rank 1", 10, { { ability = claw, rank = 1 } }),
    ["2"] = mockNpc("Rank 3", 10, { { ability = claw, rank = 3 } }),
    ["3"] = mockNpc("Rank 5 Above Level", 20, { { ability = claw, rank = 5 } }),
  })

  local bestRanks = ZoneTames:GetBestRanks({ level = 13 })

  assert(Matchers:IsDeepEqual(bestRanks, { [claw] = 3 }))
end

-- Test: returns the ranks of the NPCs on the map.
do
  local claw = { name = "Claw" }
  local dash = { name = "Dash" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Here", 10, { { ability = claw, rank = 1 } }),
    ["2"] = { name = "Other Map", min_level = 10, ui_map_id = OTHER_MAP_ID, abilities = { { ability = dash, rank = 1 } } },
  })

  local bestRanks = ZoneTames:GetBestRanks({ level = HIGH_LEVEL, uiMapId = MAP_ID })

  assert(Matchers:IsDeepEqual(bestRanks, { [claw] = 1 }))
end

-- Test: returns only the ranks of NPCs that teach every filtered ability, with the filtered ones.
do
  local claw = { name = "Claw" }
  local dash = { name = "Dash" }
  local bite = { name = "Bite" }
  local cower = { name = "Cower" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("Claw Dash Bite", 10, { { ability = claw, rank = 1 }, { ability = dash, rank = 1 }, { ability = bite, rank = 1 } }),
    ["2"] = mockNpc("Claw Cower", 10, { { ability = claw, rank = 1 }, { ability = cower, rank = 1 } }),
  })

  local bestRanks = ZoneTames:GetBestRanks({ level = HIGH_LEVEL, abilities = { claw, dash } })

  assert(Matchers:IsDeepEqual(bestRanks, { [claw] = 1, [dash] = 1, [bite] = 1 }))
end

-- Test: returns no ranks when no NPC matches.
do
  local claw = { name = "Claw" }
  local ZoneTames = setupContext({
    ["1"] = mockNpc("High", 14, { { ability = claw, rank = 1 } }),
  })

  local bestRanks = ZoneTames:GetBestRanks({ level = 13 })

  assert(next(bestRanks) == nil)
end
