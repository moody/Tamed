local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class SectionTitleOptions
--- @field titleText string

-- =============================================================================
-- ComponentFactory - SectionTitle
-- =============================================================================

--- Creates a small white title with a thin rule underneath. Anything added to it sits at the right end.
--- @param options SectionTitleOptions
--- @return SectionTitleComponent root
function ComponentFactory:SectionTitle(options)
  --- @class SectionTitleComponent : WaffleFlexComponent<SectionTitleFrame>
  local root = Addon.Waffle:Flex({
    height = 24,
    justify = "END",
    align = "END",

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class SectionTitleFrame : Frame
      --- @field text FontString
      local frame = CreateFrame("Frame", nil, parent)

      frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      frame.text:SetPoint("BOTTOMLEFT", 0, Widgets:Padding(0.5))
      frame.text:SetJustifyH("LEFT")
      frame.text:SetTextColor(Colors.White:GetRGB())
      frame.text:SetText(options.titleText)

      local rule = frame:CreateTexture(nil, "ARTWORK")
      rule:SetColorTexture(Colors.White:GetRGBA(0.1))
      rule:SetHeight(1)
      rule:SetPoint("BOTTOMLEFT")
      rule:SetPoint("BOTTOMRIGHT")

      return frame
    end,
  })

  --- Sets the title text.
  --- @param text string
  function root:SetTitleText(text)
    self:WhenFrameReady(function(frame)
      frame.text:SetText(text)
    end)
  end

  return root
end
