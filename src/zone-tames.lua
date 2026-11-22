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
--- @field isBest boolean `true` if no tameable NPC in the zone teaches a higher rank of the ability.

--- @class ZoneTame
--- @field npc TameableNPC
--- @field abilities ZoneTameAbility[] Every ability the NPC teaches, sorted by name.
--- @field lead ZoneTameAbility The best ability with the highest rank. The first by name on a tie.

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

-- ============================================================================
-- ZoneTames
-- ============================================================================

--- Returns the NPCs worth taming in a zone: those the player can tame that teach the
--- zone's highest rank of an ability.
--- @param uiMapId? integer
--- @param level integer The player's level.
--- @return ZoneTame[]
function ZoneTames:Get(uiMapId, level)
  --- @type ZoneTame[]
  local zoneTames = {}

  if uiMapId then
    --- NPCs in the zone the player can tame.
    --- @type TameableNPC[]
    local npcs = {}

    --- Highest rank of each ability among `npcs`.
    --- @type table<TameableAbility, integer>
    local bestRanks = {}

    for _, npc in pairs(TameableNPCs) do
      if npc.ui_map_id == uiMapId and npc.min_level <= level then
        npcs[#npcs + 1] = npc
        for _, abilityRank in ipairs(npc.ability_ranks) do
          if abilityRank.rank > (bestRanks[abilityRank.ability] or 0) then
            bestRanks[abilityRank.ability] = abilityRank.rank
          end
        end
      end
    end

    for _, npc in ipairs(npcs) do
      --- @type ZoneTame
      local zoneTame = { npc = npc, abilities = {} }

      for _, abilityRank in ipairs(npc.ability_ranks) do
        --- @type ZoneTameAbility
        local entry = {
          ability = abilityRank.ability,
          rank = abilityRank.rank,
          isBest = abilityRank.rank == bestRanks[abilityRank.ability],
        }
        zoneTame.abilities[#zoneTame.abilities + 1] = entry

        if entry.isBest and (zoneTame.lead == nil or entry.rank > zoneTame.lead.rank) then
          zoneTame.lead = entry
        end
      end

      if zoneTame.lead then
        zoneTames[#zoneTames + 1] = zoneTame
      end
    end

    table.sort(zoneTames, isListedBefore)
  end

  return zoneTames
end
