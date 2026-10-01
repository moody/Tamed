local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local GetCoinTextureString = C_CurrencyInfo and C_CurrencyInfo.GetCoinTextureString or GetCoinTextureString
local L = Addon:GetModule("Locale")
local TameableNPCs = Addon:GetModule("TameableNPCs")
local Widgets = Addon:GetModule("Widgets")

--- @class RankScreen
local RankScreen = Addon:GetModule("RankScreen")

-- ============================================================================
-- RankScreen
-- ============================================================================

--- Builds and returns a root component describing the Rank Screen.
--- @return RankScreenComponent root
function RankScreen:Build()
  local Components = {}

  local NUM_NPC_CARDS = 7

  --- @type TameableAbilityRank?
  local currentRank

  --- Ids of NPCs teaching `currentRank`, sorted by name.
  --- @type string[]
  local currentNpcIds = {}

  -- ------------------------------------------------------
  -- Local Functions
  -- ------------------------------------------------------

  --- Adds a label/value row to `container`. The value wraps, growing the row.
  --- @param container WaffleFlexComponent
  --- @param labelText string
  --- @return WaffleFlexComponent valueNode
  local function addDetailRow(container, labelText)
    local row = container:AddRow({ height = "AUTO", align = "START", gap = Widgets:Padding(0.5) })

    row:AddChild({
      width = 110,
      height = 18,

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fontString:SetJustifyH("LEFT")
        fontString:SetJustifyV("TOP")
        fontString:SetText(labelText)
        return fontString
      end,
    })

    return row:AddChild({
      height = "AUTO",

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        fontString:SetJustifyH("LEFT")
        fontString:SetJustifyV("TOP")
        fontString:SetWordWrap(true)
        fontString:SetTextColor(Colors.White:GetRGB())
        return fontString
      end,

      onMeasure = function(fontString, width)
        fontString:SetSize(width, 0)
        return width, fontString:GetStringHeight()
      end,
    })
  end

  --- Fills the NPC cards from the scroll offset and updates the slider.
  local function refreshNpcCards()
    --- @type SliderWidget
    local slider = Components.NpcSlider:GetFrame()
    local offset = math.floor(slider:GetValue() + 0.5)

    for i, card in ipairs(Components.NpcCards) do
      local npc_id = currentNpcIds[i + offset]
      local npc = npc_id and TameableNPCs[npc_id]
      card:SetNpc(npc)
      card:SetVisibility(npc and "VISIBLE" or "INVISIBLE")
    end

    local isEmpty = #currentNpcIds == 0
    Components.NpcCardColumn:SetVisibility(isEmpty and "GONE" or "VISIBLE")
    Components.NpcEmptyText:SetVisibility(isEmpty and "VISIBLE" or "GONE")

    local maxScroll = math.max(#currentNpcIds - NUM_NPC_CARDS, 0)
    slider:SetMinMaxValues(0, maxScroll)
    Components.NpcSlider:SetVisibility(maxScroll <= 0 and "GONE" or "VISIBLE")
  end

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  --- @class RankScreenComponent : WaffleFlexComponent
  Components.Root = Addon.Waffle:Flex({
    visibility = "GONE",
    direction = "COLUMN",
    gap = Widgets:Padding(),
  })

  --- Shows the given rank.
  --- @param ability TameableAbility
  --- @param rank TameableAbilityRank
  function Components.Root:SetRank(ability, rank)
    currentRank = rank

    --- @type RankHeadingIcon
    local headingIcon = Components.HeadingIcon:GetFrame()
    headingIcon.texture:SetTexture(ability.icon)
    Components.HeadingText:GetFrame():SetText(
      Colors.Grey("%s (%s %d)"):format(Colors.White(ability.name), L.RANK, rank.rank)
    )

    Components.PetLevelText:GetFrame():SetText(rank.pet_level and tostring(rank.pet_level) or L.NONE)
    Components.TrainingCostText:GetFrame():SetText(
      rank.training_cost and GetCoinTextureString(rank.training_cost) or L.NONE)
    Components.LearnableByText:GetFrame():SetText(
      #ability.learned_by > 0 and table.concat(ability.learned_by, ", ") or L.ALL_PET_FAMILIES)

    currentNpcIds = {}
    for _, npc_id in ipairs(rank.npc_ids) do
      currentNpcIds[#currentNpcIds + 1] = npc_id
    end
    table.sort(currentNpcIds, function(a, b)
      --- @type TameableNPC, TameableNPC
      a, b = TameableNPCs[a], TameableNPCs[b]
      if a.level_range ~= b.level_range then
        return a.level_range < b.level_range
      end
      return a.name < b.name
    end)

    Components.NpcSlider:GetFrame():SetValue(0)
    refreshNpcCards()

    self:MarkDirty()
  end

  -- ------------------------------------------------------
  -- Heading Components
  -- ------------------------------------------------------

  -- Heading: name/rank text, spell icon flush right.
  local heading = Components.Root:AddRow({
    height = 32,
    align = "CENTER",
    gap = Widgets:Padding(),
  })

  Components.HeadingIcon = heading:AddChild({
    width = 24,
    height = 24,

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class RankHeadingIcon : FrameWidget
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.25))

      frame.texture = frame:CreateTexture(nil, "ARTWORK")
      frame.texture:SetPoint("TOPLEFT", 1, -1)
      frame.texture:SetPoint("BOTTOMRIGHT", -1, 1)
      frame.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

      return frame
    end,
  })

  Components.HeadingText = heading:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
      fontString:SetJustifyH("LEFT")
      fontString:SetWordWrap(false)
      return fontString
    end,

    onMeasure = function(fontString, width)
      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight()
    end,
  })

  -- ------------------------------------------------------
  -- Details Components
  -- ------------------------------------------------------

  -- Details card. Grows with its text, shrinking the NPC list.
  Components.DetailsCard = Components.Root:AddColumn({
    height = "AUTO",
    gap = Widgets:Padding(0.5),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:Frame({ parent = parent })
    end,
  })

  Components.PetLevelText = addDetailRow(Components.DetailsCard, L.PET_LEVEL)
  Components.TrainingCostText = addDetailRow(Components.DetailsCard, L.TRAINING_COST)
  Components.LearnableByText = addDetailRow(Components.DetailsCard, L.LEARNABLE_BY)

  -- Shows the spell tooltip on hover.
  Components.DetailsCard:AddChild({
    height = 24,
    marginTop = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:Button({
        parent = parent,
        labelText = L.SHOW_TOOLTIP,
        onEnter = function(self)
          if not currentRank then return end
          GameTooltip:SetOwner(self, "ANCHOR_TOP")
          GameTooltip:SetHyperlink("spell:" .. currentRank.spell_id)
          GameTooltip:Show()
        end,
        onLeave = function() GameTooltip:Hide() end,
      })
    end,
  })

  -- ------------------------------------------------------
  -- NPCs Components
  -- ------------------------------------------------------

  -- Tameable NPCs heading.
  Components.Root:AddChild({
    height = 24,

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
      fontString:SetJustifyH("LEFT")
      fontString:SetText(Colors.White(L.TAMEABLE_NPCS))
      return fontString
    end,
  })

  -- NPC list: cards and slider.
  Components.NpcListRow = Components.Root:AddRow({
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

  -- Cards split this column's height evenly.
  Components.NpcCardColumn = Components.NpcListRow:AddColumn({
    gap = Widgets:Padding(0.5),
  })

  -- Shown instead of the cards when the rank has no NPCs.
  Components.NpcEmptyText = Components.NpcListRow:AddChild({
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

  Components.NpcSlider = Components.NpcListRow:AddChild({
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
    local card = ComponentFactory:NpcCard()
    card:SetVisibility("INVISIBLE")
    Components.NpcCards[i] = Components.NpcCardColumn:AttachComponent(card)
  end

  return Components.Root
end
