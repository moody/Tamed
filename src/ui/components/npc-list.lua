local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class NpcListColumnLabel
--- @field justify "LEFT" | "CENTER" | "RIGHT"
--- @field width? integer Without it, the label takes the width left over.
--- @field text string

--- @class NpcListOptions
--- @field numCards integer How many NPCs show at once.
--- @field columnLabels NpcListColumnLabel[] Labels above the cards, lined up with the card's columns.
--- @field emptyText string Shown instead of the cards when there are no entries.
--- @field cardOptions? NpcCardOptions
--- @field getAbilitiesText? fun(entry: NpcListEntry): string Returns the text of an entry's abilities line.

--- @class NpcListEntry
--- @field npc TameableNPC

-- =============================================================================
-- ComponentFactory - NpcList
-- =============================================================================

--- Width of the list's slider.
local SLIDER_WIDTH = 6

--- Creates a scrollable list of NPC cards under a band of column labels. Shows a fixed
--- number of cards at a time and fills its parent's remaining height.
--- @param options NpcListOptions
--- @return NpcListComponent root
function ComponentFactory:NpcList(options)
  local Components = {}

  --- @type NpcListEntry[]
  local currentEntries = {}

  -- ------------------------------------------------------
  -- Local Functions
  -- ------------------------------------------------------

  --- Fills the cards from the scroll offset and updates the slider.
  local function refreshCards()
    --- @type SliderWidget
    local slider = Components.Slider:GetFrame()
    local offset = math.floor(slider:GetValue() + 0.5)

    for i, card in ipairs(Components.Cards) do
      local entry = currentEntries[i + offset]
      if entry then
        card:SetNpc(entry.npc, options.getAbilitiesText and options.getAbilitiesText(entry))
      else
        card:SetNpc()
      end
      card:SetVisibility(entry and "VISIBLE" or "INVISIBLE")
    end

    -- An empty list shows no surface, header, or slider, only the empty text.
    local isEmpty = #currentEntries == 0
    Components.Root:GetFrame():SetBackdropColor(Colors.White:GetRGBA(isEmpty and 0 or 0.04))
    Components.ColumnLabels:SetVisibility(isEmpty and "GONE" or "VISIBLE")
    Components.CardColumn:SetVisibility(isEmpty and "GONE" or "VISIBLE")
    Components.EmptyText:SetVisibility(isEmpty and "VISIBLE" or "GONE")

    -- The track keeps its space on every list, so the right edge never shifts.
    -- Only the thumb hides when the list cannot scroll.
    local maxScroll = math.max(#currentEntries - options.numCards, 0)
    slider:SetMinMaxValues(0, maxScroll)
    slider.texture:SetShown(maxScroll > 0)
    Components.Slider:SetVisibility(isEmpty and "INVISIBLE" or "VISIBLE")
  end

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  --- @class NpcListComponent : WaffleFlexComponent<FrameWidget>
  Components.Root = Addon.Waffle:Flex({
    direction = "COLUMN",

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.04))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:EnableMouseWheel(true)
      frame:SetScript("OnMouseWheel", function(_, delta)
        local slider = Components.Slider:GetFrame()
        if slider then slider:SetValue(slider:GetValue() - delta) end
      end)
      return frame
    end,
  })

  --- Shows the given entries from the top of the list.
  --- @param entries NpcListEntry[]
  function Components.Root:SetEntries(entries)
    currentEntries = entries

    --- @type SliderWidget
    local slider = Components.Slider:GetFrame()

    -- Moving the slider refreshes the cards, so refresh them here only if it does not move.
    local isScrolled = slider:GetValue() ~= 0
    slider:SetValue(0)
    if not isScrolled then refreshCards() end

    self:MarkDirty()
  end

  -- ------------------------------------------------------
  -- Column Labels Components
  -- ------------------------------------------------------

  -- Column labels, in a band of their own. Right padding lines them up with the card text.
  Components.ColumnLabels = Components.Root:AddRow({
    height = 24,
    gap = Widgets:Padding(0.25),
    paddingLeft = Widgets:Padding(),
    paddingRight = Widgets:Padding() + Widgets:Padding(0.5) * 2 + SLIDER_WIDTH,

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.06))
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      local rule = frame:CreateTexture(nil, "BORDER")
      rule:SetColorTexture(Colors.White:GetRGBA(0.1))
      rule:SetHeight(1)
      rule:SetPoint("BOTTOMLEFT")
      rule:SetPoint("BOTTOMRIGHT")

      return frame
    end,
  })

  for _, label in ipairs(options.columnLabels) do
    Components.ColumnLabels:AddChild({
      width = label.width,

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        fontString:SetJustifyH(label.justify)
        fontString:SetText(Colors.LightGrey(label.text))
        return fontString
      end,
    })
  end

  -- ------------------------------------------------------
  -- Cards Components
  -- ------------------------------------------------------

  -- Cards and slider.
  local body = Components.Root:AddRow({
    gap = Widgets:Padding(0.5),
    paddingRight = Widgets:Padding(0.5),
  })

  -- Cards split this column's height evenly.
  Components.CardColumn = body:AddColumn({})

  -- Shown instead of the cards when there are no entries, under the labels' rule.
  Components.EmptyText = body:AddChild({
    visibility = "GONE",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("LEFT")
      fontString:SetJustifyV("TOP")
      fontString:SetText(Colors.Grey(options.emptyText))
      return fontString
    end,
  })

  -- Margins keep the thumb, which overhangs the track by half its height, inside the body.
  Components.Slider = body:AddChild({
    width = SLIDER_WIDTH,
    marginTop = SLIDER_WIDTH,
    marginBottom = SLIDER_WIDTH,

    --- @param parent Frame
    frameFactory = function(parent)
      local slider = Widgets:Slider({ parent = parent, width = SLIDER_WIDTH })
      slider:SetBackdropColor(Colors.Black:GetRGBA(0.3))
      slider:SetBackdropBorderColor(0, 0, 0, 0)
      slider:SetScript("OnValueChanged", refreshCards)
      return slider
    end,
  })

  --- @type NpcCardComponent[]
  Components.Cards = {}
  for i = 1, options.numCards do
    local card = ComponentFactory:NpcCard(options.cardOptions)
    card:SetVisibility("INVISIBLE")
    Components.Cards[i] = Components.CardColumn:AttachComponent(card)
  end

  return Components.Root
end
