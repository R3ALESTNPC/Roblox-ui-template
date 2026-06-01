-- =============================================================================
-- AUTOMATION DASHBOARD CONFIGURATION
-- =============================================================================
local Config = {
    AutoRollAndBuy = false, 
    AutoBuyGears = false,
    AutoSell = false,
    AutoShoot = false,
    AutoFertilize = false,
    AutoCollect = false, 
    
    TargetSprayName = "Acid Spray" -- Controlled via new UI Dropdown
}

-- Complete shop listing for the gear selector dropdown
local SpraySequence = {
    "Acid Spray", "Wet Spray", "Frozen Spray", "Autumn Spray", 
    "Void Spray", "Radioactive Spray", "Rainbow Spray"
}

-- =============================================================================
-- ENGINE INITIALIZATION
-- =============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
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

if playerGui:FindFirstChild("DevControlPanel") then
    playerGui.DevControlPanel:Destroy()
end

-- =============================================================================
-- USER INTERFACE CONSTRUCTION
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevControlPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 290) 
mainFrame.Position = UDim2.new(0.05, 0, 0.2, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
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
    button.Size = UDim2.new(1, 0, 0, 32)
    button.Text = labelName .. ": OFF"
    button.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
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

createToggleButton("Auto Buy All Tiers & Roll", "AutoRollAndBuy")
createToggleButton("Auto Buy Selected Gear", "AutoBuyGears")

-- Gear Shop Dropdown Selector Menu
local shopDropdownToggle = Instance.new("TextButton")
shopDropdownToggle.Size = UDim2.new(1, 0, 0, 32)
shopDropdownToggle.Text = "Shop Target: " .. Config.TargetSprayName
shopDropdownToggle.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
shopDropdownToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopDropdownToggle.Font = Enum.Font.SourceSansBold
shopDropdownToggle.TextSize = 13
shopDropdownToggle.Parent = mainFrame

local shopDropdownMenu = Instance.new("ScrollingFrame")
shopDropdownMenu.Size = UDim2.new(1, 0, 0, 120)
shopDropdownMenu.Position = UDim2.new(0, 0, 1, 2)
shopDropdownMenu.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
shopDropdownMenu.Visible = false
shopDropdownMenu.ZIndex = 10
shopDropdownMenu.CanvasSize = UDim2.new(0, 0, 0, #SpraySequence * 26)
shopDropdownMenu.ScrollBarThickness = 4
shopDropdownMenu.Parent = shopDropdownToggle

local shopDropdownLayout = Instance.new("UIListLayout")
shopDropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopDropdownLayout.Parent = shopDropdownMenu

for _, sprayName in ipairs(SpraySequence) do
    local itemButton = Instance.new("TextButton")
    itemButton.Size = UDim2.new(1, 0, 0, 25)
    itemButton.Text = "  " .. sprayName
    itemButton.TextXAlignment = Enum.TextXAlignment.Left
    itemButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    itemButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    itemButton.Font = Enum.Font.SourceSans
    itemButton.TextSize = 13
    itemButton.ZIndex = 11
    itemButton.Parent = shopDropdownMenu

    itemButton.MouseButton1Click:Connect(function()
        Config.TargetSprayName = sprayName
        shopDropdownToggle.Text = "Shop Target: " .. sprayName
        shopDropdownMenu.Visible = false
    end)
end

shopDropdownToggle.MouseButton1Click:Connect(function()
    shopDropdownMenu.Visible = not shopDropdownMenu.Visible
end)

createToggleButton("Auto Pick Up Drops", "AutoCollect") 
createToggleButton("Auto Shoot / Sweeper", "AutoShoot")
createToggleButton("Smart Carpet Fertilize", "AutoFertilize")
createToggleButton("Auto Sell Crates", "AutoSell")

-- =============================================================================
-- SYSTEM EXECUTION CORE LOOPS
-- =============================================================================

-- Thread 1: Progressive Multi-Tier Seed Buyer Pipeline
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoRollAndBuy and buySeedRemote and rollRemote then
            -- Dynamically loops from tier 1 to tier 6 to ensure your entire inventory builds evenly
            for tier = 1, 6 do
                if not Config.AutoRollAndBuy then break end
                pcall(function()
                    buySeedRemote:FireServer(tier)
                end)
                task.wait(0.1) -- Paced delay between tier purchases
            end
            
            task.wait(0.3) -- Processing window for the server database
            
            pcall(function()
                rollRemote:FireServer()
            end)
        end
    end
end)

-- Thread 2: Laser-Targeted Gear Upgrade Engine
task.spawn(function()
    while true do
        task.wait(3.0) -- High safety latency gap to prevent anti-cheat triggers
        if Config.AutoBuyGears and gearTransaction and Config.TargetSprayName then
            pcall(function()
                gearTransaction:InvokeServer(Config.TargetSprayName)
            end)
        end
    end
end)

-- Thread 3: Force Physical Coin Touch Vacuum
task.spawn(function()
    while true do
        task.wait(0.1) 
        if Config.AutoCollect then
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root then
                for _, object in ipairs(Workspace:GetChildren()) do
                    if object:IsA("Part") or object:IsA("MeshPart") then
                        local nameLower = string.lower(object.Name)
                        if string.find(nameLower, "coin") or string.find(nameLower, "drop") or string.find(nameLower, "heart") then
                            pcall(function()
                                object.CFrame = root.CFrame
                                firetouchinterest(root, object, 0)
                                task.wait()
                                firetouchinterest(root, object, 1)
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Thread 4: Weapon Handling & Progressive Sweeper Line
task.spawn(function()
    while true do
        task.wait(0.15)
        if Config.AutoShoot and shootRemote then
            local character = localPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                local playerPos = rootPart.Position
                local forwardVector = rootPart.CFrame.LookVector
                
                local blastArgs = {
                    [1] = playerPos + (forwardVector * 12), 
                    [2] = forwardVector,
                    [3] = playerPos
                }
                
                if equipToolRemote then
                    pcall(function() equipToolRemote:FireServer() end)
                end
                pcall(function() shootRemote:FireServer(unpack(blastArgs)) end)
            end
        end
    end
end)

-- Thread 5: Sequential Paced Carpet Fertilizer Engine (Stops "Too Fast" errors)
task.spawn(function()
    while true do
        task.wait(1.0) -- Wait between complete field passes
        
        if Config.AutoFertilize and useFertilizerRemote then
            local mapFolder = Workspace:FindFirstChild("Map")
            local plotsFolder = mapFolder and mapFolder:FindFirstChild("Plots")
            
            if plotsFolder then
                for _, plotParent in ipairs(plotsFolder:GetChildren()) do
                    local farmPlot = plotParent:FindFirstChild("FarmPlot")
                    if farmPlot then
                        for _, individualPlot in ipairs(farmPlot:GetChildren()) do
                            -- Emergency stop check mid-loop
                            if not Config.AutoFertilize then break end
                            
                            local dirtNode = individualPlot:FindFirstChild("Dirt")
                            if dirtNode then
                                pcall(function()
                                    useFertilizerRemote:FireServer(dirtNode)
                                end)
                                -- Deliberate micro-pause between plots so they don't hit the server at once
                                task.wait(0.06) 
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Thread 6: Auto Liquidation Crate Processing
task.spawn(function()
    while true do
        task.wait(1.0)
        if Config.AutoSell and sellRemote then
            pcall(function() sellRemote:FireServer() end)
        end
    end
end)
