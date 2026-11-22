local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local L = Addon:GetModule("Locale")
local TameableAbilities = Addon:GetModule("TameableAbilities")
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
        Colors.Grey(("(%s %d)"):format(L.RANK, entry.rank))
      )
    else
      parts[#parts + 1] = ("|T%s:0|t %s"):format(
        ability.icon,
        Colors.DimGrey(("%s (%s %d)"):format(ability.name, L.RANK, entry.rank))
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

  --- The player's map and level when the screen was last refreshed.
  local shownMapId, shownPlayerLevel

  --- Level chosen with the slider, or `nil` to use the player's.
  local chosenLevel

  --- `true` if only NPCs in the player's zone are listed.
  local isZoneOnly = false

  --- Created once the data has loaded.
  --- @type AbilityFilterComponent?
  local abilityFilter

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  --- @class ZoneScreenComponent : WaffleFlexComponent
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

    --- @type ZoneTame[]
    local zoneTames = {}

    -- Without a map there is nothing to list in the player's zone.
    if shownMapId or not isZoneOnly then
      zoneTames = ZoneTames:Get({
        level = level,
        uiMapId = isZoneOnly and shownMapId or nil,
        abilities = abilityFilter and abilityFilter:GetSelected(),
      })
    end

    Components.LevelSlider:SetValue(level)

    Components.HeadingName:GetFrame():SetText(Colors.White(isZoneOnly and GetRealZoneText() or L.ALL_ZONES))
    Components.HeadingLevel:GetFrame():SetText(Colors.Grey(("%s %d"):format(L.LEVEL, level)))

    --- @type NpcListEntry[]
    local entries = {}
    for i, zoneTame in ipairs(zoneTames) do
      entries[i] = { npc = zoneTame.npc, abilitiesText = formatAbilities(zoneTame) }
    end

    local npcTitle = L.TAMEABLE_NPCS
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

  -- Heading: zone name or all zones, description, then the level slider, the zone switch, and the ability filter.
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
      fontString:SetText(Colors.Grey(L.CURRENT_ZONE_DESCRIPTION))
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
    onChange = function(level) Components.Root:SetLevel(level) end,
  }))

  heading:AttachComponent(ComponentFactory:OptionRow({
    labelText = L.CURRENT_ZONE_ONLY,
    get = function() return isZoneOnly end,
    set = function(value)
      isZoneOnly = value
      Components.Root:Refresh()
    end,
  }))

  -- Ability filter: one icon per ability.
  EventManager:Once(E.DataLoaded, function()
    local abilities = {}
    for _, ability in pairs(TameableAbilities) do
      abilities[#abilities + 1] = ability
    end
    table.sort(abilities, function(a, b) return a.name < b.name end)

    abilityFilter = heading:AttachComponent(ComponentFactory:AbilityFilter({
      abilities = abilities,
      onChange = function() Components.Root:Refresh() end,
    }))
  end)

  -- ------------------------------------------------------
  -- NPCs Components
  -- ------------------------------------------------------

  -- Tameable NPCs heading, with the NPC count.
  Components.NpcHeading = Components.Root:AttachComponent(
    ComponentFactory:SectionTitle({ titleText = L.TAMEABLE_NPCS })
  )

  -- NPC list, with each NPC's family and abilities under its name.
  Components.NpcList = Components.Root:AttachComponent(ComponentFactory:NpcList({
    numCards = 6,
    emptyText = L.NO_TAMEABLE_NPCS,
    cardOptions = { showAbilities = true },
    columnLabels = {
      { justify = "LEFT", text = L.NAME },
      { justify = "CENTER", width = ComponentFactory.NPC_CARD_LEVEL_WIDTH, text = L.LEVEL },
      { justify = "RIGHT", width = ComponentFactory.NPC_CARD_LOCATION_WIDTH, text = L.LOCATION },
    },
  }))

  return Components.Root
end
