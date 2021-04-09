local AddonName, Addon = ...
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local L = Addon.Locale
local strsplit = _G.strsplit
local TameableAbilities = Addon.TameableAbilities
local TameableNPCs = Addon.TameableNPCs
local UnitGUID = _G.UnitGUID

local cache = {}

local function getAbilities(npc_id)
  if cache[npc_id] then return cache[npc_id] end
  local abilities = {}

  for _, ability in pairs(TameableAbilities) do
    for rankIndex, rank in ipairs(ability.ranks) do
      for _, id in ipairs(rank.npc_ids) do
        if npc_id == id then
          abilities[#abilities+1] = {
            ("|T%s:0|t %s"):format(ability.icon, ability.name),
            ("%s %s"):format(L.RANK, rankIndex)
          }
        end
      end
    end
  end

  cache[npc_id] = abilities
  return abilities
end

_G.GameTooltip:HookScript("OnTooltipSetUnit", function(self)
  if not DB.global.npc_tooltips then return end

  -- Get unit.
  local _, unit = self:GetUnit()
  if not unit then return end

  -- Get unit type and id.
  local guid = UnitGUID(unit) or ""
  local unitType, _, _, _, _, id = strsplit("-", guid)
  if not (id and unitType == "Creature") then return end

  -- Get npc.
  local npc = TameableNPCs[id]
  if not npc then return end

  -- Get abilities.
  local abilities = getAbilities(tonumber(id))
  if #abilities == 0 then return end

  -- Add lines.
  self:AddLine(DCL:ColorString(AddonName, Colors.Primary))
  for _, ability in ipairs(abilities) do
    self:AddLine(
      ("  %s |cFF9D9D9D(%s)|r"):format(ability[1], ability[2]),
      1, 1, 1
    )
  end
end)
