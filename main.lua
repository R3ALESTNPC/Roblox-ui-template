-- Conceptual layout setup
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Main GUI container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ControlPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Menu Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 100)
mainFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.Parent = screenGui

local isAutoTaskEnabled = false

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(1, 0, 0.5, 0)
toggleButton.Text = "Toggle Task: OFF"
toggleButton.Parent = mainFrame

toggleButton.MouseButton1Click:Connect(function()
    isAutoTaskEnabled = not isAutoTaskEnabled
    if isAutoTaskEnabled then
        toggleButton.Text = "Toggle Task: ON"
        toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        toggleButton.Text = "Toggle Task: OFF"
        toggleButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    end
end)

-- Background loop running independently of the UI thread
task.spawn(function()
    while true do
        task.wait(1) -- Yielding avoids crashing the client environment
        
        if isAutoTaskEnabled then
            -- Fulfill the condition if the toggle is active
            print("Executing standard routine check...")
        end
    end
end)
