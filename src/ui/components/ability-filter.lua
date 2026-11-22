local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

--- Width and height of an ability icon.
local ICON_SIZE = 24

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class AbilityFilterOptions
--- @field abilities TameableAbility[] The abilities to show, in order.
--- @field onChange fun() Called when an ability is selected or deselected.

-- =============================================================================
-- ComponentFactory - AbilityFilter
-- =============================================================================

--- Creates a wrapping grid of ability icons that are selected and deselected by clicking. Hovering
--- shows the spell tooltip of the ability's highest rank.
--- @param options AbilityFilterOptions
--- @return AbilityFilterComponent root
function ComponentFactory:AbilityFilter(options)
  --- @type table<TameableAbility, true>
  local isSelected = {}

  --- @class AbilityFilterComponent : WaffleFlexComponent
  local root = Addon.Waffle:Flex({
    direction = "ROW",
    height = "AUTO",
    wrap = true,
    gap = Widgets:Padding(0.5),
    lineGap = Widgets:Padding(0.5),
  })

  --- Returns the selected abilities, in the order given.
  --- @return TameableAbility[]
  function root:GetSelected()
    local selected = {}
    for _, ability in ipairs(options.abilities) do
      if isSelected[ability] then selected[#selected + 1] = ability end
    end
    return selected
  end

  for _, ability in ipairs(options.abilities) do
    root:AddChild({
      width = ICON_SIZE,
      height = ICON_SIZE,

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

        --- Shows a selected icon in full color with a green border, and the others dimmed.
        local function refresh()
          local selected = isSelected[ability] == true
          icon:SetAlpha(selected and 1 or 0.45)

          local border = Colors.Black
          if isHovered then
            border = Colors.White
          elseif selected then
            border = Colors.Green
          end
          frame:SetBackdropBorderColor(border:GetRGBA())
        end

        frame:SetScript("OnClick", function()
          isSelected[ability] = not isSelected[ability] or nil
          refresh()
          options.onChange()
        end)

        frame:SetScript("OnEnter", function()
          isHovered = true
          refresh()
          GameTooltip:SetOwner(frame, "ANCHOR_TOP")
          GameTooltip:SetHyperlink("spell:" .. ability.ranks[#ability.ranks].spell_id)
          GameTooltip:Show()
        end)

        frame:SetScript("OnLeave", function()
          isHovered = false
          refresh()
          GameTooltip:Hide()
        end)

        refresh()

        return frame
      end,
    })
  end

  return root
end
