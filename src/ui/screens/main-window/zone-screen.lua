local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")
local ZoneTames = Addon:GetModule("ZoneTames")

--- @class ZoneScreen
local ZoneScreen = Addon:GetModule("ZoneScreen")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns the abilities line of an NPC's card: the zone's best abilities in
--- white, the rest dimmed.
--- @param zoneTame ZoneTame
--- @return string
local function formatAbilities(zoneTame)
  local parts = {}

  for _, entry in ipairs(zoneTame.abilities) do
    local ability = entry.ability
    if entry.isBest then
      parts[#parts + 1] = ("|T%s:0|t %s %s"):format(
        ability.icon,
        Colors.White(ability.name),
        Colors.LightGrey(tostring(entry.rank))
      )
    else
      parts[#parts + 1] = ("|T%s:0|t %s"):format(
        ability.icon,
        Colors.DimGrey(("%s %d"):format(ability.name, entry.rank))
      )
    end
  end

  return table.concat(parts, Colors.Grey(" · "))
end

-- ============================================================================
-- ZoneScreen
-- ============================================================================

--- Builds and returns a root component describing the Zone Screen.
--- @return ZoneScreenComponent root
function ZoneScreen:Build()
  local Components = {}

  local NUM_NPC_CARDS = 6
  local LEVEL_TEXT_WIDTH = 70
  local LEVEL_SLIDER_WIDTH = 200
  local LEVEL_SLIDER_HEIGHT = 12

  --- The player's map and level when the screen was last refreshed.
  local shownMapId, shownPlayerLevel

  --- Level chosen with the slider, or `nil` to use the player's.
  local chosenLevel

  --- `true` while `Refresh()` moves the slider, so the move is not taken as a choice.
  local isSyncingSlider = false

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  --- @class ZoneScreenComponent : WaffleFlexComponent
  Components.Root = Addon.Waffle:Flex({
    visibility = "GONE",
    direction = "COLUMN",
    gap = Widgets:Padding(),

    --- Refreshes the screen once a second while it is shown, if the player's map or level changed.
    --- @param parent Frame
    frameFactory = function(parent)
      local frame = CreateFrame("Frame", nil, parent)

      TickerManager:NewTicker(1, function()
        if C_Map.GetBestMapForUnit("player") ~= shownMapId or UnitLevel("player") ~= shownPlayerLevel then
          Components.Root:Refresh()
        end
      end):BindFrame(frame)

      return frame
    end,
  })

  --- Shows the NPCs worth taming in the player's zone at the chosen level, or the player's.
  function Components.Root:Refresh()
    shownMapId, shownPlayerLevel = C_Map.GetBestMapForUnit("player"), UnitLevel("player")
    local level = chosenLevel or shownPlayerLevel
    local zoneTames = ZoneTames:Get(shownMapId, level)

    isSyncingSlider = true
    Components.LevelSlider:GetFrame():SetValue(level)
    isSyncingSlider = false

    Components.HeadingName:GetFrame():SetText(Colors.White(GetRealZoneText()))
    Components.HeadingLevel:GetFrame():SetText(Colors.Grey(("%s %d"):format(L.LEVEL, level)))

    --- @type NpcListEntry[]
    local entries = {}
    for i, zoneTame in ipairs(zoneTames) do
      entries[i] = { npc = zoneTame.npc, abilitiesText = formatAbilities(zoneTame) }
    end

    local npcTitle = L.RECOMMENDED_TAMES
    if #entries > 0 then npcTitle = npcTitle .. Colors.Grey(" · " .. #entries) end
    Components.NpcHeading:SetTitleText(npcTitle)

    Components.NpcList:SetEntries(entries)

    self:MarkDirty()
  end

  --- Shows the NPCs worth taming at the given level, and keeps that level. Without a level, follows
  --- the player's.
  --- @param level? integer
  function Components.Root:SetLevel(level)
    chosenLevel = level
    self:Refresh()
  end

  -- ------------------------------------------------------
  -- Heading Components
  -- ------------------------------------------------------

  -- Heading: zone name above the level and its slider.
  local heading = Components.Root:AddColumn({
    height = 48,
    justify = "CENTER",
    gap = Widgets:Padding(0.25),
  })

  Components.HeadingName = heading:AddChild({
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

  local levelRow = heading:AddRow({
    height = "AUTO",
    align = "CENTER",
    gap = Widgets:Padding(),
  })

  Components.HeadingLevel = levelRow:AddChild({
    width = LEVEL_TEXT_WIDTH,
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

  Components.LevelSlider = levelRow:AddChild({
    width = LEVEL_SLIDER_WIDTH,
    height = LEVEL_SLIDER_HEIGHT,

    --- @param parent Frame
    frameFactory = function(parent)
      local slider = Widgets:Slider({
        parent = parent,
        orientation = "HORIZONTAL",
        width = LEVEL_SLIDER_WIDTH,
        height = LEVEL_SLIDER_HEIGHT,
        minValue = 1,
        maxValue = Addon.MAX_LEVEL,
      })
      slider:SetBackdropColor(Colors.Black:GetRGBA(0.3))
      slider:SetBackdropBorderColor(0, 0, 0, 0)
      slider:SetScript("OnValueChanged", function(_, value)
        if not isSyncingSlider then Components.Root:SetLevel(math.floor(value + 0.5)) end
      end)
      return slider
    end,
  })

  -- ------------------------------------------------------
  -- NPCs Components
  -- ------------------------------------------------------

  -- Recommended tames heading, with the NPC count.
  Components.NpcHeading = Components.Root:AttachComponent(
    ComponentFactory:SectionTitle({ titleText = L.RECOMMENDED_TAMES })
  )

  -- NPC list, with each NPC's abilities under its name.
  Components.NpcList = Components.Root:AttachComponent(ComponentFactory:NpcList({
    numCards = NUM_NPC_CARDS,
    emptyText = L.NO_TAMEABLE_NPCS,
    cardOptions = { showAbilities = true },
    columnLabels = {
      { justify = "LEFT", text = L.NAME },
      { justify = "CENTER", width = ComponentFactory.NPC_CARD_LEVEL_WIDTH, text = L.LEVEL },
    },
  }))

  return Components.Root
end
