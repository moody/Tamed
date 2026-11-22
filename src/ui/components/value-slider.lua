local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

--- Height of the slider, which is the height of its thumb.
local SLIDER_HEIGHT = 14

--- Width of the thumb.
local THUMB_WIDTH = 8

--- Height of the track behind the thumb.
local TRACK_HEIGHT = 4

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ValueSliderOptions
--- @field minValue integer
--- @field maxValue integer
--- @field onChange fun(value: integer) Called with the new value while the slider is dragged.

-- =============================================================================
-- ComponentFactory - ValueSlider
-- =============================================================================

--- Creates a horizontal slider that stops at whole values.
--- @param options ValueSliderOptions
--- @return ValueSliderComponent root
function ComponentFactory:ValueSlider(options)
  local isSyncing = false

  --- @class ValueSliderComponent : WaffleFlexComponent<SliderWidget>
  local root = Addon.Waffle:Flex({
    height = SLIDER_HEIGHT,

    --- @param parent Frame
    frameFactory = function(parent)
      local slider = Widgets:Slider({
        parent = parent,
        orientation = "HORIZONTAL",
        height = SLIDER_HEIGHT,
        minValue = options.minValue,
        maxValue = options.maxValue,
      })
      slider:SetBackdropColor(0, 0, 0, 0)
      slider:SetBackdropBorderColor(0, 0, 0, 0)

      -- Thin dark line behind the thumb.
      local track = slider:CreateTexture("$parent_Track", "BACKGROUND")
      track:SetColorTexture(Colors.Black:GetRGBA(0.5))
      track:SetPoint("LEFT")
      track:SetPoint("RIGHT")
      track:SetHeight(TRACK_HEIGHT)

      -- Part of the track up to the thumb's center.
      local fill = slider:CreateTexture("$parent_Fill", "BORDER")
      fill:SetColorTexture(Colors.Green:GetRGBA(0.8))
      fill:SetPoint("LEFT", track, "LEFT")
      fill:SetPoint("RIGHT", slider.texture, "CENTER")
      fill:SetHeight(TRACK_HEIGHT)

      slider.texture:SetSize(THUMB_WIDTH, SLIDER_HEIGHT)

      local isHovered = false
      local isDragging = false

      --- Brightens the thumb while hovered, and colors it while dragged.
      local function refreshThumb()
        local color = Colors.Grey
        if isDragging then
          color = Colors.Green
        elseif isHovered then
          color = Colors.White
        end

        slider.texture:SetColorTexture(color:GetRGBA())
      end

      slider:SetScript("OnEnter", function()
        isHovered = true
        refreshThumb()
      end)
      slider:SetScript("OnLeave", function()
        isHovered = false
        refreshThumb()
      end)
      slider:SetScript("OnMouseDown", function()
        isDragging = true
        refreshThumb()
      end)
      slider:SetScript("OnMouseUp", function()
        isDragging = false
        refreshThumb()
      end)
      slider:SetScript("OnValueChanged", function(_, value)
        if not isSyncing then options.onChange(math.floor(value + 0.5)) end
      end)
      refreshThumb()

      return slider
    end,
  })

  --- Moves the slider to the given value, without calling `onChange`.
  --- @param value integer
  function root:SetValue(value)
    self:WhenFrameReady(function(slider)
      isSyncing = true
      slider:SetValue(value)
      isSyncing = false
    end)
  end

  return root
end
