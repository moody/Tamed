local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local StateManager = Addon:GetModule("StateManager")
local TameableNPCs = Addon:GetModule("TameableNPCs")

EventManager:Once(E.StoreCreated, function()
  --- Returns true if `value` is set and not hidden from addons.
  local function isReadable(value)
    if not value then return false end
    return not (issecretvalue and issecretvalue(value))
  end

  --- Adds the NPC's abilities to a unit tooltip.
  local function addTamedTooltip(self)
    if not StateManager:GetState().npc_tooltips then return end

    -- Get unit.
    local _, unit = self:GetUnit()
    if not isReadable(unit) then return end

    -- Get unit type and id.
    local guid = UnitGUID(unit) or ""
    if not isReadable(guid) then return end

    local unitType, _, _, _, _, id = strsplit("-", guid)
    if not (id and unitType == "Creature") then return end

    -- Get npc.
    local npc = TameableNPCs[id]
    if not npc then return end

    -- Add lines.
    self:AddLine(Colors.Green(ADDON_NAME))
    for _, ability in ipairs(npc.abilities) do
      self:AddLine("  " .. ability, 1, 1, 1)
    end
  end

  if Addon.IS_VANILLA or Addon.IS_TBC then
    GameTooltip:HookScript("OnTooltipSetUnit", addTamedTooltip)
  else
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, addTamedTooltip)
  end
end)
