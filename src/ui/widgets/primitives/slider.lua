local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class SliderWidgetOptions : FrameWidgetOptions
--- @field orientation? "VERTICAL" | "HORIZONTAL"
--- @field minValue? number
--- @field maxValue? number

-- =============================================================================
-- Widgets - Slider
-- =============================================================================

--- Creates a basic slider.
--- @param options SliderWidgetOptions
--- @return SliderWidget frame
function Widgets:Slider(options)
  -- Defaults.
  options.name = options.name or Widgets:GetUniqueName("Slider")
  options.frameType = "Slider"
  options.width = options.width or 12
  options.height = options.height or 12
  options.orientation = options.orientation or "VERTICAL"
  options.minValue = options.minValue or 0
  options.maxValue = options.maxValue or 1

  --- @class SliderWidget : FrameWidget, Slider
  local frame = self:Frame(options)
  frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
  frame:SetBackdropBorderColor(Colors.DarkGrey:GetRGBA(0.5))

  frame:SetOrientation(options.orientation)
  frame:SetValueStep(1)
  frame:SetMinMaxValues(options.minValue, options.maxValue)
  frame:SetValue(options.minValue)

  -- Thumb texture.
  frame.texture = frame:CreateTexture("$parent_Texture", "ARTWORK")
  frame.texture:SetColorTexture(Colors.White:GetRGBA(0.25))
  frame:SetThumbTexture(frame.texture)

  -- Set texture size.
  if options.orientation == "VERTICAL" then
    local size = frame:GetWidth()
    frame.texture:SetSize(size, size * 2)
  else
    local size = frame:GetHeight()
    frame.texture:SetSize(size * 1.25, size)
  end

  frame:SetScript("OnMouseDown", function()
    frame.texture:SetColorTexture(Colors.White:GetRGBA(0.5))
  end)

  frame:SetScript("OnMouseUp", function()
    frame.texture:SetColorTexture(Colors.White:GetRGBA(0.25))
  end)

  return frame
end
