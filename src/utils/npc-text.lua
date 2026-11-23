local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")

--- @class NpcText
local NpcText = Addon:GetModule("NpcText")

-- ============================================================================
-- NpcText
-- ============================================================================

--- Returns the text of one of an NPC's abilities: its icon, name, and rank. The name and rank are dimmed together
--- if `isDimmed`.
--- @param npcAbility TameableNPCAbility
--- @param isDimmed? boolean
--- @return string
function NpcText:Ability(npcAbility, isDimmed)
  local ability = npcAbility.ability
  local rank = ("(%s %d)"):format(L.RANK, npcAbility.rank)

  if isDimmed then
    return ("|T%s:0|t %s"):format(ability.icon, Colors.DimGrey(ability.name .. " " .. rank))
  end

  return ("|T%s:0|t %s %s"):format(ability.icon, Colors.White(ability.name), Colors.Grey(rank))
end

--- Returns the text of all of an NPC's abilities, separated by commas.
--- @param npc TameableNPC
--- @return string
function NpcText:Abilities(npc)
  local texts = {}
  for i, npcAbility in ipairs(npc.abilities) do
    texts[i] = self:Ability(npcAbility)
  end
  return table.concat(texts, ", ")
end

--- Returns the NPC's level range, followed by its classification if it has one.
--- @param npc TameableNPC
--- @return string
function NpcText:Level(npc)
  if npc.classification then
    return ("%s (%s)"):format(npc.level_range, Colors.Gold(npc.classification))
  end

  return npc.level_range
end
