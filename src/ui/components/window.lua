local ADDON_NAME = ... ---@type string
local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- LuaCATS Annotations
-- =============================================================================

--- @class WindowComponentOptions
--- @field name string Used for the frame's name, gets prefixed with `Tamed_`.
--- @field width integer
--- @field height integer
--- @field titleText string

-- =============================================================================
-- ComponentFactory - Window
-- =============================================================================

--- Creates a draggable floating window with a title bar and close button,
--- centered on screen. Position is not persisted; it always opens centered.
--- @param options WindowComponentOptions
--- @return WindowComponent root
function ComponentFactory:Window(options)
  local root

  --- @class WindowComponent : WaffleFlexComponent
  --- @field TitleRow WaffleFlexComponent
  --- @field TitleText WaffleFlexComponent
  --- @field CloseButton WaffleFlexComponent
  root = Addon.Waffle:Flex({
    width = options.width,
    height = options.height,
    direction = "COLUMN",
    visibility = "GONE",

    defaultFrameFactory = function(parent)
      return CreateFrame("Frame", nil, parent)
    end,

    frameFactory = function()
      local frame = Widgets:Frame({
        name = ADDON_NAME .. "_" .. options.name,
        enableDragging = true,
        frameStrata = "HIGH"
      })
      frame:SetPoint("CENTER")

      -- Register with Blizzard's own ESC-closes-this-frame mechanism.
      table.insert(UISpecialFrames, frame:GetName())

      frame:Hide()
      frame:HookScript("OnHide", function()
        root:SetVisibility("GONE")
      end)

      return frame
    end
  })

  root.TitleRow = root:AddRow({
    height = 32,
    paddingLeft = Widgets:Padding(),
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent })
      frame:SetBackdropColor(Colors.DarkGrey:GetRGB())
      return frame
    end
  })

  root.TitleText = root.TitleRow:AddChild({
    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString("$parent_TitleText", "ARTWORK", "GameFontNormalLarge")
      fontString:SetWordWrap(false)
      fontString:SetJustifyH("LEFT")
      fontString:SetText(options.titleText)
      return fontString
    end
  })

  root.CloseButton = root.TitleRow:AddChild({
    width = 24,
    --- @param parent Frame
    frameFactory = function(parent)
      local button = CreateFrame("Button", "$parent_CloseButton", parent, "UIPanelCloseButton")
      button:SetScript("OnClick", function()
        root:SetVisibility("GONE")
        root:Layout()
      end)
      return button
    end
  })

  return root
end
