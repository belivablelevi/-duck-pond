local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HUD = {}

function HUD.init(remotes)
    local player     = Players.LocalPlayer
    local playerGui  = player:WaitForChild("PlayerGui")

    -- ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name            = "HUD"
    gui.ResetOnSpawn    = false
    gui.IgnoreGuiInset  = true
    gui.Parent          = playerGui

    -- Top-left panel (coins + uncollected)
    local topLeft = Instance.new("Frame")
    topLeft.Name            = "TopLeft"
    topLeft.Size            = UDim2.new(0, 200, 0, 80)
    topLeft.Position        = UDim2.new(0, 12, 0, 12)
    topLeft.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
    topLeft.BackgroundTransparency = 0.3
    topLeft.BorderSizePixel = 0
    topLeft.Parent          = gui

    local corner1 = Instance.new("UICorner")
    corner1.CornerRadius = UDim.new(0, 8)
    corner1.Parent = topLeft

    local coinsLabel = Instance.new("TextLabel")
    coinsLabel.Name            = "CoinsLabel"
    coinsLabel.Size            = UDim2.new(1, -16, 0.5, 0)
    coinsLabel.Position        = UDim2.new(0, 8, 0, 4)
    coinsLabel.BackgroundTransparency = 1
    coinsLabel.Font            = Enum.Font.GothamBold
    coinsLabel.TextSize        = 18
    coinsLabel.TextColor3      = Color3.fromRGB(245, 193, 74)
    coinsLabel.TextXAlignment  = Enum.TextXAlignment.Left
    coinsLabel.Text            = "🪙 0"
    coinsLabel.Parent          = topLeft

    local uncollectedLabel = Instance.new("TextLabel")
    uncollectedLabel.Name            = "UncollectedLabel"
    uncollectedLabel.Size            = UDim2.new(1, -16, 0.5, 0)
    uncollectedLabel.Position        = UDim2.new(0, 8, 0.5, 0)
    uncollectedLabel.BackgroundTransparency = 1
    uncollectedLabel.Font            = Enum.Font.Gotham
    uncollectedLabel.TextSize        = 13
    uncollectedLabel.TextColor3      = Color3.fromRGB(160, 200, 160)
    uncollectedLabel.TextXAlignment  = Enum.TextXAlignment.Left
    uncollectedLabel.Text            = "+0 uncollected"
    uncollectedLabel.Parent          = topLeft

    -- Bottom-left carry capacity display
    local carryFrame = Instance.new("Frame")
    carryFrame.Name             = "CarryFrame"
    carryFrame.Size             = UDim2.new(0, 200, 0, 50)
    carryFrame.Position         = UDim2.new(0, 12, 1, -62)
    carryFrame.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
    carryFrame.BackgroundTransparency = 0.3
    carryFrame.BorderSizePixel  = 0
    carryFrame.Parent           = gui

    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 8)
    corner2.Parent = carryFrame

    local carryLabel = Instance.new("TextLabel")
    carryLabel.Name            = "CarryLabel"
    carryLabel.Size            = UDim2.new(1, -16, 1, 0)
    carryLabel.Position        = UDim2.new(0, 8, 0, 0)
    carryLabel.BackgroundTransparency = 1
    carryLabel.Font            = Enum.Font.GothamBold
    carryLabel.TextSize        = 16
    carryLabel.TextColor3      = Color3.fromRGB(255, 255, 255)
    carryLabel.TextXAlignment  = Enum.TextXAlignment.Left
    carryLabel.Text            = "🥅 0 / 1"
    carryLabel.Parent          = carryFrame

    -- Remote listeners
    remotes.UpdateCoins.OnClientEvent:Connect(function(data)
        coinsLabel.Text      = "🪙 " .. math.floor(data.coins)
        uncollectedLabel.Text = "+" .. math.floor(data.uncollectedCoins) .. " uncollected"
    end)

    remotes.UpdateInventory.OnClientEvent:Connect(function(data)
        carryLabel.Text = "🥅 " .. #data.ducks .. " / " .. data.capacity
    end)

    print("[HUD] Initialized")
end

return HUD
