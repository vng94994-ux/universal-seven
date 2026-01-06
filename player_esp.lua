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
local RightGroupBox = Tabs.Main:AddRightGroupbox('Camera Assist')

LeftGroupBox:AddToggle('PlayerESP', {
    Text = 'Player ESP',
    Default = false,
})

LeftGroupBox:AddLabel('ESP Color'):AddColorPicker('PlayerESPColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Title = 'Player ESP Color',
})

RightGroupBox:AddToggle('CamLock', {
    Text = 'Cam Lock',
    Default = false,
})

RightGroupBox:AddToggle('SoftLock', {
    Text = 'Soft Lock',
    Default = false,
})

RightGroupBox:AddSlider('FOVRadius', {
    Text = 'FOV Radius',
    Default = 140,
    Min = 60,
    Max = 300,
    Rounding = 0,
})

RightGroupBox:AddToggle('ShowFOV', {
    Text = 'Show FOV',
    Default = false,
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
    self.color = Color3.new(1, 1, 1)
    self.entries = {}
    self.connections = {}
    return self
end

function ESPController:setEnabled(state)
    self.enabled = state
    if not state then
        for _, entry in pairs(self.entries) do
            entry:setVisible(false)
        end
    end
end

function ESPController:setColor(color)
    self.color = color
    for _, entry in pairs(self.entries) do
        entry:setColor(color)
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

    self.box = Drawing.new('Square')
    self.box.Thickness = 1
    self.box.Filled = false
    self.box.Visible = false

    self.nameText = Drawing.new('Text')
    self.nameText.Size = 16
    self.nameText.Center = true
    self.nameText.Outline = true
    self.nameText.Visible = false

    self:setColor(controller.color)

    return self
end

function ESPEntry:setColor(color)
    self.box.Color = color
    self.nameText.Color = color
end

function ESPEntry:setVisible(state)
    self.box.Visible = state
    self.nameText.Visible = state
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
    self.nameText:Remove()
end

local function getStableBoxSize(camera, rootPart)
    local screenPoint, onScreen = camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen then
        return nil
    end

    local distance = (camera.CFrame.Position - rootPart.Position).Magnitude
    local scale = 850 / math.max(distance, 1)

    local minHeight = 32
    local maxHeight = math.min(camera.ViewportSize.Y * 0.65, 320)
    local height = math.clamp(scale * 120, minHeight, maxHeight)
    local width = height * 0.6

    return Vector2.new(width, height), Vector2.new(screenPoint.X, screenPoint.Y)
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
    if not humanoidRoot then
        self:setVisible(false)
        return
    end

    local size, screenPos = getStableBoxSize(camera, humanoidRoot)
    if not size then
        self:setVisible(false)
        return
    end

    local smoothing = 0.2
    self.smoothedSize = self.smoothedSize:Lerp(size, smoothing)

    local boxWidth = self.smoothedSize.X
    local boxHeight = self.smoothedSize.Y

    self.box.Position = Vector2.new(screenPos.X - boxWidth / 2, screenPos.Y - boxHeight / 2)
    self.box.Size = Vector2.new(boxWidth, boxHeight)

    self.nameText.Text = self.player.Name
    self.nameText.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight / 2 - 18)

    self:setVisible(true)
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
    self.showFov = false
    self.snapAngleTolerance = math.rad(3)
    self.softLockBaseStrength = 0.04
    self.softLockMaxStrength = 0.12
    self.softLockDistanceScaleMax = 0.65
    self.softLockCenterBias = 1.0
    self.softLockSwitchTolerance = 0.8
    self.fovCircle = Drawing.new('Circle')
    self.fovCircle.Filled = false
    self.fovCircle.Thickness = 1
    self.fovCircle.Transparency = 0.6
    self.fovCircle.Visible = false
    return self
end

local function getHumanoidRoot(character)
    return character and character:FindFirstChild('HumanoidRootPart')
end

local function getHumanoid(character)
    return character and character:FindFirstChildOfClass('Humanoid')
end

local function isValidTarget(player, camera)
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
    return onScreen
end

local function getScreenDistanceToCenter(camera, root)
    local point, onScreen = camera:WorldToViewportPoint(root.Position)
    if not onScreen then
        return math.huge
    end

    local viewportCenter = camera.ViewportSize / 2
    local delta = Vector2.new(point.X, point.Y) - viewportCenter
    return delta.Magnitude
end

local function isWithinFov(camera, root, radius)
    local distance = getScreenDistanceToCenter(camera, root)
    return distance <= radius
end

local function findClosestToCenter(camera, radius)
    local viewportCenter = camera.ViewportSize / 2
    local bestPlayer
    local bestDistance = math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = getHumanoidRoot(player.Character)
            local humanoid = getHumanoid(player.Character)
            if root and humanoid and humanoid.Health > 0 then
                local point, onScreen = camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local delta = Vector2.new(point.X, point.Y) - viewportCenter
                    local distance = delta.Magnitude
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

    local target = findClosestToCenter(camera, self.fovRadius)
    if not target then
        return
    end

    self.target = target
    self.lockedByKey = true
end

function TargetingController:updateFovVisual(camera)
    local viewportCenter = camera.ViewportSize / 2
    self.fovCircle.Position = Vector2.new(viewportCenter.X, viewportCenter.Y)
    self.fovCircle.Radius = self.fovRadius
    self.fovCircle.Visible = self.showFov and self.mode ~= 'None'
end

function TargetingController:applyCamLock(camera)
    if self.target and not isValidTarget(self.target, camera) then
        self.target = nil
        self.lockedByKey = false
        Toggles.CamLock:SetValue(false)
        return
    end

    if self.lockedByKey and not self.target then
        self.lockedByKey = false
        Toggles.CamLock:SetValue(false)
        return
    end

    local target = self.target or findClosestToCenter(camera, self.fovRadius)
    if not target then
        return
    end

    self.target = target
    local root = getHumanoidRoot(target.Character)
    if not root then
        Toggles.CamLock:SetValue(false)
        return
    end

    local screenPoint, onScreen = camera:WorldToViewportPoint(root.Position)
    if not onScreen or not isWithinFov(camera, root, self.fovRadius) then
        self.target = nil
        self.lockedByKey = false
        Toggles.CamLock:SetValue(false)
        return
    end

    local desired = CFrame.new(camera.CFrame.Position, root.Position)
    local angle = math.acos(math.clamp(camera.CFrame.LookVector:Dot(desired.LookVector), -1, 1))
    if angle > self.snapAngleTolerance then
        camera.CFrame = desired
    end
end

function TargetingController:applySoftLock(camera)
    local bestTarget = findClosestToCenter(camera, self.fovRadius)
    if not bestTarget then
        if not self.lockedByKey then
            self.target = nil
        else
            self.target = nil
            self.lockedByKey = false
        end
        return
    end

    if self.lockedByKey then
        if not (self.target and isValidTarget(self.target, camera)) then
            self.target = nil
            self.lockedByKey = false
        end
    elseif self.target and isValidTarget(self.target, camera) then
        local currentRoot = getHumanoidRoot(self.target.Character)
        local bestRoot = getHumanoidRoot(bestTarget.Character)
        if currentRoot and bestRoot then
            local currentDistance = getScreenDistanceToCenter(camera, currentRoot)
            local bestDistance = getScreenDistanceToCenter(camera, bestRoot)
            if bestDistance < currentDistance * self.softLockSwitchTolerance then
                self.target = bestTarget
            end
        else
            self.target = bestTarget
        end
    else
        self.target = bestTarget
    end

    local target = self.target
    if not target then
        return
    end

    local root = getHumanoidRoot(target.Character)
    if not root then
        if not self.lockedByKey then
            self.target = nil
        else
            self.target = nil
            self.lockedByKey = false
        end
        return
    end

    local screenPoint, onScreen = camera:WorldToViewportPoint(root.Position)
    if not onScreen or not isWithinFov(camera, root, self.fovRadius) then
        if not self.lockedByKey then
            self.target = nil
        else
            self.target = nil
            self.lockedByKey = false
        end
        return
    end

    local viewportCenter = camera.ViewportSize / 2
    local delta = Vector2.new(screenPoint.X, screenPoint.Y) - viewportCenter
    local screenDistance = delta.Magnitude

    local distance = (camera.CFrame.Position - root.Position).Magnitude
    local distanceFactor = math.clamp(1 - (distance / 300), 0.1, self.softLockDistanceScaleMax)
    local screenFactor = math.clamp(1 - (screenDistance / self.fovRadius), 0, 1) * self.softLockCenterBias

    local strength = math.clamp(self.softLockBaseStrength + ((self.softLockMaxStrength - self.softLockBaseStrength) * screenFactor), self.softLockBaseStrength, self.softLockMaxStrength) * distanceFactor
    local desired = CFrame.new(camera.CFrame.Position, root.Position)

    camera.CFrame = camera.CFrame:Lerp(desired, strength)
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

local targeting = TargetingController.new()
targeting:start()
targeting.fovRadius = Options.FOVRadius.Value
targeting.showFov = Toggles.ShowFOV.Value

Toggles.PlayerESP:OnChanged(function()
    controller:setEnabled(Toggles.PlayerESP.Value)
end)

Options.PlayerESPColor:OnChanged(function()
    controller:setColor(Options.PlayerESPColor.Value)
end)

Options.FOVRadius:OnChanged(function()
    targeting.fovRadius = Options.FOVRadius.Value
end)

Toggles.ShowFOV:OnChanged(function()
    targeting.showFov = Toggles.ShowFOV.Value
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
