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
      coord.x * 0.01, coord.y * 0.01, HBD_PINS_WORLDMAP_SHOW_WORLD
    )
  end
end

-- =============================================================================
-- ComponentFactory - NpcCard
-- =============================================================================

--- Creates a card showing an NPC's name, level, and location. Hovering shows
--- the NPC tooltip; clicking shows the NPC on the map, if it has a `ui_map_id`.
--- @return NpcCardComponent card
function ComponentFactory:NpcCard()
  --- @type TameableNPC?
  local npc

  --- @type { node: WaffleFlexComponent, getText: fun(npc: TameableNPC): string }[]
  local textLines = {}

  --- Highlights the card while hovered, if its NPC has a map.
  --- @param frame FrameWidget
  local function updateHighlight(frame)
    if npc and npc.ui_map_id and frame:IsMouseOver() then
      frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.5))
      frame:SetBackdropBorderColor(Colors.Green:GetRGBA(0.5))
    else
      frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(0.25))
      frame:SetBackdropBorderColor(Colors.White:GetRGBA(0.1))
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
      if npc.ui_map_id then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(Colors.White(L.LEFT_CLICK), Colors.Green(L.SHOW_ON_MAP))
      end
      GameTooltip:Show()
    end
  end

  local card

  --- @class NpcCardComponent : WaffleFlexComponent
  card = Addon.Waffle:Flex({
    direction = "ROW",
    align = "CENTER",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      updateHighlight(frame)

      frame:SetScript("OnClick", function()
        if npc and npc.ui_map_id then showOnMap(npc) end
      end)

      frame:SetScript("OnEnter", function()
        updateHighlight(frame)
        showTooltip(frame)
      end)

      frame:SetScript("OnLeave", function()
        updateHighlight(frame)
        GameTooltip:Hide()
      end)

      return frame
    end,
  })

  -- Name, level, and location.
  local info = card:AddRow({ height = "AUTO", gap = Widgets:Padding(0.25), align = "CENTER" })

  --- Adds a text line filled in by `getText` for the current NPC.
  --- @param justify "LEFT" | "CENTER" | "RIGHT"
  --- @param getText fun(npc: TameableNPC): string
  local function addTextLine(justify, getText)
    local node = info:AddChild({
      height = "AUTO",

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
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

  addTextLine("LEFT", function(n) return Colors.Green(n.name) end)
  addTextLine("CENTER", function(n) return Colors.White(n.level_range) end)
  addTextLine("RIGHT", function(n) return Colors.LightGrey(n.location) end)

  --- Sets the NPC shown.
  --- @param newNpc? TameableNPC
  function card:SetNpc(newNpc)
    npc = newNpc
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
