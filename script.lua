-- MM2 Enhanced loader
-- Execute this file (or the GitHub raw URL). It never calls loadstring on nil.

local BASE = "https://raw.githubusercontent.com/jhenielpr/script/main/"

local function fetch(file)
    local url = BASE .. file .. "?cb=" .. tostring(os.clock())
    local ok, src = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok then
        error("[MM2 Enhanced] HttpGet failed for " .. file .. ": " .. tostring(src), 0)
    end
    if type(src) ~= "string" or #src < 40 then
        error("[MM2 Enhanced] Empty download for " .. file .. " (" .. type(src) .. " len=" .. tostring(src and #src) .. ")", 0)
    end
    return src
end

local function run(file)
    local src = fetch(file)
    local chunk, err = loadstring(src, "=" .. file)
    if type(chunk) ~= "function" then
        error("[MM2 Enhanced] " .. file .. " compile failed: " .. tostring(err or chunk), 0)
    end
    return chunk()
end

print("[MM2 Enhanced] loading pphud.lua ...")
local library = run("pphud.lua")
if type(library) ~= "table" or type(library.Window) ~= "function" then
    error("[MM2 Enhanced] pphud.lua did not return a library table.", 0)
end
getgenv().MM2PPHUD = library

print("[MM2 Enhanced] loading mm2.lua ...")
run("mm2.lua")
print("[MM2 Enhanced] ready")
