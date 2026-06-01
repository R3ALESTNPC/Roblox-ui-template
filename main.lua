-- =============================================================================
-- AUTOMATION DASHBOARD CONFIGURATION
-- =============================================================================
local Config = {
    AutoRoll = false,
    AutoBuySeeds = false, 
    AutoBuyGears = false,
    AutoSell = false,
    AutoShoot = false,
    AutoFertilize = false,
    AutoCollect = false, -- Brand new magnetic pickup toggle
    
    TargetSeedSlot = 6,          
    TargetSprayName = "Acid Spray" 
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
mainFrame.Size = UDim2.new(0, 240, 0, 275) -- Adjusted for the new layout button
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
    button.Size = UDim2.new(1, 0, 0, 35)
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

createToggleButton("Auto Buy Seeds Slot", "AutoBuySeeds")
createToggleButton("Auto Roll Active Seeds", "AutoRoll")
createToggleButton("Auto Buy Selected Gear", "AutoBuyGears")
createToggleButton("Auto Pick Up Coins", "AutoCollect") -- New Button Linked!
createToggleButton("Auto Shoot / Sweeper", "AutoShoot")
createToggleButton("Auto Carpet Fertilize", "AutoFertilize")
createToggleButton("Auto Sell Crates", "AutoSell")

-- =============================================================================
-- SYSTEM EXECUTION CORE LOOPS
-- =============================================================================

-- Loop 1: Core Seed Merchant Pipeline
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoBuySeeds and buySeedRemote then
            pcall(function()
                buySeedRemote:FireServer(unpack({[1] = Config.TargetSeedSlot}))
            end)
        end
    end
end)

-- Loop 2: Seed Rolling Standalone Pipeline
task.spawn(function()
    while true do
        task.wait(0.3)
        if Config.AutoRoll and rollRemote then
            pcall(function()
                rollRemote:FireServer()
            end)
        end
    end
end)

-- Loop 3: Gear Upgrade Transaction Pipeline
task.spawn(function()
    while true do
        task.wait(1.5)
        if Config.AutoBuyGears and gearTransaction then
            pcall(function()
                gearTransaction:InvokeServer(unpack({[1] = Config.TargetSprayName}))
            end)
        end
    end
end)

-- Loop 4: Coin Vacuum & Magnetic Collection Engine
task.spawn(function()
    while true do
        task.wait(0.1) -- High-speed pickup scan
        if Config.AutoCollect then
            local char = localPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            
            if root then
                -- Scans game workspace for dropped coins, items, or reward boxes
                for _, object in ipairs(Workspace:GetChildren()) do
                    if object:IsA("Part") or object:IsA("MeshPart") then
                        -- Target models matching coin naming structures or holding coin properties
                        if string.find(string.lower(object.Name), "coin") or string.find(string.lower(object.Name), "drop") then
                            pcall(function()
                                -- Snaps the coin coordinates directly onto your character model
                                object.CFrame = root.CFrame
                            end)
                        end
                    end
                end
            end
        end
    end
end)

-- Loop 5: Weapon Handling & Progressive Sweeper Line
task.spawn(function()
    while true do
        task.wait(0.1)
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

-- Loop 6: Total Carpet Fertilize Map Sweep
task.spawn(function()
    while true do
        task.wait(0.6)
        if Config.AutoFertilize and useFertilizerRemote then
            local mapFolder = Workspace:FindFirstChild("Map")
            local plotsFolder = mapFolder and mapFolder:FindFirstChild("Plots")
            
            if plotsFolder then
                for _, plotParent in ipairs(plotsFolder:GetChildren()) do
                    local farmPlot = plotParent:FindFirstChild("FarmPlot")
                    if farmPlot then
                        for _, individualPlot in ipairs(farmPlot:GetChildren()) do
                            local dirtNode = individualPlot:FindFirstChild("Dirt")
                            if dirtNode then
                                pcall(function()
                                    useFertilizerRemote:FireServer(unpack({[1] = dirtNode}))
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- Loop 7: Auto Liquidation Crate Processing
task.spawn(function()
    while true do
        task.wait(1.0)
        if Config.AutoSell and sellRemote then
            pcall(function() sellRemote:FireServer() end)
        end
    end
end)
