local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")


-- ============================
-- WINDUI LOAD
-- ============================
local WindUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
))()

-- ============================
-- WINDOW
-- ============================
local window = WindUI:CreateWindow({
    Title = "MM2 Enhanced",
    SubTitle = "MM2 utility suite",
    Icon = "shield",
    Theme = "Dark",
    Folder = "MM2Enhanced",
})

-- Compatibility layer keeps the existing feature callbacks intact while
-- translating the old menu calls to WindUI components.
local flagValues = {}

function window:Get(name)
    return flagValues[name]
end

function window:Notify(data)
    return WindUI:Notify({
        Title = data.title or data.Title or "MM2 Enhanced",
        Content = data.content or data.Content or data.subtitle or "",
        Duration = data.duration or data.Duration or 3,
    })
end

window.Toast = window.Notify

function window:ChangeTheme(theme)
    pcall(function()
        WindUI:SetTheme(theme)
    end)
end

function window:ToggleHide()
    pcall(function() self:Toggle() end)
end

function window:Save()
    local ok, result = pcall(function()
        self.CurrentConfig = self.ConfigManager:Config("MM2Enhanced")
        return self.CurrentConfig:Save()
    end)
    return ok and result ~= false
end

function window:Load()
    local ok, result = pcall(function()
        self.CurrentConfig = self.ConfigManager:CreateConfig("MM2Enhanced")
        return self.CurrentConfig:Load()
    end)
    return ok and result ~= false
end

function window:Unload()
    pcall(function() WindUI:Destroy() end)
    pcall(function() self:Destroy() end)
end

local function normalizeValue(value, fallback)
    if type(value) == "table" then
        return value[1] or fallback
    end
    return value == nil and fallback or value
end

function window:CreateTab(config)
    local tab = self:Tab({
        Title = config.name or config.Name,
        Icon = config.icon or config.Icon,
    })

    function tab:CreateSection(section)
        return self:Section({ Title = section.name or section.Name })
    end

    function tab:CreateToggle(element)
        flagValues[element.flag] = element.value
        return self:Toggle({
            Title = element.name,
            Desc = element.description,
            Value = element.value,
            Flag = element.flag,
            Callback = function(value)
                flagValues[element.flag] = value
                if element.callback then element.callback(value) end
            end,
        })
    end

    function tab:CreateSlider(element)
        flagValues[element.flag] = element.value
        return self:Slider({
            Title = element.name,
            Desc = element.description,
            Value = {
                Min = element.range[1],
                Max = element.range[2],
                Default = element.value,
            },
            Step = element.increment,
            Flag = element.flag,
            Callback = function(value)
                flagValues[element.flag] = value
                if element.callback then element.callback(value) end
            end,
        })
    end

    function tab:CreateDropdown(element)
        flagValues[element.flag] = normalizeValue(element.value, element.options[1])
        return self:Dropdown({
            Title = element.name,
            Desc = element.description,
            Values = element.options,
            Value = flagValues[element.flag],
            Multi = element.multiSelect == true,
            Flag = element.flag,
            Callback = function(value)
                flagValues[element.flag] = normalizeValue(value, element.options[1])
                if element.callback then element.callback(value) end
            end,
        })
    end

    function tab:CreateInput(element)
        flagValues[element.flag] = element.value or ""
        return self:Input({
            Title = element.name,
            Desc = element.description,
            Value = element.value or "",
            Placeholder = element.placeholder,
            Flag = element.flag,
            Callback = function(value)
                flagValues[element.flag] = value
                if element.callback then element.callback(value) end
            end,
        })
    end

    function tab:CreateKeybind(element)
        flagValues[element.flag] = element.value
        local keyValue = element.value
        if typeof(keyValue) == "EnumItem" then
            keyValue = keyValue.Name
        end
        return self:Keybind({
            Title = element.name,
            Desc = element.description,
            Value = keyValue,
            Flag = element.flag,
            Callback = function(value)
                flagValues[element.flag] = value
                if element.callback then element.callback(value) end
            end,
        })
    end

    function tab:CreateButton(element)
        return self:Button({
            Title = element.name,
            Desc = element.description,
            Callback = element.callback,
        })
    end

    function tab:CreateStat(element)
        local paragraph = self:Paragraph({
            Title = element.name,
            Content = tostring(element.value or "") .. (element.suffix or ""),
        })
        return {
            Set = function(_, value)
                if paragraph and paragraph.Set then
                    paragraph:Set({
                        Title = element.name,
                        Content = tostring(value) .. (element.suffix or ""),
                    })
                end
            end,
        }
    end

    return tab
end

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
local removeVisuals, removeCoinESP, removeGunESP
local cachedCoins, cachedVotePads, coinVisuals, gunDropVisuals
local infectionActive, infectionConn
local destroyRoundHud
local stopAntiIdle

local function trackConnection(connection)
    if connection then
        table.insert(allConnections, connection)
    end
    return connection
end

local function unloadScript()
   if scriptUnloaded then return end
   scriptUnloaded = true

   -- Stop all loops
   uiRunning = false
   farmRunning = false
   gunFarmRunning = false
   Settings.AutoFling = false
   Settings.AutoVote = false
   flinging = false
   bringLoop = false

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

   -- Stop infection
   infectionActive = false
   if infectionConn then infectionConn:Disconnect() infectionConn = nil end

   -- Clean up server body viewer


   -- Disconnect all tracked connections
   for _, conn in ipairs(allConnections) do
      if conn and conn.Disconnect then
         pcall(function() conn:Disconnect() end)
      end
   end
   table.clear(allConnections)

   -- Clean up all ESP visuals
   for _, player in ipairs(Players:GetPlayers()) do
      if player.Character then
         pcall(removeVisuals, player.Character)
      end
   end
   table.clear(playerRoleCache)

   -- Clean up coin ESP
   for coin in pairs(coinVisuals) do
      pcall(removeCoinESP, coin)
   end
   table.clear(coinVisuals)
   table.clear(cachedCoins)

   -- Clean up gun ESP
   for part in pairs(gunDropVisuals) do
      pcall(removeGunESP, part)
   end
   table.clear(gunDropVisuals)

      -- Reset character properties
   local char2, hum, root = getCharacterParts()
   if hum then
      pcall(function()
         hum.WalkSpeed = 16
         hum.JumpPower = 50
      end)
   end
   if root then
      pcall(function()
         root.AssemblyLinearVelocity = Vector3.zero
         root.AssemblyAngularVelocity = Vector3.zero
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

   currentTarget = nil
   currentMode = nil

   -- Clear caches
   pcall(invalidateMapCache)
   pcall(function() table.clear(cachedVotePads) end)
   pcall(function() table.clear(farmCooldowns) end)

   print("[MM2 Enhanced] Fully unloaded")

   -- Unload UI last
   pcall(function() window:Unload() end)
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
local function getCharacterParts(player)
    player = player or LocalPlayer
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not rootPart then return nil end
    return character, humanoid, rootPart
end

local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
end

local function hasTool(player, toolName)
    local backpack = player:FindFirstChild("Backpack")
    if backpack and backpack:FindFirstChild(toolName) then return true end
    local character = player.Character
    if character and character:FindFirstChild(toolName) then return true end
    return false
end

local function getRole(player)
    if hasTool(player, "Knife") then return "Murderer" end
    if hasTool(player, "Gun") then return "Sheriff" end
    return "Innocent"
end

local function isLocalPlayerAlive()
    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
    return LocalPlayer:GetAttribute("Alive") == true
        and humanoid ~= nil
        and humanoid.Health > 0
end

local function canUseFarmAutomation()
    if not isLocalPlayerAlive() then
        return false, "You must be alive"
    end

    local role = getRole(LocalPlayer)
    if role == "Murderer" or role == "Sheriff" then
        return false, role .. " cannot use coin or gun automation"
    end

    return true
end

local function findPlayerByText(text)
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

local function getFlag(name, fallback)
    local ok, value = pcall(function()
        return window:Get(name)
    end)
    if ok and value ~= nil then
        if type(value) == "table" then
            return value[1] or fallback
        end
        return value
    end
    return fallback
end

-- WindUI sliders sometimes pass a table or string — always normalize to number
local function asNumber(value, fallback)
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

local function enableAntiIdle()
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
local function enableNoclip()
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
                    part.CanCollide = false
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
        -- Restore CanCollide
        for _, desc in ipairs(character:GetDescendants()) do
            if desc:IsA("BasePart") then
                desc.CanCollide = true
            end
        end
    end
end

local function maintainInvisibleCollisions(character)
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    for _, desc in ipairs(character:GetDescendants()) do
        if desc:IsA("BasePart") then
            if desc == root then
                -- HRP must stay collidable so you don't fall through the floor
                if not desc.CanCollide then desc.CanCollide = true end
            else
                -- All other parts: non-collidable so you pass through players
                if desc.CanCollide then desc.CanCollide = false end
            end
        end
    end
end

local function enableInvisible()
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
                    position = "Top",
                    duration = 2,
                })
            end
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
local function enableAntifling()
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

local function flingByMode(silent)
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

-- ============================
-- AIMBOT
-- ============================
local aiming = false
local aimbotEnabled = true

trackConnection(UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        aiming = true
    end
end))

trackConnection(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
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
    local targetPartName = getFlag("AimbotTargetPart", "Head") or "Head"

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local targetPart = player.Character:FindFirstChild(targetPartName)
            local hum = player.Character:FindFirstChildWhichIsA("Humanoid")
            if targetPart and hum and hum.Health > 0 then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < shortestDist and dist <= fov then
                        shortestDist = dist
                        closest = targetPart
                    end
                end
            end
        end
    end
    return closest
end

-- Only runs work while aimbot is active + RMB held
trackConnection(RunService.RenderStepped:Connect(function()
    if not aimbotEnabled or not aiming then return end
    local target = getClosestPlayer()
    if not target then return end

    local camera = Workspace.CurrentCamera
    if not camera then return end

    local goalCFrame = CFrame.new(camera.CFrame.Position, target.Position)
    local smoothness = tonumber(getFlag("AimbotSmoothing", 0)) or 0
    if smoothness <= 0 then
        camera.CFrame = goalCFrame
    else
        camera.CFrame = camera.CFrame:Lerp(goalCFrame, 1 / smoothness)
    end
end))

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

local function getAvailableCoins()
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

local function updateRoundHud()
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

local function coinFarmLoop()
    if farmRunning then return end
    farmRunning = true
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

            local reached = tweenToCoin(coin)
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

local function collectGun()
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

local function gunFarmLoop()
    if gunFarmRunning then return end
    gunFarmRunning = true
    task.spawn(function()
        while getFlag("AutoGunDrop", false) do
            local allowed = canUseFarmAutomation()
            if allowed and not currentMode then
                collectGun()
            end
            task.wait(0.2)
        end
        gunFarmRunning = false
    end)
end

-- ============================
-- ESP SYSTEM (event-driven + throttled)
-- ============================
-- [Player] = { role = string, character = character }
local playerRoleCache = {}
coinVisuals = {} -- [coin] = true

removeVisuals = function(character)
    if not character then return end
    local head = character:FindFirstChild("Head")
    if head then
        local billboard = head:FindFirstChild("RoleName")
        if billboard then billboard:Destroy() end
    end
    local highlight = character:FindFirstChild("RoleHighlight")
    if highlight then highlight:Destroy() end
end

local function updatePlayer(player)
    if player == LocalPlayer then return end
    local character = player.Character
    if not character then return end

    -- Show a separate spectator marker for players who are out of the round.
    if player:GetAttribute("Alive") ~= true then
        if not getFlag("EnableESP", true) or not getFlag("SpectatorESP", true) then
            removeVisuals(character)
            playerRoleCache[player] = nil
            return
        end

        local head = character:FindFirstChild("Head")
        if head then
            local billboard = head:FindFirstChild("RoleName")
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "RoleName"
                billboard.Size = UDim2.fromOffset(220, 44)
                billboard.StudsOffset = Vector3.new(0, 2.8, 0)
                billboard.AlwaysOnTop = true
                billboard.MaxDistance = 1000
                billboard.LightInfluence = 0
                billboard.Parent = head

                local label = Instance.new("TextLabel")
                label.Name = "TextLabel"
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.TextStrokeTransparency = 0
                label.TextStrokeColor3 = getStrokeColor(SPECTATOR_COLOR)
                label.Parent = billboard
            end
            local label = billboard:FindFirstChild("TextLabel")
            if label then
                label.Text = player.DisplayName .. "\n[Spectator]"
                label.TextColor3 = SPECTATOR_COLOR
                label.TextStrokeColor3 = getStrokeColor(SPECTATOR_COLOR)
            end
        end

        local highlight = character:FindFirstChild("RoleHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "RoleHighlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 0.7
            highlight.OutlineTransparency = 0
            highlight.Parent = character
        end
        highlight.FillColor = SPECTATOR_COLOR
        highlight.OutlineColor = getStrokeColor(SPECTATOR_COLOR)
        playerRoleCache[player] = { role = "Spectator", character = character }
        return
    end

    if not getFlag("EnableESP", true) then
        removeVisuals(character)
        playerRoleCache[player] = nil
        return
    end

    local role = getRole(player)
    local roleColor = ROLE_COLORS[role]

    -- Only skip if role AND character are both unchanged
    local cached = playerRoleCache[player]
    if cached and cached.role == role and cached.character == character then
        return
    end
    playerRoleCache[player] = { role = role, character = character }

    if getFlag("Nametags", true) and (role ~= "Innocent" or getFlag("ShowInnocentNames", true)) then
        local head = character:FindFirstChild("Head")
        if head then
            local billboard = head:FindFirstChild("RoleName")
            if not billboard then
                billboard = Instance.new("BillboardGui")
                billboard.Name = "RoleName"
                billboard.Size = UDim2.fromOffset(220, 44)
                billboard.StudsOffset = Vector3.new(0, 2.8, 0)
                billboard.AlwaysOnTop = true
                billboard.MaxDistance = 1000
                billboard.LightInfluence = 0
                billboard.Parent = head

                local label = Instance.new("TextLabel")
                label.Name = "TextLabel"
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 1
                label.Font = Enum.Font.GothamBold
                label.TextSize = 14
                label.TextWrapped = true
                label.TextStrokeTransparency = 0
                label.TextStrokeColor3 = getStrokeColor(roleColor)
                label.TextColor3 = roleColor
                label.Parent = billboard
            end
            local label = billboard:FindFirstChild("TextLabel")
            if label then
                local desired = player.DisplayName .. "\n[" .. role .. "]"
                if label.Text ~= desired then
                    label.Text = desired
                end
                if label.TextColor3 ~= roleColor then
                    label.TextColor3 = roleColor
                end
                label.TextStrokeColor3 = getStrokeColor(roleColor)
            end
        end
    else
        local head = character:FindFirstChild("Head")
        if head then
            local billboard = head:FindFirstChild("RoleName")
            if billboard then billboard:Destroy() end
        end
    end

    if getFlag("Highlights", true) and role ~= "Innocent" then
        local highlight = character:FindFirstChild("RoleHighlight")
        if not highlight then
            highlight = Instance.new("Highlight")
            highlight.Name = "RoleHighlight"
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.FillTransparency = 0.5
            highlight.OutlineTransparency = 0
            highlight.Parent = character
        end
        if highlight.FillColor ~= roleColor then
            highlight.FillColor = roleColor
        end
        highlight.OutlineColor = getStrokeColor(roleColor)
    else
        local highlight = character:FindFirstChild("RoleHighlight")
        if highlight then highlight:Destroy() end
    end
end

local function refreshAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        updatePlayer(player)
    end
end

removeCoinESP = function(coin)
    if not coin then return end
    local highlight = coin:FindFirstChild("CoinHighlight")
    if highlight then highlight:Destroy() end
    local billboard = coin:FindFirstChild("CoinBillboard")
    if billboard then billboard:Destroy() end
    coinVisuals[coin] = nil
end

local function updateCoinVisual(coin, rootPos, showDistance)
    if not isActiveCoin(coin) then
        removeCoinESP(coin)
        return
    end

    local highlight = coin:FindFirstChild("CoinHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "CoinHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = COIN_ESP_COLOR
        highlight.FillTransparency = 0.35
        highlight.OutlineColor = getStrokeColor(COIN_ESP_COLOR)
        highlight.OutlineTransparency = 0
        highlight.Parent = coin
    end

    if showDistance then
        local billboard = coin:FindFirstChild("CoinBillboard")
        if not billboard then
            billboard = Instance.new("BillboardGui")
            billboard.Name = "CoinBillboard"
            billboard.Size = UDim2.fromOffset(120, 36)
            billboard.StudsOffset = Vector3.new(0, 1.5, 0)
            billboard.AlwaysOnTop = true
            billboard.MaxDistance = 1000
            billboard.LightInfluence = 0
            billboard.Parent = coin

            local label = Instance.new("TextLabel")
            label.Name = "TextLabel"
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextColor3 = COIN_ESP_COLOR
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = getStrokeColor(COIN_ESP_COLOR)
            label.Text = "Coin"
            label.Parent = billboard
        end
        
        local label = billboard:FindFirstChild("TextLabel")
        if label and rootPos then
            label.TextColor3 = COIN_ESP_COLOR
            label.TextStrokeColor3 = getStrokeColor(COIN_ESP_COLOR)
            local dist = math.floor((rootPos - coin.Position).Magnitude + 0.5)
            local newText = string.format("COIN\n%d studs", dist)
            if label.Text ~= newText then
                label.Text = newText
            end
        end
    end

    coinVisuals[coin] = true
end

local function updateCoinESP(updateDistances)
    local enabled = getFlag("CoinESP", true) and getFlag("EnableESP", true)
    ensureCoinCache()

    if not enabled then
        for coin in pairs(coinVisuals) do
            if coin.Parent then
                removeCoinESP(coin)
            else
                coinVisuals[coin] = nil
            end
        end
        return
    end

    -- Clean dead refs
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
gunDropVisuals = {} -- [BasePart] = true

local function getCachedGunDropPart()
    if cachedGunDropPart and cachedGunDropPart.Parent then
        return cachedGunDropPart
    end
    cachedGunDropPart = nil
    local map = getCurrentMap()
    if not map then return nil end
    -- FindFirstChild with recursive=true is much cheaper than GetDescendants
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
    local h = part:FindFirstChild("GunDropHighlight")
    if h then h:Destroy() end
    local b = part:FindFirstChild("GunDropBillboard")
    if b then b:Destroy() end
    gunDropVisuals[part] = nil
end

local function updateGunESP()
    local enabled = getFlag("GunESP", true) and getFlag("EnableESP", true)

    if not enabled then
        for part in pairs(gunDropVisuals) do
            removeGunESP(part)
        end
        table.clear(gunDropVisuals)
        return
    end

    -- Clean up dead refs
    for part in pairs(gunDropVisuals) do
        if not part.Parent then
            gunDropVisuals[part] = nil
        end
    end

    local gunPart = getCachedGunDropPart()

    -- Remove visuals for any parts that are no longer the gun drop
    for part in pairs(gunDropVisuals) do
        if part ~= gunPart then
            removeGunESP(part)
        end
    end

    if not gunPart then return end

    -- Add highlight if missing
    local highlight = gunPart:FindFirstChild("GunDropHighlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "GunDropHighlight"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = GUN_ESP_COLOR
        highlight.FillTransparency = 0.3
        highlight.OutlineColor = getStrokeColor(GUN_ESP_COLOR)
        highlight.OutlineTransparency = 0
        highlight.Parent = gunPart
    end

    -- Add billboard if missing
    local billboard = gunPart:FindFirstChild("GunDropBillboard")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "GunDropBillboard"
        billboard.Size = UDim2.fromOffset(140, 40)
        billboard.StudsOffset = Vector3.new(0, 2.5, 0)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = 1000
        billboard.LightInfluence = 0
        billboard.Parent = gunPart

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
    end

    -- Update distance text
    local label = billboard and billboard:FindFirstChild("TextLabel")
    if label then
        label.TextColor3 = GUN_ESP_COLOR
        label.TextStrokeColor3 = getStrokeColor(GUN_ESP_COLOR)
        local _, _, root = getCharacterParts()
        if root then
            local dist = math.floor((root.Position - gunPart.Position).Magnitude + 0.5)
            local newText = "GUN\n" .. dist .. " studs"
            if label.Text ~= newText then
                label.Text = newText
            end
        end
    end

    gunDropVisuals[gunPart] = true
end
-- Hook character tools so role ESP updates without full spam
local function hookPlayer(player)
    if player == LocalPlayer then return end

    local function onCharacter(character)
        task.defer(function()
            updatePlayer(player)
        end)

        trackConnection(character.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then
                task.defer(function()
                    updatePlayer(player)
                end)
            end
        end))
        trackConnection(character.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then
                task.defer(function()
                    updatePlayer(player)
                end)
            end
        end))
    end

    if player.Character then
        onCharacter(player.Character)
    end
    trackConnection(player.CharacterAdded:Connect(onCharacter))

    -- Re-run ESP when Alive attribute changes (round start/end)
    trackConnection(player.AttributeChanged:Connect(function(attr)
        if attr == "Alive" then
            task.defer(function()
                updatePlayer(player)
            end)
        end
    end))

    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        trackConnection(backpack.ChildAdded:Connect(function()
            task.defer(function()
                updatePlayer(player)
            end)
        end))
        trackConnection(backpack.ChildRemoved:Connect(function()
            task.defer(function()
                updatePlayer(player)
            end)
        end))
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    hookPlayer(player)
end
trackConnection(Players.PlayerAdded:Connect(hookPlayer))

trackConnection(Players.PlayerRemoving:Connect(function(player)
    local cached = playerRoleCache[player]
    if cached and cached.character then
        removeVisuals(cached.character)
    elseif player.Character then
        removeVisuals(player.Character)
    end
    playerRoleCache[player] = nil
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

-- ESP refresh — optimized to reduce stuttering
task.spawn(function()
    local espTick = 0
    while uiRunning do
        espTick = espTick + 1
        refreshAllPlayers()
        -- Only update coin/gun distances every other tick to reduce overhead
        updateCoinESP(espTick % 2 == 0)
        updateGunESP()
        updateRoundHud()
        task.wait(0.2)
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

-- ============================
-- TABS
-- ============================
local movementTab = window:CreateTab({ name = "Movement", icon = "move" })
local combatTab = window:CreateTab({ name = "Combat", icon = "swords" })
local farmTab = window:CreateTab({ name = "Farm", icon = "coins" })
local espTab = window:CreateTab({ name = "ESP", icon = "scan-eye" })
local playersTab = window:CreateTab({ name = "Players", icon = "users" })
local lobbyTab = window:CreateTab({ name = "Lobby", icon = "map" })
local funTab = window:CreateTab({ name = "Fun", icon = "sparkles" })
local miscTab = window:CreateTab({ name = "Misc", icon = "wrench" })
local settingsTab = window:CreateTab({ name = "Settings", icon = "settings" })

-- ============================
-- MOVEMENT TAB
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
    description = "Turn aimbot on or off. Hold Right Click to lock on.",
    value = true,
    flag = "EnableAimbot",
    callback = function(enabled)
        aimbotEnabled = enabled
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
        refreshAllPlayers()
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
        refreshAllPlayers()
    end,
})

espTab:CreateToggle({
    name = "Role Highlights",
    description = "Highlight the Murderer and Sheriff",
    value = true,
    flag = "Highlights",
    callback = function()
        refreshAllPlayers()
    end,
})

espTab:CreateToggle({
    name = "Show Innocent Names",
    description = "Show names for Innocent players too",
    value = true,
    flag = "ShowInnocentNames",
    callback = function()
        refreshAllPlayers()
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
        refreshAllPlayers()
    end,
})

espTab:CreateToggle({
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
-- FARM TAB
-- ============================
farmTab:CreateSection({ name = "Automation" })

farmTab:CreateToggle({
    name = "Auto Coin Farm",
    description = "Collect nearby coins automatically",
    value = false,
    flag = "AutoCoins",
    callback = function(enabled)
        if enabled then
            local allowed, reason = canUseFarmAutomation()
            if not allowed then
                window:Toast({ title = "Coin Farm", subtitle = reason, position = "Top", duration = 2 })
                return
            end
            coinFarmLoop()
        end
    end,
})

farmTab:CreateToggle({
    name = "Auto Gun Pickup",
    description = "Pick up the dropped gun automatically",
    value = false,
    flag = "AutoGunDrop",
    callback = function(enabled)
        if enabled then
            local allowed, reason = canUseFarmAutomation()
            if not allowed then
                window:Toast({ title = "Gun Pickup", subtitle = reason, position = "Top", duration = 2 })
                return
            end
            gunFarmLoop()
        end
    end,
})

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

local coinStat = farmTab:CreateStat({
    name = "Coins Available",
    value = 0,
    suffix = "",
    compact = true,
    changeMode = "absolute",
})

task.spawn(function()
    while uiRunning do
        coinStat:Set(#getAvailableCoins())
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
        and player:GetAttribute("Alive") == true
end

local function startBringLoop()
    if bringLoop then return end
    bringLoop = true
    task.spawn(function()
        while bringLoop do
            if not canUseBring() then
                bringLoop = false
                break
            end

            local _, _, myRoot = getCharacterParts()
            if myRoot then
                local bringCFrame = myRoot.CFrame * CFrame.new(0, 0, -1.5)
                local playersList = Players:GetPlayers()
                for _, player in ipairs(playersList) do
                    if player ~= LocalPlayer and player.Character and shouldBring(player) then
                        local targetChar = player.Character
                        local targetRoot = getRoot(targetChar)
                        if targetRoot and isAlivePlayer(player, targetChar) then
                            targetRoot.CFrame = bringCFrame
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

local function stopBringLoop()
    bringLoop = false
end

combatTab:CreateKeybind({
    name = "Bring All Keybind",
    description = "Bring living players 1.5 studs ahead while you are Murderer",
    value = Enum.KeyCode.G,
    hold = false,
    flag = "BringAllKey",
    callback = function()
        if not canUseBring() then
            stopBringLoop()
            window:Toast({ title = "Bring", subtitle = "Murderer only", position = "Top", duration = 2 })
            return
        end

        if bringLoop then
            stopBringLoop()
            window:Toast({ title = "Bring", subtitle = "Stopped", position = "Top", duration = 2 })
        else
            startBringLoop()
            window:Toast({ title = "Bring", subtitle = "Active", position = "Top", duration = 2 })
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

miscTab:CreateSection({ name = "Clipboard" })

miscTab:CreateButton({
    name = "Copy Server JobId",
    description = "Copies the current server JobId to clipboard",
    callback = function()
        setclipboard(game.JobId)
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
        setclipboard(tostring(game.PlaceId))
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

settingsTab:CreateSection({ name = "Theme" })

settingsTab:CreateDropdown({
    name = "Theme",
    options = { "default", "cobalt", "ember", "amethyst", "frost", "rose" },
    value = "cobalt",
    multiSelect = false,
    placeholder = "Select theme",
    flag = "UITheme",
    callback = function(selected)
        window:ChangeTheme(selected[1] or selected)
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
    value = 4.4,
    suffix = "",
    compact = true,
})

-- ============================
-- INIT
-- ============================

window:Notify({
    title = "MM2 Enhanced is ready",
    content = "Alive-gated ESP, Gun ESP, Invisible via anim ID. Q = UI.",
    duration = 5,
})
