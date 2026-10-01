local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")

--- @class Widgets
local Widgets = Addon:GetModule("Widgets")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class FrameWidgetOptions
--- @field name? string
--- @field frameType? string
--- @field parent? table
--- @field points? table[]
--- @field width? integer
--- @field height? integer
--- @field frameStrata? FrameStrata
--- @field enableDragging? boolean Lets the frame be dragged, and raises it above other frames when shown or clicked.

-- =============================================================================
-- Widgets - Frame
-- =============================================================================

--- Creates a basic frame with a backdrop.
--- @param options FrameWidgetOptions
--- @return FrameWidget frame
function Widgets:Frame(options)
  -- Defaults.
  options.name = options.name or Widgets:GetUniqueName("Frame")
  options.frameType = options.frameType or "Frame"
  options.parent = options.parent or UIParent
  options.width = options.width or 1
  options.height = options.height or 1

  --- @class FrameWidget : Frame, BackdropTemplate
  local frame = CreateFrame(options.frameType, options.name, options.parent)

  -- Strata.
  if type(options.frameStrata) == "string" then
    frame:SetFrameStrata(options.frameStrata)
  end

  -- Backdrop.
  Mixin(frame, BackdropTemplateMixin)
  frame:SetBackdrop(self.BORDER_BACKDROP)
  frame:SetBackdropColor(Colors.Backdrop:GetRGBA(0.95))
  frame:SetBackdropBorderColor(Colors.Black:GetRGBA(1))

  -- Size.
  frame:SetWidth(options.width)
  frame:SetHeight(options.height)

  -- Points.
  if options.points then
    for _, point in ipairs(options.points) do
      frame:SetPoint(unpack(point))
    end
  end

  -- Dragging.
  if options.enableDragging then
    frame:SetToplevel(true)
    frame:HookScript("OnShow", frame.Raise)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  end

  return frame
end
