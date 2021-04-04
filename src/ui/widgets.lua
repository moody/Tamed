local _, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local Widgets = Addon.UI.Widgets

--[[
  Adds a basic AceGUI Button to a parent widget and returns it.

  options = {
    parent = widget,
    text = string,
    fullWidth = boolean,
    width = number,
    height = number,
    onClick = function,
    onEnter = function,
    onLeave = function
  }
]]
function Widgets:Button(options)
  local button = AceGUI:Create("Button")
  button:SetText(options.text)
  button:SetFullWidth(options.fullWidth)
  if options.width then button:SetWidth(options.width) end
  if options.height then button:SetHeight(options.height) end
  button:SetCallback("OnClick", options.onClick)
  button:SetCallback("OnEnter", options.onEnter)
  button:SetCallback("OnLeave", options.onLeave)
  options.parent:AddChild(button)
  return button
end

-- Adds an AceGUI Heading to a parent widget and returns it.
function Widgets:Heading(parent, text)
  local heading = AceGUI:Create("Heading")
  heading:SetText(text)
  heading:SetFullWidth(true)
  parent:AddChild(heading)
  return heading
end

--[[
  Adds a basic AceGUI Label to a parent widget and returns it.

  options = {
    parent = widget,
    text = string,
    fullWidth = boolean,
    color = table
  }
]]
function Widgets:Label(options)
  local label = AceGUI:Create("Label")
  label:SetText(options.text)
  label:SetFullWidth(options.fullWidth)

  if options.color then
    label:SetColor(options.color.r, options.color.g, options.color.b)
  end

  if options.font then
    if options.fontHeight then
      label:SetFont(options.font, options.fontHeight, options.fontFlags)
    else
      label:SetFontObject(options.font)
    end
  end

  if options.image then
    label:SetImage(options.image.path, _G.unpack(options.image.texCoord))
    if options.image.width and options.image.height then
      label:SetImageSize(options.image.width, options.image.height)
    end
  end

  options.parent:AddChild(label)
  return label
end

--[[
  Helper function to create an empty, full width Label widget.
]]
function Widgets:Spacer(parent)
  return self:Label({
    parent = parent,
    text = " ",
    fullWidth = true
  })
end

--[[
  Adds an AceGUI InlineGroup to a parent widget and returns it.

  options = {
    parent = widget,
    title = string,
    fullWidth = boolean,
    layout = "Flow", -- "Flow" | "Fill" | "List"
  }
--]]
function Widgets:InlineGroup(options)
  local inlineGroup = AceGUI:Create("InlineGroup")
  inlineGroup:SetTitle(options.title)
  inlineGroup:SetFullWidth(options.fullWidth)
  inlineGroup:SetLayout(options.layout or "Flow")
  options.parent:AddChild(inlineGroup)
  return inlineGroup
end

--[[
  Adds an AceGUI SimpleGroup to a parent widget and returns it.

  options = {
    parent = widget,
    fullWidth = boolean,
    fullHeight = boolean,
    layout = "Flow", -- "Flow" | "Fill" | "List"
  }
--]]
function Widgets:SimpleGroup(options)
  local simpleGroup = AceGUI:Create("SimpleGroup")
  simpleGroup:SetFullWidth(options.fullWidth)
  simpleGroup:SetFullHeight(options.fullHeight)
  simpleGroup:SetLayout(options.layout or "Flow")
  options.parent:AddChild(simpleGroup)
  return simpleGroup
end
