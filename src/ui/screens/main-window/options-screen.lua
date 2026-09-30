local Addon = select(2, ...) ---@type Addon
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local StateManager = Addon:GetModule("StateManager")
local Widgets = Addon:GetModule("Widgets")
local Waffle = Addon.Waffle

--- @class OptionsScreen
local OptionsScreen = Addon:GetModule("OptionsScreen")

-- ============================================================================
-- OptionsScreen
-- ============================================================================

--- Builds and returns a root component describing the Options Screen.
--- @return WaffleFlexComponent root
function OptionsScreen:Build()
  local root = Waffle:Flex({
    visibility = "GONE",
    direction = "COLUMN",
    height = "AUTO",
    gap = Widgets:Padding(),
  })

  root:AttachComponent(ComponentFactory:OptionButton({
    labelText = L.MINIMAP_ICON,
    tooltipText = L.MINIMAP_ICON_TOOLTIP,
    get = function() return MinimapIcon:IsEnabled() end,
    set = function(value) MinimapIcon:SetEnabled(value) end,
  }))

  root:AttachComponent(ComponentFactory:OptionButton({
    labelText = L.NPC_TOOLTIPS,
    tooltipText = L.NPC_TOOLTIPS_TOOLTIP,
    get = function() return StateManager:GetState().npc_tooltips end,
    set = function(value) StateManager:SetNpcTooltipsEnabled(value) end,
  }))

  return root
end
