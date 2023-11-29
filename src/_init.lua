local AddonName, Addon = ...
Addon.VERSION = C_AddOns.GetAddOnMetadata(AddonName, "Version")
Addon.ICON = "Interface\\ICONS\\Ability_Hunter_BeastTaming"

Addon.Libs = {
  AceAddon = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0"),
  AceGUI = LibStub("AceGUI-3.0"),
  DCL = Addon.DethsColorLib,
  HBD = LibStub("HereBeDragons-2.0"),
  HBDPins = LibStub("HereBeDragons-Pins-2.0"),
  LDB = LibStub("LibDataBroker-1.1"),
  LDBIcon = LibStub("LibDBIcon-1.0"),
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
