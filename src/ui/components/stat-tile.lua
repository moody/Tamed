local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class StatTileOptions
--- @field labelText string
--- @field valueFont? string Font object name of the value. Defaults to `GameFontNormalLarge`.

-- =============================================================================
-- ComponentFactory - StatTile
-- =============================================================================

--- Creates a tile with a small grey label above a white value. The value wraps, growing the tile.
--- @param options StatTileOptions
--- @return StatTileComponent root
function ComponentFactory:StatTile(options)
  local valueText = ""
  local isMuted = false

  --- Colors the value white, or grey when muted.
  --- @param fontString FontString
  local function colorValue(fontString)
    local color = isMuted and Colors.Grey or Colors.White
    fontString:SetTextColor(color:GetRGB())
  end

  --- @class StatTileComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "COLUMN",
    height = "AUTO",
    padding = Widgets:Padding(),
    gap = Widgets:Padding(0.25),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.04))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      return frame
    end,
  })

  root:AddChild({
    height = 14,

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
      fontString:SetJustifyH("LEFT")
      fontString:SetTextColor(Colors.Grey:GetRGB())
      fontString:SetText(options.labelText)
      return fontString
    end,
  })

  local valueNode = root:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", options.valueFont or "GameFontNormalLarge")
      fontString:SetJustifyH("LEFT")
      fontString:SetJustifyV("TOP")
      fontString:SetWordWrap(true)
      colorValue(fontString)
      fontString:SetText(valueText)
      return fontString
    end,

    onMeasure = function(fontString, width)
      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight()
    end,
  })

  --- Sets the value text.
  --- @param text string
  --- @param muted? boolean Shows the value in grey.
  function root:SetText(text, muted)
    valueText = text
    isMuted = muted == true
    local fontString = valueNode:GetFrame()
    if fontString then
      colorValue(fontString)
      fontString:SetText(text)
    end
    self:MarkDirty()
  end

  return root
end
