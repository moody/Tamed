local Addon = select(2, ...) ---@type Addon
local L = Addon:GetModule("Locale")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")

--- @class OptionsGroup
local OptionsGroup = Addon:GetModule("OptionsGroup")

function OptionsGroup:Create(parent)
  Widgets:Heading(parent, L.OPTIONS)
  self:AddGeneral(parent)
end

function OptionsGroup:AddGeneral(parent)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.GENERAL,
    fullWidth = true
  })

  -- Minimap Icon.
  Widgets:CheckBox({
    parent = parent,
    label = L.MINIMAP_ICON,
    tooltip = L.MINIMAP_ICON_TOOLTIP,
    get = function() return not StateManager:GetState().minimapIcon.hide end,
    set = function() MinimapIcon:Toggle() end
  })

  -- NPC Tooltips.
  Widgets:CheckBox({
    parent = parent,
    label = L.NPC_TOOLTIPS,
    tooltip = L.NPC_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetState().npc_tooltips end,
    set = function(value) StateManager:SetNpcTooltipsEnabled(value) end
  })
end
