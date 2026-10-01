local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local StateManager = Addon:GetModule("StateManager")
local TameableNPCs = Addon:GetModule("TameableNPCs")

EventManager:Once(E.StoreCreated, function()
  local function addTamedTooltip(self)
    if not StateManager:GetState().npc_tooltips then return end

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

    -- Add lines.
    self:AddLine(Colors.Green(ADDON_NAME))
    for _, ability in ipairs(npc.abilities) do
      self:AddLine("  " .. ability, 1, 1, 1)
    end
  end

  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, addTamedTooltip)
  else
    GameTooltip:HookScript("OnTooltipSetUnit", addTamedTooltip)
  end
end)
