local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local OptionsScreen = Addon:GetModule("OptionsScreen")
local RankScreen = Addon:GetModule("RankScreen")
local Sidebar = Addon:GetModule("Sidebar")
local Widgets = Addon:GetModule("Widgets")

--- @class UI
local UI = Addon:GetModule("UI")

local Components = {}

-- ============================================================================
-- Local Functions
-- ============================================================================

--- @type WaffleFlexComponent?
local currentContentScreen

--- Shows the given content-area screen, hiding whichever one was showing.
--- @param screen WaffleFlexComponent
local function showContentScreen(screen)
  if screen == currentContentScreen then return end
  if currentContentScreen then currentContentScreen:SetVisibility("GONE") end
  screen:SetVisibility("VISIBLE")
  currentContentScreen = screen
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = ComponentFactory:Window({
  name = "MainWindow",
  width = 720,
  height = 540,
  titleText = "",
  refresh = function() Components.Root:Layout() end
})

-- Window()'s generic title text goes unused in favor of the title bar below.
Components.Root.TitleText:Detach()
Components.Root.TitleText = nil

-- ============================================================================
-- Title Bar Components
-- ============================================================================

-- Addon name, in green.
Components.TitleBarNameText = Components.Root.TitleRow:AddRow()
Components.TitleBarNameText:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
    fontString:SetJustifyH("LEFT")
    fontString:SetText(Colors.Green(ADDON_NAME))
    return fontString
  end
})

-- Addon version, centered.
Components.TitleBarVersionText = Components.Root.TitleRow:AddRow({ justify = "CENTER" })
Components.TitleBarVersionText:AddChild({
  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString("$parent_VersionText", "ARTWORK", "GameFontNormalSmall")
    fontString:SetText(Colors.Grey(Addon.VERSION))
    return fontString
  end
})

-- Reuse Window()'s close button, moved into its own right-aligned row.
Components.Root.TitleRow:AddRow({ justify = "END" }):AttachComponent(Components.Root.CloseButton:Detach())

-- ============================================================================
-- Main Screen Components
-- ============================================================================

-- Holds Sidebar and ContentArea side by side.
local mainScreenRow = Components.Root:AddRow({
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5)
})

-- Sidebar: build content once data is loaded.
EventManager:Once(E.DataLoaded, function()
  local sidebarComponent = mainScreenRow:AddColumn({
    width = "30%",
    padding = Widgets:Padding(),
    frameFactory = function(parent)
      return Widgets:Frame({ parent = parent })
    end
  })

  sidebarComponent:AttachComponent(Sidebar:Build({
    onSelectOptions = function()
      showContentScreen(Components.OptionsScreen)
    end,
    onSelectRank = function(ability, rank)
      Components.RankScreen:SetRank(ability, rank)
      showContentScreen(Components.RankScreen)
    end,
  }))
end)

-- Content area: switches to match the sidebar's current selection.
local contentArea = mainScreenRow:AddColumn({
  padding = Widgets:Padding(),
  order = 2,
  frameFactory = function(parent)
    return Widgets:Frame({ parent = parent })
  end
})

Components.OptionsScreen = contentArea:AttachComponent(OptionsScreen:Build())

--- @type RankScreenComponent
Components.RankScreen = contentArea:AttachComponent(RankScreen:Build())

-- ============================================================================
-- UI
-- ============================================================================

--- Shows the main window.
function UI:Show()
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
end

--- Hides the main window.
function UI:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

--- Shows or hides the main window.
function UI:Toggle()
  if Components.Root:IsVisible() then
    self:Hide()
  else
    self:Show()
  end
end
