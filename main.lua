-- [[ PS99 PRO UTILITY - FULLY DEBUGGED ]]
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
if not PlayerGui then return warn("[DEBUG] Failed to find PlayerGui") end

-- ==========================================
-- 1. UI SETUP (Draggable + Minimizable)
-- ==========================================
local screenGui = Instance.new("ScreenGui", PlayerGui)
screenGui.Name = "UtilityInterface_" .. math.random(100, 999)
screenGui.ResetOnSpawn = false

local mainGroup = Instance.new("CanvasGroup", screenGui)
mainGroup.Size = UDim2.new(0, 500, 0, 350)
mainGroup.Position = UDim2.new(0.5, -250, 0.5, -175)
mainGroup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainGroup.Active = true
mainGroup.Draggable = true -- Makes it movable

Instance.new("UICorner", mainGroup).CornerRadius = UDim.new(0, 8)

-- Minimize Button
local MinBtn = Instance.new("TextButton", mainGroup)
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -35, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
MinBtn.Text = "-"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 4)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local newSize = minimized and UDim2.new(0, 500, 0, 40) or UDim2.new(0, 500, 0, 350)
    TweenService:Create(mainGroup, TweenInfo.new(0.3), {Size = newSize}):Play()
end)

local ContentContainer = Instance.new("ScrollingFrame", mainGroup)
ContentContainer.Size = UDim2.new(1, -20, 1, -50)
ContentContainer.Position = UDim2.new(0, 10, 0, 40)
ContentContainer.BackgroundTransparency = 1
local ListLayout = Instance.new("UIListLayout", ContentContainer)
ListLayout.Padding = UDim.new(0, 5)

-- ==========================================
-- 2. FRAMEWORK DETECTION (With Debugging)
-- ==========================================
local GameFramework = nil
local function GetFramework()
    local rs = game:GetService("ReplicatedStorage")
    local library = rs:FindFirstChild("Library") and rs.Library:FindFirstChild("Client")
    if library and library:FindFirstChild("Network") then
        print("[DEBUG] Framework found via ReplicatedStorage")
        return require(library.Network)
    end
    print("[DEBUG] ReplicatedStorage path failed. Trying getgc...")
    for _, value in pairs(getgc(true)) do
        if type(value) == "table" and rawget(value, "Network") and rawget(value, "EverythingLoaded") then
            print("[DEBUG] Framework found via getgc")
            return value
        end
    end
    warn("[DEBUG] FATAL: Could not find PS99 Framework!")
    return nil
end
GameFramework = GetFramework()

-- ==========================================
-- 3. NETWORK QUEUE & FARM LOGIC
-- ==========================================
local NetworkQueue = {}
task.spawn(function()
    while true do
        if #NetworkQueue > 0 and GameFramework then
            local payload = table.remove(NetworkQueue, 1)
            pcall(function()
                GameFramework.Network.Fire(unpack(payload))
            end)
        end
        task.wait(0.05)
    end
end)

local ActiveStates = { AutoFarm = false }

local function ToggleAutoFarm(state)
    ActiveStates.AutoFarm = state
    if not state then return end
    print("[DEBUG] AutoFarm toggled ON")
    
    task.spawn(function()
        while ActiveStates.AutoFarm do
            -- PS99 updated their folders: They use 'Breakables' now instead of 'Coins'
            local things = workspace:FindFirstChild("__THINGS")
            local breakables = things and things:FindFirstChild("Breakables")
            
            if breakables and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                for _, node in ipairs(breakables:GetChildren()) do
                    -- GetRenderBoundsCenter can fail if the model isn't fully loaded
                    local success, pos = pcall(function() return node:GetRenderBoundsCenter() end)
                    if success then
                        local dist = (LocalPlayer.Character.HumanoidRootPart.Position - pos).Magnitude
                        if dist < 100 then
                            table.insert(NetworkQueue, {"Breakables_PlayerInstaBreak", node.Name})
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- ==========================================
-- 4. UI BUTTON GENERATION
-- ==========================================
local function CreateToggle(name, callback)
    local button = Instance.new("TextButton", ContentContainer)
    button.Size = UDim2.new(1, 0, 0, 35)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.Text = name
    button.TextColor3 = Color3.fromRGB(220, 220, 220)
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
    
    local isEnabled = false
    button.MouseButton1Click:Connect(function()
        isEnabled = not isEnabled
        button.BackgroundColor3 = isEnabled and Color3.fromRGB(45, 120, 75) or Color3.fromRGB(30, 30, 30)
        callback(isEnabled)
    end)
end

CreateToggle("Toggle Auto Farm", ToggleAutoFarm)

print("[DEBUG] PS99 Script Fully Loaded and Ready.")
