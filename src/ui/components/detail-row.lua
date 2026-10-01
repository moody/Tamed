local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class DetailRowOptions
--- @field labelText string
--- @field valueText? string

-- =============================================================================
-- ComponentFactory - DetailRow
-- =============================================================================

--- Creates a gold label beside a white value. The value wraps, growing the row.
--- @param options DetailRowOptions
--- @return DetailRowComponent root
function ComponentFactory:DetailRow(options)
  local valueText = options.valueText or ""

  --- @class DetailRowComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = "AUTO",
    align = "START",
    gap = Widgets:Padding(0.5),
  })

  root:AddChild({
    width = 110,
    height = 18,

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("LEFT")
      fontString:SetJustifyV("TOP")
      fontString:SetText(options.labelText)
      return fontString
    end,
  })

  local valueNode = root:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("LEFT")
      fontString:SetJustifyV("TOP")
      fontString:SetWordWrap(true)
      fontString:SetTextColor(Colors.White:GetRGB())
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
  function root:SetText(text)
    valueText = text
    local fontString = valueNode:GetFrame()
    if fontString then fontString:SetText(text) end
    self:MarkDirty()
  end

  return root
end
