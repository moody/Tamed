local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local TameableAbilities = Addon:GetModule("TameableAbilities")
local TameableNPCs = Addon:GetModule("TameableNPCs")

-- Resolves TameableAbilities/TameableNPCs against the running client, once
-- every flavor's data has been merged in (guaranteed by PlayerLogin, since
-- the flavor data files all load and run before then).
EventManager:Once(E.Wow.PlayerLogin, function()
  -- Update TameableAbilities with in-game data.
  for key, ability in pairs(TameableAbilities) do
    -- Remove unavailable ranks.
    for i = #ability.ranks, 1, -1 do
      local rank = ability.ranks[i]
      if (GetSpellInfo(rank.spell_id) == nil) then
        table.remove(ability.ranks, i)
      end
    end

    -- Every surviving rank gets an npc_ids list, even one that stays empty.
    for _, rank in ipairs(ability.ranks) do
      rank.npc_ids = {}
    end

    -- If ability exists, update its name and icon.
    if #ability.ranks > 0 then
      local name, _, icon = GetSpellInfo(ability.ranks[1].spell_id)
      if type(name) == "string" and type(icon) == "number" then
        ability.name = name
        ability.icon = icon
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

    if npc.location then
      -- Add `classification` to `level_range`.
      if npc.classification then
        npc.level_range = ("%s (%s)"):format(
          npc.level_range,
          Colors.Highlight(npc.classification)
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
end)
