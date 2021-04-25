local _, Addon = ...
local C_Map = _G.C_Map
local Colors = Addon.Colors
local DCL = Addon.Libs.DCL
local L = Addon.Locale
local TameableAbilities = Addon.TameableAbilities
local TameableNPCs = Addon.TameableNPCs

-- Update TameableAbilities with in-game data.
for _, ability in pairs(TameableAbilities) do
  local name, _, icon = _G.GetSpellInfo(ability.ranks[1].spell_id)
  ability.name = name
  ability.icon = icon
end

-- Update TameableNPCs with in-game data.
for npc_id, npc in pairs(TameableNPCs) do
  npc.location = C_Map.GetAreaInfo(npc.zone_id)

  -- Add `classification` to `level_range`.
  if npc.classification then
    npc.level_range = ("%s (%s)"):format(
      npc.level_range, DCL:ColorString(
        npc.classification,
        Colors.Highlight
      )
    )
  end

  -- Add `abilities` table.
  local abilities = {}
  for _, ability in pairs(TameableAbilities) do
    for rankIndex, rank in ipairs(ability.ranks) do
      for _, id in ipairs(rank.npc_ids) do
        if npc_id == tostring(id) then
          abilities[#abilities+1] = {
            ability.name,
            ("|T%s:0|t %s |cFF9D9D9D(%s %s)|r"):format(
              ability.icon,
              ability.name,
              L.RANK,
              rankIndex
            )
          }
        end
      end
    end
  end
  table.sort(abilities, function(a, b) return a[1] < b[1] end)
  npc.abilities = {}
  for _, v in ipairs(abilities) do npc.abilities[#npc.abilities+1] = v[2] end
end
