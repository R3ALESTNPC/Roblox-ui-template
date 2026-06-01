-- =============================================================================
-- CENTRAL CONFIGURATION SYSTEM & PRICE DATA
-- =============================================================================
local Config = {
    AutoRoll = false,
    AutoBuy = false, 
    AutoSell = false,
    MaxSeedTier = 6  
}

-- Calibrated entry costs based on your crop tiers data
local SeedPrices = {
    [1] = 100,       -- Tier 1: Common Seeds (Carrot base)
    [2] = 600,       -- Tier 2: Uncommon Seeds (Wheat base)
    [3] = 15000,     -- Tier 3: Rare Seeds (Blueberry base)
    [4] = 200000,    -- Tier 4: Epic Seeds (Corn base)
    [5] = 2500000,   -- Tier 5: Legendary Seeds (Spring Onion base)
    [6] = 30000000   -- Tier 6: Secret/Late-game Seeds (Strawberry base)
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

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local buySeedRemote = remotesFolder:WaitForChild("BuySeed")
local rollRemote = remotesFolder:WaitForChild("RollSeeds")
local sellRemote = remotesFolder:WaitForChild("SellCrates")
local gearTransaction = remotesFolder:WaitForChild("Gear"):WaitForChild("Transaction")

if playerGui:FindFirstChild("DevControlPanel") then
    playerGui.DevControlPanel:Destroy()
end

-- =============================================================================
-- USER INTERFACE LAYER
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

createToggleButton("Smart Auto-Buy & Roll", "AutoRoll")
createToggleButton("Smart Progressive Shop", "AutoBuy")
createToggleButton("Auto Sell Crates", "AutoSell")

-- =============================================================================
-- LIVE GAME-INTEGRATION BACKGROUND THREADS
-- =============================================================================

-- Thread 1: Math-Based Seed Buyer (Instantly reads wallet and picks the correct affordable slot)
task.spawn(function()
    while true do
        task.wait(0.4) 
        
        if Config.AutoRoll and buySeedRemote and rollRemote then
            local leaderstats = localPlayer:FindFirstChild("leaderstats")
            local cashField = leaderstats and leaderstats:FindFirstChild("Cash")
            
            if cashField then
                local currentCash = cashField.Value
                local slotToBuy = nil
                
                -- Count downwards from MaxSeedTier to find the highest affordable slot
                for tier = Config.MaxSeedTier, 1, -1 do
                    local price = SeedPrices[tier]
                    if price and currentCash >= price then
                        slotToBuy = tier
                        break -- Found the highest affordable seed tier!
                    end
                end
                
                -- If we found an affordable seed, execute the buy and roll sequence
                if slotToBuy then
                    pcall(function()
                        buySeedRemote:FireServer(unpack({[1] = slotToBuy}))
                    end)
                    
                    task.wait(0.1) -- Small structural lag buffer
                    rollRemote:FireServer()
                end
            end
        end
    end
end)

-- Thread 2: Smart Progressive Shop (Only buys sprays you can afford)
task.spawn(function()
    while true do
        task.wait(2.0) 
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
                        break -- Skip cheaper options once the best spray is bought
                    end
                end
            end
        end
    end
end)

-- Thread 3: Auto Sell Crates
task.spawn(function()
    while true do
        task.wait(1.0)
        if Config.AutoSell and sellRemote then
            sellRemote:FireServer()
        end
    end
end)
