local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
--yes AI made this but i fucking suck at UI

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Configuration
local ANIMATION_DURATION = 0.3
-- VISIBLE_GOAL now uses solid background transparency (0)
local VISIBLE_GOAL = {Position = UDim2.new(0.5, 0, 0.5, 0), Size = UDim2.new(0.25, 0, 0.45, 0), BackgroundTransparency = 0}
local HIDDEN_GOAL = {Position = UDim2.new(0.5, 0, 1.5, 0)} -- Move off-screen to hide

-- Initial state
local isVisible = true
local guiElements = {} -- Stores references to all elements that need to be hidden/shown

local function createGlassGUI()
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "LiquidInterface"
	ScreenGui.ResetOnSpawn = false -- Keep the GUI visible across respawns
	ScreenGui.Parent = PlayerGui

	-- --- 1. The Main Panel (Frame) - Now a solid, dark background ---
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainPanel"
	MainFrame.Size = UDim2.new(0.25, 0, 0.45, 0) -- Responsive size, adjust as needed
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 50) -- Dark background for high contrast
	MainFrame.BackgroundTransparency = 0 -- Solid color
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	table.insert(guiElements, MainFrame)

	-- Rounded Corners (UICorner)
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 16) -- Slightly smaller corner radius for a cleaner look
	Corner.Parent = MainFrame

	-- Inner Padding Layout
	local ListLayout = Instance.new("UIListLayout")
	ListLayout.FillDirection = Enum.FillDirection.Vertical
	ListLayout.Padding = UDim.new(0, 15) -- Increased padding
	ListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ListLayout.Parent = MainFrame

	-- --- 2. Title Label ---
	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(1, 0, 0.15, 0)
	Title.BackgroundTransparency = 1 -- Keep it fully transparent
	Title.Text = "ZYLANG'S CHEATS"
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextScaled = true
	Title.Font = Enum.Font.Oswald
	Title.TextStrokeTransparency = 0.8
	Title.TextWrapped = true
	Title.Parent = MainFrame

	-- --- 3. Custom Button Template Function ---
	local function createButton(name, text, color)
		local Button = Instance.new("TextButton")
		Button.Name = name
		Button.Text = text
		Button.Size = UDim2.new(0.9, 0, 0.2, 0)
		Button.TextColor3 = Color3.fromRGB(255, 255, 255)
		Button.TextScaled = true
		Button.Font = Enum.Font.SourceSansBold
		Button.BackgroundTransparency = 0 -- Solid color
		Button.BackgroundColor3 = color or Color3.fromRGB(40, 40, 40)
		Button.BorderSizePixel = 0
		Button.Parent = MainFrame

		-- Rounded Corners for Buttons
		local ButtonCorner = Instance.new("UICorner")
		ButtonCorner.CornerRadius = UDim.new(0, 10)
		ButtonCorner.Parent = Button

		-- Add hover/press effect (optional, uses mouse events)
		Button.MouseEnter:Connect(function()
			Button:TweenSize(UDim2.new(0.95, 0, 0.22, 0), "Out", "Quad", 0.15, true)
		end)
		Button.MouseLeave:Connect(function()
			Button:TweenSize(UDim2.new(0.9, 0, 0.2, 0), "Out", "Quad", 0.15, true)
		end)

		return Button
	end

	-- --- 4. Create Buttons ---
	local ButtonOne = createButton("ButtonOne", "🚀 LAUNCH AIMBOT", Color3.fromRGB(50, 150, 250))
	local ButtonTwo = createButton("ButtonTwo", "🚀 LAUNCH ESP", Color3.fromRGB(250, 100, 50))

	-- --- 5. Button Logic ---
	ButtonOne.Activated:Connect(function()
		print("aimbot1")
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Zylang104/frontline-versus-Zylang-cheat/refs/heads/main/aimbot.lua"))()
	end)

	ButtonTwo.Activated:Connect(function()
		print("esp1")
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Zylang104/frontline-versus-Zylang-cheat/refs/heads/main/esp.lua"))()
	end)

	return MainFrame
end

-- Wait until the PlayerGui is ready before creating the GUI
local MainFrame = createGlassGUI()

-- Function to smoothly toggle visibility
local function toggleGuiVisibility()
	-- Get the current goal for the animation (either show or hide)
	local targetGoal = isVisible and HIDDEN_GOAL or VISIBLE_GOAL
	local tweenInfo = TweenInfo.new(ANIMATION_DURATION, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)

	-- Create and play the tween
	local tween = TweenService:Create(MainFrame, tweenInfo, targetGoal)

	-- If we are showing, make it visible right away before the tween starts
	if not isVisible then
		MainFrame.Visible = true
	end

	tween:Play()

	-- If we are hiding, wait for the tween to finish before setting Visible to false
	if isVisible then
		-- This line yields (pauses the function) until the tween completes.
		-- We only want this yield when we are *hiding* the GUI.
		tween.Completed:Wait() 
		MainFrame.Visible = false
	end

	isVisible = not isVisible
end

-- Set the initial visibility (so the GUI is visible when the game starts)
MainFrame.Visible = true 

-- Event listener for the 'End' keypress
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	-- Check for the 'End' key and ensure the input wasn't processed by a TextBox/Chat
	if input.KeyCode == Enum.KeyCode.End and not gameProcessedEvent then
		toggleGuiVisibility()
	end
end)

print("Press the 'End' key to toggle visibility.")
