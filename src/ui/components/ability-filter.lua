local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class AbilityFilterOptions
--- @field abilities TameableAbility[] The abilities to show, in order.
--- @field onChange fun() Called when the selection changes.

-- =============================================================================
-- ComponentFactory - AbilityFilter
-- =============================================================================

--- Creates a labeled grid of ability icons that are selected by clicking. Hovering an icon shows the spell
--- tooltip of its highest rank.
--- @param options AbilityFilterOptions
--- @return AbilityFilterComponent root
function ComponentFactory:AbilityFilter(options)
  --- @type table<TameableAbility, boolean>
  local isSelected = {}

  --- The abilities that can be selected, or `nil` if any can.
  --- @type table<TameableAbility, boolean>?
  local available

  --- Functions that refresh each icon.
  --- @type fun()[]
  local iconRefreshers = {}

  -- ------------------------------------------------------
  -- Local Functions
  -- ------------------------------------------------------

  --- Returns `true` if the ability is selected, or can be.
  --- @param ability TameableAbility
  --- @return boolean
  local function isEnabled(ability)
    return isSelected[ability] == true or available == nil or available[ability] == true
  end

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  --- @class AbilityFilterComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "COLUMN",
    height = "AUTO",
    gap = Widgets:Padding(0.5),
  })

  -- Label, selected abilities, and clear button.
  local header = root:AddRow({
    height = "AUTO",
    align = "CENTER",
    gap = Widgets:Padding(),
  })

  --- The label, followed by the names of the selected abilities.
  local headerText = header:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
      fontString:SetJustifyH("LEFT")
      fontString:SetWordWrap(false)
      fontString:SetText(Colors.Grey(L.FILTER_BY_ABILITY))
      return fontString
    end,

    onMeasure = function(fontString, width)
      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight()
    end,
  })

  local clearButton = header:AddChild({
    width = 56,
    height = 18,
    visibility = "INVISIBLE",

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:Button({
        parent = parent,
        labelText = L.CLEAR,
        onClick = function()
          for ability in pairs(isSelected) do isSelected[ability] = nil end
          root:Refresh()
          options.onChange()
        end,
      })
    end,
  })

  --- Refreshes the header and each icon.
  function root:Refresh()
    local names = {}
    for _, ability in ipairs(self:GetSelected()) do names[#names + 1] = ability.name end

    local text = Colors.Grey(L.FILTER_BY_ABILITY)
    if #names > 0 then
      text = text .. Colors.Grey(" · ") .. Colors.White(table.concat(names, Colors.Grey(" + ")))
    end
    headerText:WhenFrameReady(function(fontString) fontString:SetText(text) end)
    clearButton:SetVisibility(#names > 0 and "VISIBLE" or "INVISIBLE")

    for _, refreshIcon in ipairs(iconRefreshers) do refreshIcon() end
  end

  --- Returns the selected abilities, in the order given.
  --- @return TameableAbility[]
  function root:GetSelected()
    local selected = {}
    for _, ability in ipairs(options.abilities) do
      if isSelected[ability] then selected[#selected + 1] = ability end
    end
    return selected
  end

  --- Sets the abilities that can be selected, or any if omitted. The rest are greyed out unless selected.
  --- @param abilities? table<TameableAbility, boolean>
  function root:SetAvailable(abilities)
    available = abilities
    self:Refresh()
  end

  -- ------------------------------------------------------
  -- Icons Components
  -- ------------------------------------------------------

  -- Icons, wrapping onto new lines.
  local grid = root:AddRow({
    height = "AUTO",
    wrap = true,
    gap = Widgets:Padding(0.5),
    lineGap = Widgets:Padding(0.5),
  })

  for _, ability in ipairs(options.abilities) do
    grid:AddChild({
      width = 24,
      height = 24,

      --- @param parent Frame
      frameFactory = function(parent)
        local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
        frame:SetBackdropColor(0, 0, 0, 0)

        local icon = frame:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", -1, 1)
        icon:SetTexture(ability.icon)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local isHovered = false

        --- Shows the icon full color with a green border if selected, greyed out if it cannot be selected,
        --- and slightly dimmed otherwise.
        local function refreshIcon()
          local selected = isSelected[ability] == true
          local enabled = isEnabled(ability)

          local alpha = 0.85
          if not enabled then
            alpha = 0.25
          elseif selected then
            alpha = 1
          end
          icon:SetAlpha(alpha)
          icon:SetDesaturated(not enabled)

          local border = Colors.Black
          if enabled and isHovered then
            border = Colors.White
          elseif selected then
            border = Colors.Green
          end
          frame:SetBackdropBorderColor(border:GetRGBA())
        end

        iconRefreshers[#iconRefreshers + 1] = refreshIcon

        frame:SetScript("OnClick", function()
          if not isEnabled(ability) then return end
          if isSelected[ability] then
            isSelected[ability] = nil
          else
            isSelected[ability] = true
          end
          root:Refresh()
          options.onChange()
        end)

        frame:SetScript("OnEnter", function()
          isHovered = true
          refreshIcon()
          GameTooltip:SetOwner(frame, "ANCHOR_TOP")
          GameTooltip:SetHyperlink("spell:" .. ability.ranks[#ability.ranks].spell_id)
          GameTooltip:Show()
        end)

        frame:SetScript("OnLeave", function()
          isHovered = false
          refreshIcon()
          GameTooltip:Hide()
        end)

        refreshIcon()

        return frame
      end,
    })
  end

  return root
end
