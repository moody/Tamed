local Addon = select(2, ...) ---@type Addon
local TameableNPCs = Addon:GetModule("TameableNPCs")

--- @class TameFinder
local TameFinder = Addon:GetModule("TameFinder")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class TameFinderResult
--- @field npc TameableNPC
--- @field leadAbility TameableAbility The highest ranked best ability, among the filtered ones if any. The first by name on a tie.
--- @field leadRank integer The displayed rank of `leadAbility`.

--- @class TameFinderFilters
--- @field level integer Only NPCs that can be tamed at this level.
--- @field uiMapId? integer Only NPCs on this map. Without it, NPCs on any map or none.
--- @field abilities? TameableAbility[] Only NPCs that teach every one of these. Only these count when finding the highest ranks.

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns `true` if `a` is listed before `b`: higher lead rank, then lead ability name,
--- then higher level, then name.
--- @param a TameFinderResult
--- @param b TameFinderResult
local function isListedBefore(a, b)
  if a.leadRank ~= b.leadRank then
    return a.leadRank > b.leadRank
  end
  if a.leadAbility.name ~= b.leadAbility.name then
    return a.leadAbility.name < b.leadAbility.name
  end
  if a.npc.min_level ~= b.npc.min_level then
    return a.npc.min_level > b.npc.min_level
  end
  return a.npc.name < b.npc.name
end

--- Returns `true` if `npc` teaches every one of `abilities`, or if there are none.
--- @param npc TameableNPC
--- @param abilities? TameableAbility[]
--- @return boolean
local function teachesEvery(npc, abilities)
  if abilities then
    for _, ability in ipairs(abilities) do
      local isTaught = false
      for _, npcAbility in ipairs(npc.abilities) do
        if npcAbility.ability == ability then isTaught = true end
      end
      if not isTaught then return false end
    end
  end
  return true
end

--- Returns `true` if `npc` matches the filters.
--- @param npc TameableNPC
--- @param filters TameFinderFilters
--- @return boolean
local function isMatch(npc, filters)
  return (
    npc.min_level <= filters.level and
    (filters.uiMapId == nil or npc.ui_map_id == filters.uiMapId) and
    teachesEvery(npc, filters.abilities)
  )
end

--- Returns `true` if `ability` counts when finding the highest ranks: always if no abilities are filtered.
--- @param ability TameableAbility
--- @param filteredAbilities? TameableAbility[]
--- @return boolean
local function isCounted(ability, filteredAbilities)
  if filteredAbilities and #filteredAbilities > 0 then
    for _, filteredAbility in ipairs(filteredAbilities) do
      if filteredAbility == ability then return true end
    end
    return false
  end
  return true
end

-- ============================================================================
-- TameFinder
-- ============================================================================

--- Returns the NPCs worth taming: those that teach the highest rank of an ability among the NPCs
--- matching the filters.
--- @param filters TameFinderFilters
--- @return TameFinderResult[] results
--- @return table<TameableAbility, integer> bestRanks Highest rank of each ability among those NPCs. A missing ability cannot be added to the filter.
function TameFinder:Get(filters)
  --- @type table<TameableAbility, integer>
  local bestRanks = {}

  for _, npc in pairs(TameableNPCs) do
    if isMatch(npc, filters) then
      for _, npcAbility in ipairs(npc.abilities) do
        if npcAbility.rank > (bestRanks[npcAbility.ability] or 0) then
          bestRanks[npcAbility.ability] = npcAbility.rank
        end
      end
    end
  end

  --- @type TameFinderResult[]
  local results = {}

  for _, npc in pairs(TameableNPCs) do
    if isMatch(npc, filters) then
      --- @type TameableAbility?, integer?
      local leadAbility, leadRank

      for _, npcAbility in ipairs(npc.abilities) do
        local isBest = npcAbility.rank == bestRanks[npcAbility.ability]
        if isBest and isCounted(npcAbility.ability, filters.abilities) and (leadRank == nil or npcAbility.rank > leadRank) then
          leadAbility, leadRank = npcAbility.ability, npcAbility.rank
        end
      end

      if leadAbility and leadRank then
        results[#results + 1] = { npc = npc, leadAbility = leadAbility, leadRank = leadRank }
      end
    end
  end

  table.sort(results, isListedBefore)

  return results, bestRanks
end
