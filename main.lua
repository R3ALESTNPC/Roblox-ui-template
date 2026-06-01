-- =============================================================================
-- CENTRAL CONFIGURATION SYSTEM
-- =============================================================================
local Config = {
    AutoRoll = false,
    AutoBuy = false,
    AutoSell = false
}

-- =============================================================================
-- SERVICES & INITIAL SETUP
-- =============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Safely verify the existence of all your discovered remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local buySeedRemote = remotesFolder:WaitForChild("BuySeed")
local rollRemote = remotesFolder:WaitForChild("RollSeeds")
local sellRemote = remotesFolder:WaitForChild("SellCrates")
local gearTransaction = remotesFolder:WaitForChild("Gear"):WaitForChild("Transaction")

-- Wipe old interface versions to clear screen real estate
if playerGui:FindFirstChild("DevControlPanel") then
    playerGui.DevControlPanel:Destroy()
end

-- =============================================================================
-- USER INTERFACE LAYER (Visual Build)
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevControlPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 180)
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local uiPadding = Instance.new("UIPadding")
uiPadding.PaddingTop = UDim.new(0, 10)
uiPadding.PaddingBottom = UDim.new(0, 10)
uiPadding.PaddingLeft = UDim.new(0, 10)
uiPadding.PaddingRight = UDim.new(0, 10)
uiPadding.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 6)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Parent = mainFrame

-- Factory function to link buttons directly to configuration keys
local function createToggleButton(labelName, configKey)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 45)
    button.Text = labelName .. ": OFF"
    button.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 16
    button.Parent = mainFrame

    button.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        if Config[configKey] then
            button.Text = labelName .. ": ON"
            button.BackgroundColor3 = Color3.fromRGB(55, 180, 55)
        else
            button.Text = labelName .. ": OFF"
            button.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
        end
    end)
end

-- UI generation calls
createToggleButton("Auto Buy & Roll", "AutoRoll")
createToggleButton("Auto Buy Rainbow Spray", "AutoBuy")
createToggleButton("Auto Sell Crates", "AutoSell")

-- =============================================================================
-- LIVE GAME-INTEGRATION BACKGROUND THREADS
-- =============================================================================

-- Thread 1: Combines BuySeed and RollSeeds into a fluid loop
task.spawn(function()
    while true do
        task.wait(0.4) -- Balanced yield time to allow both actions to register safely
        if Config.AutoRoll then
            -- Step A: Buy the seed using your exact argument layout
            if buySeedRemote then
                local seedArgs = { [1] = 1 }
                buySeedRemote:FireServer(unpack(seedArgs))
            end
            
            -- Small micro-pause to let the server process the seed purchase
            task.wait(0.1)
            
            -- Step B: Roll the seed
            if rollRemote then
                rollRemote:FireServer()
            end
        end
    end
end)

-- Thread 2: Executes your Gear Transaction InvokeServer string
task.spawn(function()
    while true do
        task.wait(1.5) -- Kept slower to avoid triggering anti-spam shop limits
        if Config.AutoBuy and gearTransaction then
            local targetItem = { [1] = "Rainbow Spray" } 
            
            -- Safeguarded remote invoke
            pcall(function()
                gearTransaction:InvokeServer(unpack(targetItem))
            end)
        end
    end
end)

-- Thread 3: Executes your SellCrates FireServer string
task.spawn(function()
    while true do
        task.wait(1.0) -- Automatically unloads crates once every second
        if Config.AutoSell and sellRemote then
            sellRemote:FireServer()
        end
    end
end)
