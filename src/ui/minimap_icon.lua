local AddonName, Addon = ...
local Colors = Addon.Colors
local DB = Addon.DB
local DCL = Addon.Libs.DCL
local L = Addon.Locale
local LDB = Addon.Libs.LDB
local LDBIcon = Addon.Libs.LDBIcon
local MinimapIcon = Addon.UI.MinimapIcon
local PinHelper = Addon.UI.PinHelper
local UI = Addon.UI

-- Initialize LDB object.
function MinimapIcon:Initialize()
  local object = LDB:NewDataObject(AddonName, {
    type = "data source",
    text = AddonName,
    icon = Addon.ICON,

    OnClick = function(_, button)
      if button == "LeftButton" then
        UI:Toggle()
      elseif button == "RightButton" then
        PinHelper:Clear()
      end
    end,

    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine(
        DCL:ColorString(AddonName, Colors.Primary),
        Addon.VERSION
      )
      tooltip:AddLine(" ")
      tooltip:AddDoubleLine(L.LEFT_CLICK, L.TOGGLE_UI, nil, nil, nil, 1, 1, 1)
      tooltip:AddDoubleLine(L.RIGHT_CLICK, L.CLEAR_PINS, nil, nil, nil, 1, 1, 1)
    end,
  })

  LDBIcon:Register(AddonName, object, DB.global.minimapIcon)
  self.Initialize = nil
end

-- Displays the minimap icon.
function MinimapIcon:Show()
  DB.global.minimapIcon.hide = false
  LDBIcon:Show(AddonName)
end

-- Hides the minimap icon.
function MinimapIcon:Hide()
  DB.global.minimapIcon.hide = true
  LDBIcon:Hide(AddonName)
end

-- Toggles the minimap icon.
function MinimapIcon:Toggle()
  if DB.global.minimapIcon.hide then
    self:Show()
  else
    self:Hide()
  end
end
