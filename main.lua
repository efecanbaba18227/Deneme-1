--=== Settings ===--
local DEFAULT_WALK_SPEED = 16
local DEFAULT_FLY_SPEED = 40

--=== Services ===--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--=== State Vars ===--
local flyEnabled = false
local flySpeed = DEFAULT_FLY_SPEED
local speedValue = DEFAULT_WALK_SPEED
local infiniteJump = false
local espEnabled = false

local bodyGyro, bodyVelocity

--=== GUI Creation (Rayfield Style) ===--
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")
screenGui.IgnoreGuiInset = true

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 320, 0, 420)
mainFrame.Position = UDim2.new(0, 50, 0.5, -210)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Rayfield tarzı köşeler
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = mainFrame

-- Gölge efekti
local shadow = Instance.new("ImageLabel")
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
title.Text = "Control Panel"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

-- Buton oluşturucu
local function createButton(name, yPos, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -20, 0, 40)
	btn.Position = UDim2.new(0, 10, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(55, 55, 55)
	btn.Text = name
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 16
	btn.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = btn

	btn.MouseButton1Click:Connect(callback)
	return btn
end

-- Slider oluşturucu
local function createSlider(name, yPos, minVal, maxVal, defaultVal, callback)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 20)
	label.Position = UDim2.new(0, 10, 0, yPos)
	label.BackgroundTransparency = 1
	label.Text = name .. ": " .. defaultVal
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.Parent = mainFrame

	local sliderBack = Instance.new("Frame")
	sliderBack.Size = UDim2.new(1, -20, 0, 10)
	sliderBack.Position = UDim2.new(0, 10, 0, yPos + 20)
	sliderBack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	sliderBack.BorderSizePixel = 0
	sliderBack.Parent = mainFrame
	local backCorner = Instance.new("UICorner")
	backCorner.CornerRadius = UDim.new(0, 4)
	backCorner.Parent = sliderBack

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBack
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = sliderFill

	local dragging = false

	local function updateSlider(inputX)
		local rel = math.clamp((inputX - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
		sliderFill.Size = UDim2.new(rel, 0, 1, 0)
		local value = math.floor(minVal + rel * (maxVal - minVal))
		label.Text = name .. ": " .. value
		callback(value)
	end

	sliderBack.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateSlider(UserInputService:GetMouseLocation().X)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateSlider(UserInputService:GetMouseLocation().X)
		end
	end)
end

--=== Feature Functions ===--
local function toggleFly()
	flyEnabled = not flyEnabled
	if flyEnabled then
		local rootPart = character:WaitForChild("HumanoidRootPart")
		bodyGyro = Instance.new("BodyGyro")
		bodyGyro.P = 9e4
		bodyGyro.Parent = rootPart

		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(9e4, 9e4, 9e4)
		bodyVelocity.Parent = rootPart

		RunService.RenderStepped:Connect(function()
			if flyEnabled then
				local camCF = workspace.CurrentCamera.CFrame
				bodyGyro.CFrame = camCF
				bodyVelocity.Velocity = camCF.LookVector * flySpeed
			end
		end)
	else
		if bodyGyro then bodyGyro:Destroy() end
		if bodyVelocity then bodyVelocity:Destroy() end
	end
end

local function setSpeed(val)
	speedValue = val
	humanoid.WalkSpeed = speedValue
end

local function setFlySpeed(val)
	flySpeed = val
end

local function toggleInfiniteJump()
	infiniteJump = not infiniteJump
end

UserInputService.JumpRequest:Connect(function()
	if infiniteJump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

local function toggleESP()
	espEnabled = not espEnabled
	if espEnabled then
		RunService.RenderStepped:Connect(function()
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= player and plr.Character and plr.Character:FindFirstChild("Head") then
					if not plr.Character.Head:FindFirstChild("ESPTag") then
						local bb = Instance.new("BillboardGui")
						bb.Name = "ESPTag"
						bb.Size = UDim2.new(0, 100, 0, 50)
						bb.AlwaysOnTop = true
						local lbl = Instance.new("TextLabel")
						lbl.Size = UDim2.new(1,0,1,0)
						lbl.BackgroundTransparency = 1
						lbl.Text = plr.Name
						lbl.TextColor3 = Color3.new(1,0,0)
						lbl.TextScaled = true
						lbl.Parent = bb
						bb.Parent = plr.Character.Head
					end
				end
			end
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Part") and (obj.Name == "Key" or obj.Name == "Door") then
					if not obj:FindFirstChild("ESPTag") then
						local bb = Instance.new("BillboardGui")
						bb.Name = "ESPTag"
						bb.Size = UDim2.new(0, 100, 0, 50)
						bb.AlwaysOnTop = true
						local lbl = Instance.new("TextLabel")
						lbl.Size = UDim2.new(1,0,1,0)
						lbl.BackgroundTransparency = 1
						lbl.Text = obj.Name
						lbl.TextColor3 = Color3.new(1,1,0)
						lbl.TextScaled = true
						lbl.Parent = bb
						bb.Parent = obj
					end
				end
			end
		end)
	else
		for _, tag in ipairs(workspace:GetDescendants()) do
			if tag:IsA("BillboardGui") and tag.Name == "ESPTag" then
				tag:Destroy()
			end
		end
	end
end

--=== UI Elements ===--
createButton("Toggle Fly", 50, toggleFly)
createSlider("Fly Speed", 100, 10, 100, flySpeed, setFlySpeed)
createSlider("Walk Speed", 160, 10, 100, speedValue, setSpeed)
createButton("Toggle Infinite Jump", 220, toggleInfiniteJump)
createButton("Toggle ESP", 270, toggleESP)
﻿
