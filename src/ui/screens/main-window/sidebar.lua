local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local TameableAbilities = Addon:GetModule("TameableAbilities")
local Widgets = Addon:GetModule("Widgets")

--- @class Sidebar
local Sidebar = Addon:GetModule("Sidebar")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- @type SelectableRowComponent?
local selectedRow

--- Highlights the given row as selected, restoring the previously selected one.
--- @param row SelectableRowComponent
local function selectRow(row)
  if selectedRow then selectedRow:SetSelected(false) end
  row:SetSelected(true)
  selectedRow = row
end

--- `onMeasure` for a FontString leaf.
--- @param fontString FontString
--- @param width integer
local function measureFontString(fontString, width)
  fontString:SetSize(width, 0)
  return width, fontString:GetStringHeight() + Widgets:Padding(1.5)
end

--- Adds an ability's header row to `container`, expandable to reveal a
--- selectable row per rank.
--- @param container WaffleFlexComponent
--- @param ability TameableAbility
--- @param onSelectRank fun(ability: TameableAbility, rank: TameableAbilityRank)
local function addAbilityGroup(container, ability, onSelectRank)
  local abilityGroup = container:AddColumn({ height = "AUTO" })

  --- @type WaffleFlexComponent
  local ranksColumn
  --- @type FontString
  local expandIcon

  -- Header: icon + name + expand/collapse indicator, the whole row clickable.
  local header = abilityGroup:AddRow({
    height = "AUTO",
    gap = Widgets:Padding(0.5),
    align = "CENTER",

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
      fontString:SetTextColor(Colors.White:GetRGB())
      fontString:SetTextToFit(ability.name)
      return fontString
    end,

    onMeasure = measureFontString
  })

  -- Expand/collapse indicator. Placeholder text until an icon exists.
  header:AddChild({
    width = 16,
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      expandIcon = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      expandIcon:SetJustifyH("RIGHT")
      expandIcon:SetTextColor(Colors.Grey:GetRGBA())
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

  for _, rank in ipairs(ability.ranks) do
    local rankRow = ranksColumn:AddRow({
      height = "AUTO",
      paddingLeft = Widgets:Padding(),
      paddingRight = Widgets:Padding(),
    })

    rankRow:AttachComponent(ComponentFactory:SelectableRow({
      labelText = ("%s %d"):format(L.RANK, rank.rank),
      onClick = function(row)
        selectRow(row)
        onSelectRank(ability, rank)
      end,
    }))
  end
end

-- ============================================================================
-- Sidebar
-- ============================================================================

--- @class SidebarOptions
--- @field onSelectOptions fun() Called when the Options row is selected.
--- @field onSelectRank fun(ability: TameableAbility, rank: TameableAbilityRank) Called when a rank row is selected.

--- Builds and returns a root component describing the Sidebar.
--- @param options SidebarOptions
--- @return WaffleFlexComponent root
function Sidebar:Build(options)
  local root = ComponentFactory:ScrollPanel()

  --- @type SelectableRowComponent
  local optionsRow = root.ScrollChild:AttachComponent(ComponentFactory:SelectableRow({
    labelText = L.OPTIONS,
    marginBottom = Widgets:Padding(2),
    onClick = function(row)
      selectRow(row)
      options.onSelectOptions()
    end,
  }))

  -- Select Options by default.
  selectRow(optionsRow)
  options.onSelectOptions()

  -- Ability rows, sorted by name.
  local abilities = {}
  for _, ability in pairs(TameableAbilities) do
    abilities[#abilities + 1] = ability
  end
  table.sort(abilities, function(a, b) return a.name < b.name end)

  for _, ability in ipairs(abilities) do
    addAbilityGroup(root.ScrollChild, ability, options.onSelectRank)
  end

  return root
end
