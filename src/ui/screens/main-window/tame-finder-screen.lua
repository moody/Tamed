local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local TameableAbilities = Addon:GetModule("TameableAbilities")
local TameFinder = Addon:GetModule("TameFinder")
local TickerManager = Addon:GetModule("TickerManager")
local Widgets = Addon:GetModule("Widgets")

--- @class TameFinderScreen
local TameFinderScreen = Addon:GetModule("TameFinderScreen")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns the abilities line of an NPC's card: the abilities at the highest ranks in `bestRanks` in
--- white, the rest dimmed.
--- @param npc TameableNPC
--- @param bestRanks table<TameableAbility, integer>
--- @return string
local function formatAbilities(npc, bestRanks)
  local parts = {}

  for _, npcAbility in ipairs(npc.abilities) do
    local ability = npcAbility.ability
    if npcAbility.rank == bestRanks[ability] then
      parts[#parts + 1] = ("|T%s:0|t %s %s"):format(
        ability.icon,
        Colors.White(ability.name),
        Colors.Grey(("(%s %d)"):format(L.RANK, npcAbility.rank))
      )
    else
      parts[#parts + 1] = ("|T%s:0|t %s"):format(
        ability.icon,
        Colors.DimGrey(("%s (%s %d)"):format(ability.name, L.RANK, npcAbility.rank))
      )
    end
  end

  return table.concat(parts, Colors.Grey(" · "))
end

-- ============================================================================
-- TameFinderScreen
-- ============================================================================

--- Builds and returns a root component describing the Tame Finder Screen.
--- @return TameFinderScreenComponent root
function TameFinderScreen:Build()
  local Components = {}

  --- The player's map and level when the screen was last refreshed.
  local shownMapId, shownPlayerLevel

  --- Level chosen with the slider, or `nil` to use the player's.
  local chosenLevel

  --- `true` if only NPCs in the player's zone are listed.
  local isZoneOnly = false

  --- Created once the data has loaded.
  --- @type AbilityFilterComponent?
  local abilityFilter

  --- The filters for `TameFinder:Get()`, reused by every refresh.
  --- @type TameFinderFilters
  local filters = { level = 1 }

  --- The highest rank of each ability among the NPCs listed.
  --- @type table<TameableAbility, integer>
  local bestRanks = {}

  --- Stand-ins for a list with no NPCs, so a refresh creates no empty tables.
  local noResults, noBestRanks = {}, {}

  --- Refreshes the screen after a short delay, so a moving slider refreshes it at most every 0.1 seconds.
  local refreshTimer = TickerManager:NewTimer(0.1, function() Components.Root:Refresh() end)
  refreshTimer:Cancel()

  --- Starts the refresh timer unless it is already running.
  local function refreshSoon()
    if refreshTimer:IsCancelled() then refreshTimer:Restart() end
  end

  --- Shows the level next to the slider.
  --- @param level integer
  local function showLevel(level)
    Components.HeadingLevel:GetFrame():SetText(Colors.White(L.LEVEL) .. " " .. Colors.Green(tostring(level)))
  end

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  --- @class TameFinderScreenComponent : WaffleFlexComponent
  Components.Root = Addon.Waffle:Flex({
    visibility = "GONE",
    direction = "COLUMN",
    gap = Widgets:Padding(),

    --- Once a second while shown, refreshes if the zone or level the screen depends on changed.
    --- @param parent Frame
    frameFactory = function(parent)
      local frame = CreateFrame("Frame", nil, parent)

      TickerManager:NewTicker(1, function()
        local isMapChanged = isZoneOnly and C_Map.GetBestMapForUnit("player") ~= shownMapId
        local isLevelChanged = chosenLevel == nil and UnitLevel("player") ~= shownPlayerLevel
        if isMapChanged or isLevelChanged then
          Components.Root:Refresh()
        end
      end):BindFrame(frame)

      return frame
    end,
  })

  --- Shows the NPCs worth taming for the level and the zone switch.
  function Components.Root:Refresh()
    -- Nothing to update before the screen is laid out. The ticker refreshes it once it is shown.
    if not Components.HeadingName:GetFrame() then return end

    shownMapId, shownPlayerLevel = C_Map.GetBestMapForUnit("player"), UnitLevel("player")
    local level = chosenLevel or shownPlayerLevel

    filters.level = level
    filters.uiMapId = isZoneOnly and shownMapId or nil
    filters.abilities = abilityFilter and abilityFilter:GetSelected()

    local results = noResults
    bestRanks = noBestRanks

    -- Without a map there is nothing to list in the player's zone.
    if shownMapId or not isZoneOnly then
      results, bestRanks = TameFinder:Get(filters)
    end

    if abilityFilter then abilityFilter:SetBestRanks(bestRanks) end

    Components.LevelSlider:SetValue(level)
    showLevel(level)

    local npcTitle = L.TAMEABLE_NPCS
    if #results > 0 then npcTitle = npcTitle .. Colors.Grey(" · " .. #results) end
    Components.NpcHeading:SetTitleText(npcTitle)

    Components.NpcList:SetEntries(results)

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

  -- Heading: title, description, then a panel with the level slider and the ability filter.
  local heading = Components.Root:AddColumn({
    height = "AUTO",
    gap = Widgets:Padding(0.25),
  })

  Components.HeadingName = heading:AddChild({
    height = "AUTO",

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
      fontString:SetJustifyH("LEFT")
      fontString:SetWordWrap(false)
      fontString:SetText(Colors.White(L.TAME_FINDER))
      return fontString
    end,

    onMeasure = function(fontString, width)
      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight()
    end,
  })

  -- What the screen shows, and how the slider changes it.
  heading:AddChild({
    height = "AUTO",
    marginBottom = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
      fontString:SetJustifyH("LEFT")
      fontString:SetText(Colors.Grey(L.TAME_FINDER_DESCRIPTION))
      return fontString
    end,

    onMeasure = function(fontString, width)
      fontString:SetSize(width, 0)
      return width, fontString:GetStringHeight()
    end,
  })

  -- Panel behind the level slider and the ability filter.
  local filters = heading:AddColumn({
    height = "AUTO",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.White:GetRGBA(0.04))
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      return frame
    end,
  })

  local levelRow = filters:AddRow({
    height = "AUTO",
    align = "CENTER",
    gap = Widgets:Padding(),
  })

  Components.HeadingLevel = levelRow:AddChild({
    width = 70,
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

  Components.LevelSlider = levelRow:AttachComponent(ComponentFactory:ValueSlider({
    minValue = 1,
    maxValue = Addon.MAX_LEVEL,
    onChange = function(level)
      chosenLevel = level
      showLevel(level)
      refreshSoon()
    end,
  }))

  -- Ability filter: one icon per ability.
  EventManager:Once(E.DataLoaded, function()
    local abilities = {}
    for _, ability in pairs(TameableAbilities) do
      abilities[#abilities + 1] = ability
    end
    table.sort(abilities, function(a, b) return a.name < b.name end)

    abilityFilter = filters:AttachComponent(ComponentFactory:AbilityFilter({
      abilities = abilities,
      onChange = function() Components.Root:Refresh() end,
    }))
  end)

  -- ------------------------------------------------------
  -- NPCs Components
  -- ------------------------------------------------------

  -- Tameable NPCs heading, with the NPC count and the zone switch.
  Components.NpcHeading = Components.Root:AttachComponent(
    ComponentFactory:SectionTitle({ titleText = L.TAMEABLE_NPCS })
  )

  --- Width and height of the zone switch's checkbox.
  local ZONE_SWITCH_CHECK_BOX_SIZE = 14

  --- Height of the zone switch, the same as a line of the title's text.
  local ZONE_SWITCH_HEIGHT = 14

  -- Zone switch: a label with a checkbox on its right, as wide as its text.
  Components.NpcHeading:AddChild({
    width = "AUTO",
    height = ZONE_SWITCH_HEIGHT,
    marginBottom = Widgets:Padding(0.5),

    --- @param parent Frame
    frameFactory = function(parent)
      --- @class ZoneSwitchFrame : FrameWidget
      --- @field label FontString
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      frame:SetBackdropColor(0, 0, 0, 0)
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      frame:SetScript("OnEnter", function(self) self:SetBackdropColor(Colors.White:GetRGBA(0.1)) end)
      frame:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0) end)

      --- Sets whether only NPCs in the player's zone are listed.
      --- @param value boolean
      local function setZoneOnly(value)
        isZoneOnly = value
        Components.Root:Refresh()
      end

      frame:SetScript("OnClick", function() setZoneOnly(not isZoneOnly) end)

      local checkBox = Widgets:CheckBox({
        parent = frame,
        width = ZONE_SWITCH_CHECK_BOX_SIZE,
        height = ZONE_SWITCH_CHECK_BOX_SIZE,
        get = function() return isZoneOnly end,
        set = setZoneOnly,
      })
      checkBox:EnableMouse(false)
      checkBox:SetPoint("RIGHT", -Widgets:Padding(0.5), 0)

      frame.label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
      frame.label:SetPoint("RIGHT", checkBox, "LEFT", -Widgets:Padding(), 0)
      frame.label:SetTextColor(Colors.White:GetRGB())
      frame.label:SetText(L.CURRENT_ZONE_ONLY)

      return frame
    end,

    --- @param frame ZoneSwitchFrame
    onMeasure = function(frame)
      -- Padding, checkbox, and gap: everything but the label.
      local fixedWidth = Widgets:Padding(0.5) * 2 + ZONE_SWITCH_CHECK_BOX_SIZE + Widgets:Padding()
      return fixedWidth + frame.label:GetStringWidth(), ZONE_SWITCH_HEIGHT
    end,
  })

  -- NPC list, with each NPC's family and abilities under its name.
  Components.NpcList = Components.Root:AttachComponent(ComponentFactory:NpcList({
    numCards = 6,
    emptyText = L.NO_MATCHING_NPCS,
    cardOptions = { showAbilities = true },
    getAbilitiesText = function(entry) return formatAbilities(entry.npc, bestRanks) end,
    columnLabels = {
      { justify = "LEFT", text = L.NAME },
      { justify = "CENTER", width = ComponentFactory.NPC_CARD_LEVEL_WIDTH, text = L.LEVEL },
      { justify = "RIGHT", width = ComponentFactory.NPC_CARD_LOCATION_WIDTH, text = L.LOCATION },
    },
  }))

  return Components.Root
end
