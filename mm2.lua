-- MM2 Enhanced
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local PathfindingService = game:GetService("PathfindingService")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

getgenv().MM2EnhancedPersist = getgenv().MM2EnhancedPersist or {}

-- ============================
-- PPHUD (extended: Input, Keybind, Notify, Save/Load)
-- Loader may already have set getgenv().MM2PPHUD so we never loadstring(nil).
-- ============================
local library = rawget(getgenv(), "MM2PPHUD")
if type(library) ~= "table" or type(library.Window) ~= "function" then
    local okFetch, pphudSource = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/jhenielpr/script/main/pphud.lua")
    end)
    if not okFetch or type(pphudSource) ~= "string" or #pphudSource < 40 then
        error("[MM2 Enhanced] PPHUD download failed: " .. tostring(pphudSource), 0)
    end
    local pphudChunk, compileErr = loadstring(pphudSource, "=pphud.lua")
    if type(pphudChunk) ~= "function" then
        error("[MM2 Enhanced] PPHUD compile failed: " .. tostring(compileErr or pphudChunk), 0)
    end
    library = pphudChunk()
end
if type(library) ~= "table" or type(library.Window) ~= "function" then
    error("[MM2 Enhanced] PPHUD did not return a library table.", 0)
end

local rawWindow = library:Window({ Text = "MM2 Enhanced  v4.5" })

local flagValues = {}
local loadingConfig = false

local window = {}

function window:Get(name)
    local value = library.Flags and library.Flags[name]
    if value ~= nil then
        return value
    end
    return flagValues[name]
end

function window:Notify(data)
    local ok, result = pcall(function()
        return rawWindow:Notify(data)
    end)
    if not ok then
        warn("[MM2 Enhanced] Notify: " .. tostring(result))
        return
    end
    return result
end

window.Toast = window.Notify

function window:Save()
    return rawWindow:Save("MM2Enhanced")
end

function window:Load()
    return rawWindow:Load("MM2Enhanced")
end

function window:Unload()
    pcall(function()
        rawWindow:Exit()
    end)
end

function window:ToggleHide()
    rawWindow:Toggle()
end

function window:ChangeTheme()
end

function window:Navigate()
end

function window:CreateTab(config)
    local tab = rawWindow:Tab({ Text = config.name or config.Name or "Tab" })
    local lastSection = nil
    local useRight = false

    local function currentSection()
        if not lastSection then
            lastSection = tab:Section({ Text = "General", Side = "Left" })
        end
        return lastSection
    end

    function tab:CreateSection(section)
        useRight = not useRight
        lastSection = tab:Section({
            Text = section.name or section.Name or "Section",
            Side = useRight and "Left" or "Right",
        })
        return lastSection
    end

    function tab:CreateToggle(element)
        if element.flag then
            flagValues[element.flag] = element.value == true
        end
        return currentSection():Check({
            Text = element.name,
            Flag = element.flag,
            Default = element.value == true,
            Callback = element.callback or function() end,
        })
    end

    function tab:CreateSlider(element)
        if element.flag then
            flagValues[element.flag] = element.value
            library.Flags[element.flag] = element.value
        end
        return currentSection():Slider({
            Text = element.name,
            Flag = element.flag,
            Minimum = element.range and element.range[1] or 0,
            Maximum = element.range and element.range[2] or 100,
            Default = element.value or 0,
            Incrementation = element.increment or 1,
            Postfix = element.suffix or "",
            Callback = element.callback or function() end,
        })
    end

    function tab:CreateDropdown(element)
        local current = element.value
        if type(current) == "table" then
            current = current[1]
        end
        if element.flag then
            flagValues[element.flag] = current
            library.Flags[element.flag] = current
        end
        local drop = currentSection():Dropdown({
            Text = element.name,
            Flag = element.flag,
            List = element.options or {},
            Default = current,
            Multi = element.multiSelect == true,
            Callback = function(value)
                if element.flag then
                    flagValues[element.flag] = value
                    library.Flags[element.flag] = value
                end
                if element.callback then
                    element.callback(value)
                end
            end,
        })
        return drop
    end

    function tab:CreateInput(element)
        if element.flag then
            flagValues[element.flag] = element.value or ""
        end
        return currentSection():Input({
            Text = element.name,
            Flag = element.flag,
            Default = element.value or "",
            Placeholder = element.placeholder or "",
            Callback = element.callback or function() end,
        })
    end

    function tab:CreateKeybind(element)
        return currentSection():Keybind({
            Text = element.name,
            Flag = element.flag,
            Default = element.value,
            Callback = element.callback or function() end,
        })
    end

    function tab:CreateButton(element)
        return currentSection():Button({
            Text = element.name,
            Callback = element.callback or function() end,
        })
    end

    function tab:CreateStat(element)
        local label = currentSection():Label({
            Text = (element.name or "Stat") .. ": " .. tostring(element.value or "") .. tostring(element.suffix or ""),
        })
        return {
            Set = function(_, value)
                if label and label.Set then
                    label:Set((element.name or "Stat") .. ": " .. tostring(value) .. tostring(element.suffix or ""))
                end
            end,
        }
    end

    return tab
end

local function pickFn(...)
    for i = 1, select("#", ...) do
        local fn = select(i, ...)
        if type(fn) == "function" then
            return fn
        end
    end
    return nil
end

local queueteleport = pickFn(queue_on_teleport, syn and syn.queue_on_teleport, fluxus and fluxus.queue_on_teleport)
local everyClipboard = pickFn(setclipboard, toclipboard, set_clipboard, Clipboard and Clipboard.set)
local getcustomasset = pickFn(getcustomasset, getsynasset)
local getconnections = pickFn(getconnections, get_signal_cons)

local missingRequired, missingOptional = {}, {}
if type(writefile) ~= "function" then table.insert(missingRequired, "writefile (Rayfield config auto-save)") end
if type(readfile) ~= "function" then table.insert(missingRequired, "readfile (Rayfield config load)") end
if type(isfile) ~= "function" then table.insert(missingRequired, "isfile (Rayfield config load)") end
if type(makefolder) ~= "function" then table.insert(missingRequired, "makefolder (Rayfield config folder)") end
if type(firetouchinterest) ~= "function" then table.insert(missingOptional, "firetouchinterest (knife kill-all)") end
if type(getconnections) ~= "function" then table.insert(missingOptional, "getconnections (Anti Idle)") end
if type(getcustomasset) ~= "function" then table.insert(missingOptional, "getcustomasset (Los Pollos)") end
if type(queueteleport) ~= "function" then table.insert(missingOptional, "queue_on_teleport (farm rejoin)") end
if type(everyClipboard) ~= "function" then table.insert(missingOptional, "setclipboard (copy JobId)") end

-- ============================
-- SETTINGS STATE
-- ============================
local Settings = {
    WalkSpeed = 16,
    JumpPower = 50,
    CoinFarmSpeed = 55,
    CoinPickupRange = 100,
    CoinTeleportDelay = 0.05,
    InvisibleHipHeight = 0.08,
    HitboxSize = 5,
    BringMode = "All",
    AutoFling = false,
    AutoVote = false,
    VoteTarget = "Random",
    AutofarmMode = "Fast",
}

local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 55, 55),
    Sheriff = Color3.fromRGB(50, 145, 255),
    Innocent = Color3.fromRGB(100, 255, 130),
}
local SPECTATOR_COLOR = Color3.fromRGB(170, 175, 190)

local function getStrokeColor(color)
    return color:Lerp(Color3.new(0, 0, 0), 0.45)
end

local COIN_ESP_COLOR = Color3.fromRGB(255, 215, 0)

local KNOWN_MAPS = {
    "Random",
    "Bank2",
    "Bio Lab",
    "Factory",
    "Hospital",
    "Hospital3",
    "House2",
    "Mansion2",
    "MilBase",
    "nStudio",
    "Office3",
    "Pier",
    "Police Station",
    "Research Facility",
    "Wild West",
    "Workplace",
    "Barn",
}

-- ============================
-- CORE STATE
-- ============================
local farmRunning = false
local gunFarmRunning = false
local farmCooldowns = setmetatable({}, { __mode = "k" }) -- weak keys so destroyed coins GC
local currentTarget = nil
local currentMode = nil
local flingMode = "Murderer"
local targetInputText = ""
local flinging = false
local advancedFling
local noclipConnection = nil
local antiflingConnection = nil
local bringLoop = false
local uiRunning = true
local selectedPlayerName = nil
local antiIdleConnection = nil
local INVISIBLE_ANIMATION_ID = "rbxassetid://122954953446602"

-- ============================
-- UNLOAD FUNCTION
-- ============================
local allConnections = {}
local scriptUnloaded = false

-- Forward declarations used by unloadScript.
local disableInvisible, disableNoclip, disableAntifling
local clearCoinContainerHooks, invalidateMapCache
local removeVisuals, removeCoinESP, removeGunESP, destroyEspFolder, destroyFovCircle
local cachedCoins, cachedVotePads, coinVisuals, gunDropVisuals
local infectionActive, infectionConn
local destroyRoundHud
local stopAntiIdle
local getCharacterParts, getRoot, getRole, getFlag, asNumber
local hasTool, isSpectator, findPlayerByText
local enableNoclip, enableInvisible, enableAntifling, enableAntiIdle
local coinFarmLoop, gunFarmLoop, collectGun, applyFarmRendering
local updateCoinESP, updateGunESP, refreshAllPlayers, updateRoundHud
local getAvailableCoins, flingByMode, canUseFarmAutomation
local aimbotEnabled, aiming, aimbotTargetName, predictBox

local function trackConnection(connection)
    if connection then
        table.insert(allConnections, connection)
    end
    return connection
end

local function destroyTrackedGui(parent, name)
    if not parent then return end
    local inst = parent:FindFirstChild(name)
    if inst then
        pcall(function() inst:Destroy() end)
    end
end

local function sweepScriptGuis()
    local parents = {}
    pcall(function()
        table.insert(parents, game:GetService("CoreGui"))
    end)
    pcall(function()
        table.insert(parents, LocalPlayer:FindFirstChildOfClass("PlayerGui"))
    end)
    local names = {
        "MM2RoundHUD",
        "MM2EnhancedESP",
        "Fluent",
        "Rayfield",
        "MM2 Enhanced",
        "MM2Enhanced",
    }
    for _, parent in ipairs(parents) do
        for _, name in ipairs(names) do
            destroyTrackedGui(parent, name)
        end
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                local n = child.Name
                if child:IsA("ScreenGui") or child:IsA("Folder") then
                    if string.find(n, "Fluent", 1, true)
                        or string.find(n, "Rayfield", 1, true)
                        or string.find(n, "MM2 Enhanced", 1, true)
                        or string.find(n, "MM2Enhanced", 1, true)
                    then
                        child:Destroy()
                    end
                end
            end
        end)
    end
end

local function unloadScript()
   if scriptUnloaded then return end
   scriptUnloaded = true
   loadingConfig = true

   -- Stop all loops / feature flags (getFlag returns false for booleans after this)
   uiRunning = false
   farmRunning = false
   gunFarmRunning = false
   Settings.AutoFling = false
   Settings.AutoVote = false
   flinging = false
   bringLoop = false
   infectionActive = false
   currentTarget = nil
   currentMode = nil
   aimbotEnabled = false
   aiming = false

   pcall(function()
      for key, value in pairs(flagValues) do
         if type(value) == "boolean" then
            flagValues[key] = false
         end
      end
      flagValues.EnableAimbot = false
      flagValues.SilentAim = false
      flagValues.AutoCoins = false
      flagValues.AutoGunDrop = false
      flagValues.FarmNoRender = false
      flagValues.EnableHitboxes = false
      flagValues.EnableESP = false
      flagValues.CoinESP = false
      flagValues.GunESP = false
      flagValues.RoundHUD = false
      flagValues.AntiIdle = false
      flagValues.LosPollosInfect = false
      flagValues.InvisibleKeybindEnabled = false
      flagValues.AutoFling = false
      flagValues.AdvancedFling = false
      flagValues.AimbotFOVCircle = false
      flagValues.AimbotPredictBox = false
   end)
   pcall(function()
      if library and library.Flags then
         for key, value in pairs(library.Flags) do
            if type(value) == "boolean" then
               library.Flags[key] = false
            end
         end
      end
   end)
   pcall(function()
      local persist = getgenv().MM2EnhancedPersist
      if persist then
         persist.AutoCoins = false
         persist.AutoGunDrop = false
         persist.FarmNoRender = false
         persist.EnableAimbot = false
      end
   end)

   -- Disable features (pcall in case not yet defined)
   pcall(disableInvisible)
   pcall(disableNoclip)
   pcall(disableAntifling)
   pcall(function()
      if stopAntiIdle then stopAntiIdle() end
   end)
   pcall(clearCoinContainerHooks)
   pcall(function()
      if destroyRoundHud then destroyRoundHud() end
   end)

   if infectionConn then
      pcall(function() infectionConn:Disconnect() end)
      infectionConn = nil
   end
   if noclipConnection then
      pcall(function() noclipConnection:Disconnect() end)
      noclipConnection = nil
   end
   if antiflingConnection then
      pcall(function() antiflingConnection:Disconnect() end)
      antiflingConnection = nil
   end
   if antiIdleConnection then
      pcall(function() antiIdleConnection:Disconnect() end)
      antiIdleConnection = nil
   end
   if invisibleCollisionConnection then
      pcall(function() invisibleCollisionConnection:Disconnect() end)
      invisibleCollisionConnection = nil
   end

   -- Disconnect all tracked connections
   for _, conn in ipairs(allConnections) do
      if conn then
         pcall(function()
            conn:Disconnect()
         end)
      end
   end
   table.clear(allConnections)

   -- Clean up all ESP visuals
   pcall(function()
      for _, player in ipairs(Players:GetPlayers()) do
         pcall(removeVisuals, player)
      end
   end)
   pcall(function() table.clear(playerRoleCache) end)
   pcall(function()
      if playerEsp then table.clear(playerEsp) end
   end)

   pcall(function()
      for coin in pairs(coinVisuals) do
         pcall(removeCoinESP, coin)
      end
      table.clear(coinVisuals)
      table.clear(cachedCoins)
   end)

   pcall(function()
      for part in pairs(gunDropVisuals) do
         pcall(removeGunESP, part)
      end
      table.clear(gunDropVisuals)
   end)
   pcall(function()
      if destroyEspFolder then destroyEspFolder() end
   end)

   -- Reset local character
   local character = LocalPlayer.Character
   local hum = character and character:FindFirstChildWhichIsA("Humanoid")
   local root = character and character:FindFirstChild("HumanoidRootPart")
   if hum then
      pcall(function()
         hum.WalkSpeed = 16
         hum.JumpPower = 50
         hum.PlatformStand = false
         hum.AutoRotate = true
         if invisibleOldHipHeight ~= nil then
            hum.HipHeight = invisibleOldHipHeight
         end
      end)
   end
   if root then
      pcall(function()
         root.AssemblyLinearVelocity = Vector3.zero
         root.AssemblyAngularVelocity = Vector3.zero
         root.CanCollide = true
      end)
   end

   -- Reset hitboxes
   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character then
         local hrp = player.Character:FindFirstChild("HumanoidRootPart")
         if hrp then
            pcall(function()
               hrp.Size = Vector3.new(2, 2, 1)
               hrp.Transparency = 0
               hrp.CanCollide = false
            end)
         end
      end
   end

   -- Clear caches
   pcall(invalidateMapCache)
   pcall(function() table.clear(cachedVotePads) end)
   pcall(function() table.clear(farmCooldowns) end)

   pcall(function()
      RunService:Set3dRenderingEnabled(true)
   end)
   pcall(destroyFovCircle)

   -- Unload UI and leftover ScreenGuis (also disconnects PPHUD keybinds / Q hide)
   pcall(function() window:Unload() end)
   pcall(sweepScriptGuis)

   print("[MM2 Enhanced] Fully unloaded")
end

-- Invisible mode state
local invisibleEnabled = false
local invisibleAnimConnection = nil -- the playing AnimationTrack
local invisibleCharConn = nil
local invisibleConnection = nil
local invisibleAnimationTrack = nil
local invisibleAnimationAsset = nil
local invisibleCollisionConnection = nil
local invisibleCollisionStates = {}
local invisibleOldHipHeight = nil

-- Cached map / coins (avoids GetDescendants spam)
local cachedMap = nil
local cachedCoinContainer = nil
cachedCoins = {} -- [BasePart] = true
local coinCacheDirty = true
local mapScanAt = 0
local MAP_SCAN_INTERVAL = 2

-- Cached gun drop (avoids GetDescendants spam in gun ESP)
local cachedGunDropPart = nil
local function invalidateGunDropCache()
    cachedGunDropPart = nil
end

-- ============================
-- HELPERS
-- ============================
do
getCharacterParts = function(player)
    player = player or LocalPlayer
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then return nil end
    return character, humanoid, rootPart
end

getRoot = function(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
end

hasTool = function(player, toolName)
    local backpack = player:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(toolName) then return true end
    local character = player.Character
    if character and character:FindFirstChild(toolName) then return true end
    return false
end

getRole = function(player)
    if hasTool(player, "Knife") then return "Murderer" end
    if hasTool(player, "Gun") then return "Sheriff" end
    return "Innocent"
end

isSpectator = function(player)
    if not player then
        return true
    end

    local attrAlive = player:GetAttribute("Alive")
    if attrAlive == false then
        return true
    end

    local character = player.Character
    if not character or not character.Parent then
        return true
    end

    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return true
    end
    local okState, state = pcall(function()
        return humanoid:GetState()
    end)
    if okState and state == Enum.HumanoidStateType.Dead then
        return true
    end

    local lobby = Workspace:FindFirstChild("Lobby")
    if lobby and character:IsDescendantOf(lobby) then
        return true
    end

    -- Mid-round: people standing in the lobby are spectators even if Alive is stale.
    local map = cachedMap
    if not (map and map.Parent) then
        for _, object in ipairs(Workspace:GetChildren()) do
            if object:IsA("Model") and object:GetAttribute("MapID") ~= nil then
                map = object
                break
            end
        end
    end
    if map and lobby then
        local root = getRoot(character)
        if root then
            if root:IsDescendantOf(lobby) then
                return true
            end
            local ok, cf, size = pcall(function()
                return lobby:GetBoundingBox()
            end)
            if ok and cf and size then
                local localPos = cf:PointToObjectSpace(root.Position)
                if math.abs(localPos.X) <= size.X * 0.5
                    and math.abs(localPos.Y) <= size.Y * 0.5
                    and math.abs(localPos.Z) <= size.Z * 0.5
                then
                    return true
                end
            end
        end
    end

    return false
end

local function getEspRole(player)
    if isSpectator(player) then
        return "Spectator"
    end
    return getRole(player)
end

local function isLocalPlayerAlive()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return LocalPlayer:GetAttribute("Alive") == true
        and humanoid ~= nil
        and humanoid.Health > 0
end

canUseFarmAutomation = function()
    if not isLocalPlayerAlive() then
        return false, "You must be alive"
    end

    local role = getRole(LocalPlayer)
    if role == "Murderer" or role == "Sheriff" then
        return false, role .. " cannot use coin or gun automation"
    end

    return true
end

findPlayerByText = function(text)
    text = string.lower(text or "")
    if text == "" then return nil end
    local partialMatch
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local name = string.lower(player.Name)
            local display = string.lower(player.DisplayName)
            if name == text or display == text then return player end
            if string.sub(name, 1, #text) == text or string.sub(display, 1, #text) == text then
                partialMatch = partialMatch or player
            end
        end
    end
    return partialMatch
end

getFlag = function(name, fallback)
    if scriptUnloaded then
        if type(fallback) == "boolean" then
            return false
        end
        return fallback
    end
    local ok, value = pcall(function()
        return window:Get(name)
    end)
    if ok and value ~= nil then
        if type(value) == "table" then
            return value[1] or fallback
        end
        return value
    end
    if flagValues[name] ~= nil then
        return flagValues[name]
    end
    return fallback
end

local function set3dRenderingEnabled(enabled)
    pcall(function()
        RunService:Set3dRenderingEnabled(enabled)
    end)
end

-- Disable 3D rendering while farming when the Farm tab toggle is on (lowers CPU).
applyFarmRendering = function()
    local farmActive = getFlag("AutoCoins", false) or getFlag("AutoGunDrop", false)
    local noRender = getFlag("FarmNoRender", false)
    set3dRenderingEnabled(not (farmActive and noRender))
end

-- WindUI sliders sometimes pass a table or string — always normalize to number
asNumber = function(value, fallback)
    if type(value) == "table" then
        value = value[1]
    end
    local n = tonumber(value)
    if n == nil then
        return fallback
    end
    return n
end

stopAntiIdle = function()
    if antiIdleConnection then
        pcall(function() antiIdleConnection:Disconnect() end)
        antiIdleConnection = nil
    end
end

enableAntiIdle = function()
    if getconnections then
        for _, connection in ipairs(getconnections(LocalPlayer.Idled)) do
            pcall(function() connection:Disable() end)
            pcall(function() connection:Disconnect() end)
        end
    end

    stopAntiIdle()
    antiIdleConnection = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end)
end

-- A coin is active only while its visible mesh is still present.
-- Coin_Server can contain CoinVisual/MainCoin at different nesting depths.
local function isActiveCoin(coin)
    if not coin or not coin.Parent then
        return false
    end

    local coinVisual = coin:FindFirstChild("CoinVisual", true)
    local mainCoin = coinVisual and coinVisual:FindFirstChild("MainCoin", true)

    return mainCoin
        and mainCoin:IsA("MeshPart")
        and mainCoin.Transparency < 1
end

-- ============================
-- NOCLIP (only flip parts that still collide)
-- ============================
enableNoclip = function()
    if noclipConnection then return end
    noclipConnection = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end)
end

disableNoclip = function()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
end

-- ============================
-- INVISIBLE — PlatformStand + stop all tracks (replicates to server)
-- Body non-collide, HRP collidable.
-- ============================

local function stopInvisibleAnim()
    if invisibleAnimConnection then
        invisibleAnimConnection:Disconnect()
        invisibleAnimConnection = nil
    end

    if invisibleAnimationTrack then
        pcall(function()
            invisibleAnimationTrack:Stop(0.1)
            invisibleAnimationTrack:Destroy()
        end)
        invisibleAnimationTrack = nil
    end

    if invisibleAnimationAsset then
        pcall(function() invisibleAnimationAsset:Destroy() end)
        invisibleAnimationAsset = nil
    end
end

local function normalizeLocalCharacterCollision(character)
    if not character then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            if part == root then
                part.CanCollide = true
            else
                part.CanCollide = false
            end
        end
    end
end

trackConnection(RunService.Stepped:Connect(function()
    if scriptUnloaded then return end
    normalizeLocalCharacterCollision(LocalPlayer.Character)
end))

local function setInvisibleCollision(enabled)
    if enabled then
        if invisibleCollisionConnection then return end

        table.clear(invisibleCollisionStates)
        invisibleCollisionConnection = RunService.Stepped:Connect(function()
            local character = LocalPlayer.Character
            if not character then return end

            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if invisibleCollisionStates[part] == nil then
                        invisibleCollisionStates[part] = part.CanCollide
                    end
                    local root = character:FindFirstChild("HumanoidRootPart")
                    part.CanCollide = part == root
                end
            end
        end)
    else
        if invisibleCollisionConnection then
            invisibleCollisionConnection:Disconnect()
            invisibleCollisionConnection = nil
        end

        for part, oldCanCollide in pairs(invisibleCollisionStates) do
            if part and part.Parent then
                part.CanCollide = oldCanCollide
            end
        end
        table.clear(invisibleCollisionStates)
        normalizeLocalCharacterCollision(LocalPlayer.Character)
    end
end

local function playInvisibleAnimation(humanoid)
    if not humanoid then return false, "Humanoid missing" end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = humanoid
    end

    local animation = Instance.new("Animation")
    animation.Name = "MM2InvisibleAnimation"
    animation.AnimationId = INVISIBLE_ANIMATION_ID

    local loadedTrack, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if not loadedTrack or not track then
        animation:Destroy()
        return false, "Emote animation could not be loaded by this client"
    end

    track.Priority = Enum.AnimationPriority.Action
    track.Looped = true
    track:Play(0.1, 1, 1)

    invisibleAnimationTrack = track
    invisibleAnimationAsset = animation
    animation.Parent = humanoid
    return true
end

-- Desync invisible: teleport real character to sky (server sees it there = "invisible" on ground),
-- create a local fake clone to control for your own view.
local invisibleFakeChar = nil
local invisibleRealPos = nil

local function playInvisibleOnCharacter(character)
    if not character then return false end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildWhichIsA("Humanoid")
    if not hrp or not hum then return false end

    stopInvisibleAnim()

    local animationLoaded, animationError = playInvisibleAnimation(hum)
    if not animationLoaded then
        warn("[Invisible] Emote animation unavailable: " .. tostring(animationError))
        return false
    end

    invisibleOldHipHeight = hum.HipHeight
    hum.HipHeight = Settings.InvisibleHipHeight
    setInvisibleCollision(true)

    print("[Invisible] Keyframe animation active")
    return true
end

--[[ Legacy desync fallback intentionally disabled.

    -- Save current position so we can return to it
    invisibleRealPos = hrp.CFrame

    -- Clone the character for local visual only
    character.Archivable = true
    local clone = character:Clone()
    character.Archivable = false

    if not clone then return false end
    clone.Name = "MM2FakeChar"

    -- Strip scripts and humanoid from clone so it doesn't interfere
    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("Script") or v:IsA("LocalScript") or v:IsA("ModuleScript") then
            v:Destroy()
        end
    end
    local cloneHum = clone:FindFirstChildWhichIsA("Humanoid")
    if cloneHum then cloneHum:Destroy() end

    -- Anchor all clone parts — no-collision, no physics
    for _, v in ipairs(clone:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Anchored = true
            v.CanCollide = false
            v.CanTouch = false
            v.CanQuery = false
        end
    end

    clone.Parent = workspace
    invisibleFakeChar = clone

    -- Teleport real character way up into the sky — server sees you there
    -- Other players see nothing at your ground position
    hrp.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 9999, 0))

    -- Every Heartbeat: sync fake clone to camera direction + WASD input
    -- and keep real HRP in sky
    invisibleAnimConnection = RunService.Heartbeat:Connect(function()
        if not invisibleEnabled then return end
        local char2 = LocalPlayer.Character
        if not char2 then return end
        local hrp2 = char2:FindFirstChild("HumanoidRootPart")
        local hum2 = char2:FindFirstChildWhichIsA("Humanoid")
        if not hrp2 or not hum2 then return end

        -- Keep real char in sky (server position)
        if hrp2.Position.Y < 9000 then
            hrp2.CFrame = CFrame.new(hrp2.Position.X, 9999, hrp2.Position.Z)
        end

        -- Sync fake clone to where YOU think you are locally
        if invisibleFakeChar then
            local fakeHRP = invisibleFakeChar:FindFirstChild("HumanoidRootPart")
            if fakeHRP then
                -- Move fake char with player input
                local cam = workspace.CurrentCamera
                local moveDir = hum2.MoveDirection
                if moveDir.Magnitude > 0 then
                    invisibleRealPos = CFrame.new(
                        invisibleRealPos.Position + moveDir * (hum2.WalkSpeed * 0.016)
                    ) * CFrame.Angles(0, math.atan2(-moveDir.X, -moveDir.Z), 0)
                end
                -- Sync all parts of clone to offset from where real char joints are
                for _, part in ipairs(invisibleFakeChar:GetDescendants()) do
                    if part:IsA("BasePart") then
                        local realPart = char2:FindFirstChild(part.Name, true)
                        if realPart and realPart:IsA("BasePart") then
                            local offset = realPart.CFrame * hrp2.CFrame:Inverse()
                            part.CFrame = offset * invisibleRealPos
                        end
                    end
                end
            end
        end
    end)

    print("[Invisible] Desync active" .. (animationLoaded and " with Invisible animation" or " with fallback"))
    return true
end
]]


disableInvisible = function()
    invisibleEnabled = false

    if invisibleConnection then
        invisibleConnection:Disconnect()
        invisibleConnection = nil
    end
    if invisibleCharConn then
        invisibleCharConn:Disconnect()
        invisibleCharConn = nil
    end

    stopInvisibleAnim()
    setInvisibleCollision(false)

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    if humanoid and invisibleOldHipHeight ~= nil then
        humanoid.HipHeight = invisibleOldHipHeight
    end
    invisibleOldHipHeight = nil

    -- Destroy the fake clone
    if invisibleFakeChar then
        pcall(function() invisibleFakeChar:Destroy() end)
        invisibleFakeChar = nil
    end

    -- Teleport real character back to where they were standing
    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp and invisibleRealPos then
            hrp.CFrame = invisibleRealPos
        end
        invisibleRealPos = nil
    end
end

local function maintainInvisibleCollisions(character)
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    for _, desc in ipairs(character:GetDescendants()) do
        if desc:IsA("BasePart") then
            desc.CanCollide = desc == root
        end
    end
end

enableInvisible = function()
    if invisibleEnabled then return end
    invisibleEnabled = true

        local function setupCharacter(character)
            if not invisibleEnabled or not character or not character.Parent then
                warn("[Invisible] Character invalid after wait")
                return
            end

            -- Ensure humanoid exists
            local humanoid = character:FindFirstChildWhichIsA("Humanoid")
            if not humanoid then
                warn("[Invisible] No humanoid found")
                return
            end

            local played = playInvisibleOnCharacter(character)
            pcall(function()
                if not played then
                    window:Notify({
                        title = "Invisible Failed",
                        content = "Could not load the Invisible Me emote animation. Check console (F9).",
                        duration = 5,
                    })
                else
                    window:Toast({
                        title = "Invisible",
                        subtitle = "Animation playing",
                        duration = 2,
                    })
                end
            end)
        end

    if LocalPlayer.Character then
        task.spawn(setupCharacter, LocalPlayer.Character)
    end

    if invisibleCharConn then
        invisibleCharConn:Disconnect()
    end
    invisibleCharConn = LocalPlayer.CharacterAdded:Connect(function(character)
        if invisibleEnabled then
            setupCharacter(character)
        end
    end)

end

-- ============================
-- ANTIFLING (HRP only — far cheaper than all descendants)
-- ============================
enableAntifling = function()
    if antiflingConnection then return end
    antiflingConnection = RunService.Heartbeat:Connect(function()
        -- Cache players list to avoid repeated GetPlayers calls
        local playersList = Players:GetPlayers()
        for _, player in ipairs(playersList) do
            if player ~= LocalPlayer then
                local char = player.Character
                if char then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp and hrp.CanCollide then
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end)
end

disableAntifling = function()
    if antiflingConnection then
        antiflingConnection:Disconnect()
        antiflingConnection = nil
    end
end

end
do
-- ============================
-- FLING ENGINE
-- ============================
local activeAnimTrack = nil

local function playFlingAnimation(humanoid)
    if not humanoid then return end
    local animId = getFlag("FlingAnimID", "rbxassetid://129881979528827")
    if animId == "" then animId = "rbxassetid://129881979528827" end
    if not string.find(animId, "rbxassetid://", 1, true) then
        animId = "rbxassetid://" .. animId
    end

    local anim = Instance.new("Animation")
    anim.AnimationId = animId

    local success, track = pcall(function()
        return humanoid:LoadAnimation(anim)
    end)

    if success and track then
        track.Priority = Enum.AnimationPriority.Action
        track:Play()
        activeAnimTrack = track
    end
end

local function stopFlingAnimation()
    if activeAnimTrack then
        activeAnimTrack:Stop()
        activeAnimTrack = nil
    end
end

local function walkFling(targetPlayer, silent)
    if not targetPlayer then
        if not silent then
            window:Notify({
                title = "Fling Failed",
                content = "No target found for mode: " .. tostring(flingMode),
                duration = 4,
            })
        end
        return
    end

    local targetChar = targetPlayer.Character
    local targetRoot = getRoot(targetChar)
    local myChar, myHum, myRoot = getCharacterParts()

    if not targetRoot or not myRoot or not myHum then
        if not silent then
            window:Notify({
                title = "Fling Failed",
                content = "Missing character or root part.",
                duration = 4,
            })
        end
        return
    end

    if flinging then return end
    flinging = true

    local duration = tonumber(getFlag("FlingDuration", 1)) or 1
    local useInvis = getFlag("InvisibleFling", true)
    local oldFallen = workspace.FallenPartsDestroyHeight
    workspace.FallenPartsDestroyHeight = 0 / 0

    if getFlag("UseFlingAnim", false) then
        playFlingAnimation(myHum)
    end

    local bav = Instance.new("BodyAngularVelocity")
    bav.Name = "IY_FlingTorque"
    bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bav.P = math.huge
    bav.AngularVelocity = Vector3.new(0, 9e8, 0)
    bav.Parent = myRoot

    -- Add linear velocity force for extra launch power
    local bv = Instance.new("BodyVelocity")
    bv.Name = "IY_FlingVelocity"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.P = math.huge
    bv.Velocity = Vector3.new(0, 0, 0) -- set per-frame in applyFlingFrame
    bv.Parent = myRoot

    local deathConn = myHum.Died:Connect(function()
        flinging = false
    end)

    local heartbeatConn
    local renderConn
    local currentLocalCFrame = myRoot.CFrame
    local flip = 1
    local angle = 0
    local startTime = os.clock()

    local function applyFlingFrame(prediction)
        if not flinging or not myRoot or not myRoot.Parent then return end

        local tChar = targetPlayer.Character
        local tRoot = tChar and getRoot(tChar)
        local tHum = tChar and tChar:FindFirstChildWhichIsA("Humanoid")

        if not (tRoot and tRoot.Parent and tHum and tHum.Health > 0) then
            flinging = false
            return
        end

        myRoot.CanCollide = true
        if myChar then
            for _, part in ipairs(myChar:GetChildren()) do
                if part:IsA("BasePart") and part ~= myRoot then
                    part.CanCollide = false
                end
            end
        end

        angle = angle + 100
        flip = -flip

        local targetVel = tRoot.AssemblyLinearVelocity or Vector3.zero
        local predictedPos = tRoot.CFrame + (targetVel * prediction) + Vector3.new(0, useInvis and 0.2 or 0, 0)
        local rotCFrame = CFrame.Angles(math.rad(angle), math.rad(angle), math.rad(angle))

        myRoot.CFrame = predictedPos * rotCFrame
        local highPower = 9e8 * flip
        myRoot.AssemblyLinearVelocity = Vector3.new(highPower, highPower, highPower)
        myRoot.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
        if bv and bv.Parent then
            bv.Velocity = Vector3.new(highPower, highPower, highPower)
        end
    end

    if useInvis then
        heartbeatConn = RunService.Heartbeat:Connect(function()
            applyFlingFrame(0.1)
        end)

        renderConn = RunService.RenderStepped:Connect(function(deltaTime)
            if not flinging or not myRoot or not myRoot.Parent then return end

            if myHum and myHum.MoveDirection.Magnitude > 0 then
                local speed = myHum.WalkSpeed or 16
                local moveOffset = myHum.MoveDirection * (speed * deltaTime)
                currentLocalCFrame = CFrame.new(currentLocalCFrame.Position + moveOffset) * currentLocalCFrame.Rotation
            end

            myRoot.CFrame = currentLocalCFrame
            myRoot.AssemblyLinearVelocity = Vector3.zero
            myRoot.AssemblyAngularVelocity = Vector3.zero
        end)
    else
        enableNoclip()
        heartbeatConn = RunService.Heartbeat:Connect(function()
            applyFlingFrame(0.16)
        end)
    end

    task.spawn(function()
        while flinging and (os.clock() - startTime) < duration do
            task.wait(0.05)
        end

        flinging = false

        if heartbeatConn then heartbeatConn:Disconnect() end
        if renderConn then renderConn:Disconnect() end
        disableNoclip()
        stopFlingAnimation()

        if deathConn then
            deathConn:Disconnect()
        end

        if bav and bav.Parent then
            bav:Destroy()
        end
        if bv and bv.Parent then
            bv:Destroy()
        end

        workspace.FallenPartsDestroyHeight = oldFallen

        local char = LocalPlayer.Character
        local root = getRoot(char)
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            if useInvis then
                root.CFrame = currentLocalCFrame
            end
            root.CanCollide = true
        end
    end)

    if not silent then
        window:Toast({
            title = useInvis and "Invisible Fling" or "Fling",
            subtitle = "Flinging " .. targetPlayer.Name .. " (" .. duration .. "s)",
            position = "Top",
            duration = 3,
        })
    end
end

advancedFling = function(targetPlayer, silent)
    if not targetPlayer then
        if not silent then
            window:Notify({ title = "Advanced", content = "No target found.", duration = 3 })
        end
        return
    end

    local myChar, myHum, myRoot = getCharacterParts()
    local targetChar = targetPlayer.Character
    local targetRoot = getRoot(targetChar)
    if not myChar or not myHum or not myRoot or not targetChar or not targetRoot then
        if not silent then
            window:Notify({ title = "Advanced", content = "Missing character or target root.", duration = 3 })
        end
        return
    end

    if flinging then return end
    flinging = true

    local oldCFrame = myRoot.CFrame
    local oldFallenHeight = workspace.FallenPartsDestroyHeight
    local duration = math.max(0.5, tonumber(getFlag("FlingDuration", 1)) or 1)
    local angle = 0
    local flip = 1
    local startTime = os.clock()

    pcall(function() workspace.FallenPartsDestroyHeight = 0 / 0 end)

    local angular = Instance.new("BodyAngularVelocity")
    angular.Name = "MM2AdvancedFlingTorque"
    angular.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    angular.AngularVelocity = Vector3.new(0, 9e8, 0)
    angular.Parent = myRoot

    local velocity = Instance.new("BodyVelocity")
    velocity.Name = "MM2AdvancedFlingVelocity"
    velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    velocity.P = math.huge
    velocity.Parent = myRoot

    local deathConnection = myHum.Died:Connect(function()
        flinging = false
    end)

    while flinging and os.clock() - startTime < duration do
        local currentChar = targetPlayer.Character
        local currentRoot = currentChar and getRoot(currentChar)
        local currentHumanoid = currentChar and currentChar:FindFirstChildWhichIsA("Humanoid")
        if not currentRoot or not currentHumanoid or currentHumanoid.Health <= 0 then
            break
        end

        angle = angle + 100
        flip = -flip
        local targetVelocity = currentRoot.AssemblyLinearVelocity or Vector3.zero
        local predicted = currentRoot.Position + targetVelocity * 0.08
        local offset = (flip > 0)
            and CFrame.new(0, 1.5, 0)
            or CFrame.new(0, -1.5, 0)

        myRoot.CFrame = CFrame.new(predicted) * offset * CFrame.Angles(math.rad(angle), 0, 0)
        myRoot.AssemblyLinearVelocity = Vector3.new(9e8, 9e8, 9e8)
        myRoot.AssemblyAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
        velocity.Velocity = Vector3.new(9e8, 9e8, 9e8)
        task.wait()
    end

    flinging = false
    if deathConnection then deathConnection:Disconnect() end
    if angular.Parent then angular:Destroy() end
    if velocity.Parent then velocity:Destroy() end
    pcall(function() workspace.FallenPartsDestroyHeight = oldFallenHeight end)

    if myRoot and myRoot.Parent then
        myRoot.CFrame = oldCFrame
        myRoot.AssemblyLinearVelocity = Vector3.zero
        myRoot.AssemblyAngularVelocity = Vector3.zero
    end

    if not silent then
        window:Toast({
            title = "Advanced",
            subtitle = "Flinging " .. targetPlayer.Name,
            position = "Top",
            duration = 3,
        })
    end
end

flingByMode = function(silent)
    local target
    if flingMode == "Murderer" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and getRole(p) == "Murderer" then
                target = p
                break
            end
        end
    elseif flingMode == "Sheriff" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and getRole(p) == "Sheriff" then
                target = p
                break
            end
        end
    else
        target = findPlayerByText(targetInputText)
    end
    if getFlag("AdvancedFling", false) then
        advancedFling(target, silent)
    else
        walkFling(target, silent)
    end
end

end
do
-- ============================
-- AIMBOT
-- ============================
aiming = false
aimbotEnabled = true
aimbotTargetName = ""
local fovCircle = nil
predictBox = nil

local function destroyDrawing(obj)
    if not obj then
        return
    end
    pcall(function()
        if obj.Remove then
            obj:Remove()
        elseif obj.Destroy then
            obj:Destroy()
        end
    end)
end

destroyFovCircle = function()
    destroyDrawing(fovCircle)
    fovCircle = nil
    destroyDrawing(predictBox)
    predictBox = nil
end

local function ensureFovCircle()
    if fovCircle then
        return fovCircle
    end
    if type(Drawing) == "table" and Drawing.new then
        local ok, circle = pcall(Drawing.new, "Circle")
        if ok and circle then
            circle.Filled = false
            circle.Thickness = 1.5
            circle.NumSides = 64
            circle.Color = Color3.fromRGB(120, 190, 255)
            circle.Transparency = 1
            circle.Visible = false
            fovCircle = circle
            return fovCircle
        end
    end
    return nil
end

local function ensurePredictBox()
    if predictBox then
        return predictBox
    end
    if type(Drawing) == "table" and Drawing.new then
        local ok, box = pcall(Drawing.new, "Square")
        if ok and box then
            box.Filled = false
            box.Thickness = 2
            box.Color = Color3.fromRGB(255, 40, 40)
            box.Size = Vector2.new(16, 16)
            box.Visible = false
            predictBox = box
            return predictBox
        end
    end
    return nil
end

local function getPredictedPosition(part)
    if not part then
        return nil
    end
    local method = getFlag("AimbotPredictMethod", "Velocity")
    if type(method) == "table" then
        method = method[1] or "Velocity"
    end
    local strength = tonumber(getFlag("AimbotPredict", 0.12)) or 0.12
    if method == "None" or strength <= 0 then
        return part.Position
    end
    local vel = Vector3.zero
    pcall(function()
        vel = part.AssemblyLinearVelocity or part.Velocity or Vector3.zero
    end)
    local camera = Workspace.CurrentCamera
    local dist = 0
    if camera then
        dist = (part.Position - camera.CFrame.Position).Magnitude
    end
    if method == "Distance" then
        return part.Position + vel * (dist / 280) * strength
    end
    if method == "Hybrid" then
        return part.Position + vel * (0.04 + dist / 420) * math.max(strength, 0.05)
    end
    return part.Position + vel * strength
end

local function hasWallBetween(origin, part)
    if not origin or not part then
        return true
    end
    local character = part.Parent
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local ignore = { LocalPlayer.Character, character }
    params.FilterDescendantsInstances = ignore
    local delta = part.Position - origin
    local result = Workspace:Raycast(origin, delta, params)
    if not result then
        return false
    end
    if character and result.Instance:IsDescendantOf(character) then
        return false
    end
    return true
end

local function matchesAimbotTarget(player)
    local mode = getFlag("AimbotTargetMode", "Sheriff")
    if type(mode) == "table" then
        mode = mode[1] or "Sheriff"
    end
    if isSpectator(player) then
        return false
    end
    if mode == "Target" then
        local wanted = tostring(aimbotTargetName or getFlag("AimbotTargetInput", "") or selectedPlayerName or "")
        if wanted == "" then
            return false
        end
        wanted = string.lower(wanted)
        local name = string.lower(player.Name)
        local display = string.lower(player.DisplayName)
        return name == wanted
            or display == wanted
            or string.sub(name, 1, #wanted) == wanted
            or string.sub(display, 1, #wanted) == wanted
    end
    local role = getRole(player)
    if mode == "Murderer" or mode == "Murder" then
        return role == "Murderer"
    end
    if mode == "Sheriff" then
        return role == "Sheriff"
    end
    if mode == "Innocent" or mode == "Inno" then
        return role == "Innocent"
    end
    return true
end

local function getAimKeyName()
    local key = getFlag("AimbotKey", "MouseButton2")
    if type(key) == "table" then
        key = key[1]
    end
    if typeof(key) == "EnumItem" then
        key = key.Name
    end
    return tostring(key or "MouseButton2")
end

local function inputMatchesAimKey(input)
    local key = getAimKeyName()
    if key == "MouseButton2" or key == "RightClick" or key == "MB2" then
        return input.UserInputType == Enum.UserInputType.MouseButton2
    end
    if key == "MouseButton1" or key == "LeftClick" or key == "MB1" then
        return input.UserInputType == Enum.UserInputType.MouseButton1
    end
    if key == "MouseButton3" or key == "MB3" then
        return input.UserInputType == Enum.UserInputType.MouseButton3
    end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode.Name == key
    end
    return false
end

local function isAimHoldMode()
    local mode = getFlag("AimbotKeyMode", "Hold")
    if type(mode) == "table" then
        mode = mode[1]
    end
    return mode ~= "Toggle"
end

trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if not inputMatchesAimKey(input) then
        return
    end
    if isAimHoldMode() then
        aiming = true
    else
        aiming = not aiming
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if not isAimHoldMode() then
        return
    end
    if inputMatchesAimKey(input) then
        aiming = false
    end
end))

local function getClosestPlayer()
    local closest = nil
    local shortestDist = math.huge
    local camera = Workspace.CurrentCamera
    if not camera then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local fov = tonumber(getFlag("AimbotFOV", 150)) or 150
    local useFov = getFlag("AimbotUseFOV", true)
    local targetPartName = getFlag("AimbotTargetPart", "Head") or "Head"
    if type(targetPartName) == "table" then
        targetPartName = targetPartName[1] or "Head"
    end
    local wallCheck = getFlag("AimbotWallCheck", true)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and matchesAimbotTarget(player) then
            local targetPart = player.Character:FindFirstChild(targetPartName)
                or player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                if not wallCheck or not hasWallBetween(camera.CFrame.Position, targetPart) then
                    local aimPos = getPredictedPosition(targetPart)
                    local screenPos, onScreen = camera:WorldToViewportPoint(aimPos)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < shortestDist and (not useFov or dist <= fov) then
                            shortestDist = dist
                            closest = targetPart
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function moveSilentTo(screenPos)
    local mousePos = UserInputService:GetMouseLocation()
    local dx = screenPos.X - mousePos.X
    local dy = screenPos.Y - mousePos.Y
    if type(mousemoverel) == "function" then
        pcall(mousemoverel, dx * 0.45, dy * 0.45)
        return true
    end
    return false
end

trackConnection(RunService.RenderStepped:Connect(function()
    if scriptUnloaded then
        destroyFovCircle()
        return
    end

    local camera = Workspace.CurrentCamera
    local enabled = getFlag("EnableAimbot", true)
    local showFov = getFlag("AimbotFOVCircle", true) and enabled
    local fov = tonumber(getFlag("AimbotFOV", 150)) or 150
    if showFov then
        local circle = ensureFovCircle()
        if circle then
            local mousePos = UserInputService:GetMouseLocation()
            circle.Position = Vector2.new(mousePos.X, mousePos.Y)
            circle.Radius = fov
            circle.Visible = true
        end
    elseif fovCircle then
        fovCircle.Visible = false
    end

    local target = nil
    if enabled then
        target = getClosestPlayer()
    end

    local predicted = target and getPredictedPosition(target)
    local showBox = getFlag("AimbotPredictBox", false) and enabled and predicted and camera
    if showBox then
        local box = ensurePredictBox()
        local screen, onScreen = camera:WorldToViewportPoint(predicted)
        if box then
            if onScreen and screen.Z > 0 then
                box.Position = Vector2.new(screen.X - 8, screen.Y - 8)
                box.Visible = true
            else
                box.Visible = false
            end
        end
    elseif predictBox then
        predictBox.Visible = false
    end

    if not aimbotEnabled or not aiming or not target or not camera or not predicted then
        return
    end

    local silent = getFlag("SilentAim", false)
    local screen, onScreen = camera:WorldToViewportPoint(predicted)
    if silent and onScreen then
        if not moveSilentTo(screen) then
            camera.CFrame = CFrame.new(camera.CFrame.Position, predicted)
        end
        return
    end

    local goalCFrame = CFrame.new(camera.CFrame.Position, predicted)
    local smoothness = tonumber(getFlag("AimbotSmoothing", 0)) or 0
    if smoothness <= 0 then
        camera.CFrame = goalCFrame
    else
        camera.CFrame = camera.CFrame:Lerp(goalCFrame, math.clamp(1 / smoothness, 0.02, 1))
    end
end))

end
do
-- ============================
-- MAP / COIN CACHE
-- ============================
local coinContainerConns = {}

clearCoinContainerHooks = function()
    for _, conn in ipairs(coinContainerConns) do
        conn:Disconnect()
    end
    table.clear(coinContainerConns)
end

local function rebuildCoinCache()
    table.clear(cachedCoins)
    if not cachedCoinContainer or not cachedCoinContainer.Parent then
        coinCacheDirty = false
        return
    end

    for _, obj in ipairs(cachedCoinContainer:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
            cachedCoins[obj] = true
        end
    end
    coinCacheDirty = false
end

local function hookCoinContainer(container)
    clearCoinContainerHooks()
    if not container then return end

    table.insert(coinContainerConns, container.DescendantAdded:Connect(function(obj)
        if obj:IsA("BasePart") and obj.Name == "Coin_Server" then
            cachedCoins[obj] = true
        end
    end))

    table.insert(coinContainerConns, container.DescendantRemoving:Connect(function(obj)
        if cachedCoins[obj] then
            cachedCoins[obj] = nil
            farmCooldowns[obj] = nil
        end
    end))
end

invalidateMapCache = function()
    cachedMap = nil
    cachedCoinContainer = nil
    table.clear(cachedCoins)
    clearCoinContainerHooks()
    coinCacheDirty = true
    mapScanAt = 0
    invalidateGunDropCache()
end

local function getCurrentMap(force)
    local now = os.clock()
    if not force and cachedMap and cachedMap.Parent and (now - mapScanAt) < MAP_SCAN_INTERVAL then
        return cachedMap
    end

    -- Prefer direct children first (cheap and covers 99% of cases)
    for _, object in ipairs(Workspace:GetChildren()) do
        if object:IsA("Model") and object:GetAttribute("MapID") ~= nil then
            if cachedMap ~= object then
                cachedMap = object
                cachedCoinContainer = object:FindFirstChild("CoinContainer", true)
                hookCoinContainer(cachedCoinContainer)
                coinCacheDirty = true
            end
            mapScanAt = now
            return cachedMap
        end
    end

    -- Only do expensive deep scan if absolutely necessary
    -- Most MM2 maps are direct Workspace children
    if cachedMap and not cachedMap.Parent then
        invalidateMapCache()
    end
    mapScanAt = now
    return cachedMap
end

local function getCoinContainer()
    local map = getCurrentMap()
    if not map then return nil end
    if cachedCoinContainer and cachedCoinContainer.Parent then
        return cachedCoinContainer
    end
    cachedCoinContainer = map:FindFirstChild("CoinContainer", true)
    hookCoinContainer(cachedCoinContainer)
    coinCacheDirty = true
    return cachedCoinContainer
end

local function ensureCoinCache()
    getCoinContainer()
    if coinCacheDirty then
        rebuildCoinCache()
    end
end

getAvailableCoins = function()
    ensureCoinCache()
    local coins = {}
    for coin in pairs(cachedCoins) do
        if isActiveCoin(coin) and not farmCooldowns[coin] then
            table.insert(coins, coin)
        else
            if not coin.Parent then
                cachedCoins[coin] = nil
            end
        end
    end
    return coins
end

local function getNearestCoin()
    if not isLocalPlayerAlive() then return nil end
    local _, _, rootPart = getCharacterParts()
    if not rootPart then return nil end

    ensureCoinCache()
    local nearest = nil
    local nearestDist = math.huge
    -- Use the actual setting value
    local range = asNumber(Settings.CoinPickupRange, 100)
    local origin = rootPart.Position

    for coin in pairs(cachedCoins) do
        if isActiveCoin(coin) and not farmCooldowns[coin] then
            local dist = (origin - coin.Position).Magnitude
            if dist < nearestDist and dist < range then
                nearestDist = dist
                nearest = coin
            end
        elseif not coin.Parent then
            cachedCoins[coin] = nil
        end
    end
    return nearest
end

-- ============================
-- ROUND HUD
-- ============================
local roundHudGui = nil
local roundHudLabels = {}

destroyRoundHud = function()
    if roundHudGui then
        pcall(function() roundHudGui:Destroy() end)
        roundHudGui = nil
    end
    table.clear(roundHudLabels)
end

local function createRoundHud()
    destroyRoundHud()

    local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return nil end

    local gui = Instance.new("ScreenGui")
    gui.Name = "MM2RoundHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 20
    gui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Position = UDim2.fromOffset(18, 86)
    frame.Size = UDim2.fromOffset(210, 92)
    frame.BackgroundColor3 = Color3.fromRGB(18, 20, 28)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(95, 105, 145)
    stroke.Transparency = 0.35
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(12, 8)
    title.Size = UDim2.new(1, -24, 0, 20)
    title.Font = Enum.Font.GothamBold
    title.Text = "MM2 ENHANCED"
    title.TextColor3 = Color3.fromRGB(220, 225, 255)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    local info = Instance.new("TextLabel")
    info.BackgroundTransparency = 1
    info.Position = UDim2.fromOffset(12, 30)
    info.Size = UDim2.new(1, -24, 0, 52)
    info.Font = Enum.Font.Gotham
    info.TextColor3 = Color3.fromRGB(235, 235, 240)
    info.TextSize = 13
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.TextWrapped = false
    info.Parent = frame

    roundHudLabels.info = info
    roundHudGui = gui
    return gui
end

updateRoundHud = function()
    if not getFlag("RoundHUD", false) then
        if roundHudGui then destroyRoundHud() end
        return
    end

    if not roundHudGui or not roundHudGui.Parent then
        if not createRoundHud() then return end
    end

    ensureCoinCache()
    local activeCoins = 0
    for coin in pairs(cachedCoins) do
        if isActiveCoin(coin) then
            activeCoins = activeCoins + 1
        end
    end

    local alive = LocalPlayer:GetAttribute("Alive")
    local status = alive == true and "Alive" or (alive == false and "Out" or "Waiting")
    local role = getRole(LocalPlayer)
    local roleColor = ROLE_COLORS[role] or Color3.fromRGB(235, 235, 240)

    if roundHudLabels.info then
        roundHudLabels.info.Text = string.format(
            "Role: %s\nStatus: %s\nCoins: %d active",
            role,
            status,
            activeCoins
        )
        roundHudLabels.info.TextColor3 = roleColor
    end
end

trackConnection(Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") and child:GetAttribute("MapID") ~= nil then
        task.defer(function()
            getCurrentMap(true)
        end)
    end
end))

trackConnection(Workspace.ChildRemoved:Connect(function(child)
    if child == cachedMap then
        invalidateMapCache()
    end
end))

-- ============================
-- COIN FARMING
-- ============================
local function tweenToCoin(coin)
    local character, humanoid, rootPart = getCharacterParts()
    if not character or not isActiveCoin(coin) then
        return false
    end
    if currentMode and currentMode ~= "coin" then return false end

    currentMode = "coin"
    currentTarget = coin

    local originalPlatform = humanoid.PlatformStand
    local originalAutoRotate = humanoid.AutoRotate
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero

    local distance = (rootPart.Position - coin.Position).Magnitude
    -- Use the actual setting value
    local farmSpeed = asNumber(Settings.CoinFarmSpeed, 55)
    if farmSpeed <= 0 then farmSpeed = 55 end
    local duration = math.max(distance / farmSpeed, 0.05)
    local targetCFrame = CFrame.new(coin.Position + Vector3.new(0, 1.8, 0)) * rootPart.CFrame.Rotation

    local tween = TweenService:Create(
        rootPart,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        { CFrame = targetCFrame }
    )
    tween:Play()
    local result = tween.Completed:Wait()

    if humanoid.Parent and humanoid.Health > 0 then
        humanoid.PlatformStand = originalPlatform
        humanoid.AutoRotate = originalAutoRotate
    end
    if rootPart.Parent then
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
    end

    currentMode = nil
    currentTarget = nil
    return result == Enum.PlaybackState.Completed
end

local function walkToCoin(coin)
    local character, humanoid, rootPart = getCharacterParts()
    if not character or not humanoid or not rootPart or not isActiveCoin(coin) then
        return false
    end
    if currentMode and currentMode ~= "coin" then
        return false
    end

    currentMode = "coin"
    currentTarget = coin

    local destination = coin.Position + Vector3.new(0, 1.5, 0)
    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 5,
        AgentCanJump = true,
        AgentCanClimb = true,
        WaypointSpacing = 6,
    })

    local okCompute = pcall(function()
        path:ComputeAsync(rootPart.Position, destination)
    end)
    if not okCompute or path.Status ~= Enum.PathStatus.Success then
        currentMode = nil
        currentTarget = nil
        return tweenToCoin(coin)
    end

    local waypoints = path:GetWaypoints()
    for i, waypoint in ipairs(waypoints) do
        if not getFlag("AutoCoins", false) or not isActiveCoin(coin) then
            break
        end
        if not humanoid.Parent or humanoid.Health <= 0 then
            break
        end
        if waypoint.Action == Enum.PathWaypointAction.Jump then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        humanoid:MoveTo(waypoint.Position)
        local finished = false
        local conn
        conn = humanoid.MoveToFinished:Connect(function()
            finished = true
        end)
        local deadline = os.clock() + 2.2
        while not finished and os.clock() < deadline do
            if not getFlag("AutoCoins", false) or not isActiveCoin(coin) then
                break
            end
            if (rootPart.Position - coin.Position).Magnitude <= 4.5 then
                finished = true
                break
            end
            task.wait()
        end
        if conn then
            conn:Disconnect()
        end
        if (rootPart.Position - coin.Position).Magnitude <= 4.5 then
            break
        end
        if not finished and i == #waypoints then
            currentMode = nil
            currentTarget = nil
            return tweenToCoin(coin)
        end
    end

    currentMode = nil
    currentTarget = nil
    return isActiveCoin(coin) == false or (rootPart.Position - coin.Position).Magnitude <= 6
end

local function waitForCoinCollection(coin)
    local startTime = os.clock()
    while getFlag("AutoCoins", false) do
        if not coin or not coin.Parent then
            return true
        end
        if not isActiveCoin(coin) then
            return true
        end
        if os.clock() - startTime > 2 then
            break
        end
        task.wait(0.05)
    end

    -- Short skip so we don't instantly re-target the same unbroken coin.
    -- Real inter-coin wait is getCoinTeleportDelay() in the farm loop.
    if isActiveCoin(coin) then
        farmCooldowns[coin] = true
        local cooldown = math.max(0.05, asNumber(Settings.CoinTeleportDelay, 0.05))
        task.delay(cooldown, function()
            if farmCooldowns[coin] then
                farmCooldowns[coin] = nil
            end
        end)
    end
    return false
end

coinFarmLoop = function()
    if farmRunning then return end
    farmRunning = true
    applyFarmRendering()
    task.spawn(function()
        while getFlag("AutoCoins", false) do
            local allowed = canUseFarmAutomation()
            if not allowed then
                task.wait(0.2)
                continue
            end
            if currentMode and currentMode ~= "coin" then
                task.wait(0.15)
                continue
            end

            local coin = getNearestCoin()
            if not coin then
                task.wait(0.2)
                continue
            end

            if not isActiveCoin(coin) then
                farmCooldowns[coin] = nil
                task.wait()
                continue
            end

            local mode = getFlag("AutofarmMode", Settings.AutofarmMode)
            if type(mode) == "table" then
                mode = mode[1]
            end
            local reached
            if mode == "Legit" then
                reached = walkToCoin(coin)
            else
                reached = tweenToCoin(coin)
            end
            if reached and getFlag("AutoCoins", false) then
                waitForCoinCollection(coin)
                -- Use the actual slider delay value
                local delaySec = math.max(0, asNumber(Settings.CoinTeleportDelay, 0.05))
                if delaySec > 0 then
                    task.wait(delaySec)
                end
            else
                task.wait(0.1)
            end
        end
        farmRunning = false
        currentMode = nil
        currentTarget = nil
        applyFarmRendering()
    end)
end

-- ============================
-- GUN FARMING
-- ============================
local function getGunDrop()
    local map = getCurrentMap()
    if not map then return nil end

    local gunObject = map:FindFirstChild("GunDrop", true)
    if not gunObject or not gunObject.Parent then return nil end

    local gunPart
    if gunObject:IsA("BasePart") then
        gunPart = gunObject
    elseif gunObject.PrimaryPart then
        gunPart = gunObject.PrimaryPart
    else
        gunPart = gunObject:FindFirstChildWhichIsA("BasePart", true)
    end

    if not gunPart or not gunPart.Parent then return nil end
    return gunObject, gunPart
end

local function waitForGunInBackpack(timeout)
    local deadline = os.clock() + (timeout or 1)
    repeat
        if hasTool(LocalPlayer, "Gun") then
            return true
        end
        task.wait(0.05)
    until os.clock() >= deadline
    return hasTool(LocalPlayer, "Gun")
end

local function tryTouchGun(gunPart)
    if not gunPart or not gunPart.Parent or not gunPart:IsA("BasePart") then
        return false
    end

    local fireTouch = firetouchinterest
    if type(fireTouch) ~= "function" then
        return false
    end

    local hasTouchInterest = gunPart:FindFirstChild("TouchInterest") ~= nil
    if not hasTouchInterest then
        local ok, transmitter = pcall(function()
            return gunPart:FindFirstChildOfClass("TouchTransmitter")
        end)
        hasTouchInterest = ok and transmitter ~= nil
    end
    if not hasTouchInterest or gunPart.CanTouch == false then
        return false
    end

    local character = LocalPlayer.Character
    local toucher = character and (
        character:FindFirstChild("LeftFoot")
        or character:FindFirstChild("Left Leg")
        or character:FindFirstChild("HumanoidRootPart")
    )
    if not toucher or not toucher:IsA("BasePart") then
        return false
    end

    local began = pcall(fireTouch, toucher, gunPart, 0)
    pcall(fireTouch, toucher, gunPart, 1)
    if not began then
        return false
    end

    return waitForGunInBackpack(0.8)
end

collectGun = function()
    if currentMode and currentMode ~= "gun" then return end
    local allowed = canUseFarmAutomation()
    if not allowed then return end

    local gunObject, gunPart = getGunDrop()
    if not gunObject or not gunPart then return end

    if hasTool(LocalPlayer, "Gun") then
        return
    end

    -- Prefer executor touch support when the drop exposes a touch interest.
    if tryTouchGun(gunPart) then
        return
    end

    local character, humanoid, rootPart = getCharacterParts()
    if not character then return end

    currentMode = "gun"
    currentTarget = gunObject

    local originalCFrame = rootPart.CFrame
    local originalPlatform = humanoid.PlatformStand
    local originalAutoRotate = humanoid.AutoRotate

    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    rootPart.AssemblyLinearVelocity = Vector3.zero
    rootPart.AssemblyAngularVelocity = Vector3.zero
    rootPart.CFrame = CFrame.new(gunPart.Position + Vector3.new(0, 1.5, 0)) * originalCFrame.Rotation

    waitForGunInBackpack(0.8)

    local _, newHumanoid, newRootPart = getCharacterParts()
    if newRootPart == rootPart and newHumanoid then
        rootPart.CFrame = originalCFrame
        rootPart.AssemblyLinearVelocity = Vector3.zero
        rootPart.AssemblyAngularVelocity = Vector3.zero
        newHumanoid.PlatformStand = originalPlatform
        newHumanoid.AutoRotate = originalAutoRotate
    end

    currentMode = nil
    currentTarget = nil
end

gunFarmLoop = function()
    if gunFarmRunning then return end
    gunFarmRunning = true
    applyFarmRendering()
    task.spawn(function()
        while getFlag("AutoGunDrop", false) do
            local allowed = canUseFarmAutomation()
            if allowed and not currentMode then
                collectGun()
            end
            task.wait(0.2)
        end
        gunFarmRunning = false
        applyFarmRendering()
    end)
end

-- ============================
-- ESP SYSTEM (folder + Adornee, flag-aware cache)
-- ============================
local playerRoleCache = {}
local playerEsp = {}
coinVisuals = {}
gunDropVisuals = {}

local espFolder
local function getEspFolder()
    if espFolder and espFolder.Parent then
        return espFolder
    end
    local parent
    pcall(function()
        parent = game:GetService("CoreGui")
    end)
    if not parent then
        parent = LocalPlayer:FindFirstChildWhichIsA("PlayerGui") or PlayerGui
    end
    espFolder = Instance.new("Folder")
    espFolder.Name = "MM2EnhancedESP"
    espFolder.Parent = parent
    return espFolder
end

destroyEspFolder = function()
    if espFolder then
        pcall(function() espFolder:Destroy() end)
        espFolder = nil
    end
    table.clear(playerEsp)
    table.clear(coinVisuals)
    table.clear(gunDropVisuals)
end

local function stripLegacyEsp(character)
    if not character then return end
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = head:FindFirstChild("RoleName")
        if billboard then billboard:Destroy() end
    end
    local highlight = character:FindFirstChild("RoleHighlight")
    if highlight then highlight:Destroy() end
    local coinH = character:FindFirstChild("CoinHighlight")
    if coinH then coinH:Destroy() end
end

local function destroyEspObjects(visual)
    if not visual then return end
    if visual.highlight then pcall(function() visual.highlight:Destroy() end) end
    if visual.billboard then pcall(function() visual.billboard:Destroy() end) end
end

local function getEspAdornee(character)
    if not character then return nil end
    return character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
        or character:FindFirstChildWhichIsA("BasePart")
end

local function ensurePlayerVisuals(player)
    local visual = playerEsp[player]
    if visual and visual.highlight and visual.highlight.Parent and visual.billboard and visual.billboard.Parent then
        return visual
    end
    destroyEspObjects(visual)

    local folder = getEspFolder()
    local highlight = Instance.new("Highlight")
    highlight.Name = "RoleHighlight_" .. player.UserId
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.55
    highlight.OutlineTransparency = 0
    highlight.Enabled = false
    highlight.Parent = folder

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "RoleName_" .. player.UserId
    billboard.Size = UDim2.fromOffset(220, 44)
    billboard.StudsOffset = Vector3.new(0, 2.8, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 1000
    billboard.LightInfluence = 0
    billboard.ResetOnSpawn = false
    billboard.Enabled = false
    billboard.Parent = folder

    local label = Instance.new("TextLabel")
    label.Name = "TextLabel"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextWrapped = true
    label.TextStrokeTransparency = 0
    label.Parent = billboard

    visual = {
        highlight = highlight,
        billboard = billboard,
        label = label,
    }
    playerEsp[player] = visual
    return visual
end

removeVisuals = function(playerOrCharacter)
    local player = playerOrCharacter
    if typeof(playerOrCharacter) == "Instance" and playerOrCharacter:IsA("Model") then
        for tracked, data in pairs(playerRoleCache) do
            if data.character == playerOrCharacter then
                player = tracked
                break
            end
        end
        stripLegacyEsp(playerOrCharacter)
        if typeof(player) ~= "Instance" or not player:IsA("Player") then
            return
        end
    end

    if typeof(player) == "Instance" and player:IsA("Player") then
        destroyEspObjects(playerEsp[player])
        playerEsp[player] = nil
        if player.Character then
            stripLegacyEsp(player.Character)
        end
        playerRoleCache[player] = nil
        return
    end

    if typeof(playerOrCharacter) == "Instance" then
        stripLegacyEsp(playerOrCharacter)
    end
end

local function hidePlayerVisuals(visual)
    if not visual then return end
    if visual.highlight then visual.highlight.Enabled = false end
    if visual.billboard then visual.billboard.Enabled = false end
end

local function updatePlayer(player, force)
    if player == LocalPlayer then return end

    local character = player.Character
    if not character or not character.Parent then
        hidePlayerVisuals(playerEsp[player])
        return
    end

    local enabled = getFlag("EnableESP", true)
    local nametagsOn = getFlag("Nametags", true)
    local highlightsOn = getFlag("Highlights", true)
    local showInnocent = getFlag("ShowInnocentNames", true)
    local spectatorOn = getFlag("SpectatorESP", true)
    local alive = not isSpectator(player)
    local role = alive and getRole(player) or "Spectator"
    local displayName = player.DisplayName

    local cached = playerRoleCache[player]
    if not force and cached
        and cached.role == role
        and cached.character == character
        and cached.alive == alive
        and cached.enabled == enabled
        and cached.nametags == nametagsOn
        and cached.highlights == highlightsOn
        and cached.showInnocent == showInnocent
        and cached.spectator == spectatorOn
        and cached.displayName == displayName
        and playerEsp[player]
        and playerEsp[player].highlight
        and playerEsp[player].highlight.Parent
    then
        local visual = playerEsp[player]
        local adornee = getEspAdornee(character)
        if visual.billboard and visual.billboard.Adornee ~= adornee then
            visual.billboard.Adornee = adornee
        end
        if visual.highlight and visual.highlight.Adornee ~= character then
            visual.highlight.Adornee = character
        end
        return
    end

    playerRoleCache[player] = {
        role = role,
        character = character,
        alive = alive,
        enabled = enabled,
        nametags = nametagsOn,
        highlights = highlightsOn,
        showInnocent = showInnocent,
        spectator = spectatorOn,
        displayName = displayName,
    }

    stripLegacyEsp(character)

    if not enabled or (not alive and not spectatorOn) then
        hidePlayerVisuals(playerEsp[player])
        return
    end

    local roleColor = ROLE_COLORS[role] or SPECTATOR_COLOR
    local showTag = nametagsOn and (role ~= "Innocent" or showInnocent or not alive)
    local showHighlight = highlightsOn and (role ~= "Innocent" or not alive)
    local visual = ensurePlayerVisuals(player)
    local adornee = getEspAdornee(character)

    if visual.highlight then
        visual.highlight.Adornee = character
        visual.highlight.FillColor = roleColor
        visual.highlight.OutlineColor = getStrokeColor(roleColor)
        visual.highlight.FillTransparency = alive and 0.5 or 0.7
        visual.highlight.Enabled = showHighlight
    end

    if visual.billboard and visual.label then
        visual.billboard.Adornee = adornee
        visual.billboard.Enabled = showTag and adornee ~= nil
        local desired = displayName .. "\n[" .. role .. "]"
        if visual.label.Text ~= desired then
            visual.label.Text = desired
        end
        visual.label.TextColor3 = roleColor
        visual.label.TextStrokeColor3 = getStrokeColor(roleColor)
    end
end

refreshAllPlayers = function(force)
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayer(player, force == true)
    end
end

local function destroyTrackedVisual(store, key)
    local visual = store[key]
    if visual == true then
        store[key] = nil
        return
    end
    destroyEspObjects(visual)
    store[key] = nil
end

removeCoinESP = function(coin)
    if not coin then return end
    destroyTrackedVisual(coinVisuals, coin)
    if coin.Parent then
        local highlight = coin:FindFirstChild("CoinHighlight")
        if highlight then highlight:Destroy() end
        local billboard = coin:FindFirstChild("CoinBillboard")
        if billboard then billboard:Destroy() end
    end
end

local function updateCoinVisual(coin, rootPos, showDistance)
    if not isActiveCoin(coin) then
        removeCoinESP(coin)
        return
    end

    local visual = coinVisuals[coin]
    if type(visual) ~= "table" or not visual.highlight or not visual.highlight.Parent then
        destroyEspObjects(visual)
        local folder = getEspFolder()
        local highlight = Instance.new("Highlight")
        highlight.Name = "CoinHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = COIN_ESP_COLOR
        highlight.FillTransparency = 0.35
        highlight.OutlineColor = getStrokeColor(COIN_ESP_COLOR)
        highlight.OutlineTransparency = 0
        highlight.Adornee = coin
        highlight.Parent = folder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "CoinBillboard"
        billboard.Size = UDim2.fromOffset(120, 36)
        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 1000
        billboard.LightInfluence = 0
        billboard.ResetOnSpawn = false
        billboard.Adornee = coin
        billboard.Parent = folder

        local label = Instance.new("TextLabel")
        label.Name = "TextLabel"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = COIN_ESP_COLOR
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = getStrokeColor(COIN_ESP_COLOR)
        label.Text = "COIN"
        label.Parent = billboard

        visual = { highlight = highlight, billboard = billboard, label = label }
        coinVisuals[coin] = visual
    else
        visual.highlight.Adornee = coin
        visual.billboard.Adornee = coin
    end

    if showDistance and visual.label and rootPos then
        local dist = math.floor((rootPos - coin.Position).Magnitude + 0.5)
        local newText = string.format("COIN\n%d studs", dist)
        if visual.label.Text ~= newText then
            visual.label.Text = newText
        end
    end
end

updateCoinESP = function(updateDistances)
    local enabled = getFlag("CoinESP", true) and getFlag("EnableESP", true)
    ensureCoinCache()

    if not enabled then
        for coin in pairs(coinVisuals) do
            removeCoinESP(coin)
        end
        return
    end

    for coin in pairs(coinVisuals) do
        if not isActiveCoin(coin) then
            removeCoinESP(coin)
        end
    end

    local rootPos
    if updateDistances then
        local _, _, root = getCharacterParts()
        rootPos = root and root.Position
    end

    for coin in pairs(cachedCoins) do
        if isActiveCoin(coin) then
            updateCoinVisual(coin, rootPos, updateDistances)
        else
            if not coin.Parent then
                cachedCoins[coin] = nil
            end
            removeCoinESP(coin)
        end
    end
end

-- ============================
-- GUN DROP ESP
-- ============================
local GUN_ESP_COLOR = Color3.fromRGB(50, 145, 255)

local function getCachedGunDropPart()
    if cachedGunDropPart and cachedGunDropPart.Parent then
        return cachedGunDropPart
    end
    cachedGunDropPart = nil
    local map = getCurrentMap()
    if not map then return nil end
    local gunObj = map:FindFirstChild("GunDrop", true)
    if not gunObj then return nil end
    local part
    if gunObj:IsA("BasePart") then
        part = gunObj
    elseif gunObj.PrimaryPart then
        part = gunObj.PrimaryPart
    else
        part = gunObj:FindFirstChildWhichIsA("BasePart", true)
    end
    if part and part.Parent then
        cachedGunDropPart = part
    end
    return cachedGunDropPart
end

removeGunESP = function(part)
    if not part then return end
    destroyTrackedVisual(gunDropVisuals, part)
    if part.Parent then
        local h = part:FindFirstChild("GunDropHighlight")
        if h then h:Destroy() end
        local b = part:FindFirstChild("GunDropBillboard")
        if b then b:Destroy() end
    end
end

updateGunESP = function()
    local enabled = getFlag("GunESP", true) and getFlag("EnableESP", true)

    if not enabled then
        for part in pairs(gunDropVisuals) do
            removeGunESP(part)
        end
        return
    end

    local gunPart = getCachedGunDropPart()
    for part in pairs(gunDropVisuals) do
        if part ~= gunPart or not part.Parent then
            removeGunESP(part)
        end
    end

    if not gunPart then return end

    local visual = gunDropVisuals[gunPart]
    if type(visual) ~= "table" or not visual.highlight or not visual.highlight.Parent then
        destroyEspObjects(visual)
        local folder = getEspFolder()
        local highlight = Instance.new("Highlight")
        highlight.Name = "GunDropHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = GUN_ESP_COLOR
        highlight.FillTransparency = 0.3
        highlight.OutlineColor = getStrokeColor(GUN_ESP_COLOR)
        highlight.OutlineTransparency = 0
        highlight.Adornee = gunPart
        highlight.Parent = folder

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "GunDropBillboard"
        billboard.Size = UDim2.fromOffset(140, 40)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 1000
        billboard.LightInfluence = 0
        billboard.ResetOnSpawn = false
        billboard.Adornee = gunPart
        billboard.Parent = folder

        local label = Instance.new("TextLabel")
        label.Name = "TextLabel"
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 13
        label.TextColor3 = GUN_ESP_COLOR
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = getStrokeColor(GUN_ESP_COLOR)
        label.Text = "GUN"
        label.Parent = billboard

        visual = { highlight = highlight, billboard = billboard, label = label }
        gunDropVisuals[gunPart] = visual
    else
        visual.highlight.Adornee = gunPart
        visual.billboard.Adornee = gunPart
    end

    if visual.label then
        local _, _, root = getCharacterParts()
        if root then
            local dist = math.floor((root.Position - gunPart.Position).Magnitude + 0.5)
            local newText = "GUN\n" .. dist .. " studs"
            if visual.label.Text ~= newText then
                visual.label.Text = newText
            end
        end
    end
end

local function hookBackpack(player, backpack)
    if not backpack then return end
    trackConnection(backpack.ChildAdded:Connect(function()
        task.defer(updatePlayer, player)
    end))
    trackConnection(backpack.ChildRemoved:Connect(function()
        task.defer(updatePlayer, player)
    end))
end

local function hookPlayer(player)
    if player == LocalPlayer then return end

    local function onCharacter(character)
        task.defer(function()
            updatePlayer(player, true)
        end)

        trackConnection(character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.defer(updatePlayer, player)
            end
        end))
        trackConnection(character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                task.defer(updatePlayer, player)
            end
        end))

        local humanoid = character:FindFirstChildWhichIsA("Humanoid")
        if humanoid then
            trackConnection(humanoid.Died:Connect(function()
                task.defer(updatePlayer, player, true)
            end))
        end
    end

    if player.Character then
        onCharacter(player.Character)
    end
    trackConnection(player.CharacterAdded:Connect(onCharacter))
    trackConnection(player.CharacterRemoving:Connect(function(character)
        hidePlayerVisuals(playerEsp[player])
        stripLegacyEsp(character)
    end))

    trackConnection(player.AttributeChanged:Connect(function(attr)
        if attr == "Alive" then
            task.defer(updatePlayer, player, true)
        end
    end))

    hookBackpack(player, player:FindFirstChild("Backpack"))
    trackConnection(player.ChildAdded:Connect(function(child)
        if child:IsA("Backpack") then
            hookBackpack(player, child)
            task.defer(updatePlayer, player)
        end
    end))
end

for _, player in ipairs(Players:GetPlayers()) do
    hookPlayer(player)
end
trackConnection(Players.PlayerAdded:Connect(hookPlayer))

trackConnection(Players.PlayerRemoving:Connect(function(player)
    removeVisuals(player)
    if selectedPlayerName == player.Name then
        selectedPlayerName = nil
    end
end))

trackConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(0.5)
    local hum = character:FindFirstChildWhichIsA("Humanoid")
    if hum then
        hum.WalkSpeed = Settings.WalkSpeed
        hum.JumpPower = Settings.JumpPower
    end
end))

task.spawn(function()
    local espTick = 0
    while uiRunning do
        espTick = espTick + 1
        -- Role poll is cheap now; cache skips unchanged players.
        refreshAllPlayers(false)
        updateCoinESP(espTick % 2 == 0)
        if espTick % 2 == 0 then
            updateGunESP()
        end
        updateRoundHud()
        task.wait(0.25)
    end
end)

-- ============================
-- LOBBY AUTO-VOTE (Optimized to reduce stuttering)
-- ============================
local lastVotedMapName = nil
local lastVoteCycleTime = 0
cachedVotePads = {}
local lastVotePadScan = 0
local VOTE_PAD_SCAN_INTERVAL = 2 -- Only scan every 2 seconds

local function getVotePads()
    local now = os.clock()
    -- Use cached pads if recently scanned
    if now - lastVotePadScan < VOTE_PAD_SCAN_INTERVAL and #cachedVotePads > 0 then
        return cachedVotePads
    end
    
    table.clear(cachedVotePads)
    local lobby = Workspace:FindFirstChild("Lobby")
    if not lobby then 
        lastVotePadScan = now
        return cachedVotePads 
    end
    
    local votePads = lobby:FindFirstChild("VotePads")
    if not votePads then 
        lastVotePadScan = now
        return cachedVotePads 
    end

    for _, padModel in ipairs(votePads:GetChildren()) do
        local pad = padModel:FindFirstChild("Pad")
        local voteInfoGui = padModel:FindFirstChild("VoteInfoGui")

        local mapNameLabel = nil
        if voteInfoGui then
            local container = voteInfoGui:FindFirstChild("Container")
            if container then
                mapNameLabel = container:FindFirstChild("MapName")
            end
        end

        if pad and mapNameLabel and mapNameLabel.Text and mapNameLabel.Text ~= "" and mapNameLabel.Text ~= "?" then
            table.insert(cachedVotePads, {
                Name = mapNameLabel.Text,
                Pad = pad,
            })
        end
    end
    
    lastVotePadScan = now
    return cachedVotePads
end

local function getVoteTouchPart(character)
    if not character then return nil end
    return character:FindFirstChild("LeftFoot")
        or character:FindFirstChild("Left Leg")
        or character:FindFirstChild("HumanoidRootPart")
end

local function tryTouchVotePad(pad)
    if not pad or not pad.Parent or not pad:IsA("BasePart") then
        return false
    end

    local fireTouch = firetouchinterest
    if type(fireTouch) ~= "function" then
        return false
    end

    local hasTouchInterest = pad:FindFirstChild("TouchInterest") ~= nil
    if not hasTouchInterest then
        local ok, transmitter = pcall(function()
            return pad:FindFirstChildOfClass("TouchTransmitter")
        end)
        hasTouchInterest = ok and transmitter ~= nil
    end
    if not hasTouchInterest or pad.CanTouch == false then
        return false
    end

    local character = LocalPlayer.Character
    local toucher = getVoteTouchPart(character)
    if not toucher or not toucher:IsA("BasePart") then
        return false
    end

    local began = pcall(fireTouch, toucher, pad, 0)
    pcall(fireTouch, toucher, pad, 1)
    task.wait(0.1)
    return began
end

local function activateVotePad(pad)
    -- Use executor touch support first, without moving the character.
    if tryTouchVotePad(pad) then
        return true
    end

    -- Compatibility fallback for executors or pads without touch support.
    local _, _, rootPart = getCharacterParts()
    if not rootPart or not pad or not pad.Parent then
        return false
    end

    local oldCFrame = rootPart.CFrame
    local oldVelocity = rootPart.AssemblyLinearVelocity
    local oldAngularVelocity = rootPart.AssemblyAngularVelocity
    rootPart.CFrame = pad.CFrame * CFrame.new(0, 3, 0)
    task.wait(0.15)
    if rootPart.Parent then
        rootPart.CFrame = oldCFrame
        rootPart.AssemblyLinearVelocity = oldVelocity
        rootPart.AssemblyAngularVelocity = oldAngularVelocity
    end
    return true
end

task.spawn(function()
    while uiRunning do
        local pads = getVotePads()

        if #pads > 0 then
            if os.clock() - lastVoteCycleTime > 30 then
                lastVotedMapName = nil
            end
            lastVoteCycleTime = os.clock()
        end

        if Settings.AutoVote and #pads > 0 and not lastVotedMapName then
            local targetPad = nil
            if Settings.VoteTarget == "Random" then
                targetPad = pads[math.random(1, #pads)]
            else
                local want = string.lower(Settings.VoteTarget)
                for _, p in ipairs(pads) do
                    if p.Name == Settings.VoteTarget or string.find(string.lower(p.Name), want, 1, true) then
                        targetPad = p
                        break
                    end
                end
            end

            if targetPad then
                if activateVotePad(targetPad.Pad) then
                    lastVotedMapName = targetPad.Name
                end
            end
        end

        if #pads == 0 then
            lastVotedMapName = nil
            table.clear(cachedVotePads)
        end

        task.wait(2)
    end
end)

-- ============================
-- AUTO FLING LOOP
-- ============================
task.spawn(function()
    while uiRunning do
        if Settings.AutoFling and not flinging then
            flingByMode(true)
        end
        task.wait(0.5)
    end
end)

end -- feature scope (keeps the chunk under Luau's 200-local limit)

do -- ui scope
-- ============================
-- TABS
-- ============================
local homeTab = window:CreateTab({ name = "Home", icon = 7733960981 })
local mainTab = window:CreateTab({ name = "Main", icon = 7733970318 })
local combatTab = window:CreateTab({ name = "Combat", icon = 7743872758 })
local visualsTab = window:CreateTab({ name = "Visuals", icon = 7733774602 })
local miscTab = window:CreateTab({ name = "Misc", icon = 7743878358 })
local settingsTab = window:CreateTab({ name = "Settings", icon = 7734053495 })

-- Keep old names as aliases so existing sections stay on the new tabs.
local movementTab = mainTab
local farmTab = mainTab
local lobbyTab = mainTab
local espTab = visualsTab
local playersTab = miscTab
local funTab = miscTab

-- ============================
-- HOME TAB
-- ============================
homeTab:CreateSection({ name = "Overview" })

pcall(function()
    homeTab:CreateStat({
        name = "Version",
        value = 4.5,
        suffix = "",
        compact = true,
    })
end)

homeTab:CreateToggle({
    name = "Round HUD",
    description = "Show your role, round status, and active coin count",
    value = false,
    flag = "RoundHUD",
    callback = function(enabled)
        if enabled then
            updateRoundHud()
        else
            destroyRoundHud()
        end
    end,
})

-- ============================
-- MAIN TAB
-- ============================
movementTab:CreateSection({ name = "Character Stats" })

movementTab:CreateSlider({
    name = "Walk Speed",
    range = { 0, 100 },
    increment = 1,
    value = 16,
    suffix = " studs/s",
    flag = "WalkSpeed",
    callback = function(value)
        Settings.WalkSpeed = value
        local _, hum = getCharacterParts()
        if hum then hum.WalkSpeed = value end
    end,
})

movementTab:CreateSlider({
    name = "Jump Power",
    range = { 0, 200 },
    increment = 1,
    value = 50,
    suffix = "",
    flag = "JumpPower",
    callback = function(value)
        Settings.JumpPower = value
        local _, hum = getCharacterParts()
        if hum then hum.JumpPower = value end
    end,
})

movementTab:CreateSection({ name = "Modes" })

movementTab:CreateToggle({
    name = "Noclip",
    description = "Move through walls",
    value = false,
    flag = "Noclip",
    callback = function(enabled)
        if enabled then
            enableNoclip()
        else
            disableNoclip()
        end
    end,
})

-- ============================
-- COMBAT TAB
-- ============================
combatTab:CreateSection({ name = "Aimbot" })

combatTab:CreateToggle({
    name = "Enable Aimbot",
    description = "Uses the aim key below (hold or toggle)",
    value = true,
    flag = "EnableAimbot",
    callback = function(enabled)
        aimbotEnabled = enabled
        if not enabled then
            aiming = false
            destroyFovCircle()
        end
    end,
})

combatTab:CreateDropdown({
    name = "Aim Key Mode",
    options = { "Hold", "Toggle" },
    value = "Hold",
    flag = "AimbotKeyMode",
    callback = function()
        aiming = false
    end,
})

combatTab:CreateKeybind({
    name = "Aim Key",
    description = "Click then press a keyboard key or mouse button (LMB/RMB/MMB)",
    value = Enum.UserInputType.MouseButton2,
    flag = "AimbotKey",
    callback = function()
    end,
})

combatTab:CreateDropdown({
    name = "Aimbot Target",
    options = { "Target", "Sheriff", "Murderer", "Innocent" },
    value = "Target",
    multiSelect = false,
    placeholder = "Who to lock onto",
    flag = "AimbotTargetMode",
    callback = function() end,
})

combatTab:CreateInput({
    name = "Aimbot Username",
    value = "",
    placeholder = "Used when Aimbot Target is Target",
    flag = "AimbotTargetInput",
    callback = function(text)
        aimbotTargetName = text or ""
    end,
})

combatTab:CreateDropdown({
    name = "Target Part",
    options = { "Head", "HumanoidRootPart", "Torso", "UpperTorso" },
    value = "Head",
    multiSelect = false,
    placeholder = "Select target part",
    flag = "AimbotTargetPart",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "Silent Aim",
    description = "Move mouse to the target instead of locking the camera",
    value = false,
    flag = "SilentAim",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "Use FOV",
    description = "Only lock targets inside the FOV circle (off = anywhere on screen)",
    value = true,
    flag = "AimbotUseFOV",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "Wall Check",
    description = "Do not lock onto people behind walls",
    value = true,
    flag = "AimbotWallCheck",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "FOV Circle",
    description = "Draw the aimbot FOV around your mouse",
    value = true,
    flag = "AimbotFOVCircle",
    callback = function(enabled)
        if not enabled then
            destroyFovCircle()
        end
    end,
})

combatTab:CreateDropdown({
    name = "Prediction",
    options = { "None", "Velocity", "Distance", "Hybrid" },
    value = "Velocity",
    flag = "AimbotPredictMethod",
    callback = function() end,
})

combatTab:CreateSlider({
    name = "Predict Amount",
    range = { 0, 0.5 },
    increment = 0.01,
    value = 0.12,
    suffix = " s",
    flag = "AimbotPredict",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "Predict Box",
    description = "Red box at the predicted aim point",
    value = false,
    flag = "AimbotPredictBox",
    callback = function(enabled)
        if not enabled and predictBox then
            predictBox.Visible = false
        end
    end,
})

combatTab:CreateSlider({
    name = "Aimbot Smoothing",
    range = { 0, 20 },
    increment = 0.5,
    value = 0,
    suffix = " (0 = instant)",
    flag = "AimbotSmoothing",
    callback = function() end,
})

combatTab:CreateSlider({
    name = "Aimbot FOV",
    range = { 20, 1000 },
    increment = 10,
    value = 150,
    suffix = " px",
    flag = "AimbotFOV",
    callback = function() end,
})

combatTab:CreateSection({ name = "Fling" })

combatTab:CreateDropdown({
    name = "Fling Mode",
    options = { "Target", "Murderer", "Sheriff" },
    value = "Murderer",
    multiSelect = false,
    placeholder = "Select mode",
    flag = "FlingMode",
    callback = function(selected)
        flingMode = selected[1] or selected
    end,
})

combatTab:CreateInput({
    name = "Target Username",
    value = "",
    placeholder = "Enter username (for Target mode)",
    clearOnFocus = false,
    flag = "FlingTargetInput",
    callback = function(text)
        targetInputText = text
    end,
})

combatTab:CreateToggle({
    name = "Invisible Fling",
    description = "Keep your view in place while flinging a target",
    value = true,
    flag = "InvisibleFling",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "Advanced",
    description = "Use the advanced fling routine",
    value = false,
    flag = "AdvancedFling",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "Play Fling Animation",
    description = "Play the selected animation during a fling",
    value = false,
    flag = "UseFlingAnim",
    callback = function() end,
})

combatTab:CreateInput({
    name = "Fling Animation ID",
    value = "129881979528827",
    placeholder = "Enter animation asset ID",
    clearOnFocus = false,
    flag = "FlingAnimID",
    callback = function() end,
})

combatTab:CreateSlider({
    name = "Fling Duration",
    range = { 0.5, 5 },
    increment = 0.1,
    value = 1,
    suffix = "s",
    flag = "FlingDuration",
    callback = function() end,
})

combatTab:CreateToggle({
    name = "Auto Fling",
    description = "Keep flinging the selected target",
    value = false,
    flag = "AutoFling",
    callback = function(enabled)
        Settings.AutoFling = enabled
    end,
})

combatTab:CreateToggle({
    name = "Anti-Fling",
    description = "Disable collision with other players",
    value = false,
    flag = "AntiFling",
    callback = function(enabled)
        if enabled then
            enableAntifling()
        else
            disableAntifling()
        end
    end,
})

combatTab:CreateKeybind({
    name = "Fling Keybind",
    value = Enum.KeyCode.F,
    hold = false,
    flag = "FlingKey",
    callback = function()
        flingByMode(false)
    end,
})

combatTab:CreateButton({
    name = "Fling Now",
    description = "Walk fling the current target",
    callback = function()
        flingByMode(false)
    end,
})

-- ============================
-- ESP TAB
-- ============================
espTab:CreateSection({ name = "Visualization" })

espTab:CreateToggle({
    name = "Enable ESP",
    description = "Turn all ESP features on or off",
    value = true,
    flag = "EnableESP",
    callback = function()
        refreshAllPlayers(true)
        updateCoinESP(false)
        updateGunESP()
    end,
})

espTab:CreateToggle({
    name = "Show Nametags",
    description = "Show each player's role above them",
    value = true,
    flag = "Nametags",
    callback = function()
        refreshAllPlayers(true)
    end,
})

espTab:CreateToggle({
    name = "Role Highlights",
    description = "Highlight the Murderer and Sheriff",
    value = true,
    flag = "Highlights",
    callback = function()
        refreshAllPlayers(true)
    end,
})

espTab:CreateToggle({
    name = "Show Innocent Names",
    description = "Show names for Innocent players too",
    value = true,
    flag = "ShowInnocentNames",
    callback = function()
        refreshAllPlayers(true)
    end,
})

espTab:CreateToggle({
    name = "Coin ESP",
    description = "Show active coins with distance labels",
    value = true,
    flag = "CoinESP",
    callback = function()
        updateCoinESP(true)
    end,
})

espTab:CreateToggle({
    name = "Gun ESP",
    description = "Show the dropped gun and its distance",
    value = true,
    flag = "GunESP",
    callback = function()
        updateGunESP()
    end,
})

espTab:CreateToggle({
    name = "Spectator ESP",
    description = "Show players who are out of the round",
    value = true,
    flag = "SpectatorESP",
    callback = function()
        refreshAllPlayers(true)
    end,
})

espTab:CreateButton({
    name = "Refresh Player ESP",
    description = "Rebuild player nametags and role highlights only",
    callback = function()
        for _, player in ipairs(Players:GetPlayers()) do
            removeVisuals(player)
        end
        refreshAllPlayers(true)
        window:Toast({
            title = "Player ESP",
            subtitle = "Refreshed",
            position = "Top",
            duration = 2,
        })
    end,
})

-- ============================
-- FARM (Main tab)
-- ============================
farmTab:CreateSection({ name = "Automation" })

farmTab:CreateDropdown({
    name = "Autofarm Mode",
    options = { "Legit", "Fast" },
    value = "Fast",
    flag = "AutofarmMode",
    callback = function(selected)
        if type(selected) == "table" then
            selected = selected[1]
        end
        Settings.AutofarmMode = selected or "Fast"
    end,
})

farmTab:CreateToggle({
    name = "Auto Coin Farm",
    description = "Collect nearby coins automatically",
    value = false,
    flag = "AutoCoins",
    callback = function(enabled)
        getgenv().MM2EnhancedPersist.AutoCoins = enabled == true
        if enabled then
            local allowed, reason = canUseFarmAutomation()
            if not allowed then
                window:Toast({ title = "Coin Farm", subtitle = reason, position = "Top", duration = 2 })
                return
            end
            coinFarmLoop()
        end
        applyFarmRendering()
    end,
})

farmTab:CreateToggle({
    name = "Disable 3D Rendering",
    description = "Turns off 3D rendering while Auto Coin Farm or Auto Gun Pickup is running (lowers CPU load)",
    value = false,
    flag = "FarmNoRender",
    callback = function(enabled)
        getgenv().MM2EnhancedPersist.FarmNoRender = enabled == true
        applyFarmRendering()
    end,
})

farmTab:CreateButton({
    name = "Get Gun from Ground",
    description = "Teleport to the dropped gun once",
    callback = function()
        collectGun()
        window:Toast({
            title = "Gun",
            subtitle = "Tried to pick up the dropped gun",
            duration = 2,
        })
    end,
})

farmTab:CreateToggle({
    name = "Auto Gun Pickup",
    description = "Pick up the dropped gun automatically",
    value = false,
    flag = "AutoGunDrop",
    callback = function(enabled)
        getgenv().MM2EnhancedPersist.AutoGunDrop = enabled == true
        if enabled then
            local allowed, reason = canUseFarmAutomation()
            if not allowed then
                window:Toast({ title = "Gun Pickup", subtitle = reason, position = "Top", duration = 2 })
                return
            end
            gunFarmLoop()
        end
        applyFarmRendering()
    end,
})

do
    local persist = getgenv().MM2EnhancedPersist
    if persist.FarmNoRender then
        flagValues.FarmNoRender = true
        applyFarmRendering()
    end
    if persist.AutoCoins then
        flagValues.AutoCoins = true
        coinFarmLoop()
        applyFarmRendering()
    end
    if persist.AutoGunDrop then
        flagValues.AutoGunDrop = true
        gunFarmLoop()
        applyFarmRendering()
    end
end

farmTab:CreateSection({ name = "Tuning" })

farmTab:CreateSlider({
    name = "Coin Farm Speed",
    range = { 10, 500 },
    increment = 1,
    value = 55,
    suffix = " studs/s",
    flag = "CoinFarmSpeed",
    callback = function(value)
        local normalized = asNumber(value, 55)
        Settings.CoinFarmSpeed = normalized
        print("[Farm] Coin Farm Speed set to:", normalized)
    end,
})

farmTab:CreateSlider({
    name = "Coin Pickup Range",
    range = { 20, 1000 },
    increment = 1,
    value = 100,
    suffix = " studs",
    flag = "CoinPickupRange",
    callback = function(value)
        local normalized = asNumber(value, 100)
        Settings.CoinPickupRange = normalized
        print("[Farm] Coin Pickup Range set to:", normalized)
    end,
})

farmTab:CreateSlider({
    name = "Coin Teleport Delay",
    description = "Delay before moving to the next coin",
    range = { 0, 2.5 },
    increment = 0.05,
    value = 0.05,
    suffix = "s",
    flag = "CoinTeleportDelay",
    callback = function(value)
        local normalized = math.clamp(asNumber(value, 0.05), 0, 2.5)
        Settings.CoinTeleportDelay = normalized
        print("[Farm] Coin Teleport Delay set to:", normalized)
    end,
})

farmTab:CreateSection({ name = "Status" })

local coinStat
pcall(function()
    coinStat = farmTab:CreateStat({
        name = "Coins Available",
        value = 0,
        suffix = "",
        compact = true,
        changeMode = "absolute",
    })
end)

task.spawn(function()
    while uiRunning do
        if coinStat and coinStat.Set then
            pcall(function()
                coinStat:Set(#getAvailableCoins())
            end)
        end
        task.wait(1.5)
    end
end)

-- ============================
-- COMBAT TAB
-- ============================
combatTab:CreateSection({ name = "Hitboxes" })

combatTab:CreateToggle({
    name = "Enable Hitbox Expander",
    description = "Make player hitboxes larger",
    value = false,
    flag = "EnableHitboxes",
    callback = function(enabled)
        if not enabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = Vector3.new(2, 2, 1)
                        hrp.Transparency = 0
                        hrp.CanCollide = false
                    end
                end
            end
        end
    end,
})

combatTab:CreateSlider({
    name = "Hitbox Size",
    range = { 1, 30 },
    increment = 1,
    value = 5,
    suffix = " studs",
    flag = "HitboxSize",
    callback = function(value)
        Settings.HitboxSize = value
    end,
})

combatTab:CreateToggle({
    name = "Show Hitboxes",
    description = "Show the expanded hitboxes",
    value = true,
    flag = "ShowHitboxes",
    callback = function() end,
})

task.spawn(function()
    while uiRunning do
        if getFlag("EnableHitboxes", false) then
            local size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
            local transparency = getFlag("ShowHitboxes", true) and 0.5 or 1
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                    if hrp and (hrp.Size ~= size or hrp.Transparency ~= transparency) then
                        hrp.Size = size
                        hrp.Transparency = transparency
                        hrp.CanCollide = false
                    end
                end
            end
        end
        task.wait(0.75)
    end
end)

combatTab:CreateSection({ name = "Bring" })

combatTab:CreateDropdown({
    name = "Bring Mode",
    options = { "All", "Innocents Only", "Sheriff Only" },
    value = "All",
    multiSelect = false,
    placeholder = "Select who to bring",
    flag = "BringMode",
    callback = function(selected)
        Settings.BringMode = selected[1] or selected
    end,
})

local function shouldBring(player)
    local role = getRole(player)
    if Settings.BringMode == "Innocents Only" then
        return role == "Innocent"
    elseif Settings.BringMode == "Sheriff Only" then
        return role == "Sheriff"
    end
    return true
end

local function canUseBring()
    return getRole(LocalPlayer) == "Murderer"
end

local function isAlivePlayer(player, character)
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return humanoid
        and humanoid.Health > 0
        and not isSpectator(player)
end

local function getKnifeTool()
    local character = LocalPlayer.Character
    if character then
        local equipped = character:FindFirstChild("Knife")
        if equipped then return equipped end
    end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    return backpack and backpack:FindFirstChild("Knife")
end

local function equipKnife()
    local knife = getKnifeTool()
    if not knife then return nil end
    local character, humanoid = getCharacterParts()
    if character and humanoid and knife.Parent ~= character then
        pcall(function()
            humanoid:EquipTool(knife)
        end)
    end
    return getKnifeTool()
end

local function getKnifeHitPart(knife)
    if not knife then return nil end
    return knife:FindFirstChild("Handle")
        or knife:FindFirstChildWhichIsA("BasePart")
end

local function tryKnifeHit(knife, targetRoot)
    if not knife or not targetRoot then return end
    pcall(function()
        knife:Activate()
    end)
    local handle = getKnifeHitPart(knife)
    if handle and firetouchinterest then
        pcall(function()
            firetouchinterest(handle, targetRoot, 0)
            firetouchinterest(handle, targetRoot, 1)
        end)
    end
end

local function startBringLoop()
    if bringLoop then return end
    bringLoop = true
    task.spawn(function()
        while bringLoop and not scriptUnloaded do
            if not canUseBring() then
                task.wait(0.15)
                continue
            end

            local _, _, myRoot = getCharacterParts()
            local knife = equipKnife()
            if myRoot then
                local bringCFrame = myRoot.CFrame * CFrame.new(0, 0, -2.5)
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character and shouldBring(player) then
                        local targetChar = player.Character
                        local targetRoot = getRoot(targetChar)
                        if targetRoot and isAlivePlayer(player, targetChar) then
                            targetRoot.CFrame = bringCFrame
                            tryKnifeHit(knife, targetRoot)
                        end
                    end
                end
            end
            task.wait()
        end
    end)
end

local function stopBringLoop()
    bringLoop = false
end

combatTab:CreateKeybind({
    name = "Bring / Kill All",
    description = "G: Murderer only — stack everyone 2.5 studs in front of you and knife them there",
    value = Enum.KeyCode.G,
    hold = false,
    flag = "BringAllKey",
    callback = function()
        if not canUseBring() then
            stopBringLoop()
            window:Toast({ title = "Kill All", subtitle = "Murderer only", position = "Top", duration = 2 })
            return
        end

        if bringLoop then
            stopBringLoop()
            window:Toast({ title = "Kill All", subtitle = "Stopped", position = "Top", duration = 2 })
        else
            startBringLoop()
            window:Toast({ title = "Kill All", subtitle = "Active", position = "Top", duration = 2 })
        end
    end,
})

-- ============================
-- PLAYERS TAB
-- ============================
playersTab:CreateSection({ name = "Select" })

local function getPlayerNames()
    local names = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(names, player.Name)
        end
    end
    table.sort(names)
    if #names == 0 then
        table.insert(names, "No Players")
    end
    return names
end

playersTab:CreateDropdown({
    name = "Select Player",
    options = getPlayerNames(),
    value = getPlayerNames()[1] or "None",
    multiSelect = false,
    placeholder = "Choose a player",
    flag = "SelectedPlayer",
    callback = function(selected)
        if type(selected) == "table" then
            selectedPlayerName = selected[1] or nil
        else
            selectedPlayerName = selected
        end
    end,
})

playersTab:CreateButton({
    name = "Refresh Player List",
    description = "Refresh the player list",
    callback = function()
        window:Notify({
            title = "Players",
            content = "Online: " .. table.concat(getPlayerNames(), ", "),
            duration = 5,
        })
    end,
})

local function getSelectedPlayer()
    if selectedPlayerName and selectedPlayerName ~= "" then
        return Players:FindFirstChild(selectedPlayerName)
    end
    local flagVal = getFlag("SelectedPlayer", nil)
    if type(flagVal) == "string" then
        return Players:FindFirstChild(flagVal)
    end
    return nil
end

playersTab:CreateSection({ name = "Invisible" })


playersTab:CreateToggle({
    name = "Invisible",
    description = "Play the Invisible Me emote animation.",
    value = false,
    flag = "Invisible",
    callback = function(enabled)
        if enabled then
            enableInvisible()
        else
            disableInvisible()
            window:Toast({
                title = "Invisible",
                subtitle = "Disabled",
                position = "Top",
                duration = 2,
            })
        end
    end,
})

playersTab:CreateToggle({
    name = "Enable Invisible Keybind",
    description = "Allow the keybind below to toggle Invisible",
    value = true,
    flag = "InvisibleKeybindEnabled",
    callback = function() end,
})

playersTab:CreateKeybind({
    name = "Invisible Keybind",
    description = "Toggle Invisible on or off",
    value = Enum.KeyCode.V,
    hold = false,
    flag = "InvisibleKey",
    callback = function()
        if not getFlag("InvisibleKeybindEnabled", true) then
            return
        end

        local enabled = not invisibleEnabled
        if enabled then
            enableInvisible()
        else
            disableInvisible()
        end
        window:Toast({
            title = "Invisible",
            subtitle = enabled and "Enabled" or "Disabled",
            position = "Top",
            duration = 2,
        })
    end,
})

playersTab:CreateSlider({
    name = "Invisible HipHeight",
    description = "Adjust the lowered height used by Invisible",
    range = { 0.01, 0.5 },
    increment = 0.01,
    value = 0.08,
    suffix = "",
    flag = "InvisibleHipHeight",
    callback = function(value)
        local normalized = math.clamp(asNumber(value, 0.08), 0.01, 0.5)
        Settings.InvisibleHipHeight = normalized

        if invisibleEnabled then
            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid.HipHeight = normalized
            end
        end
    end,
})

playersTab:CreateSection({ name = "Actions" })

playersTab:CreateButton({
    name = "Teleport to Selected",
    callback = function()
        local target = getSelectedPlayer()
        local targetRoot = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
        local _, _, myRoot = getCharacterParts()
        if targetRoot and myRoot then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 4)
            window:Toast({
                title = "Teleported",
                subtitle = "to " .. target.Name,
                position = "Top",
                duration = 2,
            })
        else
            window:Notify({
                title = "Teleport Failed",
                content = "Select a valid player first.",
                duration = 3,
            })
        end
    end,
})

playersTab:CreateButton({
    name = "Teleport to Random Player",
    callback = function()
        local others = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(others, player)
            end
        end
        if #others > 0 then
            local target = others[math.random(#others)]
            local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            local _, _, myRoot = getCharacterParts()
            if targetRoot and myRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 2, 4)
                window:Toast({
                    title = "Teleported",
                    subtitle = "to " .. target.Name,
                    position = "Top",
                    duration = 3,
                })
            end
        else
            window:Notify({
                title = "No Players",
                content = "No other players found.",
                duration = 3,
            })
        end
    end,
})


playersTab:CreateSection({ name = "Roster" })

playersTab:CreateButton({
    name = "List Players & Roles",
    callback = function()
        local lines = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                table.insert(lines, player.Name .. " — " .. getRole(player))
            end
        end
        window:Notify({
            title = "Players Online",
            content = #lines > 0 and table.concat(lines, "\n") or "No other players.",
            duration = 8,
        })
    end,
})

-- ============================
-- LOBBY TAB
-- ============================
lobbyTab:CreateSection({ name = "Map Voting" })

lobbyTab:CreateToggle({
    name = "Auto Vote",
    description = "Touch the selected vote pad automatically",
    value = false,
    flag = "AutoVote",
    callback = function(enabled)
        Settings.AutoVote = enabled
        if not enabled then
            lastVotedMapName = nil
        end
    end,
})

lobbyTab:CreateDropdown({
    name = "Target Map",
    options = KNOWN_MAPS,
    value = "Random",
    multiSelect = false,
    placeholder = "Select map",
    flag = "VoteTarget",
    callback = function(selected)
        Settings.VoteTarget = selected[1] or selected
        lastVotedMapName = nil
    end,
})

lobbyTab:CreateButton({
    name = "Vote Now",
    description = "Touch the matching vote pad",
    callback = function()
        local pads = getVotePads()
        if #pads == 0 then
            window:Notify({
                title = "Vote",
                content = "No vote pads found (are you in lobby?).",
                duration = 3,
            })
            return
        end

        local targetPad
        if Settings.VoteTarget == "Random" then
            targetPad = pads[math.random(1, #pads)]
        else
            local want = string.lower(Settings.VoteTarget)
            for _, p in ipairs(pads) do
                if p.Name == Settings.VoteTarget or string.find(string.lower(p.Name), want, 1, true) then
                    targetPad = p
                    break
                end
            end
        end

        if targetPad then
            if activateVotePad(targetPad.Pad) then
                lastVotedMapName = targetPad.Name
                window:Toast({
                    title = "Voted",
                    subtitle = targetPad.Name,
                    position = "Top",
                    duration = 2,
                })
            end
        else
            window:Notify({
                title = "Vote",
                content = "Target map not on the pads this cycle.",
                duration = 3,
            })
        end
    end,
})

-- ============================
-- FUN TAB
-- ============================

-- ============================
-- FUN TAB — Los Pollos
-- ============================
local losPollosImageId = nil
infectionActive = false
infectionConn = nil

local function getLosPollosImage()
    if losPollosImageId then return losPollosImageId end

    local url = "https://raw.githubusercontent.com/jhenielpr/pollos/main/los.jpg"
    local ok, data = pcall(game.HttpGet, game, url)

    if not ok or type(data) ~= "string" or #data < 500 then
        warn("[Fun] Download failed: " .. tostring(data))
        return nil
    end

    print("[Fun] Downloaded " .. #data .. " bytes")

    local fname = "lospollos_mm2.jpg"

    -- Method 1: getcustomasset (Synapse X, KRNL, Fluxus, etc.)
    if writefile and getcustomasset then
        pcall(writefile, fname, data)
        local aok, id = pcall(getcustomasset, fname)
        if aok and type(id) == "string" and id ~= "" then
            losPollosImageId = id
            print("[Fun] getcustomasset: " .. id)
            return id
        end
        warn("[Fun] getcustomasset failed: " .. tostring(id))
    end

    -- Method 2: makefileuri (some executors)
    if writefile and makefileuri then
        pcall(writefile, fname, data)
        local uok, uri = pcall(makefileuri, fname)
        if uok and type(uri) == "string" and uri ~= "" then
            losPollosImageId = uri
            print("[Fun] makefileuri: " .. uri)
            return uri
        end
    end

    warn("[Fun] No executor asset API worked")
    return nil
end

local function infectObj(obj, imageId)
    pcall(function()
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            obj.Image = imageId
        elseif obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Texture = imageId
        elseif obj:IsA("Sky") then
            obj.SkyboxBk = imageId obj.SkyboxDn = imageId
            obj.SkyboxFt = imageId obj.SkyboxLf = imageId
            obj.SkyboxRt = imageId obj.SkyboxUp = imageId
        end
        -- Infect text (GUI only, not workspace parts)
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            obj.Text = "los pollos"
        end
    end)
end

local function runInfection(imageId)
    -- Add Los Pollos decal to every BasePart in workspace
    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("BasePart") then
            pcall(function()
                if not desc:FindFirstChild("LosPollosDecal") then
                    local decal = Instance.new("Decal")
                    decal.Name = "LosPollosDecal"
                    decal.Texture = imageId
                    decal.Face = Enum.NormalId.Front
                    decal.Parent = desc
                    -- Also add to all faces
                    for _, face in ipairs({ Enum.NormalId.Back, Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Left, Enum.NormalId.Right }) do
                        local d2 = Instance.new("Decal")
                        d2.Name = "LosPollosDecal"
                        d2.Texture = imageId
                        d2.Face = face
                        d2.Parent = desc
                    end
                end
            end)
        end
    end
    -- CoreGui
    pcall(function()
        for _, desc in ipairs(game:GetService("CoreGui"):GetDescendants()) do
            infectObj(desc, imageId)
        end
    end)
    -- PlayerGui
    for _, desc in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
        infectObj(desc, imageId)
    end
    -- Lighting (sky)
    for _, desc in ipairs(game:GetService("Lighting"):GetDescendants()) do
        infectObj(desc, imageId)
    end
end

funTab:CreateSection({ name = "Los Pollos Hermanos" })

funTab:CreateToggle({
    name = "Los Pollos",
    description = "Infects all images, decals, text and parts with Los Pollos Hermanos (client-sided)",
    value = false,
    flag = "LosPollosInfect",
    callback = function(enabled)
        if enabled then
            local imageId = getLosPollosImage()
            if not imageId then
                window:Notify({ title = "Los Pollos Failed", content = "Could not load image. Make sure your executor supports getcustomasset.", duration = 5 })
                return
            end

            infectionActive = true
            runInfection(imageId)

            local lastRun = 0
            infectionConn = RunService.Heartbeat:Connect(function()
                if not infectionActive then return end
                local now = os.clock()
                if now - lastRun < 2 then return end
                lastRun = now
                runInfection(imageId)
            end)

            window:Toast({ title = "Los Pollos", subtitle = "Infected!", position = "Top", duration = 3 })
        else
            infectionActive = false
            if infectionConn then infectionConn:Disconnect() infectionConn = nil end
            window:Toast({ title = "Los Pollos", subtitle = "Stopped", position = "Top", duration = 2 })
        end
    end,
})

funTab:CreateButton({
    name = "Infect Once",
    description = "Single infection pass",
    callback = function()
        local imageId = getLosPollosImage()
        if not imageId then
            window:Notify({ title = "Failed", content = "Could not load image.", duration = 3 })
            return
        end
        runInfection(imageId)
        window:Toast({ title = "Los Pollos", subtitle = "One-time pass done", position = "Top", duration = 2 })
    end,
})

            -- ============================
-- MISC TAB
-- ============================
miscTab:CreateSection({ name = "Debug" })

miscTab:CreateButton({
    name = "Debug Server Body",
    description = "Prints current animator tracks and attachment states to F9 console",
    callback = function()
        local char = LocalPlayer.Character
        if not char then
            window:Notify({ title = "Error", content = "No character found.", duration = 3 })
            return
        end

        local lines = {}
        local function log(s) table.insert(lines, s) print("[ServerDebug] " .. s) end

        -- Check playing animation tracks
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        local animator = hum and hum:FindFirstChildOfClass("Animator")
        if animator then
            local tracks = animator:GetPlayingAnimationTracks()
            log("Playing animation tracks: " .. #tracks)
            for _, t in ipairs(tracks) do
                log("  Track: " .. tostring(t.Animation and t.Animation.AnimationId) .. " | Priority: " .. tostring(t.Priority) .. " | Looped: " .. tostring(t.Looped) .. " | Speed: " .. tostring(t.Speed))
            end
        else
            log("No Animator found")
        end

        -- Check AnimationConstraints (MM2 IK rig)
        local constraints = {}
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("AnimationConstraint") then
                table.insert(constraints, desc.Name)
            end
        end
        log("AnimationConstraints: " .. #constraints .. " found")
        for _, name in ipairs(constraints) do
            log("  " .. name)
        end

        -- Check BallSocketConstraints
        local balls = {}
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("BallSocketConstraint") then
                table.insert(balls, desc.Name)
            end
        end
        log("BallSocketConstraints: " .. #balls .. " found")

        -- Check Motor6Ds (should be 0 in MM2)
        local motors = {}
        for _, desc in ipairs(char:GetDescendants()) do
            if desc:IsA("Motor6D") then
                table.insert(motors, desc.Name)
            end
        end
        log("Motor6Ds: " .. #motors .. " found")

        -- Summary notify
        local trackCount = animator and #animator:GetPlayingAnimationTracks() or 0
        window:Notify({
            title = "Server Body Debug",
            content = trackCount .. " tracks playing | " .. #constraints .. " AnimConstraints | " .. #motors .. " Motor6Ds\nFull output in F9 console",
            duration = 6,
        })
    end,
})

miscTab:CreateToggle({
    name = "Anti Idle",
    description = "Prevent the client from being marked idle",
    value = false,
    flag = "AntiIdle",
    callback = function(enabled)
        if enabled then
            enableAntiIdle()
            window:Toast({ title = "Anti Idle", subtitle = "Enabled", position = "Top", duration = 2 })
        else
            stopAntiIdle()
            window:Toast({ title = "Anti Idle", subtitle = "Disabled", position = "Top", duration = 2 })
        end
    end,
})

miscTab:CreateSection({ name = "Server" })

miscTab:CreateButton({
    name = "Rejoin Server",
    description = "Rejoins the current server",
    callback = function()
        local TeleportService = game:GetService("TeleportService")
        local player = LocalPlayer
        
        window:Notify({
            title = "Rejoining...",
            content = "Teleporting back to this server",
            duration = 2,
        })
        
        task.wait(0.5)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end,
})

miscTab:CreateButton({
    name = "Server Hop",
    description = "Joins a different server",
    callback = function()
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        
        window:Notify({
            title = "Server Hopping...",
            content = "Finding a new server",
            duration = 2,
        })
        
        local success, servers = pcall(function()
            return HttpService:JSONDecode(game:HttpGet(
                "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
            ))
        end)
        
        if success and servers and servers.data then
            local currentJobId = game.JobId
            for _, server in ipairs(servers.data) do
                if server.id ~= currentJobId and server.playing < server.maxPlayers then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                    end)
                    return
                end
            end
            window:Notify({
                title = "Server Hop Failed",
                content = "No available servers found",
                duration = 3,
            })
        else
            window:Notify({
                title = "Server Hop Failed",
                content = "Could not fetch server list",
                duration = 3,
            })
        end
    end,
})

miscTab:CreateButton({
    name = "Rejoin (New Server)",
    description = "Rejoins the game in a new server",
    callback = function()
        local TeleportService = game:GetService("TeleportService")
        
        window:Notify({
            title = "Rejoining...",
            content = "Teleporting to a new server",
            duration = 2,
        })
        
        task.wait(0.5)
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

local farmRejoinQueued = false
local function shouldAutoRejoinOnKick()
    local persist = getgenv().MM2EnhancedPersist
    return getFlag("AutoCoins", false)
        or getFlag("AutoGunDrop", false)
        or (persist and (persist.AutoCoins or persist.AutoGunDrop))
end

local function rejoinAfterKick()
    if farmRejoinQueued or scriptUnloaded or not shouldAutoRejoinOnKick() then
        return
    end
    farmRejoinQueued = true
    pcall(function()
        local enqueue = queueteleport
        if enqueue then
            local persist = getgenv().MM2EnhancedPersist
            enqueue(string.format([[
getgenv().MM2EnhancedPersist = getgenv().MM2EnhancedPersist or {}
getgenv().MM2EnhancedPersist.AutoCoins = %s
getgenv().MM2EnhancedPersist.AutoGunDrop = %s
getgenv().MM2EnhancedPersist.FarmNoRender = %s
]], tostring(persist.AutoCoins == true), tostring(persist.AutoGunDrop == true), tostring(persist.FarmNoRender == true)))
        end
    end)
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)
end

trackConnection(GuiService.ErrorMessageChanged:Connect(function()
    local message = ""
    pcall(function()
        message = tostring(GuiService:GetErrorMessage() or "")
    end)
    if message ~= "" then
        rejoinAfterKick()
    end
end))

pcall(function()
    local promptGui = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
    if promptGui then
        local overlay = promptGui:FindFirstChild("promptOverlay")
        if overlay then
            trackConnection(overlay.ChildAdded:Connect(function(child)
                if child.Name == "ErrorPrompt" then
                    rejoinAfterKick()
                end
            end))
        end
    end
end)

miscTab:CreateSection({ name = "Clipboard" })

miscTab:CreateButton({
    name = "Copy Server JobId",
    description = "Copies the current server JobId to clipboard",
    callback = function()
        if not everyClipboard then
            window:Toast({ title = "Clipboard", subtitle = "Executor missing setclipboard", position = "Top", duration = 3 })
            return
        end
        everyClipboard(game.JobId)
        window:Toast({
            title = "Copied",
            subtitle = "Server JobId copied to clipboard",
            position = "Top",
            duration = 2,
        })
    end,
})

miscTab:CreateButton({
    name = "Copy Place ID",
    description = "Copies the game PlaceId to clipboard",
    callback = function()
        if not everyClipboard then
            window:Toast({ title = "Clipboard", subtitle = "Executor missing setclipboard", position = "Top", duration = 3 })
            return
        end
        everyClipboard(tostring(game.PlaceId))
        window:Toast({
            title = "Copied",
            subtitle = "PlaceId: " .. game.PlaceId,
            position = "Top",
            duration = 2,
        })
    end,
})

miscTab:CreateSection({ name = "Performance" })

miscTab:CreateButton({
    name = "Lower Graphics",
    description = "Lower graphics quality to improve FPS",
    callback = function()
        local settings = UserSettings():GetService("UserGameSettings")
        settings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        window:Toast({
            title = "Graphics",
            subtitle = "Set to minimum quality",
            position = "Top",
            duration = 2,
        })
    end,
})

miscTab:CreateButton({
    name = "Disable Shadows",
    description = "Turn off shadows for better performance",
    callback = function()
        local Lighting = game:GetService("Lighting")
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        window:Toast({
            title = "Shadows",
            subtitle = "Disabled",
            position = "Top",
            duration = 2,
        })
    end,
})

-- ============================
-- SETTINGS TAB
-- ============================
settingsTab:CreateSection({ name = "Appearance" })

settingsTab:CreateDropdown({
    name = "Theme",
    options = { "default", "cobalt", "ember", "amethyst", "frost", "rose" },
    value = "cobalt",
    flag = "UITheme",
    callback = function(selected)
        if type(selected) == "table" then
            selected = selected[1]
        end
        if selected then
            window:ChangeTheme(selected)
        end
    end,
})

settingsTab:CreateSection({ name = "Configuration" })

settingsTab:CreateButton({
    name = "Save Configuration",
    callback = function()
        local success = window:Save()
        window:Notify({
            title = success and "Saved" or "Save Failed",
            content = success and "Configuration saved to disk." or "Could not save.",
            duration = 4,
        })
    end,
})

settingsTab:CreateButton({
    name = "Load Configuration",
    callback = function()
        window:Load()
        window:Notify({
            title = "Loaded",
            content = "Configuration loaded from disk.",
            duration = 4,
        })
    end,
})

settingsTab:CreateSection({ name = "Window" })

settingsTab:CreateKeybind({
    name = "Toggle Window",
    value = Enum.KeyCode.Q,
    hold = false,
    flag = "ToggleKey",
    callback = function()
        window:ToggleHide()
    end,
})

settingsTab:CreateButton({
    name = "Unload UI",
    description = "Close the interface and clean up",
    callback = function()
        window:Notify({
            title = "Unloading...",
            content = "Script will unload in 1 second",
            duration = 1,
        })
        task.delay(1, function()
            pcall(unloadScript)
        end)
    end,
})

settingsTab:CreateButton({
    name = "Force Unload Now",
    description = "Unload the script immediately",
    callback = function()
        pcall(function()
            unloadScript()
        end)
    end,
})

settingsTab:CreateSection({ name = "About" })

settingsTab:CreateStat({
    name = "Version",
    value = 4.5,
    suffix = "",
    compact = true,
})

-- ============================
-- INIT
-- ============================

pcall(function()
    window:Navigate("Home")
end)

window:Notify({
    title = "MM2 Enhanced v4.5",
    content = "Q toggles the UI. Config auto-saves.",
    duration = 5,
})

if #missingRequired > 0 then
    window:Notify({
        title = "Missing required functions",
        content = table.concat(missingRequired, " | "),
        duration = 10,
    })
end
if #missingOptional > 0 then
    window:Notify({
        title = "Missing optional functions",
        content = table.concat(missingOptional, " | "),
        duration = 8,
    })
end
end -- ui scope
