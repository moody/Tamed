local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local MinimapIcon = Addon:GetModule("MinimapIcon")
local PinHelper = Addon:GetModule("PinHelper")
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

  --- Returns a card for grouping rows.
  --- @param gap number
  --- @param padding number
  --- @return WaffleFlexComponent card
  local function addCard(gap, padding)
    return root:AddColumn({
      height = "AUTO",
      gap = gap,
      padding = padding,

      --- @param parent Frame
      frameFactory = function(parent)
        local frame = Widgets:Frame({ parent = parent })
        frame:SetBackdropColor(Colors.White:GetRGBA(0.04))
        frame:SetBackdropBorderColor(0, 0, 0, 0)
        return frame
      end,
    })
  end

  -- ------------------------------------------------------
  -- Heading Components
  -- ------------------------------------------------------

  -- Heading: title.
  local heading = root:AddRow({
    height = 48,
    align = "CENTER",
  })

  heading:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
      fontString:SetJustifyH("LEFT")
      fontString:SetWordWrap(false)
      fontString:SetText(Colors.White(L.OPTIONS))
      return fontString
    end,

    onMeasure = function(fontString, width)
      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight()
    end,
  })

  -- ------------------------------------------------------
  -- Options Components
  -- ------------------------------------------------------

  root:AttachComponent(ComponentFactory:SectionTitle({ titleText = L.GENERAL }))

  -- The option rows have padding of their own.
  local optionsCard = addCard(0, Widgets:Padding(0.5))

  optionsCard:AttachComponent(ComponentFactory:OptionRow({
    labelText = L.MINIMAP_ICON,
    descriptionText = L.MINIMAP_ICON_DESCRIPTION,
    get = function() return MinimapIcon:IsEnabled() end,
    set = function(value) MinimapIcon:SetEnabled(value) end,
  }))

  optionsCard:AttachComponent(ComponentFactory:OptionRow({
    labelText = L.NPC_TOOLTIPS,
    descriptionText = L.NPC_TOOLTIPS_DESCRIPTION,
    get = function() return StateManager:GetState().npc_tooltips end,
    set = function(value) StateManager:SetNpcTooltipsEnabled(value) end,
  }))

  -- ------------------------------------------------------
  -- Commands Components
  -- ------------------------------------------------------

  root:AttachComponent(ComponentFactory:SectionTitle({ titleText = L.COMMANDS }))

  local commandsCard = addCard(Widgets:Padding(0.5), Widgets:Padding())

  commandsCard:AttachComponent(ComponentFactory:DetailRow({ labelText = "/tamed", valueText = L.TOGGLE_UI }))

  -- The `/tamed clear` row, with its action in place of a description.
  local clearRow = commandsCard:AddRow({
    height = 24,
    align = "CENTER",
    gap = Widgets:Padding(0.5),
  })

  clearRow:AddChild({
    width = 110,
    height = 18,

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("LEFT")
      fontString:SetTextColor(Colors.White:GetRGB())
      fontString:SetText("/tamed clear")
      return fontString
    end,
  })

  clearRow:AddChild({
    width = 120,
    height = 24,

    --- @param parent Frame
    frameFactory = function(parent)
      --- Colors the button flat, brighter while hovered.
      --- @param button ButtonWidget
      --- @param isHovered boolean
      local function setFlatColors(button, isHovered)
        button:SetBackdropColor(Colors.White:GetRGBA(isHovered and 0.12 or 0.06))
        button:SetBackdropBorderColor(0, 0, 0, 0)
      end

      local button = Widgets:Button({
        parent = parent,
        labelText = L.CLEAR_PINS,
        onClick = function() PinHelper:Clear() end,
        onEnter = function(target) setFlatColors(target, true) end,
        onLeave = function(target) setFlatColors(target, false) end,
      })
      setFlatColors(button, false)

      return button
    end,
  })

  return root
end
