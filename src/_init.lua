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
