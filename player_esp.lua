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

RightGroupBox:AddToggle('WallCheck', {
    Text = 'Wall Check',
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
    self.wallCheck = false
    self.softLockBaseStrength = 0.7
    self.softLockMaxStrength = 1.0
    self.camLockBaseStrength = 0.85
    self.camLockMaxStrength = 1.0
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

    local target = findClosestToMouse(camera, self.fovRadius, self.wallCheck)
    if not target then
        return
    end

    self.target = target
    self.lockedByKey = true
end

function TargetingController:updateFovVisual(camera)
    local mousePos = UserInputService:GetMouseLocation()
    self.fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    self.fovCircle.Radius = self.fovRadius
    self.fovCircle.Visible = self.showFov and self.mode ~= 'None'
end

function TargetingController:applyCamLock(camera)
    if self.target and not isValidTarget(self.target, camera, self.wallCheck) then
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

    if not self.target then
        return
    end

    local root = getHumanoidRoot(self.target.Character)
    if not root then
        Toggles.CamLock:SetValue(false)
        return
    end

    local onScreen = isValidTarget(self.target, camera, self.wallCheck)
    if not onScreen or not isWithinFov(camera, root, self.fovRadius) then
        self.target = nil
        self.lockedByKey = false
        Toggles.CamLock:SetValue(false)
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
        return
    end

    local root = getHumanoidRoot(self.target.Character)
    if not root then
        self.target = nil
        self.lockedByKey = false
        return
    end

    if not isWithinFov(camera, root, self.fovRadius) then
        self.target = nil
        self.lockedByKey = false
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
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
        or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

function TargetingController:getLerpStrength(camera, root, baseStrength, maxStrength)
    local distance = (camera.CFrame.Position - root.Position).Magnitude
    local distanceFactor = math.clamp(distance / 200, 0, 1)
    return math.clamp(baseStrength + ((maxStrength - baseStrength) * distanceFactor), baseStrength, maxStrength)
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
targeting.wallCheck = Toggles.WallCheck.Value

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

Toggles.WallCheck:OnChanged(function()
    targeting.wallCheck = Toggles.WallCheck.Value
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
