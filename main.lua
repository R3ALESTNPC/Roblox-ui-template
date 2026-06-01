-- =============================================================================
-- PROGRESSION CONTROL PANEL (Change these numbers as you get richer!)
-- =============================================================================
local Config = {
    AutoRoll = false,
    AutoBuy = false, 
    AutoSell = false,
    AutoShoot = false,
    AutoFertilize = false,
    
    TargetSeedSlot = 6,          -- Set 1 to 6 depending on what slot you can afford!
    TargetSprayName = "Acid Spray" -- Change this text to "Rainbow Spray", "Void Spray", etc.
}

-- =============================================================================
-- SERVICES & REMOTE TRACKING
-- =============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
-- USER INTERFACE LAYER
-- =============================================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DevControlPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 230)
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
    button.Size = UDim2.new(1, 0, 0, 40)
    button.Text = labelName .. ": OFF"
    button.BackgroundColor3 = Color3.fromRGB(180, 55, 55)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 15
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

createToggleButton("Force Buy & Roll", "AutoRoll")
createToggleButton("Force Buy Selected Spray", "AutoBuy")
createToggleButton("Auto Sell Crates", "AutoSell")
createToggleButton("Auto Shoot / Sweeper", "AutoShoot")
createToggleButton("Brute-Force Fertilize All", "AutoFertilize")

-- =============================================================================
-- EXECUTOR BACKGROUND LOOPS
-- =============================================================================

-- Loop 1: Direct Seed Purchase & Roll Engine
task.spawn(function()
    while true do
        task.wait(0.4)
        if Config.AutoRoll and buySeedRemote and rollRemote then
            pcall(function()
                buySeedRemote:FireServer(unpack({[1] = Config.TargetSeedSlot}))
            end)
            task.wait(0.1)
            pcall(function()
                rollRemote:FireServer()
            end)
        end
    end
end)

-- Loop 2: Direct Shop Purchase Engine
task.spawn(function()
    while true do
        task.wait(2.0) -- Paced shop transaction speed
        if Config.AutoBuy and gearTransaction then
            pcall(function()
                gearTransaction:InvokeServer(unpack({[1] = Config.TargetSprayName}))
            end)
        end
    end
end)

-- Loop 3: Auto Crate Liquidator
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

-- Loop 4: Character-Centered Area Sweeper (Auto Shoot)
task.spawn(function()
    while true do
        task.wait(0.1) -- Rapid fire execution rate
        if Config.AutoShoot and shootRemote then
            -- Safely secure character location coordinates
            local character = localPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")
            
            if rootPart then
                -- Dynamically builds 3D coordinates relative to your character's real-time position
                local playerPos = rootPart.Position
                local forwardVector = rootPart.CFrame.LookVector
                
                local blastArgs = {
                    [1] = playerPos + (forwardVector * 10), -- Focuses fire 10 units forward
                    [2] = forwardVector,
                    [3] = playerPos
                }
                
                if equipToolRemote then
                    pcall(function() equipToolRemote:FireServer() end)
                end
                
                pcall(function()
                    shootRemote:FireServer(unpack(blastArgs))
                end)
            end
        end
    end
end)

-- Loop 5: Brute-Force Carpet Fertilizer Engine
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.AutoFertilize and useFertilizerRemote then
            local mapFolder = workspace:FindFirstChild("Map")
            local plotsFolder = mapFolder and mapFolder:FindFirstChild("Plots")
            
            if plotsFolder then
                -- Blank scan over every single structural plot folder on the map layout
                for _, plotParent in ipairs(plotsFolder:GetChildren()) do
                    local farmPlot = plotParent:FindFirstChild("FarmPlot")
                    if farmPlot then
                        for _, individualPlot in ipairs(farmPlot:GetChildren()) do
                            local dirtNode = individualPlot:FindFirstChild("Dirt")
                            if dirtNode then
                                -- Bypasses item scanning entirely and targets the dirt coordinate node directly
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
