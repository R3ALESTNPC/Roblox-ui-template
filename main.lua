-- =============================================================================
-- CENTRAL CONFIGURATION SYSTEM & PRICE DATA
-- =============================================================================
local Config = {
    AutoRoll = false,
    AutoBuy = false, -- Controls the progressive spray buyer
    AutoSell = false,
    MaxSeedTier = 6  -- Loop starts trying here [1-6] and drops down if unaffordable
}

-- Price spreadsheet for the gear transaction system
local SprayPrices = {
    {Name = "Rainbow Spray",      Price = 1000000000000}, -- $1T
    {Name = "Radioactive Spray",  Price = 10000000000},    -- $10B
    {Name = "Void Spray",         Price = 1000000000},     -- $1B
    {Name = "Autumn Spray",       Price = 1000000000},     -- $1B
    {Name = "Frozen Spray",       Price = 750000000},      -- $750M
    {Name = "Wet Spray",          Price = 10000000},       -- $10M
    {Name = "Acid Spray",         Price = 1000000}         -- $1M
}

-- =============================================================================
-- SERVICES & INITIAL SETUP
-- =============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- Verify the existence of your discovered remotes
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
createToggleButton("Smart Auto-Buy & Roll", "AutoRoll")
createToggleButton("Smart Progressive Shop", "AutoBuy")
createToggleButton("Auto Sell Crates", "AutoSell")

-- =============================================================================
-- LIVE GAME-INTEGRATION BACKGROUND THREADS
-- =============================================================================

-- Thread 1: Dynamic Seed Buyer (Cascades down through tiers until purchase succeeds)
task.spawn(function()
    while true do
        task.wait(0.4) -- Keeps network traffic highly stable
        
        if Config.AutoRoll and buySeedRemote and rollRemote then
            local leaderstats = localPlayer:FindFirstChild("leaderstats")
            local cashField = leaderstats and leaderstats:FindFirstChild("Cash")
            
            if cashField then
                -- Step down from MaxSeedTier down to 1 until you find what you can afford
                for tier = Config.MaxSeedTier, 1, -1 do
                    local initialCash = cashField.Value
                    
                    -- Attempt the server handshake
                    pcall(function()
                        buySeedRemote:FireServer(unpack({[1] = tier}))
                    end)
                    
                    -- Micro pause for the server to process the transaction and reduce cash
                    task.wait(0.05)
                    
                    -- If cash went down, it means the purchase was successful!
                    if cashField.Value < initialCash then
                        rollRemote:FireServer() -- Roll the newly acquired seed
                        break -- Exit the step-down scan early since we successfully bought a seed
                    end
                end
            end
        end
    end
end)

-- Thread 2: Smart Progressive Shop (Only buys sprays you can afford)
task.spawn(function()
    while true do
        task.wait(2.0) -- Checks every 2 seconds to optimize performance
        
        if Config.AutoBuy and gearTransaction then
            local leaderstats = localPlayer:FindFirstChild("leaderstats")
            local cashField = leaderstats and leaderstats:FindFirstChild("Cash")
            
            if cashField then
                local currentCash = cashField.Value
                
                for _, spray in ipairs(SprayPrices) do
                    if currentCash >= spray.Price then
                        local targetItem = { [1] = spray.Name }
                        
                        pcall(function()
                            gearTransaction:InvokeServer(unpack(targetItem))
                        end)
                        
                        break -- Skip cheaper sprays once the best one is acquired
                    end
                end
            end
        end
    end
end)

-- Thread 3: Executes your SellCrates FireServer string
task.spawn(function()
    while true do
        task.wait(1.0)
        if Config.AutoSell and sellRemote then
            sellRemote:Server()
        end
    end
end)
