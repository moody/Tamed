local AddonName, Addon = ...
Addon.VERSION = _G.GetAddOnMetadata(AddonName, "Version")
Addon.ICON = "Interface\\ICONS\\Ability_Hunter_BeastTaming"

Addon.Libs = {
  AceAddon = _G.LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0"),
  AceGUI = _G.LibStub("AceGUI-3.0"),
  DCL = Addon.DethsColorLib,
  HBD = _G.LibStub("HereBeDragons-2.0"),
  HBDPins = _G.LibStub("HereBeDragons-Pins-2.0"),
  LDB = _G.LibStub("LibDataBroker-1.1"),
  LDBIcon = _G.LibStub("LibDBIcon-1.0"),
}

Addon.Colors = {
  Primary = "AAD372",
  Highlight = "E3E34F",
  Label = "FFD100",
}

Addon.Commands = {}
Addon.DB = {}
Addon.Locale = {}

Addon.UI = {
  Groups = {
    Ability = {},
    Options = {},
  },
  MinimapIcon = {},
  PinHelper = {},
  Widgets = {}
}

-- OnInitialize().
function Addon.Libs.AceAddon:OnInitialize()
  Addon.DB:Initialize()
  Addon.UI.MinimapIcon:Initialize()
  Addon.Commands:Initialize()
end

-- Update TameableAbilities with in-game data.
for _, ability in pairs(Addon.TameableAbilities) do
  local name, _, icon = _G.GetSpellInfo(ability.ranks[1].spell_id)
  ability.name = name
  ability.icon = icon
end

-- Update TameableNPCs with in-game data.
for _, npc in pairs(Addon.TameableNPCs) do
  npc.location = _G.C_Map.GetAreaInfo(npc.zone_id)

  -- Add `classification` to `level_range`.
  if npc.classification then
    npc.level_range = ("%s (%s)"):format(
      npc.level_range, Addon.Libs.DCL:ColorString(
        npc.classification,
        Addon.Colors.Highlight
      )
    )
  end
end
