-- SimpleDraggableMenu (LocalScript)
-- Put this in StarterPlayer > StarterPlayerScripts

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- State
local flyEnabled = false
local flySpeed = 40 -- default
local walkSpeed = 35 -- default (senin istediğin 30-40 aralığına yakın)
local infiniteJump = false
local espEnabled = false

-- Character refs (update on respawn)
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local bodyGyro, bodyVelocity

-- Utility: safe get char
local function refreshCharacterRefs()
    character = player.Character or player.CharacterAdded:Wait()
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    humanoid.WalkSpeed = walkSpeed
end

player.CharacterAdded:Connect(function()
    refreshCharacterRefs()
end)

-- --- GUI ---
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SimpleMenuGui"
screenGui.Parent = playerGui
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Main frame
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 300, 0, 260)
main.Position = UDim2.new(0, 50, 0.5, -130)
main.BackgroundColor3 = Color3.fromRGB(28,28,30)
main.BorderSizePixel = 0
main.Parent = screenGui

local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0,8)

-- Title bar (drag from here)
local title = Instance.new("Frame")
title.Name = "TitleBar"
title.Size = UDim2.new(1, 0, 0, 36)
title.Position = UDim2.new(0,0,0,0)
title.BackgroundColor3 = Color3.fromRGB(40,40,42)
title.BorderSizePixel = 0
title.Parent = main
local titleCorner = Instance.new("UICorner", title)
titleCorner.CornerRadius = UDim.new(0,8)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Simple Menu"
titleLabel.TextColor3 = Color3.new(1,1,1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = title

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 24)
closeBtn.Position = UDim2.new(1, -36, 0, 6)
closeBtn.Text = "X"
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(220,220,220)
closeBtn.BackgroundColor3 = Color3.fromRGB(160,40,40)
closeBtn.Parent = title
local closeCorner = Instance.new("UICorner", closeBtn)
closeCorner.CornerRadius = UDim.new(0,6)

closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = not screenGui.Enabled
end)

-- Simple element helper
local function createLabel(text, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -20, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = main
    return lbl
end

local function createButton(text, y, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 30)
    b.Position = UDim2.new(0, 10, 0, y)
    b.Text = text
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.TextColor3 = Color3.new(1,1,1)
    b.BackgroundColor3 = Color3.fromRGB(60,60,60)
    b.Parent = main
    local c = Instance.new("UICorner", b)
    c.CornerRadius = UDim.new(0,6)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function createSlider(text, y, minVal, maxVal, defaultVal, callback)
    createLabel(text .. " : " .. defaultVal, y)
    local back = Instance.new("Frame")
    back.Size = UDim2.new(1, -20, 0, 10)
    back.Position = UDim2.new(0, 10, 0, y + 22)
    back.BackgroundColor3 = Color3.fromRGB(50,50,50)
    back.Parent = main
    local backCorner = Instance.new("UICorner", back)
    backCorner.CornerRadius = UDim.new(0,4)

    local fill = Instance.new("Frame")
    local rel = (defaultVal - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(rel, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100,200,100)
    fill.Parent = back
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0,4)

    local dragging = false
    local label = main:FindFirstChildWhichIsA("TextLabel", true) -- not used; we'll update the top label instead

    local function setByX(x)
        local posX = math.clamp((x - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(posX, 0, 1, 0)
        local value = math.floor(minVal + posX * (maxVal - minVal))
        -- update the label above (find by position)
        for _, v in ipairs(main:GetChildren()) do
            if v:IsA("TextLabel") and v.Position.Y.Offset == y then
                v.Text = text .. " : " .. value
            end
        end
        callback(value)
    end

    back.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            setByX(UserInputService:GetMouseLocation().X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            setByX(UserInputService:GetMouseLocation().X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return {back = back, fill = fill}
end

-- Build UI
local y = 46
createLabel("Movement Controls", y); y = y + 24
-- Fly toggle
createButton("Toggle Fly (F opens/close)", y, function()
    flyEnabled = not flyEnabled
    if flyEnabled then
        -- create physics objects
        if rootPart and rootPart.Parent then
            bodyGyro = Instance.new("BodyGyro")
            bodyGyro.P = 9e4
            bodyGyro.MaxTorque = Vector3.new(9e5,9e5,9e5)
            bodyGyro.Parent = rootPart
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.MaxForce = Vector3.new(9e5,9e5,9e5)
            bodyVelocity.Parent = rootPart
        end
    else
        if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
        if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    end
end)
y = y + 36

-- Fly speed slider (10-100)
createSlider("Fly Speed", y, 10, 100, flySpeed, function(v)
    flySpeed = v
end)
y = y + 46

-- Walk speed
createSlider("Walk Speed", y, 10, 100, walkSpeed, function(v)
    walkSpeed = v
    if humanoid then humanoid.WalkSpeed = walkSpeed end
end)
y = y + 46

-- Infinite jump
createButton("Toggle Infinite Jump", y, function()
    infiniteJump = not infiniteJump
end)
y = y + 36

-- ESP toggle
createButton("Toggle ESP", y, function()
    espEnabled = not espEnabled
    if not espEnabled then
        -- remove existing ESP tags
        for _, gui in ipairs(workspace:GetDescendants()) do
            if gui:IsA("BillboardGui") and gui.Name == "SimpleESP" then
                gui:Destroy()
            end
        end
    end
end)
y = y + 36

-- --- Drag code for title ---
local draggingGui = false
local dragStart = Vector2.new()
local startPos = Vector2.new()
title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingGui = true
        dragStart = UserInputService:GetMouseLocation()
        startPos = Vector2.new(main.Position.X.Offset, main.Position.Y.Offset)
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingGui = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if draggingGui and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = UserInputService:GetMouseLocation() - dragStart
        main.Position = UDim2.new(0, startPos.X + delta.X, 0, startPos.Y + delta.Y)
    end
end)

-- --- Key bindings ---
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.F then
        -- toggle fly via key as well
        flyEnabled = not flyEnabled
        if flyEnabled then
            if rootPart and rootPart.Parent then
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e5,9e5,9e5)
                bodyGyro.Parent = rootPart
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(9e5,9e5,9e5)
                bodyVelocity.Parent = rootPart
            end
        else
            if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
            if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
        end
    end
end)

-- Infinite jump handler
UserInputService.JumpRequest:Connect(function()
    if infiniteJump and humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- --- ESP / Fly update loop ---
local espUpdateAccumulator = 0
local espUpdateInterval = 0.25 -- saniyede ~4 kez güncelle

RunService.Heartbeat:Connect(function(dt)
    -- ensure refs
    if not character or not character.Parent then
        refreshCharacterRefs()
    end

    -- Fly motion
    if flyEnabled and bodyVelocity and bodyGyro and workspace.CurrentCamera then
        local camCF = workspace.CurrentCamera.CFrame
        bodyGyro.CFrame = camCF
        bodyVelocity.Velocity = camCF.LookVector * flySpeed
        -- keep player bumped into humanoid state to avoid ragdoll
        if humanoid:GetState() == Enum.HumanoidStateType.Freefall then
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
    end

    -- ESP update periodically
    if espEnabled then
        espUpdateAccumulator = espUpdateAccumulator + dt
        if espUpdateAccumulator >= espUpdateInterval then
            espUpdateAccumulator = 0
            -- players
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
                    local head = plr.Character.Head
                    if not head:FindFirstChild("SimpleESP") then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "SimpleESP"
                        bb.Size = UDim2.new(0,120,0,40)
                        bb.StudsOffset = Vector3.new(0, 2.2, 0)
                        bb.AlwaysOnTop = true
                        local txt = Instance.new("TextLabel", bb)
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.BackgroundTransparency = 1
                        txt.Text = plr.Name
                        txt.TextScaled = true
                        txt.TextColor3 = Color3.fromRGB(255,80,80)
                        txt.Font = Enum.Font.GothamBold
                        bb.Parent = head
                    end
                end
            end
            -- objects (Key / Door named Parts)
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and (obj.Name == "Key" or obj.Name == "Door") then
                    if not obj:FindFirstChild("SimpleESP") then
                        local bb = Instance.new("BillboardGui")
                        bb.Name = "SimpleESP"
                        bb.Size = UDim2.new(0,110,0,30)
                        bb.StudsOffset = Vector3.new(0, 1.5, 0)
                        bb.AlwaysOnTop = true
                        local txt = Instance.new("TextLabel", bb)
                        txt.Size = UDim2.new(1,0,1,0)
                        txt.BackgroundTransparency = 1
                        txt.Text = obj.Name
                        txt.TextScaled = true
                        txt.TextColor3 = Color3.fromRGB(255,220,80)
                        txt.Font = Enum.Font.Gotham
                        bb.Parent = obj
                    end
                end
            end
        end
    end
end)

-- cleanup ESP when disabled or on script stop
player.AncestryChanged:Connect(function()
    if not player:IsDescendantOf(game) then
        for _, g in ipairs(workspace:GetDescendants()) do
            if g:IsA("BillboardGui") and g.Name == "SimpleESP" then
                g:Destroy()
            end
        end
    end
end)

-- Ensure initial humanoid speed
if humanoid then humanoid.WalkSpeed = walkSpeed end

print("SimpleDraggableMenu loaded")
