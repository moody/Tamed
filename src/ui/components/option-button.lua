local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class OptionButtonOptions
--- @field labelText string
--- @field tooltipText string
--- @field get fun(): boolean
--- @field set fun(value: boolean)

-- =============================================================================
-- ComponentFactory - OptionButton
-- =============================================================================

--- Creates a button with a label and checkbox that toggles on click and shows
--- `tooltipText` on hover.
--- @param options OptionButtonOptions
--- @return WaffleFlexComponent root
function ComponentFactory:OptionButton(options)
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    maxWidth = 200,
    height = "AUTO",
    align = "CENTER",
    gap = Widgets:Padding(0.5),
    paddingTop = Widgets:Padding(0.5),
    paddingBottom = Widgets:Padding(0.5),
    paddingLeft = Widgets:Padding(),
    paddingRight = Widgets:Padding(),

    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })

      --- Sets the backdrop and border alpha.
      local function setColors(alpha)
        frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(alpha))
        frame:SetBackdropBorderColor(Colors.White:GetRGBA(alpha))
      end

      setColors(0.25)
      frame:SetScript("OnUpdate", function() frame:SetAlpha(options.get() and 1 or 0.5) end)
      frame:SetScript("OnClick", function() options.set(not options.get()) end)
      frame:SetScript("OnEnter", function(self)
        setColors(0.5)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetText(options.labelText, Colors.Gold:GetRGB())
        GameTooltip:AddLine(options.tooltipText, 1, 1, 1, true)
        GameTooltip:Show()
      end)
      frame:SetScript("OnLeave", function()
        setColors(0.25)
        GameTooltip:Hide()
      end)
      return frame
    end
  })

  -- Label text.
  root:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("LEFT")
      fontString:SetWordWrap(false)
      fontString:SetTextColor(Colors.White:GetRGB())
      fontString:SetText(options.labelText)
      return fontString
    end,

    onMeasure = function(fontString, width)
      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight() + Widgets:Padding(1.5)
    end
  })

  -- Checkbox.
  root:AddChild({
    width = 12,
    height = 12,
    frameFactory = function(parent)
      local checkBox = Widgets:CheckBox({
        parent = parent,
        color = Colors.White,
        get = options.get,
        set = options.set
      })
      checkBox:EnableMouse(false)
      return checkBox
    end
  })

  return root
end
