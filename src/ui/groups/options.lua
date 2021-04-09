local _, Addon = ...
local L = Addon.Locale
local Options = Addon.UI.Groups.Options
local Widgets = Addon.UI.Widgets

function Options:Create(parent)
  Widgets:Heading(parent, L.OPTIONS)
end
