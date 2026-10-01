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

  --- Returns a bordered card for grouping rows.
  --- @param gap number
  --- @return WaffleFlexComponent card
  local function addCard(gap)
    return root:AddColumn({
      height = "AUTO",
      gap = gap,
      padding = Widgets:Padding(),

      --- @param parent Frame
      frameFactory = function(parent)
        return Widgets:Frame({ parent = parent })
      end,
    })
  end

  -- ------------------------------------------------------
  -- Heading Components
  -- ------------------------------------------------------

  -- Heading: addon icon and title.
  local heading = root:AddRow({
    height = 32,
    align = "CENTER",
    gap = Widgets:Padding(),
  })

  heading:AddChild({
    width = 24,
    height = 24,

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))

      local texture = frame:CreateTexture(nil, "ARTWORK")
      texture:SetPoint("TOPLEFT", 1, -1)
      texture:SetPoint("BOTTOMRIGHT", -1, 1)
      texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
      texture:SetTexture(Addon.ICON)

      return frame
    end,
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

  local optionsCard = addCard(0)

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

  root:AddChild({
    height = 24,

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
      fontString:SetJustifyH("LEFT")
      fontString:SetText(Colors.White(L.COMMANDS))
      return fontString
    end,
  })

  local commandsCard = addCard(Widgets:Padding(0.5))

  commandsCard:AttachComponent(ComponentFactory:DetailRow({ labelText = "/tamed", valueText = L.TOGGLE_UI }))
  commandsCard:AttachComponent(ComponentFactory:DetailRow({ labelText = "/tamed clear", valueText = L.CLEAR_PINS }))

  commandsCard:AddChild({
    height = 24,
    marginTop = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:Button({
        parent = parent,
        labelText = L.CLEAR_PINS,
        onClick = function() PinHelper:Clear() end,
      })
    end,
  })

  return root
end
