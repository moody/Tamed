local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local LDB = Addon:GetLibrary("LDB")
local LDBIcon = Addon:GetLibrary("LDBIcon")
local PinHelper = Addon:GetModule("PinHelper")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local UI = Addon:GetModule("UI")

--- @class MinimapIcon
local MinimapIcon = Addon:GetModule("MinimapIcon")

-- Initialize LDB object.
function MinimapIcon:Initialize()
  local object = LDB:NewDataObject(ADDON_NAME, {
    type = "data source",
    text = ADDON_NAME,
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
        Colors.Primary(ADDON_NAME),
        Addon.VERSION
      )
      tooltip:AddLine(" ")
      tooltip:AddDoubleLine(L.LEFT_CLICK, L.TOGGLE_UI, nil, nil, nil, 1, 1, 1)
      tooltip:AddDoubleLine(L.RIGHT_CLICK, L.CLEAR_PINS, nil, nil, nil, 1, 1, 1)
    end,
  })

  local debouncePatchMinimapIcon
  do
    local patchCache = {}
    local debounce = TickerManager:NewDebouncer(0.2, function()
      StateManager:PatchMinimapIcon(patchCache)
      for k in pairs(patchCache) do patchCache[k] = nil end
    end)

    -- Helper function to debounce a minimap icon state patch.
    --- @param key string
    --- @param value any
    debouncePatchMinimapIcon = function(key, value)
      patchCache[key] = value
      debounce()
    end
  end

  -- When the minimap icon is being dragged, LibDBIcon sets `db.minimapPos` on
  -- every frame update. Therefore, we use a metatable to debounce changes.
  local db = setmetatable({}, {
    __index = function(t, k)
      return StateManager:GetState().minimapIcon[k]
    end,
    __newindex = function(t, k, v)
      debouncePatchMinimapIcon(k, v)
    end
  })

  LDBIcon:Register(ADDON_NAME, object, db)
  self.Initialize = nil
end

-- Displays the minimap icon.
function MinimapIcon:Show()
  StateManager:PatchMinimapIcon({ hide = false })
  LDBIcon:Show(ADDON_NAME)
end

-- Hides the minimap icon.
function MinimapIcon:Hide()
  StateManager:PatchMinimapIcon({ hide = true })
  LDBIcon:Hide(ADDON_NAME)
end

-- Toggles the minimap icon.
function MinimapIcon:Toggle()
  if StateManager:GetState().minimapIcon.hide then
    self:Show()
  else
    self:Hide()
  end
end
