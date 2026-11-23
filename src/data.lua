local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local TameableAbilities = Addon:GetModule("TameableAbilities")
local TameableFamilies = Addon:GetModule("TameableFamilies")
local TameableNPCs = Addon:GetModule("TameableNPCs")

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class TameableAbilityRank
--- @field rank integer The rank's own number, not its position in `ranks`.
--- @field spell_id integer
--- @field pet_level? integer
--- @field training_cost? integer
--- @field npc_ids string[] Ids of NPCs that teach this rank.

--- @class TameableAbility
--- @field name string Resolved from `spell_id` via `GetSpellInfo`.
--- @field icon integer Resolved from `spell_id` via `GetSpellInfo`.
--- @field learned_by TameableFamily[] Resolved from family keys; empty means every family.
--- @field ranks TameableAbilityRank[] Ranks available on the running client.

--- @class TameableAbilities : table<string, TameableAbility>

--- Map position as `{x, y}` percentages (0 to 100).
--- @alias TameableNPCCoord [number, number]

--- @class TameableNPCAbility
--- @field ability TameableAbility
--- @field rank integer The displayed rank: its position among the ranks available on the running client.

--- @class TameableNPC
--- @field name string
--- @field family TameableFamily Resolved from a family key.
--- @field level_range string A level or a range, such as `12-14`.
--- @field min_level integer First number in `level_range`.
--- @field classification? string
--- @field zone_id integer
--- @field ui_map_id? integer
--- @field abilities TameableNPCAbility[] Sorted by ability name. Resolved from `{key, rank}` entries.
--- @field coords TameableNPCCoord[]
--- @field location string Resolved from `zone_id` via `C_Map.GetAreaInfo`.

--- @class TameableNPCs : table<string, TameableNPC>

--- @class TameableFamily
--- @field name string
--- @field type string `Cunning`, `Ferocity`, or `Tenacity`.
--- @field diet string[]

--- @class TameableFamilies : table<string, TameableFamily>

-- ============================================================================
-- PlayerLogin
-- ============================================================================

-- Resolves TameableAbilities/TameableNPCs against the running client, once
-- every flavor's data has been merged in (guaranteed by PlayerLogin, since
-- the flavor data files all load and run before then). Fires
-- `DataLoaded` when done.
EventManager:Once(E.Wow.PlayerLogin, function()
  -- Update TameableAbilities with in-game data.
  for key, ability in pairs(TameableAbilities) do
    -- Resolve the families that can learn it from keys.
    for i, familyKey in ipairs(ability.learned_by) do
      ability.learned_by[i] = TameableFamilies[familyKey]
    end

    -- Remove unavailable ranks.
    for i = #ability.ranks, 1, -1 do
      local rank = ability.ranks[i]
      if (C_Spell.GetSpellInfo(rank.spell_id) == nil) then
        table.remove(ability.ranks, i)
      end
    end

    -- Every surviving rank gets an npc_ids list, even one that stays empty.
    for _, rank in ipairs(ability.ranks) do
      rank.npc_ids = {}
    end

    -- If ability exists, update its name and icon.
    if #ability.ranks > 0 then
      local spellInfo = C_Spell.GetSpellInfo(ability.ranks[1].spell_id)
      if type(spellInfo.name) == "string" and type(spellInfo.iconID) == "number" then
        ability.name = spellInfo.name
        ability.icon = spellInfo.iconID
      else
        TameableAbilities[key] = nil
      end
    else
      TameableAbilities[key] = nil
    end
  end

  -- Update TameableNPCs with in-game data.
  for npc_id, npc in pairs(TameableNPCs) do
    npc.location = C_Map.GetAreaInfo(npc.zone_id)
    npc.min_level = tonumber(npc.level_range:match("%d+"))

    if npc.location then
      npc.family = TameableFamilies[npc.family]

      -- Resolve npc's ability/rank references, and record npc_id on the
      -- matching rank. Displayed rank number is the
      -- rank's position among those still available on this client, not its
      -- original number: removing an earlier rank shifts the rest.
      local resolved = {}
      for _, entry in ipairs(npc.abilities) do
        local ability = TameableAbilities[entry.key]
        if ability then
          for rankIndex, rank in ipairs(ability.ranks) do
            if rank.rank == entry.rank then
              resolved[#resolved + 1] = { ability = ability, rank = rankIndex }
              rank.npc_ids[#rank.npc_ids + 1] = npc_id
              break
            end
          end
        end
      end
      table.sort(resolved, function(a, b) return a.ability.name < b.ability.name end)
      npc.abilities = resolved
    else
      TameableNPCs[npc_id] = nil
    end
  end

  EventManager:Fire(E.DataLoaded)
end)
