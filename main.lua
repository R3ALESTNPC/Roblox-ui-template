-- =============================================================================
-- CENTRAL CONFIGURATION SYSTEM
-- =============================================================================
local Config = {
    AutoRoll = false,
    AutoBuy = false, 
    AutoSell = false,
    AutoShoot = false,
    AutoFertilize = false,
    SelectedCrop = "Carrot", -- Default initialization selection
    MaxSeedTier = 6
}

-- Full crop database mapped for the dropdown selector UI
local AllCrops = {
    "Carrot", "Beetroot", "Pumpkin", "Wheat", "Melon", "Onion", "Cantaloupe", "Watermelon",
    "Blueberry", "Cabbage", "Grape", "Peach", "Bamboo", "Corn", "Plum", "Cauliflower",
    "Nectarine", "Sunflower", "Citrus", "Honeysuckle", "Twinflame Tulip", "Martian Melon",
    "Spring Onion", "Mango", "Mushroom", "Banana", "Amulet Anemone", "Strawberry", "Glowshroom",
    "Beanstalk", "Tomato", "Starfruit", "Apple", "Duoheart Daisy", "Cherry Blossom", "Blood Orange",
    "Pineapple", "Diamond Blossom", "Golden Apple", "Pomegranate", "Horned Melon", "Kiwi",
    "Moonflower", "Passion Fruit", "Pepper", "Heartvine Bloom", "Trucker’s Delight", "Void Fruit",
    "Dragonfruit", "Durian", "Ghost Pepper", "Soulbound Orchid", "Queen Blossom"
}

-- Progressive gear upgrade price database
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
-- SERVICES & REMOTE VERIFICATION
-- =============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local buySeedRemote = remotesFolder:WaitForChild("BuySeed")
local rollRemote = remotesFolder:WaitForChild("RollSeeds")
local sellRemote = remotesFolder:WaitForChild("SellCrates")
local equipToolRemote = remotesFolder:WaitForChild("EquipTool")
local useFertilizerRemote = remotesFolder:WaitForChild("UseFertilizer")
local gearTransaction = remotesFolder:WaitForChild("Gear"):WaitForChild("Transaction")
local shootRemote = remotesFolder:WaitForChild("PlantRush"):WaitForChild("Shoot")

-- Clean up any existing instances of the script panel
if playerGui:FindFirstChild("DevControlPanel") then
    playerGui.DevControlPanel:Destroy()
end

-- =============================================================================
-- USER INTERFACE LAYER (DYNAMIC PANEL WITH DROPDOWN)
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevControlPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 260, 0, 340)
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Rounded corners for clean presentation
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = mainFrame

local containerFrame = Instance.new("Frame")
containerFrame.Size = UDim2.new(1, -20, 1, -20)
containerFrame.Position = UDim2.new(0, 10, 0, 10)
containerFrame.BackgroundTransparency = 1
containerFrame.Parent = mainFrame

local uiListLayout = Instance.new("UIListLayout")
uiListLayout.Padding = UDim.new(0, 6)
uiListLayout.SortOrder = Enum.SortOrder.LayoutOrder
uiListLayout.Parent = containerFrame

-- Helper function to generate standardized panel buttons
local function createToggleButton(labelName, configKey)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 0, 40)
    button.Text = labelName .. ": OFF"
    button.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 15
    button.Parent = containerFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 5)
    btnCorner.Parent = button

    button.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        if Config[configKey] then
            button.Text = labelName .. ": ON"
            button.BackgroundColor3 = Color3.fromRGB(50, 160, 50)
        else
            button.Text = labelName .. ": OFF"
            button.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
        end
    end)
    return button
end

-- Generate Primary Control Interfaces
createToggleButton("Force Buy & Roll", "AutoRoll")
createToggleButton("Smart Progressive Shop", "AutoBuy")
createToggleButton("Auto Sell Crates", "AutoSell")
createToggleButton("Auto Shoot / Kill Aura", "AutoShoot")
createToggleButton("Auto Fertilize Target", "AutoFertilize")

-- Dropdown Menu Container Button
local dropdownToggle = Instance.new("TextButton")
dropdownToggle.Size = UDim2.new(1, 0, 0, 40)
dropdownToggle.Text = "Target: " .. Config.SelectedCrop .. " ⚡"
dropdownToggle.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
dropdownToggle.TextColor3 = Color3.fromRGB(240, 240, 240)
dropdownToggle.Font = Enum.Font.SourceSansBold
dropdownToggle.TextSize = 14
dropdownToggle.Parent = containerFrame

local ddCorner = Instance.new("UICorner")
ddCorner.CornerRadius = UDim.new(0, 5)
ddCorner.Parent = dropdownToggle

-- Scrollable Menu Layer for Crop Profiles
local dropdownMenu = Instance.new("ScrollingFrame")
dropdownMenu.Size = UDim2.new(1, 0, 0, 150)
dropdownMenu.Position = UDim2.new(0, 0, 1, 4)
dropdownMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
dropdownMenu.BorderSizePixel = 1
dropdownMenu.BorderColor3 = Color3.fromRGB(60, 60, 60)
dropdownMenu.Visible = false
dropdownMenu.ZIndex = 5
dropdownMenu.CanvasSize = UDim2.new(0, 0, 0, #AllCrops * 26)
dropdownMenu.ScrollBarThickness = 6
dropdownMenu.Parent = dropdownToggle

local dropdownLayout = Instance.new("UIListLayout")
dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
dropdownLayout.Parent = dropdownMenu

-- Build out items inside the crop selection menu
for i, cropName in ipairs(AllCrops) do
    local itemButton = Instance.new("TextButton")
    itemButton.Size = UDim2.new(1, 0, 0, 25)
    itemButton.Text = "  " .. cropName
    itemButton.TextXAlignment = Enum.TextXAlignment.Left
    itemButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    itemButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    itemButton.Font = Enum.Font.SourceSans
    itemButton.TextSize = 14
    itemButton.ZIndex = 6
    itemButton.Parent = dropdownMenu

    itemButton.MouseButton1Click:Connect(function()
        Config.SelectedCrop = cropName
        dropdownToggle.Text = "Target: " .. cropName .. " ⚡"
        dropdownMenu.Visible = false
    end)
end

dropdownToggle.MouseButton1Click:Connect(function()
    dropdownMenu.Visible = not dropdownMenu.Visible
end)

-- =============================================================================
-- AUTOMATION BACKGROUND PARALLEL THREADS
-- =============================================================================

-- Thread 1: Bypassed Seed Buyer Engine
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoRoll and buySeedRemote and rollRemote then
            pcall(function()
                buySeedRemote:FireServer(unpack({[1] = Config.MaxSeedTier}))
            end)
            task.wait(0.1)
            pcall(function()
                rollRemote:FireServer()
            end)
        end
    end
end)

-- Thread 2: Progressive Shop Automated Purchases
task.spawn(function()
    while true do
        task.wait(2.0)
        if Config.AutoBuy and gearTransaction then
            local stats = localPlayer:FindFirstChild("leaderstats") or localPlayer:FindFirstChild("PlayerGui")
            local cash = stats and (stats:FindFirstChild("Cash") or stats:FindFirstChild("Money"))
            
            if cash then
                local currentWallet = cash.Value
                for _, spray in ipairs(SprayPrices) do
                    if currentWallet >= spray.Price then
                        pcall(function()
                            gearTransaction:InvokeServer(unpack({[1] = spray.Name}))
                        end)
                        break
                    end
                end
            end
        end
    end
end)

-- Thread 3: Auto Crate Liquidation
task.spawn(function()
    while true do
        task.wait(1.0)
        if Config.AutoSell and sellRemote then
            pcall(function()
                sellRemote:FireServer()
            end)
        end
    end
end)

-- Thread 4: Auto Weapon Handling & Kill Aura Loop
task.spawn(function()
    local vectorBundle = {
        [1] = Vector3.new(-122.791259765625, 5.772419452667236, -19.60873794555664),
        [2] = Vector3.new(0.9420660138130188, -0.10266302525997162, 0.31933045387268066),
        [3] = Vector3.new(-47.27248001098633, 9.226510047912598, 4.486339569091797)
    }

    while true do
        task.wait(0.1)
        if Config.AutoShoot then
            if equipToolRemote then
                pcall(function() equipToolRemote:FireServer() end)
            end
            if shootRemote then
                pcall(function() shootRemote:FireServer(unpack(vectorBundle)) end)
            end
        end
    end
end)

-- Thread 5: Workspace Target Scan & Auto Fertilizer Engine
task.spawn(function()
    while true do
        task.wait(0.3) -- Scanning loop speed
        
        if Config.AutoFertilize and useFertilizerRemote then
            local mapFolder = workspace:FindFirstChild("Map")
            local plotsFolder = mapFolder and mapFolder:FindFirstChild("Plots")
            
            if plotsFolder then
                -- Search across all structural plot configurations in the server map
                for _, plotParent in ipairs(plotsFolder:GetChildren()) do
                    local farmPlot = plotParent:FindFirstChild("FarmPlot")
                    if farmPlot then
                        for _, individualPlot in ipairs(farmPlot:GetChildren()) do
                            local dirtNode = individualPlot:FindFirstChild("Dirt")
                            
                            -- Confirm a plant model exists in the dirt node
                            if dirtNode then
                                local activeCropModel = individualPlot:FindFirstChild(Config.SelectedCrop)
                                
                                if activeCropModel then
                                    -- Construct argument profile using discovered workspace path string
                                    local payload = { [1] = dirtNode }
                                    pcall(function()
                                        useFertilizerRemote:FireServer(unpack(payload))
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)
