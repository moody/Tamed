local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ButtonWidgetOptions : FrameWidgetOptions
--- @field labelText string
--- @field labelColor? Color
--- @field onClick? fun(self: ButtonWidget, button: string)
--- @field onEnter? fun(self: ButtonWidget)
--- @field onLeave? fun(self: ButtonWidget)

-- =============================================================================
-- Widgets - Button
-- =============================================================================

--- Creates a basic button.
--- @param options ButtonWidgetOptions
--- @return ButtonWidget frame
function Widgets:Button(options)
  -- Defaults.
  options.name = options.name or Widgets:GetUniqueName("Button")
  options.frameType = "Button"
  options.labelColor = options.labelColor or Colors.Green

  --- @class ButtonWidget : FrameWidget, Button
  local frame = self:Frame(options)

  -- Background texture.
  frame.background = frame:CreateTexture("$parent_Background", "BACKGROUND", nil, -8)
  frame.background:SetColorTexture(Colors.Backdrop:GetRGBA(1))
  frame.background:SetAllPoints()

  -- Label text.
  frame.label = frame:CreateFontString("$parent_Label", "ARTWORK", "GameFontNormal")
  frame.label:SetText(options.labelText)
  frame.label:SetPoint("LEFT", frame, self:Padding(0.5), 0)
  frame.label:SetPoint("RIGHT", frame, -self:Padding(0.5), 0)
  frame.label:SetWordWrap(false)
  frame:SetFontString(frame.label)

  local function setNormalColors()
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.75))
    frame:SetBackdropBorderColor(Colors.Black:GetRGBA(1))
    frame.label:SetTextColor(options.labelColor:GetRGBA(1))
  end

  local function setHighlightColors()
    frame:SetBackdropColor(options.labelColor:GetRGBA(0.25))
    frame:SetBackdropBorderColor(options.labelColor:GetRGBA(1))
    frame.label:SetTextColor(Colors.White:GetRGBA(1))
  end

  -- Initialize colors.
  setNormalColors()

  -- Scripts.
  frame:SetScript("OnClick", function(self, button)
    if options.onClick then options.onClick(self, button) end
  end)

  frame:HookScript("OnEnter", function(self)
    setHighlightColors()
    if options.onEnter then options.onEnter(self) end
  end)

  frame:HookScript("OnLeave", function(self)
    setNormalColors()
    if options.onLeave then options.onLeave(self) end
  end)

  return frame
end
