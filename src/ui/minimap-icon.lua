local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local LDB = Addon:GetLibrary("LDB")
local LDBIcon = Addon:GetLibrary("LDBIcon")
local PinHelper = Addon:GetModule("PinHelper")
local StateManager = Addon:GetModule("StateManager")
local TickerManager = Addon:GetModule("TickerManager")
local UI = Addon:GetModule("UI")

--- @class MinimapIcon
local MinimapIcon = Addon:GetModule("MinimapIcon")

-- Registers the minimap icon once the store exists, since LibDBIcon reads
-- db's fields immediately to position the icon.
EventManager:Once(E.StoreCreated, function()
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

    -- Debounces a minimap icon state patch.
    --- @param key string
    --- @param value any
    debouncePatchMinimapIcon = function(key, value)
      patchCache[key] = value
      debounce()
    end
  end

  -- LibDBIcon sets `db.minimapPos` on every frame while the icon is being
  -- dragged; this metatable debounces those writes into a state patch.
  local db = setmetatable({}, {
    __index = function(t, k)
      return StateManager:GetState().minimapIcon[k]
    end,
    __newindex = function(t, k, v)
      debouncePatchMinimapIcon(k, v)
    end
  })

  LDBIcon:Register(ADDON_NAME, object, db)
end)

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
