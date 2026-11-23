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

--- Width and height of the buttons at the ends.
local BUTTON_SIZE = 20

--- Length of the bars in a button's symbol.
local SYMBOL_LENGTH = 10

--- Thickness of the bars in a button's symbol.
local SYMBOL_THICKNESS = 2

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class ValueSliderOptions
--- @field minValue integer
--- @field maxValue integer
--- @field onChange fun(value: integer) Called with the new value when the user changes it.

-- =============================================================================
-- ComponentFactory - ValueSlider
-- =============================================================================

--- Creates a horizontal slider of whole values, with a button at each end that moves it by one.
--- The mouse wheel over the slider does the same.
--- @param options ValueSliderOptions
--- @return ValueSliderComponent root
function ComponentFactory:ValueSlider(options)
  local Components = {}

  local isSyncing = false

  --- The last whole value the slider was at.
  local currentValue

  --- Moves the slider by `delta`, stopping at its ends.
  --- @param delta integer
  local function step(delta)
    --- @type SliderWidget
    local slider = Components.Slider:GetFrame()
    slider:SetValue(slider:GetValue() + delta)
  end

  --- @class ValueSliderComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = BUTTON_SIZE,
    align = "CENTER",
    gap = Widgets:Padding(0.5),
  })

  --- Adds a button that moves the slider by `delta`, with a minus or a plus.
  --- @param delta integer
  local function addStepButton(delta)
    root:AddChild({
      width = BUTTON_SIZE,
      height = BUTTON_SIZE,

      --- @param parent Frame
      frameFactory = function(parent)
        local button = Widgets:Button({
          parent = parent,
          labelText = "",
          onClick = function() step(delta) end,
        })

        -- A plus is a second bar across the first.
        local bars = {}
        bars[1] = button:CreateTexture(nil, "ARTWORK")
        bars[1]:SetSize(SYMBOL_LENGTH, SYMBOL_THICKNESS)
        if delta > 0 then
          bars[2] = button:CreateTexture(nil, "ARTWORK")
          bars[2]:SetSize(SYMBOL_THICKNESS, SYMBOL_LENGTH)
        end

        --- Colors the symbol.
        --- @param color Color
        local function colorSymbol(color)
          for _, bar in ipairs(bars) do
            bar:SetPoint("CENTER")
            bar:SetColorTexture(color:GetRGBA())
          end
        end

        colorSymbol(Colors.Green)
        button:HookScript("OnEnter", function() colorSymbol(Colors.White) end)
        button:HookScript("OnLeave", function() colorSymbol(Colors.Green) end)

        return button
      end,
    })
  end

  addStepButton(-1)

  Components.Slider = root:AddChild({
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
      slider:EnableMouseWheel(true)

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
      slider:SetScript("OnMouseWheel", function(_, delta)
        step(delta)
      end)
      slider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        local isChanged = value ~= currentValue
        currentValue = value
        if isChanged and not isSyncing then options.onChange(value) end
      end)
      refreshThumb()

      return slider
    end,
  })

  addStepButton(1)

  --- Moves the slider to the given value, without calling `onChange`.
  --- @param value integer
  function root:SetValue(value)
    Components.Slider:WhenFrameReady(function(slider)
      isSyncing = true
      slider:SetValue(value)
      isSyncing = false
    end)
  end

  return root
end
