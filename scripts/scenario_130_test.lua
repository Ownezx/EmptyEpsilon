-- Name: Testing json and toml
-- Description: 
---
--- 
-- Type: Development

--- Scenario
-- @script scenario_404_test

local json = require("libs/json.lua") -- Updated to use json.lua module
local toml = require("libs/toml.lua") -- LuaRocks-installed TOML module

function init()
    -- JSON parsing
    print("Parsed JSON:", json.decode('[1,2,3,{"x":10}]'))

    -- TOML parsing
    local toml_data = [[
        var1 = 10
        var2 = 5
    ]]
    local parsed_toml = toml.parse(toml_data)
    print("Parsed TOML:", parsed_toml)
end

function update(delta)
    -- No victory condition
end
