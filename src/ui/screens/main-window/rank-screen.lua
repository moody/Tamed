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

  --- @type TameableAbilityRank?
  local currentRank

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

    --- NPCs teaching the rank, sorted by `min_level`, then name.
    --- @type TameableNPC[]
    local npcs = {}
    for _, npc_id in ipairs(rank.npc_ids) do
      npcs[#npcs + 1] = TameableNPCs[npc_id]
    end
    table.sort(npcs, function(a, b)
      if a.min_level ~= b.min_level then
        return a.min_level < b.min_level
      end
      return a.name < b.name
    end)

    --- @type NpcListEntry[]
    local entries = {}
    for i, npc in ipairs(npcs) do entries[i] = { npc = npc } end

    local npcTitle = L.TAMEABLE_NPCS
    if #entries > 0 then npcTitle = npcTitle .. Colors.Grey(" · " .. #entries) end
    Components.NpcHeading:SetTitleText(npcTitle)

    Components.NpcList:SetEntries(entries)

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

  Components.PetLevelTile = numbers:AttachComponent(
    ComponentFactory:StatTile({ labelText = L.PET_LEVEL })
  )
  Components.TrainingCostTile = numbers:AttachComponent(
    ComponentFactory:StatTile({ labelText = L.TRAINING_COST })
  )
  Components.LearnableByTile = stats:AttachComponent(
    ComponentFactory:StatTile({ labelText = L.LEARNABLE_BY, valueFont = "GameFontNormal" })
  )

  -- ------------------------------------------------------
  -- NPCs Components
  -- ------------------------------------------------------

  -- Tameable NPCs heading, with the NPC count.
  Components.NpcHeading = Components.Root:AttachComponent(
    ComponentFactory:SectionTitle({ titleText = L.TAMEABLE_NPCS })
  )

  -- NPC list: a header band above the cards and slider, on the same surface as
  -- the stat tiles.
  Components.NpcList = Components.Root:AttachComponent(ComponentFactory:NpcList({
    numCards = NUM_NPC_CARDS,
    emptyText = L.NONE,
    columnLabels = {
      { justify = "LEFT", text = L.NAME },
      { justify = "CENTER", width = ComponentFactory.NPC_CARD_LEVEL_WIDTH, text = L.LEVEL },
      { justify = "RIGHT", width = ComponentFactory.NPC_CARD_LOCATION_WIDTH, text = L.LOCATION },
    },
  }))

  return Components.Root
end
