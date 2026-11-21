local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
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

  local NUM_NPC_CARDS = 9
  local NPC_SLIDER_WIDTH = 6

  --- @type TameableAbilityRank?
  local currentRank

  --- Ids of NPCs teaching `currentRank`, sorted by `min_level`, then name.
  --- @type string[]
  local currentNpcIds = {}

  -- ------------------------------------------------------
  -- Local Functions
  -- ------------------------------------------------------

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

    -- An empty rank shows no surface, header, or slider, only the empty text.
    local isEmpty = #currentNpcIds == 0
    Components.NpcList:GetFrame():SetBackdropColor(Colors.White:GetRGBA(isEmpty and 0 or 0.04))
    Components.NpcColumnLabels:SetVisibility(isEmpty and "GONE" or "VISIBLE")
    Components.NpcCardColumn:SetVisibility(isEmpty and "GONE" or "VISIBLE")
    Components.NpcEmptyText:SetVisibility(isEmpty and "VISIBLE" or "GONE")

    -- The track keeps its space on every rank, so the right edge never shifts.
    -- Only the thumb hides when the list cannot scroll.
    local maxScroll = math.max(#currentNpcIds - NUM_NPC_CARDS, 0)
    slider:SetMinMaxValues(0, maxScroll)
    slider.texture:SetShown(maxScroll > 0)
    Components.NpcSlider:SetVisibility(isEmpty and "INVISIBLE" or "VISIBLE")
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
    Components.HeadingName:GetFrame():SetText(Colors.White(ability.name))
    Components.HeadingRank:GetFrame():SetText(Colors.Grey(("%s %d"):format(L.RANK, rank.rank)))

    Components.PetLevelTile:SetText(
      rank.pet_level and tostring(rank.pet_level) or L.NONE,
      rank.pet_level == nil
    )
    Components.TrainingCostTile:SetText(
      rank.training_cost and tostring(rank.training_cost) or L.NONE,
      rank.training_cost == nil
    )

    local learnedBy = L.ALL_PET_FAMILIES
    if #ability.learned_by > 0 then
      learnedBy = table.concat(ability.learned_by, Colors.Grey(" · "))
    end
    Components.LearnableByTile:SetText(learnedBy)

    currentNpcIds = {}
    for _, npc_id in ipairs(rank.npc_ids) do
      currentNpcIds[#currentNpcIds + 1] = npc_id
    end
    table.sort(currentNpcIds, function(a, b)
      --- @type TameableNPC, TameableNPC
      a, b = TameableNPCs[a], TameableNPCs[b]
      if a.min_level ~= b.min_level then
        return a.min_level < b.min_level
      end
      return a.name < b.name
    end)

    --- @type RankNpcHeading
    local npcHeading = Components.NpcHeading:GetFrame()
    local npcTitle = Colors.White(L.TAMEABLE_NPCS)
    if #currentNpcIds > 0 then npcTitle = npcTitle .. Colors.Grey(" · " .. #currentNpcIds) end
    npcHeading.text:SetText(npcTitle)

    Components.NpcSlider:GetFrame():SetValue(0)
    refreshNpcCards()

    self:MarkDirty()
  end

  -- ------------------------------------------------------
  -- Heading Components
  -- ------------------------------------------------------

  -- Heading: spell icon and name/rank text. Hovering it shows the spell tooltip.
  local heading = Components.Root:AddRow({
    height = 48,
    align = "CENTER",
    gap = Widgets:Padding(),
    paddingTop = Widgets:Padding(0.5),
    paddingBottom = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:EnableMouse(true)

      frame:SetScript("OnEnter", function()
        frame:SetBackdropColor(Colors.White:GetRGBA(0.05))
        if currentRank then
          GameTooltip:SetOwner(Components.HeadingIcon:GetFrame(), "ANCHOR_RIGHT")
          GameTooltip:SetHyperlink("spell:" .. currentRank.spell_id)
          GameTooltip:Show()
        end
      end)

      frame:SetScript("OnLeave", function()
        frame:SetBackdropColor(0, 0, 0, 0)
        GameTooltip:Hide()
      end)

      return frame
    end,
  })

  Components.HeadingIcon = heading:AddChild({
    width = 40,
    height = 40,

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class RankHeadingIcon : FrameWidget
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)

      frame.texture = frame:CreateTexture(nil, "ARTWORK")
      frame.texture:SetAllPoints()
      frame.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)

      return frame
    end,
  })

  -- Ability name above the rank.
  local headingText = heading:AddColumn({
    height = "AUTO",
    gap = Widgets:Padding(0.25),
  })

  Components.HeadingName = headingText:AddChild({
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

  Components.HeadingRank = headingText:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
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
  -- Stats Components
  -- ------------------------------------------------------

  -- Pet level and training cost side by side, then the families that learn the
  -- rank. Grows with its text, shrinking the NPC list.
  local stats = Components.Root:AddColumn({
    height = "AUTO",
    gap = Widgets:Padding(0.5),
  })

  local numbers = stats:AddRow({
    height = "AUTO",
    gap = Widgets:Padding(0.5),
  })

  --- @type StatTileComponent
  Components.PetLevelTile = numbers:AttachComponent(
    ComponentFactory:StatTile({ labelText = L.PET_LEVEL })
  )
  --- @type StatTileComponent
  Components.TrainingCostTile = numbers:AttachComponent(
    ComponentFactory:StatTile({ labelText = L.TRAINING_COST })
  )
  --- @type StatTileComponent
  Components.LearnableByTile = stats:AttachComponent(
    ComponentFactory:StatTile({ labelText = L.LEARNABLE_BY, valueFont = "GameFontNormal" })
  )

  -- ------------------------------------------------------
  -- NPCs Components
  -- ------------------------------------------------------

  -- Tameable NPCs heading, with the NPC count and a rule underneath.
  Components.NpcHeading = Components.Root:AddChild({
    height = 24,

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class RankNpcHeading : Frame
      --- @field text FontString
      local frame = CreateFrame("Frame", nil, parent)

      frame.text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      frame.text:SetPoint("BOTTOMLEFT", 0, Widgets:Padding(0.5))
      frame.text:SetJustifyH("LEFT")
      frame.text:SetText(Colors.White(L.TAMEABLE_NPCS))

      local rule = frame:CreateTexture(nil, "ARTWORK")
      rule:SetColorTexture(Colors.White:GetRGBA(0.1))
      rule:SetHeight(1)
      rule:SetPoint("BOTTOMLEFT")
      rule:SetPoint("BOTTOMRIGHT")

      return frame
    end,
  })

  -- NPC list: a header band above the cards and slider, on the same surface as
  -- the stat tiles.
  Components.NpcList = Components.Root:AddColumn({
    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.04))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:EnableMouseWheel(true)
      frame:SetScript("OnMouseWheel", function(_, delta)
        local slider = Components.NpcSlider:GetFrame()
        if slider then slider:SetValue(slider:GetValue() - delta) end
      end)
      return frame
    end,
  })

  -- Column labels, in a band of their own. Right padding lines them up with the card text.
  Components.NpcColumnLabels = Components.NpcList:AddRow({
    height = 24,
    gap = Widgets:Padding(0.25),
    paddingLeft = Widgets:Padding(),
    paddingRight = Widgets:Padding() + Widgets:Padding(0.5) * 2 + NPC_SLIDER_WIDTH,

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

  --- Adds a label to the column labels.
  --- @param justify "LEFT" | "CENTER" | "RIGHT"
  --- @param width? integer Without it, the label takes the width left over.
  --- @param text string
  local function addColumnLabel(justify, width, text)
    Components.NpcColumnLabels:AddChild({
      width = width,

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
        fontString:SetJustifyH(justify)
        fontString:SetText(Colors.LightGrey(text))
        return fontString
      end,
    })
  end

  addColumnLabel("LEFT", nil, L.NAME)
  addColumnLabel("CENTER", ComponentFactory.NPC_CARD_LEVEL_WIDTH, L.LEVEL)
  addColumnLabel("RIGHT", ComponentFactory.NPC_CARD_LOCATION_WIDTH, L.LOCATION)

  -- Cards and slider.
  local npcBody = Components.NpcList:AddRow({
    gap = Widgets:Padding(0.5),
    paddingRight = Widgets:Padding(0.5),
  })

  -- Cards split this column's height evenly.
  Components.NpcCardColumn = npcBody:AddColumn({})

  -- Shown instead of the cards when the rank has no NPCs, under the heading's rule.
  Components.NpcEmptyText = npcBody:AddChild({
    visibility = "GONE",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      fontString:SetJustifyH("LEFT")
      fontString:SetJustifyV("TOP")
      fontString:SetText(Colors.Grey(L.NONE))
      return fontString
    end,
  })

  -- Margins keep the thumb, which overhangs the track by half its height, inside the body.
  Components.NpcSlider = npcBody:AddChild({
    width = NPC_SLIDER_WIDTH,
    marginTop = NPC_SLIDER_WIDTH,
    marginBottom = NPC_SLIDER_WIDTH,

    --- @param parent Frame
    frameFactory = function(parent)
      local slider = Widgets:Slider({ parent = parent, width = NPC_SLIDER_WIDTH })
      slider:SetBackdropColor(Colors.Black:GetRGBA(0.3))
      slider:SetBackdropBorderColor(0, 0, 0, 0)
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
