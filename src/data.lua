local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local TameableAbilities = Addon:GetModule("TameableAbilities")
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
--- @field learned_by string[] Pet family names; empty means every family.
--- @field ranks TameableAbilityRank[] Ranks available on the running client.

--- @class TameableAbilities : table<string, TameableAbility>

--- @class TameableNPCCoord
--- @field x number
--- @field y number

--- @class TameableNPC
--- @field name string
--- @field family string
--- @field type string
--- @field diet string[]
--- @field level_range string Includes `classification`, if any, once resolved.
--- @field min_level integer First number in `level_range`.
--- @field classification? string
--- @field zone_id integer
--- @field ui_map_id? integer
--- @field abilities string[] Formatted display strings, not `{key, rank}` entries.
--- @field coords TameableNPCCoord[]
--- @field location string Resolved from `zone_id` via `C_Map.GetAreaInfo`.

--- @class TameableNPCs : table<string, TameableNPC>

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
      -- Add `classification` to `level_range`.
      if npc.classification then
        npc.level_range = ("%s (%s)"):format(
          npc.level_range,
          Colors.Gold(npc.classification)
        )
      end

      -- Resolve npc's ability/rank references into display strings, and
      -- record npc_id on the matching rank. Displayed rank number is the
      -- rank's position among those still available on this client, not its
      -- original number: removing an earlier rank shifts the rest.
      local abilities = {}
      for _, entry in ipairs(npc.abilities) do
        local ability = TameableAbilities[entry.key]
        if ability then
          for rankIndex, rank in ipairs(ability.ranks) do
            if rank.rank == entry.rank then
              abilities[#abilities + 1] = {
                ability.name,
                ("|T%s:0|t %s |cFF9D9D9D(%s %s)|r"):format(
                  ability.icon,
                  ability.name,
                  L.RANK,
                  rankIndex
                )
              }
              rank.npc_ids[#rank.npc_ids + 1] = npc_id
              break
            end
          end
        end
      end
      table.sort(abilities, function(a, b) return a[1] < b[1] end)
      npc.abilities = {}
      for _, v in ipairs(abilities) do npc.abilities[#npc.abilities + 1] = v[2] end
    else
      TameableNPCs[npc_id] = nil
    end
  end

  EventManager:Fire(E.DataLoaded)
end)
