local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local HBDPins = Addon:GetLibrary("HBDPins")
local L = Addon:GetModule("Locale")
local PinHelper = Addon:GetModule("PinHelper")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Opens the world map to the given NPC's zone, pinning its spawn locations.
--- @param npc TameableNPC
local function showOnMap(npc)
  ShowUIPanel(WorldMapFrame)
  WorldMapFrame:SetMapID(npc.ui_map_id)
  PinHelper:Clear()
  for _, coord in ipairs(npc.coords) do
    HBDPins:AddWorldMapIconMap(
      Addon, PinHelper:Get(npc), npc.ui_map_id,
      coord[1] * 0.01, coord[2] * 0.01, HBD_PINS_WORLDMAP_SHOW_WORLD
    )
  end
end

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class NpcCardOptions
--- @field showAbilities? boolean Shows a line of abilities under the name, and no location.

-- =============================================================================
-- ComponentFactory - NpcCard
-- =============================================================================

--- Creates a card showing an NPC's name and level, and its location or abilities. Hovering
--- shows the NPC tooltip; clicking shows the NPC on the map, if it has a `ui_map_id`.
--- @param options? NpcCardOptions
--- @return NpcCardComponent card
function ComponentFactory:NpcCard(options)
  options = options or {}

  --- @type TameableNPC?
  local npc

  --- Text of the abilities line, when `options.showAbilities` is set.
  local abilitiesText = ""

  --- Font of every text line, larger when the card has an abilities line.
  local textFont = options.showAbilities and "GameFontNormal" or "GameFontNormalSmall"

  --- @type { node: WaffleFlexComponent<FontString>, getText: fun(npc: TameableNPC): string }[]
  local textLines = {}

  local isHovered = false

  --- Tints the card while hovered, green if its NPC has a map.
  --- @param frame FrameWidget
  local function updateHighlight(frame)
    if isHovered then
      if npc and npc.ui_map_id then
        frame:SetBackdropColor(Colors.Green:GetRGBA(0.12))
      else
        frame:SetBackdropColor(Colors.White:GetRGBA(0.08))
      end
    else
      frame:SetBackdropColor(0, 0, 0, 0)
    end
  end

  --- Shows the NPC tooltip on the card, if it has an NPC.
  --- @param frame FrameWidget
  local function showTooltip(frame)
    if npc then
      GameTooltip:SetOwner(frame, "ANCHOR_TOP")
      GameTooltip:SetText(Colors.Green(npc.name))
      GameTooltip:AddDoubleLine(L.LEVEL, Colors.White(npc.level_range))
      GameTooltip:AddDoubleLine(L.ABILITIES, Colors.White(table.concat(npc.abilities, ", ")))
      GameTooltip:AddDoubleLine(L.FAMILY, Colors.White(npc.family))
      GameTooltip:AddDoubleLine(L.DIET, Colors.White(table.concat(npc.diet, ", ")))
      GameTooltip:AddDoubleLine(L.TYPE, Colors.White(npc.type))
      GameTooltip:AddDoubleLine(L.LOCATION, Colors.White(npc.location))
      GameTooltip:AddLine(" ")
      if npc.ui_map_id then
        GameTooltip:AddDoubleLine(Colors.White(L.LEFT_CLICK), Colors.Green(L.SHOW_ON_MAP))
      else
        GameTooltip:AddLine(Colors.Grey(L.MAP_UNAVAILABLE))
      end
      GameTooltip:Show()
    end
  end

  local card

  --- @class NpcCardComponent : WaffleFlexComponent<FrameWidget>
  card = Addon.Waffle:Flex({
    direction = "ROW",
    align = "CENTER",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      frame:SetBackdropBorderColor(0, 0, 0, 0)
      updateHighlight(frame)

      -- Divider between cards.
      local divider = frame:CreateTexture(nil, "BORDER")
      divider:SetColorTexture(Colors.White:GetRGBA(0.06))
      divider:SetHeight(1)
      divider:SetPoint("BOTTOMLEFT")
      divider:SetPoint("BOTTOMRIGHT")

      frame:SetScript("OnClick", function()
        if npc and npc.ui_map_id then showOnMap(npc) end
      end)

      frame:SetScript("OnEnter", function()
        isHovered = true
        updateHighlight(frame)
        showTooltip(frame)
      end)

      frame:SetScript("OnLeave", function()
        isHovered = false
        updateHighlight(frame)
        GameTooltip:Hide()
      end)

      frame:SetScript("OnHide", function()
        isHovered = false
        updateHighlight(frame)
      end)

      return frame
    end,
  })

  local info = card:AddRow({ height = "AUTO", gap = Widgets:Padding(0.25), align = "CENTER" })

  --- Adds a text line to `container`, filled in by `getText` for the current NPC.
  --- @param container WaffleFlexComponent
  --- @param justify "LEFT" | "CENTER" | "RIGHT"
  --- @param columnWidth? integer Without it, the line takes the width left over.
  --- @param getText fun(npc: TameableNPC): string
  local function addTextLine(container, justify, columnWidth, getText)
    local node = container:AddChild({
      width = columnWidth,
      height = "AUTO",

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", textFont)
        fontString:SetJustifyH(justify)
        fontString:SetText(npc and getText(npc) or "")
        return fontString
      end,

      onMeasure = function(fontString, width)
        fontString:SetSize(width, 0)
        return width, fontString:GetStringHeight()
      end,
    })

    textLines[#textLines + 1] = { node = node, getText = getText }
  end

  --- Returns the text of the name line.
  local function getName(n) return Colors.Green(n.name) end
  --- Returns the text of the level line.
  local function getLevel(n) return Colors.White(n.level_range) end

  if options.showAbilities then
    -- Name, with the abilities under it, then level.
    local nameColumn = info:AddColumn({ height = "AUTO", gap = Widgets:Padding(0.25) })
    addTextLine(nameColumn, "LEFT", nil, getName)
    addTextLine(nameColumn, "LEFT", nil, function() return abilitiesText end)
    addTextLine(info, "CENTER", ComponentFactory.NPC_CARD_LEVEL_WIDTH, getLevel)
  else
    -- Name, level, and location.
    addTextLine(info, "LEFT", nil, getName)
    addTextLine(info, "CENTER", ComponentFactory.NPC_CARD_LEVEL_WIDTH, getLevel)
    addTextLine(info, "RIGHT", ComponentFactory.NPC_CARD_LOCATION_WIDTH, function(n)
      local color = n.ui_map_id and Colors.LightGrey or Colors.DimGrey
      return color(n.location)
    end)
  end

  --- Sets the NPC shown, and the text of its abilities line if the card has one.
  --- @param newNpc? TameableNPC
  --- @param newAbilitiesText? string
  function card:SetNpc(newNpc, newAbilitiesText)
    npc = newNpc
    abilitiesText = newAbilitiesText or ""
    if not npc then return end

    for _, line in ipairs(textLines) do
      local fontString = line.node:GetFrame()
      if fontString then fontString:SetText(line.getText(npc)) end
    end

    local frame = self:GetFrame()
    if frame then
      updateHighlight(frame)
      if GameTooltip:IsOwned(frame) then showTooltip(frame) end
    end

    self:MarkDirty()
  end

  return card
end
