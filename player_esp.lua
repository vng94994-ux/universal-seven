--[[
    Player ESP Script (LinoriaLib + Drawing API)

    Features:
    - Toggleable Player ESP with ColorPicker
    - Name + 2D bounding box
    - Handles join/leave/respawn
    - Client-side only
    - Lightweight RenderStepped update
]]

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// LinoriaLib setup
local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'ESP Demo',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Main = Window:AddTab('Main'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local LeftGroupBox = Tabs.Main:AddLeftGroupbox('ESP')
local EspOptionsBox = Tabs.Main:AddLeftGroupbox('ESP Options')
local RightGroupBox = Tabs.Main:AddRightGroupbox('Camera Assist')

LeftGroupBox:AddToggle('PlayerESP', {
    Text = 'Player ESP',
    Default = false,
})

LeftGroupBox:AddToggle('BoxESP', {
    Text = 'Box ESP',
    Default = true,
})

LeftGroupBox:AddToggle('NameESP', {
    Text = 'Name ESP',
    Default = true,
})

LeftGroupBox:AddToggle('HealthESP', {
    Text = 'Health Bar',
    Default = false,
})

LeftGroupBox:AddToggle('DistanceESP', {
    Text = 'Distance Text',
    Default = false,
})

LeftGroupBox:AddToggle('HideOffscreen', {
    Text = 'Hide Off-Screen',
    Default = true,
})

LeftGroupBox:AddLabel('Box Color'):AddColorPicker('BoxColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Box Color',
})

LeftGroupBox:AddLabel('Name Color'):AddColorPicker('NameColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Name Color',
})

LeftGroupBox:AddLabel('Health Color'):AddColorPicker('HealthColor', {
    Default = Color3.fromRGB(0, 255, 0),
    Title = 'Health Bar Color',
})

EspOptionsBox:AddSlider('BoxHeight', {
    Text = 'Box Height',
    Default = 90,
    Min = 40,
    Max = 200,
    Rounding = 0,
})

EspOptionsBox:AddSlider('BoxWidth', {
    Text = 'Box Width',
    Default = 55,
    Min = 25,
    Max = 140,
    Rounding = 0,
})

EspOptionsBox:AddSlider('BoxScale', {
    Text = 'Box Scale',
    Default = 0.85,
    Min = 0.5,
    Max = 1.2,
    Rounding = 2,
})

EspOptionsBox:AddSlider('OutlineThickness', {
    Text = 'Outline Thickness',
    Default = 1,
    Min = 1,
    Max = 3,
    Rounding = 0,
})

EspOptionsBox:AddSlider('EspOpacity', {
    Text = 'ESP Opacity',
    Default = 0.85,
    Min = 0.2,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddToggle('CamLock', {
    Text = 'Cam Lock',
    Default = false,
})

RightGroupBox:AddToggle('SoftLock', {
    Text = 'Soft Lock',
    Default = false,
})

RightGroupBox:AddSlider('CamFOVRadius', {
    Text = 'Cam Lock FOV',
    Default = 130,
    Min = 60,
    Max = 300,
    Rounding = 0,
})

RightGroupBox:AddSlider('SoftFOVRadius', {
    Text = 'Soft Lock FOV',
    Default = 150,
    Min = 60,
    Max = 300,
    Rounding = 0,
})

RightGroupBox:AddToggle('ShowFOV', {
    Text = 'Show FOV',
    Default = false,
})

RightGroupBox:AddSlider('FOVSmooth', {
    Text = 'FOV Smooth',
    Default = 0.2,
    Min = 0,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddSlider('FOVThickness', {
    Text = 'FOV Thickness',
    Default = 1,
    Min = 1,
    Max = 4,
    Rounding = 0,
})

RightGroupBox:AddSlider('FOVOpacity', {
    Text = 'FOV Opacity',
    Default = 0.6,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddToggle('WallCheck', {
    Text = 'Wall Check',
    Default = false,
})

RightGroupBox:AddToggle('RequireShiftLock', {
    Text = 'Require Shift Lock',
    Default = true,
})

RightGroupBox:AddToggle('RequireRightClick', {
    Text = 'Require Right Click',
    Default = true,
})

RightGroupBox:AddSlider('LockReleaseDelay', {
    Text = 'Lock Release Delay',
    Default = 0.2,
    Min = 0,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddToggle('KeepLockOutFov', {
    Text = 'Keep Lock Out FOV',
    Default = true,
})

RightGroupBox:AddSlider('CamBaseStrength', {
    Text = 'Cam Base Strength',
    Default = 0.85,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddSlider('CamMaxStrength', {
    Text = 'Cam Max Strength',
    Default = 1.0,
    Min = 0.2,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddSlider('SoftBaseStrength', {
    Text = 'Soft Base Strength',
    Default = 0.7,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddSlider('SoftMaxStrength', {
    Text = 'Soft Max Strength',
    Default = 1.0,
    Min = 0.2,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddSlider('DistanceScaleStrength', {
    Text = 'Distance Scale',
    Default = 1.0,
    Min = 0.2,
    Max = 2,
    Rounding = 2,
})

RightGroupBox:AddLabel('Lock Target Key'):AddKeyPicker('LockTargetKey', {
    Default = 'E',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Lock Target Key',
    NoUI = false,
})

--// ESP Logic
local ESPEntry = {}
ESPEntry.__index = ESPEntry

local ESPController = {}
ESPController.__index = ESPController

function ESPController.new()
    local self = setmetatable({}, ESPController)
    self.enabled = false
    self.boxColor = Color3.new(1, 1, 1)
    self.nameColor = Color3.new(1, 1, 1)
    self.healthColor = Color3.new(0, 1, 0)
    self.boxEnabled = true
    self.nameEnabled = true
    self.healthEnabled = false
    self.distanceEnabled = false
    self.hideOffscreen = true
    self.boxHeight = 90
    self.boxWidth = 55
    self.boxScale = 0.85
    self.outlineThickness = 1
    self.opacity = 0.85
    self.entries = {}
    self.connections = {}
    return self
end

function ESPController:setEnabled(state)
    self.enabled = state
end

function ESPController:setBoxColor(color)
    self.boxColor = color
    for _, entry in pairs(self.entries) do
        entry:setBoxColor(color)
    end
end

function ESPController:setNameColor(color)
    self.nameColor = color
    for _, entry in pairs(self.entries) do
        entry:setNameColor(color)
    end
end

function ESPController:setHealthColor(color)
    self.healthColor = color
    for _, entry in pairs(self.entries) do
        entry:setHealthColor(color)
    end
end

function ESPController:updateSettings()
    for _, entry in pairs(self.entries) do
        entry:updateSettings()
    end
end

function ESPController:trackPlayer(player)
    if player == LocalPlayer then
        return
    end

    if self.entries[player] then
        return
    end

    local entry = ESPEntry.new(player, self)
    self.entries[player] = entry

    self.connections[player] = {
        player.CharacterAdded:Connect(function()
            entry:bindCharacter(player.Character)
        end),
        player.CharacterRemoving:Connect(function()
            entry:clearCharacter()
        end),
    }

    if player.Character then
        entry:bindCharacter(player.Character)
    end
end

function ESPController:untrackPlayer(player)
    local entry = self.entries[player]
    if not entry then
        return
    end

    entry:destroy()
    self.entries[player] = nil

    local conns = self.connections[player]
    if conns then
        for _, conn in ipairs(conns) do
            conn:Disconnect()
        end
    end
    self.connections[player] = nil
end

function ESPController:start()
    self.renderConn = RunService.RenderStepped:Connect(function()
        self:update()
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:trackPlayer(player)
    end

    self.playerAddedConn = Players.PlayerAdded:Connect(function(player)
        self:trackPlayer(player)
    end)

    self.playerRemovingConn = Players.PlayerRemoving:Connect(function(player)
        self:untrackPlayer(player)
    end)
end

function ESPController:stop()
    if self.renderConn then
        self.renderConn:Disconnect()
    end
    if self.playerAddedConn then
        self.playerAddedConn:Disconnect()
    end
    if self.playerRemovingConn then
        self.playerRemovingConn:Disconnect()
    end

    for player in pairs(self.entries) do
        self:untrackPlayer(player)
    end
end

function ESPController:update()
    if not self.enabled then
        return
    end

    for _, entry in pairs(self.entries) do
        entry:update(Camera)
    end
end

--// ESP Entry (per player)

function ESPEntry.new(player, controller)
    local self = setmetatable({}, ESPEntry)
    self.player = player
    self.controller = controller
    self.character = nil
    self.smoothedSize = Vector2.new(0, 0)
    self.smoothedAlpha = 0

    self.box = Drawing.new('Square')
    self.box.Thickness = 1
    self.box.Filled = false
    self.box.Visible = false

    self.healthBar = Drawing.new('Square')
    self.healthBar.Thickness = 1
    self.healthBar.Filled = true
    self.healthBar.Visible = false

    self.nameText = Drawing.new('Text')
    self.nameText.Size = 16
    self.nameText.Center = true
    self.nameText.Outline = true
    self.nameText.Visible = false

    self.distanceText = Drawing.new('Text')
    self.distanceText.Size = 14
    self.distanceText.Center = true
    self.distanceText.Outline = true
    self.distanceText.Visible = false

    self:setBoxColor(controller.boxColor)
    self:setNameColor(controller.nameColor)
    self:setHealthColor(controller.healthColor)
    self:updateSettings()

    return self
end

function ESPEntry:setBoxColor(color)
    self.box.Color = color
end

function ESPEntry:setNameColor(color)
    self.nameText.Color = color
    self.distanceText.Color = color
end

function ESPEntry:setHealthColor(color)
    self.healthBar.Color = color
end

function ESPEntry:setVisible(state)
    self.box.Visible = state
    self.nameText.Visible = state
    self.distanceText.Visible = state
    self.healthBar.Visible = state
end

function ESPEntry:updateSettings()
    self.box.Thickness = self.controller.outlineThickness
    self.healthBar.Thickness = self.controller.outlineThickness
end

function ESPEntry:bindCharacter(character)
    self.character = character
end

function ESPEntry:clearCharacter()
    self.character = nil
    self:setVisible(false)
end

function ESPEntry:destroy()
    self.box:Remove()
    self.healthBar:Remove()
    self.nameText:Remove()
    self.distanceText:Remove()
end

local function getStableBoxSize(camera, rootPart, controller)
    local screenPoint, onScreen = camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        return nil, nil, nil, false
    end

    local distance = (camera.CFrame.Position - rootPart.Position).Magnitude
    local scale = 500 / math.max(distance, 1)
    local scaleFactor = math.clamp(scale, 0.6, 1.1)

    local height = controller.boxHeight * scaleFactor * controller.boxScale
    local width = controller.boxWidth * scaleFactor * controller.boxScale

    local maxHeight = math.min(camera.ViewportSize.Y * 0.4, 200)
    local maxWidth = math.min(camera.ViewportSize.X * 0.3, 140)

    height = math.clamp(height, 28, maxHeight)
    width = math.clamp(width, 18, maxWidth)

    return Vector2.new(width, height), Vector2.new(screenPoint.X, screenPoint.Y), distance, true
end

function ESPEntry:update(camera)
    if not self.character then
        self:setVisible(false)
        return
    end

    if not self.controller.enabled then
        self:setVisible(false)
        return
    end

    local humanoidRoot = self.character:FindFirstChild('HumanoidRootPart')
    local humanoid = self.character:FindFirstChildOfClass('Humanoid')
    if not humanoidRoot or not humanoid then
        self:setVisible(false)
        return
    end

    local knocked = humanoid.Health <= 0
        or humanoid.Health <= 10
        or humanoid:GetState() == Enum.HumanoidStateType.Physics
        or humanoid:GetState() == Enum.HumanoidStateType.Ragdoll
    if knocked then
        self:setVisible(false)
        return
    end

    local size, screenPos, distance, onScreen = getStableBoxSize(camera, humanoidRoot, self.controller)
    if not size and self.controller.hideOffscreen then
        local targetAlpha = 0
        self.smoothedAlpha = self.smoothedAlpha + (targetAlpha - self.smoothedAlpha) * 0.2
        self:setVisible(self.smoothedAlpha > 0.02)
        return
    end
    if not size then
        return
    end

    local smoothing = 0.2
    self.smoothedSize = self.smoothedSize:Lerp(size, smoothing)

    local boxWidth = self.smoothedSize.X
    local boxHeight = self.smoothedSize.Y

    local shouldShow = self.controller.enabled and (not self.controller.hideOffscreen or onScreen)
    local targetAlpha = shouldShow and 1 or 0
    self.smoothedAlpha = self.smoothedAlpha + (targetAlpha - self.smoothedAlpha) * 0.2
    local alpha = self.smoothedAlpha * self.controller.opacity
    local visible = alpha > 0.02

    self.box.Position = Vector2.new(screenPos.X - boxWidth / 2, screenPos.Y - boxHeight / 2)
    self.box.Size = Vector2.new(boxWidth, boxHeight)
    self.box.Transparency = alpha

    self.nameText.Text = self.player.Name
    self.nameText.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight / 2 - 16)
    self.nameText.Transparency = alpha

    if self.controller.distanceEnabled then
        self.distanceText.Text = string.format('%.0f m', distance)
        self.distanceText.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight / 2 + 2)
        self.distanceText.Transparency = alpha
    end

    if self.controller.healthEnabled then
        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local barHeight = boxHeight * healthPercent
        local barWidth = 3
        local barX = screenPos.X - boxWidth / 2 - 6
        local barY = screenPos.Y + boxHeight / 2 - barHeight

        self.healthBar.Position = Vector2.new(barX, barY)
        self.healthBar.Size = Vector2.new(barWidth, barHeight)
        self.healthBar.Transparency = alpha

        local healthColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(255, 255, 0), math.clamp(healthPercent * 2, 0, 1))
        healthColor = healthColor:Lerp(Color3.fromRGB(0, 255, 0), math.clamp((healthPercent - 0.5) * 2, 0, 1))
        self.healthBar.Color = self.controller.healthColor:Lerp(healthColor, 0.6)
    end

    self.box.Visible = visible and self.controller.boxEnabled
    self.nameText.Visible = visible and self.controller.nameEnabled
    self.distanceText.Visible = visible and self.controller.distanceEnabled
    self.healthBar.Visible = visible and self.controller.healthEnabled
end

--// Camera Targeting Logic
local TargetingController = {}
TargetingController.__index = TargetingController

function TargetingController.new()
    local self = setmetatable({}, TargetingController)
    self.mode = 'None'
    self.target = nil
    self.renderConn = nil
    self.lockedByKey = false
    self.fovRadius = 140
    self.fovRadiusCam = 130
    self.fovRadiusSoft = 150
    self.showFov = false
    self.fovSmooth = 0.2
    self.fovThickness = 1
    self.fovOpacity = 0.6
    self.wallCheck = false
    self.requireShiftLock = true
    self.requireRightClick = true
    self.lockReleaseDelay = 0.2
    self.keepLockOutFov = true
    self.softLockBaseStrength = 0.7
    self.softLockMaxStrength = 1.0
    self.camLockBaseStrength = 0.85
    self.camLockMaxStrength = 1.0
    self.distanceScaleStrength = 1.0
    self.invalidSince = nil
    self.fovCircle = Drawing.new('Circle')
    self.fovCircle.Filled = false
    self.fovCircle.Thickness = self.fovThickness
    self.fovCircle.Transparency = self.fovOpacity
    self.fovCircle.Visible = false
    return self
end

local function getHumanoidRoot(character)
    return character and character:FindFirstChild('HumanoidRootPart')
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass('Humanoid')
end

local function isValidTarget(player, camera, wallCheck)
    if player == LocalPlayer then
        return false
    end

    local character = player.Character
    if not character then
        return false
    end

    local humanoid = getHumanoid(character)
    if not humanoid or humanoid.Health <= 0 then
        return false
    end

    local state = humanoid:GetState()
    if humanoid.Health <= 15 or state == Enum.HumanoidStateType.Physics or state == Enum.HumanoidStateType.Ragdoll then
        return false
    end

    local root = getHumanoidRoot(character)
    if not root then
        return false
    end

    local _, onScreen = camera:WorldToViewportPoint(root.Position)
    if not onScreen then
        return false
    end

    local direction = root.Position - camera.CFrame.Position
    if camera.CFrame.LookVector:Dot(direction.Unit) <= 0 then
        return false
    end

    if wallCheck then
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        local ignoreList = {}
        if LocalPlayer.Character then
            table.insert(ignoreList, LocalPlayer.Character)
        end
        rayParams.FilterDescendantsInstances = ignoreList
        rayParams.IgnoreWater = true

        local result = Workspace:Raycast(camera.CFrame.Position, direction, rayParams)
        if result and not result.Instance:IsDescendantOf(character) then
            return false
        end
    end

    return onScreen
end

local function getScreenDistance(camera, root, screenPoint)
    local point, onScreen = camera:WorldToViewportPoint(root.Position)
    if not onScreen then
        return math.huge
    end

    local delta = Vector2.new(point.X, point.Y) - screenPoint
    return delta.Magnitude
end

local function isWithinFov(camera, root, radius)
    local mousePos = UserInputService:GetMouseLocation()
    local distance = getScreenDistance(camera, root, mousePos)
    return distance <= radius
end

local function findClosestToMouse(camera, radius, wallCheck)
    local mousePos = UserInputService:GetMouseLocation()
    local bestPlayer
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = getHumanoidRoot(player.Character)
            local humanoid = getHumanoid(player.Character)
            if root and humanoid and humanoid.Health > 0 then
                if isValidTarget(player, camera, wallCheck) then
                    local distance = getScreenDistance(camera, root, mousePos)
                    if distance <= radius and distance < bestDistance then
                        bestDistance = distance
                        bestPlayer = player
                    end
                end
            end
        end
    end

    return bestPlayer
end

function TargetingController:setMode(mode)
    self.mode = mode
    if mode == 'None' then
        self.target = nil
        self.lockedByKey = false
    end
end

function TargetingController:toggleLock(camera)
    if self.lockedByKey then
        self.lockedByKey = false
        self.target = nil
        return
    end

    if self.mode == 'None' then
        return
    end

    local radius = self.mode == 'CamLock' and self.fovRadiusCam or self.fovRadiusSoft
    local target = findClosestToMouse(camera, radius, self.wallCheck)
    if not target then
        return
    end

    self.target = target
    self.lockedByKey = true
    self.invalidSince = nil
end

function TargetingController:updateFovVisual(camera)
    local mousePos = UserInputService:GetMouseLocation()
    self.fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    local targetRadius = self.mode == 'CamLock' and self.fovRadiusCam or self.fovRadiusSoft
    self.fovRadius = self.fovRadius + (targetRadius - self.fovRadius) * self.fovSmooth
    self.fovCircle.Radius = self.fovRadius
    self.fovCircle.Thickness = self.fovThickness
    self.fovCircle.Transparency = self.fovOpacity
    self.fovCircle.Visible = self.showFov and self.mode ~= 'None'
end

function TargetingController:shouldUnlock(invalid)
    if not invalid then
        self.invalidSince = nil
        return false
    end

    if not self.invalidSince then
        self.invalidSince = tick()
        return false
    end

    return (tick() - self.invalidSince) >= self.lockReleaseDelay
end

function TargetingController:applyCamLock(camera)
    if not self.target then
        return
    end

    local root = getHumanoidRoot(self.target.Character)
    if not root then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        return
    end

    local onScreen = isValidTarget(self.target, camera, self.wallCheck)
    local inFov = isWithinFov(camera, root, self.fovRadiusCam)
    local invalid = not onScreen or (not inFov and not self.keepLockOutFov)
    if self:shouldUnlock(invalid) then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        return
    end

    if not self:isAiming() then
        return
    end

    local desiredLook = (root.Position - camera.CFrame.Position).Unit
    local strength = self:getLerpStrength(camera, root, self.camLockBaseStrength, self.camLockMaxStrength)
    local newLook = camera.CFrame.LookVector:Lerp(desiredLook, strength)
    camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLook)
end

function TargetingController:applySoftLock(camera)
    if not self.target then
        return
    end

    if not isValidTarget(self.target, camera, self.wallCheck) then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        return
    end

    local root = getHumanoidRoot(self.target.Character)
    if not root then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        return
    end

    local inFov = isWithinFov(camera, root, self.fovRadiusSoft)
    if self:shouldUnlock(not inFov and not self.keepLockOutFov) then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        return
    end

    if not self:isAiming() then
        return
    end

    local desiredLook = (root.Position - camera.CFrame.Position).Unit
    local strength = self:getLerpStrength(camera, root, self.softLockBaseStrength, self.softLockMaxStrength)
    local newLook = camera.CFrame.LookVector:Lerp(desiredLook, strength)
    camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLook)
end

function TargetingController:isAiming()
    local shiftLocked = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
    local rightHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    if self.requireShiftLock and self.requireRightClick then
        return shiftLocked or rightHeld
    end
    if self.requireShiftLock then
        return shiftLocked
    end
    if self.requireRightClick then
        return rightHeld
    end
    return shiftLocked or rightHeld
end

function TargetingController:getLerpStrength(camera, root, baseStrength, maxStrength)
    local distance = (camera.CFrame.Position - root.Position).Magnitude
    local distanceFactor = math.clamp(distance / 200, 0, 1) * self.distanceScaleStrength
    local scaled = math.clamp(distanceFactor, 0, 1)
    return math.clamp(baseStrength + ((maxStrength - baseStrength) * scaled), baseStrength, maxStrength)
end

function TargetingController:start()
    if self.renderConn then
        return
    end

    self.renderConn = RunService.RenderStepped:Connect(function()
        self:updateFovVisual(Camera)
        if self.mode == 'CamLock' then
            self:applyCamLock(Camera)
        elseif self.mode == 'SoftLock' then
            self:applySoftLock(Camera)
        end
    end)
end

function TargetingController:stop()
    if self.renderConn then
        self.renderConn:Disconnect()
        self.renderConn = nil
    end
    self.target = nil
    self.lockedByKey = false
    self.fovCircle.Visible = false
end

--// Initialize
local controller = ESPController.new()
controller:start()
controller.boxEnabled = Toggles.BoxESP.Value
controller.nameEnabled = Toggles.NameESP.Value
controller.healthEnabled = Toggles.HealthESP.Value
controller.distanceEnabled = Toggles.DistanceESP.Value
controller.hideOffscreen = Toggles.HideOffscreen.Value
controller.boxHeight = Options.BoxHeight.Value
controller.boxWidth = Options.BoxWidth.Value
controller.boxScale = Options.BoxScale.Value
controller.outlineThickness = Options.OutlineThickness.Value
controller.opacity = Options.EspOpacity.Value
controller:setBoxColor(Options.BoxColor.Value)
controller:setNameColor(Options.NameColor.Value)
controller:setHealthColor(Options.HealthColor.Value)
controller:updateSettings()

local targeting = TargetingController.new()
targeting:start()
targeting.fovRadiusCam = Options.CamFOVRadius.Value
targeting.fovRadiusSoft = Options.SoftFOVRadius.Value
targeting.showFov = Toggles.ShowFOV.Value
targeting.fovSmooth = Options.FOVSmooth.Value
targeting.fovThickness = Options.FOVThickness.Value
targeting.fovOpacity = Options.FOVOpacity.Value
targeting.wallCheck = Toggles.WallCheck.Value
targeting.requireShiftLock = Toggles.RequireShiftLock.Value
targeting.requireRightClick = Toggles.RequireRightClick.Value
targeting.lockReleaseDelay = Options.LockReleaseDelay.Value
targeting.keepLockOutFov = Toggles.KeepLockOutFov.Value
targeting.camLockBaseStrength = Options.CamBaseStrength.Value
targeting.camLockMaxStrength = Options.CamMaxStrength.Value
targeting.softLockBaseStrength = Options.SoftBaseStrength.Value
targeting.softLockMaxStrength = Options.SoftMaxStrength.Value
targeting.distanceScaleStrength = Options.DistanceScaleStrength.Value

Toggles.PlayerESP:OnChanged(function()
    controller:setEnabled(Toggles.PlayerESP.Value)
end)

Toggles.BoxESP:OnChanged(function()
    controller.boxEnabled = Toggles.BoxESP.Value
end)

Toggles.NameESP:OnChanged(function()
    controller.nameEnabled = Toggles.NameESP.Value
end)

Toggles.HealthESP:OnChanged(function()
    controller.healthEnabled = Toggles.HealthESP.Value
end)

Toggles.DistanceESP:OnChanged(function()
    controller.distanceEnabled = Toggles.DistanceESP.Value
end)

Toggles.HideOffscreen:OnChanged(function()
    controller.hideOffscreen = Toggles.HideOffscreen.Value
end)

Options.BoxColor:OnChanged(function()
    controller:setBoxColor(Options.BoxColor.Value)
end)

Options.NameColor:OnChanged(function()
    controller:setNameColor(Options.NameColor.Value)
end)

Options.HealthColor:OnChanged(function()
    controller:setHealthColor(Options.HealthColor.Value)
end)

Options.BoxHeight:OnChanged(function()
    controller.boxHeight = Options.BoxHeight.Value
    controller:updateSettings()
end)

Options.BoxWidth:OnChanged(function()
    controller.boxWidth = Options.BoxWidth.Value
    controller:updateSettings()
end)

Options.BoxScale:OnChanged(function()
    controller.boxScale = Options.BoxScale.Value
    controller:updateSettings()
end)

Options.OutlineThickness:OnChanged(function()
    controller.outlineThickness = Options.OutlineThickness.Value
    controller:updateSettings()
end)

Options.EspOpacity:OnChanged(function()
    controller.opacity = Options.EspOpacity.Value
end)

Options.CamFOVRadius:OnChanged(function()
    targeting.fovRadiusCam = Options.CamFOVRadius.Value
end)

Options.SoftFOVRadius:OnChanged(function()
    targeting.fovRadiusSoft = Options.SoftFOVRadius.Value
end)

Toggles.ShowFOV:OnChanged(function()
    targeting.showFov = Toggles.ShowFOV.Value
end)

Options.FOVSmooth:OnChanged(function()
    targeting.fovSmooth = Options.FOVSmooth.Value
end)

Options.FOVThickness:OnChanged(function()
    targeting.fovThickness = Options.FOVThickness.Value
end)

Options.FOVOpacity:OnChanged(function()
    targeting.fovOpacity = Options.FOVOpacity.Value
end)

Toggles.WallCheck:OnChanged(function()
    targeting.wallCheck = Toggles.WallCheck.Value
end)

Toggles.RequireShiftLock:OnChanged(function()
    targeting.requireShiftLock = Toggles.RequireShiftLock.Value
end)

Toggles.RequireRightClick:OnChanged(function()
    targeting.requireRightClick = Toggles.RequireRightClick.Value
end)

Options.LockReleaseDelay:OnChanged(function()
    targeting.lockReleaseDelay = Options.LockReleaseDelay.Value
end)

Toggles.KeepLockOutFov:OnChanged(function()
    targeting.keepLockOutFov = Toggles.KeepLockOutFov.Value
end)

Options.CamBaseStrength:OnChanged(function()
    targeting.camLockBaseStrength = Options.CamBaseStrength.Value
end)

Options.CamMaxStrength:OnChanged(function()
    targeting.camLockMaxStrength = Options.CamMaxStrength.Value
end)

Options.SoftBaseStrength:OnChanged(function()
    targeting.softLockBaseStrength = Options.SoftBaseStrength.Value
end)

Options.SoftMaxStrength:OnChanged(function()
    targeting.softLockMaxStrength = Options.SoftMaxStrength.Value
end)

Options.DistanceScaleStrength:OnChanged(function()
    targeting.distanceScaleStrength = Options.DistanceScaleStrength.Value
end)

Options.LockTargetKey:OnClick(function()
    targeting:toggleLock(Camera)
end)

Toggles.CamLock:OnChanged(function()
    if Toggles.CamLock.Value then
        if Toggles.SoftLock.Value then
            Toggles.SoftLock:SetValue(false)
        end
        targeting:setMode('CamLock')
    else
        targeting:setMode(Toggles.SoftLock.Value and 'SoftLock' or 'None')
    end
end)

Toggles.SoftLock:OnChanged(function()
    if Toggles.SoftLock.Value then
        if Toggles.CamLock.Value then
            Toggles.CamLock:SetValue(false)
        end
        targeting:setMode('SoftLock')
    else
        targeting:setMode(Toggles.CamLock.Value and 'CamLock' or 'None')
    end
end)

Library:OnUnload(function()
    controller:stop()
    targeting:stop()
end)

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

ThemeManager:SetFolder('PlayerESP')
SaveManager:SetFolder('PlayerESP')

SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

SaveManager:LoadAutoloadConfig()
