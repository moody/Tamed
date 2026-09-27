local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local TameableAbilities = Addon:GetModule("TameableAbilities")
local Widgets = Addon:GetModule("Widgets")

--- @class UI
local UI = Addon:GetModule("UI")

-- ============================================================================
-- Components
-- ============================================================================

local Components = {}

--- @type WaffleFlexComponent?
Components.currentContentScreen = nil

--- @type ButtonWidget?
Components.currentRowButton = nil

--- Highlights the given button as selected, restoring the previously selected one.
--- @param button ButtonWidget
function Components:SelectRowButton(button)
  if button == self.currentRowButton then return end

  if self.currentRowButton then
    self.currentRowButton:SetBackdropColor(0, 0, 0, 0)
    self.currentRowButton.label:SetTextColor(Colors.White:GetRGBA())
  end

  button:SetBackdropColor(Colors.Gold:GetRGBA(0.1))
  button.label:SetTextColor(Colors.Gold:GetRGBA())

  self.currentRowButton = button
end

--- Shows the given content-area screen, hiding whichever one was showing.
--- @param screen WaffleFlexComponent
function Components:ShowContentScreen(screen)
  if screen == self.currentContentScreen then return end
  if self.currentContentScreen then self.currentContentScreen:SetVisibility("GONE") end
  screen:SetVisibility("VISIBLE")
  self.currentContentScreen = screen
end

-- ============================================================================
-- Root Component
-- ============================================================================

Components.Root = ComponentFactory:Window({
  name = "MainWindow",
  width = 720,
  height = 540,
  titleText = "", -- unused; the title bar below replaces it
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
Components.MainScreenRow = Components.Root:AddRow({
  padding = Widgets:Padding(),
  gap = Widgets:Padding(0.5),
})

-- Sidebar: fixed-width column, its content scrollable. Lists Options, then
-- every ability, each expandable to its own rank rows.
Components.Sidebar = Components.MainScreenRow:AddColumn({
  width = "30%",
  padding = Widgets:Padding(),

  --- @param parent Frame
  frameFactory = function(parent)
    return Widgets:Frame({ parent = parent })
  end,
})

Components.SidebarScrollPanel = ComponentFactory:ScrollPanel()
Components.Sidebar:AttachComponent(Components.SidebarScrollPanel)

-- Populated below (Options, then one entry per ability). Scrolls
-- independently of `Sidebar` itself; see `ComponentFactory:ScrollPanel`.
Components.SidebarContent = Components.SidebarScrollPanel.ScrollChild

-- Content area: switches to match the sidebar's current selection.
Components.ContentArea = Components.MainScreenRow:AddColumn({
  padding = Widgets:Padding(),

  --- @param parent Frame
  frameFactory = function(parent)
    return Widgets:Frame({ parent = parent })
  end,
})

-- ============================================================================
-- Sidebar Rows
-- ============================================================================

--- Sizes a FontString to the width Waffle assigns it, reporting back the
--- resulting height.
--- @param fontString FontString
--- @param width integer
local function measureFontString(fontString, width)
  fontString:SetWidth(width)
  return width, fontString:GetStringHeight() + Widgets:Padding(1.5)
end

--- Adds a selectable button row to `container`: shows `screen` in the
--- content area when clicked, and highlights while selected or hovered.
--- @param container WaffleFlexComponent
--- @param options { labelText: string, screen: WaffleFlexComponent, marginBottom: number? }
local function addSelectableRow(container, options)
  return container:AddChild({
    height = "AUTO",
    marginBottom = options.marginBottom,

    --- @param parent Frame
    frameFactory = function(parent)
      local frame
      frame = Widgets:Button({
        parent = parent,
        labelText = options.labelText,
        labelColor = Colors.White,
        onClick = function()
          Components:SelectRowButton(frame)
          Components:ShowContentScreen(options.screen)
        end,
      })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:SetScript("OnEnter", function(self)
        if self ~= Components.currentRowButton then self:SetBackdropColor(Colors.White:GetRGBA(0.1)) end
      end)
      frame:SetScript("OnLeave", function(self)
        if self ~= Components.currentRowButton then self:SetBackdropColor(0, 0, 0, 0) end
      end)
      frame.label:SetJustifyH("LEFT")
      return frame
    end,

    ---@param frame ButtonWidget
    ---@param width number
    ---@return number, number
    onMeasure = function(frame, width)
      return measureFontString(frame.label, width)
    end,
  })
end

-- ============================================================================
-- Sidebar: Options
-- ============================================================================

Components.OptionsScreen = Components.ContentArea:AddChild({
  visibility = "GONE",

  --- @param parent Frame
  frameFactory = function(parent)
    local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fontString:SetText(L.OPTIONS)
    return fontString
  end,
})

addSelectableRow(Components.SidebarContent, {
  labelText = L.OPTIONS,
  screen = Components.OptionsScreen,
  marginBottom = Widgets:Padding(2),
})

-- ============================================================================
-- Sidebar: Abilities
-- ============================================================================

-- Ability rows, sorted by name. Each row's header expands to reveal the
-- ability's rank rows beneath it; selecting a rank shows that rank's screen
-- in the content area, the same way Options does above.
local abilities = {}
for _, ability in pairs(TameableAbilities) do
  abilities[#abilities + 1] = ability
end
table.sort(abilities, function(a, b) return a.name < b.name end)

for _, ability in ipairs(abilities) do
  local abilityGroup = Components.SidebarContent:AddColumn({ height = "AUTO" })

  --- @type WaffleFlexComponent set once the rank rows below are built
  local ranksColumn
  --- @type FontString set by its own frameFactory below
  local expandIcon

  -- Header: icon + name + expand/collapse indicator, the whole row clickable.
  local header = abilityGroup:AddRow({
    height = "AUTO",
    gap = Widgets:Padding(0.5),
    align = "CENTER",

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:HookScript("OnEnter", function(self) self:SetBackdropColor(Colors.White:GetRGBA(0.1)) end)
      frame:HookScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)
      frame:SetScript("OnClick", function()
        local wasExpanded = ranksColumn:IsVisible()
        ranksColumn:SetVisibility(wasExpanded and "GONE" or "VISIBLE")
        expandIcon:SetText(wasExpanded and "+" or "-")
      end)
      return frame
    end,
  })

  header:AddChild({
    width = 16,
    height = 16,
    --- @param parent Frame
    frameFactory = function(parent)
      local icon = parent:CreateTexture(nil, "ARTWORK")
      icon:SetTexture(ability.icon)
      icon:SetAllPoints()
      return icon
    end,
  })

  header:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("LEFT")
      fontString:SetWordWrap(false)
      fontString:SetTextColor(Colors.Grey:GetRGB())
      fontString:SetTextToFit(ability.name)
      return fontString
    end,

    onMeasure = measureFontString
  })

  -- Expand/collapse indicator, flush right. Placeholder text; a real icon
  -- pair belongs under `assets/` once one exists.
  header:AddChild({
    width = 16,
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      expandIcon = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      expandIcon:SetJustifyH("RIGHT")
      expandIcon:SetTextColor(Colors.White:GetRGBA())
      expandIcon:SetText("+")
      return expandIcon
    end,

    onMeasure = measureFontString
  })

  -- Rank rows: built once, hidden until the header is clicked.
  ranksColumn = abilityGroup:AddColumn({
    height = "AUTO",
    visibility = "GONE",
    paddingBottom = Widgets:Padding(),
  })

  -- Iterate ranks to set up their content screens and button rows.
  for _, rank in ipairs(ability.ranks) do
    local rankScreen = Components.ContentArea:AddChild({
      visibility = "GONE",
      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fontString:SetText(("%s (%s %d)"):format(ability.name, L.RANK, rank.rank))
        return fontString
      end,
    })

    -- Rank button row.
    local rankRow = ranksColumn:AddRow({
      height = "AUTO",
      paddingLeft = Widgets:Padding(),
      paddingRight = Widgets:Padding(),
    })
    addSelectableRow(rankRow, {
      labelText = ("%s %d"):format(L.RANK, rank.rank),
      screen = rankScreen,
    })
  end
end

-- ============================================================================
-- UI
-- ============================================================================

function UI:Show()
  Components.Root:SetVisibility("VISIBLE")
  Components.Root:Layout()
end

function UI:Hide()
  Components.Root:SetVisibility("GONE")
  Components.Root:Layout()
end

function UI:Toggle()
  if Components.Root:IsVisible() then
    self:Hide()
  else
    self:Show()
  end
end
