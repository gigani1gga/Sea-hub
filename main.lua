local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local InterfaceManager = {}
InterfaceManager.__index = InterfaceManager

function InterfaceManager.CreateBase()
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "UtilityInterface"
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false
    
    local mainGroup = Instance.new("CanvasGroup", screenGui)
    mainGroup.Size = UDim2.new(0, 500, 0, 350)
    mainGroup.Position = UDim2.new(0.5, -250, 0.5, -175)
    mainGroup.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    mainGroup.GroupTransparency = 1
    
    local corner = Instance.new("UICorner", mainGroup)
    corner.CornerRadius = UDim.new(0, 8)
    
    TweenService:Create(mainGroup, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {GroupTransparency = 0}):Play()
    
    return mainGroup
end

local GameFramework = nil
for _, value in pairs(getgc(true)) do
    if type(value) == "table" and rawget(value, "Network") and rawget(value, "EverythingLoaded") then
        GameFramework = value
        break
    end
end

local NetworkQueue = {}
task.spawn(function()
    while task.wait(0.1) do
        if #NetworkQueue > 0 and GameFramework then
            local batchSize = math.min(#NetworkQueue, 10)
            for i = 1, batchSize do
                local payload = table.remove(NetworkQueue, 1)
                pcall(function()
                    GameFramework.Network.Fire(unpack(payload))
                end)
            end
        end
    end
end)

local ActiveStates = {
    AutoFarm = false,
    AutoCollect = false
}

local function ToggleAutoFarm(state)
    ActiveStates.AutoFarm = state
    if not state then return end
    
    task.spawn(function()
        while ActiveStates.AutoFarm do
            local character = LocalPlayer.Character
            if character and character.PrimaryPart then
                local thingsFolder = workspace:FindFirstChild("__THINGS")
                local coinsFolder = thingsFolder and thingsFolder:FindFirstChild("Coins")
                
                if coinsFolder then
                    local playerPosition = character.PrimaryPart.Position
                    for _, coin in ipairs(coinsFolder:GetChildren()) do
                        local success, boundsCenter = pcall(function() return coin:GetRenderBoundsCenter() end)
                        if success then
                            local distance = (playerPosition - boundsCenter).Magnitude
                            if distance < 150 then
                                table.insert(NetworkQueue, {"Coin_Collect", coin.Name})
                            end
                            if #NetworkQueue > 50 then break end
                        end
                    end
                end
            end
            task.wait(0.05)
        end
    end)
end

local MainFrame = InterfaceManager.CreateBase()
MainFrame.Active = true
MainFrame.Draggable = true

local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 140, 1, 0)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.BorderSizePixel = 0

local ContentContainer = Instance.new("ScrollingFrame", MainFrame)
ContentContainer.Size = UDim2.new(1, -150, 1, -10)
ContentContainer.Position = UDim2.new(0, 145, 0, 5)
ContentContainer.BackgroundTransparency = 1
ContentContainer.CanvasSize = UDim2.new(0, 0, 2, 0)
ContentContainer.ScrollBarThickness = 2
ContentContainer.BorderSizePixel = 0

local ListLayout = Instance.new("UIListLayout", ContentContainer)
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function CreateToggle(name, callback)
    local button = Instance.new("TextButton", ContentContainer)
    button.Size = UDim2.new(1, -10, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    button.Font = Enum.Font.GothamMedium
    button.TextSize = 13
    button.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", button)
    corner.CornerRadius = UDim.new(0, 6)
    
    local isEnabled = false
    button.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = isEnabled and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(30, 30, 30)
        }):Play()
        callback(isEnabled)
    end)
end

CreateToggle("Auto Farm (Optimized)", ToggleAutoFarm)

CreateToggle("Auto Collect All", function(state) 
    ActiveStates.AutoCollect = state
    task.spawn(function()
        while ActiveStates.AutoCollect do
            if GameFramework then 
                pcall(function() GameFramework.Network.Fire("Orb_CollectAll") end)
            end
            task.wait(0.5)
        end
    end)
end)

CreateToggle("Staff Evasion", function(state)
    if not state then return end
    Players.PlayerAdded:Connect(function(newPlayer)
        pcall(function()
            if newPlayer:GetRankInGroup(229920) > 1 then
                LocalPlayer:Kick("Safety disconnect: Staff member joined the server.")
            end
        end)
    end)
end)
