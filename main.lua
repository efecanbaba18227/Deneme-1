--=== Services ===--
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

--=== State Vars ===--
local flyEnabled = false
local flySpeed = 40
local speedValue = 16
local speedLoopEnabled = false -- Sabit speed toggle
local infiniteJump = false
local espEnabled = false
local godmodeEnabled = false

local bodyGyro, bodyVelocity

--=== Menu GUI ===--
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 420)
mainFrame.Position = UDim2.new(0, 20, 0.5, -150)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

local function createButton(text, yPos, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 30)
	btn.Position = UDim2.new(0, 0, 0, yPos)
	btn.Text = text
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	btn.Parent = mainFrame
	btn.MouseButton1Click:Connect(callback)
	return btn
end

local function createSlider(text, yPos, min, max, default, onChange)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.Position = UDim2.new(0, 0, 0, yPos)
	label.Text = text .. ": " .. default
	label.TextColor3 = Color3.new(1,1,1)
	label.BackgroundTransparency = 1
	label.Parent = mainFrame

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, -20, 0, 10)
	sliderBg.Position = UDim2.new(0, 10, 0, yPos + 20)
	sliderBg.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
	sliderBg.Parent = mainFrame

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
	sliderFill.Parent = sliderBg

	local dragging = false

	local function updateFill(inputX)
		local percent = math.clamp((inputX - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
		local value = math.floor(min + (max - min) * percent)
		sliderFill.Size = UDim2.new(percent, 0, 1, 0)
		label.Text = text .. ": " .. value
		onChange(value)
	end

	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFill(input.Position.X)
		end
	end)

	sliderBg.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFill(input.Position.X)
		end
	end)
end

--=== Features ===--
-- Fly
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

-- Sabit Speed
RunService.RenderStepped:Connect(function()
	if speedLoopEnabled and humanoid and humanoid.WalkSpeed ~= speedValue then
		humanoid.WalkSpeed = speedValue
	end
end)

local function toggleSpeed()
	speedLoopEnabled = not speedLoopEnabled
end

-- Infinite Jump
local function toggleInfiniteJump()
	infiniteJump = not infiniteJump
end

UserInputService.JumpRequest:Connect(function()
	if infiniteJump then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

-- ESP
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
		end)
	else
		for _, tag in ipairs(workspace:GetDescendants()) do
			if tag:IsA("BillboardGui") and tag.Name == "ESPTag" then
				tag:Destroy()
			end
		end
	end
end

-- Godmode
RunService.RenderStepped:Connect(function()
	if godmodeEnabled and humanoid then
		if humanoid.Health < humanoid.MaxHealth then
			humanoid.Health = humanoid.MaxHealth
		end
	end
end)

local function toggleGodmode()
	godmodeEnabled = not godmodeEnabled
	if godmodeEnabled then
		humanoid.Died:Connect(function()
			if godmodeEnabled then
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	end
end

--=== Menu Controls ===--
createButton("Toggle Fly", 10, toggleFly)
createSlider("Fly Speed", 50, 10, 100, flySpeed, function(val)
	flySpeed = val
end)

createButton("Toggle Speed (No Kick)", 90, toggleSpeed)
createSlider("Walk Speed", 130, 10, 100, speedValue, function(val)
	speedValue = val
end)

createButton("Toggle Infinite Jump", 170, toggleInfiniteJump)
createButton("Toggle ESP", 210, toggleESP)
createButton("Toggle Godmode", 250, toggleGodmode)
