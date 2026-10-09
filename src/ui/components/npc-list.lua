local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local L = Addon:GetModule("Locale")
local TameableNPCs = Addon:GetModule("TameableNPCs")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class NpcListOptions
--- @field showAbilities? boolean Passed on to each `NpcCard`.

-- =============================================================================
-- ComponentFactory - NpcList
-- =============================================================================

--- Creates a fixed number of NPC cards scrolled by a slider and the mouse
--- wheel, or "None" when there are no NPCs to show.
--- @param options? NpcListOptions
--- @return NpcListComponent root
function ComponentFactory:NpcList(options)
  options = options or {}

  local Components = {}

  local NUM_NPC_CARDS = 7

  --- Ids of the NPCs shown, in display order.
  --- @type string[]
  local npcIds = {}

  -- ------------------------------------------------------
  -- Local Functions
  -- ------------------------------------------------------

  --- Fills the NPC cards from the scroll offset and updates the slider.
  local function refreshNpcCards()
    --- @type SliderWidget
    local slider = Components.NpcSlider:GetFrame()
    local offset = math.floor(slider:GetValue() + 0.5)

    for i, card in ipairs(Components.NpcCards) do
      local npc_id = npcIds[i + offset]
      local npc = npc_id and TameableNPCs[npc_id]
      card:SetNpc(npc)
      card:SetVisibility(npc and "VISIBLE" or "INVISIBLE")
    end

    local isEmpty = #npcIds == 0
    Components.NpcCardColumn:SetVisibility(isEmpty and "GONE" or "VISIBLE")
    Components.NpcEmptyText:SetVisibility(isEmpty and "VISIBLE" or "GONE")

    local maxScroll = math.max(#npcIds - NUM_NPC_CARDS, 0)
    slider:SetMinMaxValues(0, maxScroll)
    Components.NpcSlider:SetVisibility(maxScroll <= 0 and "GONE" or "VISIBLE")
  end

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  -- Cards and slider.
  --- @class NpcListComponent : WaffleFlexComponent
  Components.Root = Addon.Waffle:Flex({
    direction = "ROW",
    padding = Widgets:Padding(),
    gap = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:EnableMouseWheel(true)
      frame:SetScript("OnMouseWheel", function(_, delta)
        local slider = Components.NpcSlider:GetFrame()
        if slider then slider:SetValue(slider:GetValue() - delta) end
      end)
      return frame
    end,
  })

  --- Shows the given NPCs, in order, scrolled to the top.
  --- @param newNpcIds string[]
  function Components.Root:SetNpcIds(newNpcIds)
    npcIds = newNpcIds
    Components.NpcSlider:GetFrame():SetValue(0)
    refreshNpcCards()
    self:MarkDirty()
  end

  -- ------------------------------------------------------
  -- Child Components
  -- ------------------------------------------------------

  -- Cards split this column's height evenly.
  Components.NpcCardColumn = Components.Root:AddColumn({
    gap = Widgets:Padding(0.5),
  })

  -- Shown instead of the cards when there are no NPCs.
  Components.NpcEmptyText = Components.Root:AddChild({
    visibility = "GONE",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("CENTER")
      fontString:SetJustifyV("MIDDLE")
      fontString:SetText(Colors.Grey(L.NONE))
      return fontString
    end,
  })

  Components.NpcSlider = Components.Root:AddChild({
    width = 12,

    --- @param parent Frame
    frameFactory = function(parent)
      local slider = Widgets:Slider({ parent = parent })
      slider:SetScript("OnValueChanged", refreshNpcCards)
      return slider
    end,
  })

  --- @type NpcCardComponent[]
  Components.NpcCards = {}
  for i = 1, NUM_NPC_CARDS do
    local card = ComponentFactory:NpcCard({ showAbilities = options.showAbilities })
    card:SetVisibility("INVISIBLE")
    Components.NpcCards[i] = Components.NpcCardColumn:AttachComponent(card)
  end

  return Components.Root
end
