--- @diagnostic disable: undefined-global, missing-fields

-- ============================================================================
-- Harness
-- ============================================================================

--- @class TestHarness
local Harness = {
  --- Addon name passed to each loaded file.
  ADDON_NAME = "Tamed"
}

--- Returns a test context with its own addon table. Set mocks before loading the files that use them, and use a
--- new context for each scenario.
--- @return TestContext Context
function Harness:NewContext()
  --- The globals that loaded files see. Anything not set here is read from the real `_G`.
  --- @type table<string, any>
  local globals = setmetatable({}, {
    __index = function(self, k)
      -- Loaded files that use `_G` get these globals, so they cannot write to the real ones.
      if k == "_G" then return self end
      return _G[k]
    end
  })

  --- @type table<string, table>
  local mockedModules = {}

  --- @class TestContext
  local Context = {
    --- @type Addon
    Addon = {}
  }

  --- Sets a WoW global. Returns the context.
  --- @param name string
  --- @param value any
  --- @return TestContext Context
  function Context:SetGlobal(name, value)
    globals[name] = value
    return self
  end

  --- Sets the table that `Addon:GetModule(name)` returns. Returns the context.
  --- @param name string
  --- @param module table
  --- @return TestContext Context
  function Context:SetModule(name, module)
    mockedModules[name:upper()] = module
    return self
  end

  --- Loads a source file into the context. Returns the context.
  --- @param path string
  --- @return TestContext Context
  function Context:Load(path)
    local chunk = assert(loadfile(path))
    setfenv(chunk, globals)
    chunk(Harness.ADDON_NAME, self.Addon)
    return self
  end

  --- Returns the module with the given name, or its mock if one was set.
  --- @param name string
  --- @return table
  function Context:GetModule(name)
    return self.Addon:GetModule(name)
  end

  -- WoW globals read while `src/_init.lua` loads.
  Context:SetGlobal("C_AddOns", { GetAddOnMetadata = function(str) return str end })
  Context:SetGlobal("LibStub", function() return {} end)

  Context:Load("src/_init.lua")

  local getModule = Context.Addon.GetModule

  --- Returns the mock if one was set.
  function Context.Addon:GetModule(key)
    return mockedModules[key:upper()] or getModule(self, key)
  end

  return Context
end

return Harness
