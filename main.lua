-- Global Config Table to track states
local Config = {
    AutoRoll = false,
    AutoFeed = false
}

-- Services
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- 1. Main UI Container Setup
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeveloperConsole"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 150)
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- UI Layout Helper (automatically stacks buttons vertically)
local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 5)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Parent = mainFrame

--- 2. Button Creation Function (Reusable Code)
local function createToggleButton(name, configKey, positionY)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.Text = name .. ": OFF"
    button.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.Parent = mainFrame

    -- Click Event Interaction
    button.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey] -- Flip the boolean state
        
        if Config[configKey] then
            button.Text = name .. ": ON"
            button.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        else
            button.Text = name .. ": OFF"
            button.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
        end
    end)
end

-- Generate the buttons dynamically
createToggleButton("Auto Roll", "AutoRoll")
createToggleButton("Auto Feed", "AutoFeed")

--- 3. Independent Background Threads (The Logic Loops)
-- Thread 1: Handles the Roll logic state
task.spawn(function()
    while true do
        task.wait(0.5) -- Throttling delay to prevent thread saturation
        
        if Config.AutoRoll then
            -- System check simulating a gameplay action
            print("[SYSTEM] Config.AutoRoll is active. Validating inventory space...")
            
            -- In an active game development environment, you would place:
            -- ReplicatedStorage.Events.Action:FireServer()
        end
    end
end)

-- Thread 2: Handles the Feed logic state independently
task.spawn(function()
    while true do
        task.wait(1.0) -- Distinct timing interval separate from Thread 1
        
        if Config.AutoFeed then
            print("[SYSTEM] Config.AutoFeed is active. Checking companion entity proximity...")
        end
    end
end)
