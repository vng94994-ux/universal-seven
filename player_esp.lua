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
local PresetGroupBox = Tabs.Main:AddRightGroupbox('Presets & Reset')

LeftGroupBox:AddToggle('PlayerESP', {
    Text = 'Player ESP',
    Default = false,
})

LeftGroupBox:AddDropdown('ESPAnchor', {
    Text = 'ESP Anchor',
    Default = 'HumanoidRootPart',
    Values = { 'HumanoidRootPart', 'Torso', 'Head' },
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

LeftGroupBox:AddToggle('TeamCheck', {
    Text = 'Team Check',
    Default = false,
})

LeftGroupBox:AddToggle('FriendsOnly', {
    Text = 'Friends Only',
    Default = false,
})

LeftGroupBox:AddToggle('HideOffscreen', {
    Text = 'Hide Off-Screen',
    Default = true,
})

LeftGroupBox:AddToggle('HideWhenDowned', {
    Text = 'Hide When Dead/Knocked',
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

LeftGroupBox:AddToggle('LockIndicator', {
    Text = 'Lock Indicator',
    Default = true,
})

LeftGroupBox:AddLabel('Lock Color'):AddColorPicker('LockColor', {
    Default = Color3.fromRGB(255, 220, 120),
    Title = 'Lock Indicator Color',
})

local HealthOptions = LeftGroupBox:AddDependencyBox()
HealthOptions:AddToggle('HealthGradient', {
    Text = 'Gradient Health',
    Default = true,
})
HealthOptions:AddDropdown('HealthBarPlacement', {
    Text = 'Health Bar Placement',
    Default = 'Outside',
    Values = { 'Outside', 'Inside' },
})
HealthOptions:AddSlider('HealthBarWidth', {
    Text = 'Health Bar Width',
    Default = 3,
    Min = 2,
    Max = 8,
    Rounding = 0,
})
HealthOptions:SetupDependencies({
    { Toggles.HealthESP, true },
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

EspOptionsBox:AddSlider('TextScale', {
    Text = 'Text Scale',
    Default = 1,
    Min = 0.6,
    Max = 1.4,
    Rounding = 2,
})

EspOptionsBox:AddToggle('TextDistanceScale', {
    Text = 'Distance Text Scaling',
    Default = true,
})

EspOptionsBox:AddSlider('NameSpacing', {
    Text = 'Name Spacing',
    Default = 14,
    Min = 6,
    Max = 30,
    Rounding = 0,
})

local DistanceOptions = EspOptionsBox:AddDependencyBox()
DistanceOptions:AddSlider('DistanceSpacing', {
    Text = 'Distance Spacing',
    Default = 6,
    Min = 2,
    Max = 20,
    Rounding = 0,
})
DistanceOptions:AddDropdown('TextOrder', {
    Text = 'Text Order',
    Default = 'NameAboveDistance',
    Values = { 'NameAboveDistance', 'DistanceAboveName' },
})
DistanceOptions:SetupDependencies({
    { Toggles.DistanceESP, true },
})

RightGroupBox:AddToggle('CamLock', {
    Text = 'Cam Lock',
    Default = false,
})

RightGroupBox:AddToggle('SoftLock', {
    Text = 'Soft Lock',
    Default = false,
})

RightGroupBox:AddToggle('ShowFOV', {
    Text = 'Show FOV',
    Default = false,
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

RightGroupBox:AddSlider('AimDeadzone', {
    Text = 'Aim Deadzone (deg)',
    Default = 2,
    Min = 0,
    Max = 6,
    Rounding = 1,
})

RightGroupBox:AddSlider('LockReleaseDelay', {
    Text = 'Lock Release Delay',
    Default = 0.2,
    Min = 0,
    Max = 1,
    Rounding = 2,
})

RightGroupBox:AddToggle('KeepLockOffscreen', {
    Text = 'Keep Lock Off-Screen',
    Default = true,
})

RightGroupBox:AddToggle('KeepLockOutFov', {
    Text = 'Keep Lock Out FOV',
    Default = true,
})

RightGroupBox:AddToggle('AllowSwitchWhileLocked', {
    Text = 'Allow Switch While Locked',
    Default = false,
})

local SwitchOptions = RightGroupBox:AddDependencyBox()
SwitchOptions:AddLabel('Cycle Target Key'):AddKeyPicker('CycleTargetKey', {
    Default = 'Q',
    SyncToggleState = false,
    Mode = 'Toggle',
    Text = 'Cycle Target Key',
    NoUI = false,
})
SwitchOptions:SetupDependencies({
    { Toggles.AllowSwitchWhileLocked, true },
})

local CamOptions = RightGroupBox:AddDependencyBox()
CamOptions:AddSlider('CamFOVRadius', {
    Text = 'Cam Lock FOV',
    Default = 130,
    Min = 60,
    Max = 300,
    Rounding = 0,
})
CamOptions:AddSlider('CamBaseStrength', {
    Text = 'Cam Base Strength',
    Default = 0.85,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
})
CamOptions:AddSlider('CamMaxStrength', {
    Text = 'Cam Max Strength',
    Default = 1.0,
    Min = 0.2,
    Max = 1,
    Rounding = 2,
})
CamOptions:AddSlider('CamDistanceScale', {
    Text = 'Cam Distance Scale',
    Default = 1.0,
    Min = 0.2,
    Max = 2,
    Rounding = 2,
})
CamOptions:SetupDependencies({
    { Toggles.CamLock, true },
})

local SoftOptions = RightGroupBox:AddDependencyBox()
SoftOptions:AddSlider('SoftFOVRadius', {
    Text = 'Soft Lock FOV',
    Default = 150,
    Min = 60,
    Max = 300,
    Rounding = 0,
})
SoftOptions:AddSlider('SoftBaseStrength', {
    Text = 'Soft Base Strength',
    Default = 0.7,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
})
SoftOptions:AddSlider('SoftMaxStrength', {
    Text = 'Soft Max Strength',
    Default = 1.0,
    Min = 0.2,
    Max = 1,
    Rounding = 2,
})
SoftOptions:AddSlider('SoftDistanceScale', {
    Text = 'Soft Distance Scale',
    Default = 1.0,
    Min = 0.2,
    Max = 2,
    Rounding = 2,
})
SoftOptions:SetupDependencies({
    { Toggles.SoftLock, true },
})

local FovVisualOptions = RightGroupBox:AddDependencyBox()
FovVisualOptions:AddSlider('FOVSmooth', {
    Text = 'FOV Smooth',
    Default = 0.2,
    Min = 0,
    Max = 1,
    Rounding = 2,
})
FovVisualOptions:AddSlider('FOVThickness', {
    Text = 'FOV Thickness',
    Default = 1,
    Min = 1,
    Max = 4,
    Rounding = 0,
})
FovVisualOptions:AddSlider('FOVOpacity', {
    Text = 'FOV Opacity',
    Default = 0.6,
    Min = 0.1,
    Max = 1,
    Rounding = 2,
})
FovVisualOptions:SetupDependencies({
    { Toggles.ShowFOV, true },
})

local function resetEspSettings()
    Toggles.PlayerESP:SetValue(false)
    Options.ESPAnchor:SetValue('HumanoidRootPart')
    Toggles.BoxESP:SetValue(true)
    Toggles.NameESP:SetValue(true)
    Toggles.HealthESP:SetValue(false)
    Toggles.DistanceESP:SetValue(false)
    Toggles.TeamCheck:SetValue(false)
    Toggles.FriendsOnly:SetValue(false)
    Toggles.HideOffscreen:SetValue(true)
    Toggles.HideWhenDowned:SetValue(true)
    Options.BoxColor:SetValueRGB(Color3.fromRGB(255, 255, 255))
    Options.NameColor:SetValueRGB(Color3.fromRGB(255, 255, 255))
    Options.HealthColor:SetValueRGB(Color3.fromRGB(0, 255, 0))
    Toggles.LockIndicator:SetValue(true)
    Options.LockColor:SetValueRGB(Color3.fromRGB(255, 220, 120))
    Toggles.HealthGradient:SetValue(true)
    Options.HealthBarPlacement:SetValue('Outside')
    Options.HealthBarWidth:SetValue(3)
    Options.BoxHeight:SetValue(90)
    Options.BoxWidth:SetValue(55)
    Options.BoxScale:SetValue(0.85)
    Options.OutlineThickness:SetValue(1)
    Options.EspOpacity:SetValue(0.85)
    Options.TextScale:SetValue(1)
    Toggles.TextDistanceScale:SetValue(true)
    Options.NameSpacing:SetValue(14)
    Options.DistanceSpacing:SetValue(6)
    Options.TextOrder:SetValue('NameAboveDistance')
end

local function resetLockSettings()
    Toggles.CamLock:SetValue(false)
    Toggles.SoftLock:SetValue(false)
    Toggles.ShowFOV:SetValue(false)
    Toggles.WallCheck:SetValue(false)
    Toggles.RequireShiftLock:SetValue(true)
    Toggles.RequireRightClick:SetValue(true)
    Options.AimDeadzone:SetValue(2)
    Options.LockReleaseDelay:SetValue(0.2)
    Toggles.KeepLockOffscreen:SetValue(true)
    Toggles.KeepLockOutFov:SetValue(true)
    Toggles.AllowSwitchWhileLocked:SetValue(false)
    Options.CamFOVRadius:SetValue(130)
    Options.SoftFOVRadius:SetValue(150)
    Options.FOVSmooth:SetValue(0.2)
    Options.FOVThickness:SetValue(1)
    Options.FOVOpacity:SetValue(0.6)
    Options.CamBaseStrength:SetValue(0.85)
    Options.CamMaxStrength:SetValue(1)
    Options.CamDistanceScale:SetValue(1)
    Options.SoftBaseStrength:SetValue(0.7)
    Options.SoftMaxStrength:SetValue(1)
    Options.SoftDistanceScale:SetValue(1)
end

local function applyPresetLegit()
    Options.BoxScale:SetValue(0.75)
    Options.BoxHeight:SetValue(80)
    Options.BoxWidth:SetValue(50)
    Options.EspOpacity:SetValue(0.75)
    Options.TextScale:SetValue(0.9)
    Options.CamFOVRadius:SetValue(110)
    Options.SoftFOVRadius:SetValue(120)
    Options.CamBaseStrength:SetValue(0.75)
    Options.CamMaxStrength:SetValue(0.9)
    Options.SoftBaseStrength:SetValue(0.6)
    Options.SoftMaxStrength:SetValue(0.85)
    Options.CamDistanceScale:SetValue(0.8)
    Options.SoftDistanceScale:SetValue(0.8)
end

local function applyPresetComp()
    Options.BoxScale:SetValue(0.85)
    Options.BoxHeight:SetValue(90)
    Options.BoxWidth:SetValue(55)
    Options.EspOpacity:SetValue(0.85)
    Options.TextScale:SetValue(1)
    Options.CamFOVRadius:SetValue(140)
    Options.SoftFOVRadius:SetValue(160)
    Options.CamBaseStrength:SetValue(0.85)
    Options.CamMaxStrength:SetValue(1)
    Options.SoftBaseStrength:SetValue(0.7)
    Options.SoftMaxStrength:SetValue(1)
    Options.CamDistanceScale:SetValue(1)
    Options.SoftDistanceScale:SetValue(1)
end

local function applyPresetAggressive()
    Options.BoxScale:SetValue(1)
    Options.BoxHeight:SetValue(110)
    Options.BoxWidth:SetValue(70)
    Options.EspOpacity:SetValue(0.95)
    Options.TextScale:SetValue(1.1)
    Options.CamFOVRadius:SetValue(180)
    Options.SoftFOVRadius:SetValue(200)
    Options.CamBaseStrength:SetValue(0.95)
    Options.CamMaxStrength:SetValue(1)
    Options.SoftBaseStrength:SetValue(0.85)
    Options.SoftMaxStrength:SetValue(1)
    Options.CamDistanceScale:SetValue(1.2)
    Options.SoftDistanceScale:SetValue(1.2)
end

PresetGroupBox:AddButton({ Text = 'Preset: Legit', Func = applyPresetLegit })
PresetGroupBox:AddButton({ Text = 'Preset: Comp', Func = applyPresetComp })
PresetGroupBox:AddButton({ Text = 'Preset: Aggressive', Func = applyPresetAggressive })
PresetGroupBox:AddDivider()
PresetGroupBox:AddButton({ Text = 'Reset ESP Settings', Func = resetEspSettings })
PresetGroupBox:AddButton({ Text = 'Reset Lock Settings', Func = resetLockSettings })

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
    self.lockIndicatorColor = Color3.fromRGB(255, 220, 120)
    self.lockIndicatorEnabled = true
    self.boxEnabled = true
    self.nameEnabled = true
    self.healthEnabled = false
    self.distanceEnabled = false
    self.hideOffscreen = true
    self.hideWhenDowned = true
    self.teamCheck = false
    self.friendsOnly = false
    self.anchor = 'HumanoidRootPart'
    self.healthGradient = true
    self.healthPlacement = 'Outside'
    self.healthBarWidth = 3
    self.boxHeight = 90
    self.boxWidth = 55
    self.boxScale = 0.85
    self.outlineThickness = 1
    self.opacity = 0.85
    self.textScale = 1
    self.textDistanceScale = true
    self.nameSpacing = 14
    self.distanceSpacing = 6
    self.textOrder = 'NameAboveDistance'
    self.lockedTarget = nil
    self.friendCache = {}
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

function ESPController:setLockIndicatorColor(color)
    self.lockIndicatorColor = color
    for _, entry in pairs(self.entries) do
        entry:setLockIndicatorColor(color)
    end
end

function ESPController:updateSettings()
    for _, entry in pairs(self.entries) do
        entry:updateSettings()
    end
end

function ESPController:setLockedTarget(player)
    self.lockedTarget = player
end

function ESPController:isFriend(player)
    if self.friendCache[player.UserId] == nil then
        local success, result = pcall(function()
            return LocalPlayer:IsFriendsWith(player.UserId)
        end)
        self.friendCache[player.UserId] = success and result or false
    end
    return self.friendCache[player.UserId]
end

function ESPController:shouldDisplay(player)
    if player == LocalPlayer then
        return false
    end
    if self.teamCheck and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end
    if self.friendsOnly and not self:isFriend(player) then
        return false
    end
    return true
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
    self.friendCache[player.UserId] = nil

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
    if Camera.CameraType ~= Enum.CameraType.Custom then
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
    self.box.ZIndex = 1

    self.healthBar = Drawing.new('Square')
    self.healthBar.Thickness = 1
    self.healthBar.Filled = true
    self.healthBar.Visible = false
    self.healthBar.ZIndex = 1

    self.nameText = Drawing.new('Text')
    self.nameText.Size = 16
    self.nameText.Center = true
    self.nameText.Outline = true
    self.nameText.Visible = false
    self.nameText.ZIndex = 2

    self.distanceText = Drawing.new('Text')
    self.distanceText.Size = 14
    self.distanceText.Center = true
    self.distanceText.Outline = true
    self.distanceText.Visible = false
    self.distanceText.ZIndex = 2

    self:setBoxColor(controller.boxColor)
    self:setNameColor(controller.nameColor)
    self:setHealthColor(controller.healthColor)
    self:setLockIndicatorColor(controller.lockIndicatorColor)
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

function ESPEntry:setLockIndicatorColor(color)
    self.lockIndicatorColor = color
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

local function getAnchorPart(character, anchor)
    if anchor == 'Head' then
        return character:FindFirstChild('Head')
    end
    if anchor == 'Torso' then
        return character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso')
    end
    return character:FindFirstChild('HumanoidRootPart')
end

local function getStableBoxSize(camera, anchorPart, controller, anchorOffset)
    local screenPoint, onScreen = camera:WorldToViewportPoint(anchorPart.Position + anchorOffset)
    if not onScreen then
        return nil, nil, nil, false
    end

    local distance = (camera.CFrame.Position - anchorPart.Position).Magnitude
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

    if not self.controller:shouldDisplay(self.player) then
        self.smoothedAlpha = 0
        self:setVisible(false)
        return
    end

    local knocked = humanoid.Health <= 0
        or humanoid.Health <= 10
        or humanoid:GetState() == Enum.HumanoidStateType.Physics
        or humanoid:GetState() == Enum.HumanoidStateType.Ragdoll
    if knocked and self.controller.hideWhenDowned then
        self:setVisible(false)
        return
    end

    local anchorPart = getAnchorPart(self.character, self.controller.anchor) or humanoidRoot
    local anchorOffset = Vector3.new(0, 0, 0)
    if self.controller.anchor == 'Head' then
        anchorOffset = Vector3.new(0, -0.35, 0)
    end

    local size, screenPos, distance, onScreen = getStableBoxSize(camera, anchorPart, self.controller, anchorOffset)
    if not size then
        if self.controller.hideOffscreen then
            local targetAlpha = 0
            self.smoothedAlpha = self.smoothedAlpha + (targetAlpha - self.smoothedAlpha) * 0.2
            self:setVisible(self.smoothedAlpha > 0.02)
        end
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

    local textScale = self.controller.textScale
    if self.controller.textDistanceScale then
        local distanceScale = math.clamp(1 - (distance / 500), 0.75, 1.1)
        textScale = textScale * distanceScale
    end
    local nameSize = math.clamp(16 * textScale, 11, 22)
    local distanceSize = math.clamp(14 * textScale, 10, 20)

    self.nameText.Text = self.player.Name
    self.nameText.Size = nameSize
    self.nameText.Transparency = alpha

    self.distanceText.Size = distanceSize
    self.distanceText.Transparency = alpha

    local nameOffset = self.controller.nameSpacing
    local distanceOffset = self.controller.distanceSpacing
    if self.controller.textOrder == 'NameAboveDistance' or not self.controller.distanceEnabled then
        self.nameText.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight / 2 - nameOffset)
        self.distanceText.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight / 2 + distanceOffset)
    else
        self.distanceText.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight / 2 - nameOffset)
        self.nameText.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight / 2 + distanceOffset)
    end

    if self.controller.distanceEnabled then
        self.distanceText.Text = string.format('%.0f m', distance)
    end

    if self.controller.healthEnabled then
        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
        local barHeight = boxHeight * healthPercent
        local barWidth = self.controller.healthBarWidth
        local barX = screenPos.X - boxWidth / 2 - barWidth - 3
        if self.controller.healthPlacement == 'Inside' then
            barX = screenPos.X - boxWidth / 2 + 2
        end
        local barY = screenPos.Y + boxHeight / 2 - barHeight

        self.healthBar.Position = Vector2.new(barX, barY)
        self.healthBar.Size = Vector2.new(barWidth, barHeight)
        self.healthBar.Transparency = alpha

        if self.controller.healthGradient then
            local healthColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(255, 255, 0), math.clamp(healthPercent * 2, 0, 1))
            healthColor = healthColor:Lerp(Color3.fromRGB(0, 255, 0), math.clamp((healthPercent - 0.5) * 2, 0, 1))
            self.healthBar.Color = healthColor
        else
            self.healthBar.Color = self.controller.healthColor
        end
    end

    if self.controller.lockIndicatorEnabled and self.controller.lockedTarget == self.player then
        self.box.Color = self.lockIndicatorColor
        self.nameText.Color = self.lockIndicatorColor
        self.distanceText.Color = self.lockIndicatorColor
    else
        self.box.Color = self.controller.boxColor
        self.nameText.Color = self.controller.nameColor
        self.distanceText.Color = self.controller.nameColor
    end

    self.box.Visible = visible and self.controller.boxEnabled
    self.nameText.Visible = visible and self.controller.nameEnabled
    self.distanceText.Visible = visible and self.controller.distanceEnabled
    self.healthBar.Visible = visible and self.controller.healthEnabled
end

--// Camera Targeting Logic
local TargetingController = {}
TargetingController.__index = TargetingController

function TargetingController.new(espController)
    local self = setmetatable({}, TargetingController)
    self.mode = 'None'
    self.target = nil
    self.renderConn = nil
    self.espController = espController
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
    self.keepLockOffscreen = true
    self.keepLockOutFov = true
    self.allowSwitchWhileLocked = false
    self.aimDeadzone = math.rad(2)
    self.softLockBaseStrength = 0.7
    self.softLockMaxStrength = 1.0
    self.camLockBaseStrength = 0.85
    self.camLockMaxStrength = 1.0
    self.camDistanceScale = 1.0
    self.softDistanceScale = 1.0
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

local function isValidTarget(player, camera, wallCheck, requireOnScreen)
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
    if requireOnScreen and not onScreen then
        return false
    end

    local direction = root.Position - camera.CFrame.Position
    if direction.Magnitude == 0 then
        return false
    end
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

    return true
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
                if isValidTarget(player, camera, wallCheck, true) then
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

local function getTargetsInFov(camera, radius, wallCheck)
    local mousePos = UserInputService:GetMouseLocation()
    local candidates = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local root = getHumanoidRoot(player.Character)
            local humanoid = getHumanoid(player.Character)
            if root and humanoid and humanoid.Health > 0 then
                if isValidTarget(player, camera, wallCheck, true) then
                    local distance = getScreenDistance(camera, root, mousePos)
                    if distance <= radius then
                        table.insert(candidates, { player = player, distance = distance })
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b)
        return a.distance < b.distance
    end)

    return candidates
end

function TargetingController:setMode(mode)
    self.mode = mode
    if mode == 'None' then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        if self.espController then
            self.espController:setLockedTarget(nil)
        end
    end
end

function TargetingController:toggleLock(camera)
    if self.lockedByKey then
        self.lockedByKey = false
        self.target = nil
        self.invalidSince = nil
        if self.espController then
            self.espController:setLockedTarget(nil)
        end
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
    if self.espController then
        self.espController:setLockedTarget(target)
    end
end

function TargetingController:cycleTarget(camera)
    if not (self.lockedByKey and self.allowSwitchWhileLocked) then
        return
    end

    local radius = self.mode == 'CamLock' and self.fovRadiusCam or self.fovRadiusSoft
    local candidates = getTargetsInFov(camera, radius, self.wallCheck)
    if #candidates == 0 then
        return
    end

    local currentIndex = 0
    for index, candidate in ipairs(candidates) do
        if candidate.player == self.target then
            currentIndex = index
            break
        end
    end

    local nextIndex = (currentIndex % #candidates) + 1
    local nextTarget = candidates[nextIndex].player
    self.target = nextTarget
    self.invalidSince = nil
    if self.espController then
        self.espController:setLockedTarget(nextTarget)
    end
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
        if self.espController then
            self.espController:setLockedTarget(nil)
        end
        return
    end

    local valid = isValidTarget(self.target, camera, self.wallCheck, not self.keepLockOffscreen)
    local inFov = isWithinFov(camera, root, self.fovRadiusCam)
    local invalid = not valid or (not inFov and not self.keepLockOutFov)
    if self:shouldUnlock(invalid) then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        if self.espController then
            self.espController:setLockedTarget(nil)
        end
        return
    end

    if not self:isAiming() then
        return
    end

    local desiredLook = (root.Position - camera.CFrame.Position).Unit
    if self:isWithinDeadzone(desiredLook) then
        return
    end
    local strength = self:getLerpStrength(camera, root, self.camLockBaseStrength, self.camLockMaxStrength, self.camDistanceScale)
    local newLook = camera.CFrame.LookVector:Lerp(desiredLook, strength)
    camera.CFrame = CFrame.new(camera.CFrame.Position, camera.CFrame.Position + newLook)
end

function TargetingController:applySoftLock(camera)
    if not self.target then
        return
    end

    if not isValidTarget(self.target, camera, self.wallCheck, not self.keepLockOffscreen) then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        if self.espController then
            self.espController:setLockedTarget(nil)
        end
        return
    end

    local root = getHumanoidRoot(self.target.Character)
    if not root then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        if self.espController then
            self.espController:setLockedTarget(nil)
        end
        return
    end

    local inFov = isWithinFov(camera, root, self.fovRadiusSoft)
    if self:shouldUnlock(not inFov and not self.keepLockOutFov) then
        self.target = nil
        self.lockedByKey = false
        self.invalidSince = nil
        if self.espController then
            self.espController:setLockedTarget(nil)
        end
        return
    end

    if not self:isAiming() then
        return
    end

    local desiredLook = (root.Position - camera.CFrame.Position).Unit
    if self:isWithinDeadzone(desiredLook) then
        return
    end
    local strength = self:getLerpStrength(camera, root, self.softLockBaseStrength, self.softLockMaxStrength, self.softDistanceScale)
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

function TargetingController:isWithinDeadzone(desiredLook)
    local angle = math.acos(math.clamp(Camera.CFrame.LookVector:Dot(desiredLook), -1, 1))
    return angle <= self.aimDeadzone
end

function TargetingController:getLerpStrength(camera, root, baseStrength, maxStrength, distanceScale)
    local distance = (camera.CFrame.Position - root.Position).Magnitude
    local distanceFactor = math.clamp(distance / 200, 0, 1) * distanceScale
    local scaled = math.clamp(distanceFactor, 0, 1)
    return math.clamp(baseStrength + ((maxStrength - baseStrength) * scaled), baseStrength, maxStrength)
end

function TargetingController:start()
    if self.renderConn then
        return
    end

    self.renderConn = RunService.RenderStepped:Connect(function()
        if Camera.CameraType ~= Enum.CameraType.Custom then
            return
        end
        if self.mode == 'None' then
            if self.showFov then
                self:updateFovVisual(Camera)
            end
            return
        end
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
controller.anchor = Options.ESPAnchor.Value
controller.boxEnabled = Toggles.BoxESP.Value
controller.nameEnabled = Toggles.NameESP.Value
controller.healthEnabled = Toggles.HealthESP.Value
controller.distanceEnabled = Toggles.DistanceESP.Value
controller.teamCheck = Toggles.TeamCheck.Value
controller.friendsOnly = Toggles.FriendsOnly.Value
controller.hideOffscreen = Toggles.HideOffscreen.Value
controller.hideWhenDowned = Toggles.HideWhenDowned.Value
controller.boxHeight = Options.BoxHeight.Value
controller.boxWidth = Options.BoxWidth.Value
controller.boxScale = Options.BoxScale.Value
controller.outlineThickness = Options.OutlineThickness.Value
controller.opacity = Options.EspOpacity.Value
controller.textScale = Options.TextScale.Value
controller.textDistanceScale = Toggles.TextDistanceScale.Value
controller.nameSpacing = Options.NameSpacing.Value
controller.distanceSpacing = Options.DistanceSpacing.Value
controller.textOrder = Options.TextOrder.Value
controller.healthGradient = Toggles.HealthGradient.Value
controller.healthPlacement = Options.HealthBarPlacement.Value
controller.healthBarWidth = Options.HealthBarWidth.Value
controller.lockIndicatorEnabled = Toggles.LockIndicator.Value
controller:setBoxColor(Options.BoxColor.Value)
controller:setNameColor(Options.NameColor.Value)
controller:setHealthColor(Options.HealthColor.Value)
controller:setLockIndicatorColor(Options.LockColor.Value)
controller:updateSettings()

local targeting = TargetingController.new(controller)
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
targeting.keepLockOffscreen = Toggles.KeepLockOffscreen.Value
targeting.keepLockOutFov = Toggles.KeepLockOutFov.Value
targeting.allowSwitchWhileLocked = Toggles.AllowSwitchWhileLocked.Value
targeting.aimDeadzone = math.rad(Options.AimDeadzone.Value)
targeting.camLockBaseStrength = Options.CamBaseStrength.Value
targeting.camLockMaxStrength = Options.CamMaxStrength.Value
targeting.camDistanceScale = Options.CamDistanceScale.Value
targeting.softLockBaseStrength = Options.SoftBaseStrength.Value
targeting.softLockMaxStrength = Options.SoftMaxStrength.Value
targeting.softDistanceScale = Options.SoftDistanceScale.Value

Toggles.PlayerESP:OnChanged(function()
    controller:setEnabled(Toggles.PlayerESP.Value)
end)

Options.ESPAnchor:OnChanged(function()
    controller.anchor = Options.ESPAnchor.Value
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

Toggles.TeamCheck:OnChanged(function()
    controller.teamCheck = Toggles.TeamCheck.Value
end)

Toggles.FriendsOnly:OnChanged(function()
    controller.friendsOnly = Toggles.FriendsOnly.Value
end)

Toggles.HideOffscreen:OnChanged(function()
    controller.hideOffscreen = Toggles.HideOffscreen.Value
end)

Toggles.HideWhenDowned:OnChanged(function()
    controller.hideWhenDowned = Toggles.HideWhenDowned.Value
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

Toggles.LockIndicator:OnChanged(function()
    controller.lockIndicatorEnabled = Toggles.LockIndicator.Value
end)

Options.LockColor:OnChanged(function()
    controller:setLockIndicatorColor(Options.LockColor.Value)
end)

Toggles.HealthGradient:OnChanged(function()
    controller.healthGradient = Toggles.HealthGradient.Value
end)

Options.HealthBarPlacement:OnChanged(function()
    controller.healthPlacement = Options.HealthBarPlacement.Value
end)

Options.HealthBarWidth:OnChanged(function()
    controller.healthBarWidth = Options.HealthBarWidth.Value
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

Options.TextScale:OnChanged(function()
    controller.textScale = Options.TextScale.Value
end)

Toggles.TextDistanceScale:OnChanged(function()
    controller.textDistanceScale = Toggles.TextDistanceScale.Value
end)

Options.NameSpacing:OnChanged(function()
    controller.nameSpacing = Options.NameSpacing.Value
end)

Options.DistanceSpacing:OnChanged(function()
    controller.distanceSpacing = Options.DistanceSpacing.Value
end)

Options.TextOrder:OnChanged(function()
    controller.textOrder = Options.TextOrder.Value
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

Toggles.KeepLockOffscreen:OnChanged(function()
    targeting.keepLockOffscreen = Toggles.KeepLockOffscreen.Value
end)

Toggles.KeepLockOutFov:OnChanged(function()
    targeting.keepLockOutFov = Toggles.KeepLockOutFov.Value
end)

Toggles.AllowSwitchWhileLocked:OnChanged(function()
    targeting.allowSwitchWhileLocked = Toggles.AllowSwitchWhileLocked.Value
end)

Options.CamBaseStrength:OnChanged(function()
    targeting.camLockBaseStrength = Options.CamBaseStrength.Value
end)

Options.CamMaxStrength:OnChanged(function()
    targeting.camLockMaxStrength = Options.CamMaxStrength.Value
end)

Options.CamDistanceScale:OnChanged(function()
    targeting.camDistanceScale = Options.CamDistanceScale.Value
end)

Options.SoftBaseStrength:OnChanged(function()
    targeting.softLockBaseStrength = Options.SoftBaseStrength.Value
end)

Options.SoftMaxStrength:OnChanged(function()
    targeting.softLockMaxStrength = Options.SoftMaxStrength.Value
end)

Options.SoftDistanceScale:OnChanged(function()
    targeting.softDistanceScale = Options.SoftDistanceScale.Value
end)

Options.AimDeadzone:OnChanged(function()
    targeting.aimDeadzone = math.rad(Options.AimDeadzone.Value)
end)

Options.LockTargetKey:OnClick(function()
    targeting:toggleLock(Camera)
end)

Options.CycleTargetKey:OnClick(function()
    targeting:cycleTarget(Camera)
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
