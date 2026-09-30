local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class SelectableRowOptions
--- @field labelText string
--- @field marginBottom? integer
--- @field onClick fun(self: SelectableRowComponent)

-- =============================================================================
-- ComponentFactory - SelectableRow
-- =============================================================================

--- Creates a button row that highlights while selected or hovered.
--- @param options SelectableRowOptions
--- @return SelectableRowComponent root
function ComponentFactory:SelectableRow(options)
  local root
  local isSelected = false

  --- Applies selected or normal colors.
  --- @param frame ButtonWidget
  local function updateSelectionColors(frame)
    if isSelected then
      frame:SetBackdropColor(Colors.Gold:GetRGBA(0.1))
      frame.label:SetTextColor(Colors.Gold:GetRGBA())
    else
      frame:SetBackdropColor(0, 0, 0, 0)
      frame.label:SetTextColor(Colors.White:GetRGBA())
    end
  end

  --- @class SelectableRowComponent : WaffleFlexComponent
  root = Addon.Waffle:Flex({
    height = "AUTO",
    marginBottom = options.marginBottom,

    frameFactory = function(parent)
      local frame = Widgets:Button({
        parent = parent,
        labelText = options.labelText,
        labelColor = Colors.White,
        onClick = function() options.onClick(root) end
      })

      frame.label:SetJustifyH("LEFT")

      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:SetScript("OnEnter", function()
        if not isSelected then frame:SetBackdropColor(Colors.White:GetRGBA(0.1)) end
      end)
      frame:SetScript("OnLeave", function()
        if not isSelected then frame:SetBackdropColor(0, 0, 0, 0) end
      end)

      updateSelectionColors(frame)

      return frame
    end,

    --- @param frame ButtonWidget
    --- @param width number
    --- @return number, number
    onMeasure = function(frame, width)
      frame.label:SetSize(width, 0)
      return width, frame.label:GetStringHeight() + Widgets:Padding(1.5)
    end
  })

  --- Sets whether the row is selected.
  --- @param selected boolean
  function root:SetSelected(selected)
    isSelected = selected
    local frame = self:GetFrame()
    if frame then updateSelectionColors(frame) end
  end

  return root
end
