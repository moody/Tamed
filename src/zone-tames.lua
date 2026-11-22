local Addon = select(2, ...) ---@type Addon
local TameableNPCs = Addon:GetModule("TameableNPCs")

--- @class ZoneTames
local ZoneTames = Addon:GetModule("ZoneTames")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class ZoneTameAbility
--- @field ability TameableAbility
--- @field rank integer The displayed rank.
--- @field isBest boolean `true` if no NPC matching the filters teaches a higher rank of the ability.

--- @class ZoneTame
--- @field npc TameableNPC
--- @field abilities ZoneTameAbility[] Every ability the NPC teaches, sorted by name.
--- @field lead ZoneTameAbility The highest ranked best ability, among the filtered ones if any. The first by name on a tie.

--- @class ZoneTamesFilters
--- @field level integer Only NPCs that can be tamed at this level.
--- @field uiMapId? integer Only NPCs on this map. Without it, NPCs on any map or none.
--- @field abilities? TameableAbility[] Only NPCs that teach every one of these. Only these count when finding the highest ranks.

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns `true` if `a` is listed before `b`: higher lead rank, then lead ability name,
--- then higher level, then name.
--- @param a ZoneTame
--- @param b ZoneTame
local function isListedBefore(a, b)
  if a.lead.rank ~= b.lead.rank then
    return a.lead.rank > b.lead.rank
  end
  if a.lead.ability.name ~= b.lead.ability.name then
    return a.lead.ability.name < b.lead.ability.name
  end
  if a.npc.min_level ~= b.npc.min_level then
    return a.npc.min_level > b.npc.min_level
  end
  return a.npc.name < b.npc.name
end

--- Returns `true` if `npc` teaches every one of `abilities`.
--- @param npc TameableNPC
--- @param abilities TameableAbility[]
--- @return boolean
local function teachesEvery(npc, abilities)
  for _, ability in ipairs(abilities) do
    local isTaught = false
    for _, npcAbility in ipairs(npc.abilities) do
      if npcAbility.ability == ability then isTaught = true end
    end
    if not isTaught then return false end
  end
  return true
end

-- ============================================================================
-- ZoneTames
-- ============================================================================

--- Returns the NPCs worth taming: those that teach the highest rank of an ability among the NPCs
--- matching the filters.
--- @param filters ZoneTamesFilters
--- @return ZoneTame[]
function ZoneTames:Get(filters)
  local filteredAbilities = filters.abilities or {}

  --- The filtered abilities, as a set.
  --- @type table<TameableAbility, true>
  local isFiltered = {}
  for _, ability in ipairs(filteredAbilities) do isFiltered[ability] = true end

  --- NPCs that match the filters.
  --- @type TameableNPC[]
  local npcs = {}

  --- Highest rank of each ability among `npcs`.
  --- @type table<TameableAbility, integer>
  local bestRanks = {}

  for _, npc in pairs(TameableNPCs) do
    if npc.min_level <= filters.level and (filters.uiMapId == nil or npc.ui_map_id == filters.uiMapId) then
      if teachesEvery(npc, filteredAbilities) then
        npcs[#npcs + 1] = npc
        for _, npcAbility in ipairs(npc.abilities) do
          if npcAbility.rank > (bestRanks[npcAbility.ability] or 0) then
            bestRanks[npcAbility.ability] = npcAbility.rank
          end
        end
      end
    end
  end

  --- @type ZoneTame[]
  local zoneTames = {}

  for _, npc in ipairs(npcs) do
    --- @type ZoneTameAbility[]
    local zoneTameAbilities = {}

    --- @type ZoneTameAbility?
    local lead

    for _, npcAbility in ipairs(npc.abilities) do
      --- @type ZoneTameAbility
      local zoneTameAbility = {
        ability = npcAbility.ability,
        rank = npcAbility.rank,
        isBest = npcAbility.rank == bestRanks[npcAbility.ability],
      }
      zoneTameAbilities[#zoneTameAbilities + 1] = zoneTameAbility

      local isCounted = #filteredAbilities == 0 or isFiltered[zoneTameAbility.ability]
      if zoneTameAbility.isBest and isCounted and (lead == nil or zoneTameAbility.rank > lead.rank) then
        lead = zoneTameAbility
      end
    end

    if lead then
      zoneTames[#zoneTames + 1] = { npc = npc, abilities = zoneTameAbilities, lead = lead }
    end
  end

  table.sort(zoneTames, isListedBefore)

  return zoneTames
end
