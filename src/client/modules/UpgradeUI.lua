local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpgradeConfig     = require(ReplicatedStorage.Shared.UpgradeConfig)

local UpgradeUI = {}

-- Track current state
local currentCoins   = 0
local currentUpgrades: {[string]: number} = {}

local upgradeOrder = {"CarryCapacity", "WalkSpeed", "NetRange", "FarmCapacity", "IncomeMultiplier"}
local upgradeButtons: {[string]: TextButton} = {}

local function updateButtonStates()
    for upgradeType, btn in pairs(upgradeButtons) do
        local config      = UpgradeConfig[upgradeType]
        local currentTier = currentUpgrades[upgradeType] or 0
        local nextTier    = currentTier + 1

        if nextTier > #config.tiers then
            btn.Text = config.name .. "\nMAX"
            btn.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
            btn.Active = false
        else
            local cost = config.tiers[nextTier].cost
            local val  = config.tiers[nextTier].value
            btn.Text   = config.name .. "\n" .. val .. " — 🪙" .. cost
            local canAfford = currentCoins >= cost
            btn.BackgroundColor3 = canAfford
                and Color3.fromRGB(40, 100, 160)
                or  Color3.fromRGB(60, 60, 80)
            btn.Active = canAfford
        end
    end
end

function UpgradeUI.init(remotes)
    local player    = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Open button (bottom-right)
    local openGui = Instance.new("ScreenGui")
    openGui.Name          = "UpgradeOpenBtn"
    openGui.ResetOnSpawn  = false
    openGui.Parent        = playerGui

    local openBtn = Instance.new("TextButton")
    openBtn.Name             = "Open"
    openBtn.Size             = UDim2.new(0, 120, 0, 44)
    openBtn.Position         = UDim2.new(1, -132, 1, -56)
    openBtn.BackgroundColor3 = Color3.fromRGB(245, 193, 74)
    openBtn.Font             = Enum.Font.GothamBold
    openBtn.TextSize         = 15
    openBtn.TextColor3       = Color3.fromRGB(20, 30, 40)
    openBtn.Text             = "⬆ Upgrades"
    openBtn.BorderSizePixel  = 0
    openBtn.Parent           = openGui

    local openCorner = Instance.new("UICorner")
    openCorner.CornerRadius = UDim.new(0, 8)
    openCorner.Parent = openBtn

    -- Upgrade menu panel
    local menuGui = Instance.new("ScreenGui")
    menuGui.Name         = "UpgradeMenu"
    menuGui.ResetOnSpawn = false
    menuGui.Enabled      = false
    menuGui.Parent       = playerGui

    local panel = Instance.new("Frame")
    panel.Name             = "Panel"
    panel.Size             = UDim2.new(0, 320, 0, 400)
    panel.Position         = UDim2.new(0.5, -160, 0.5, -200)
    panel.BackgroundColor3 = Color3.fromRGB(15, 25, 35)
    panel.BorderSizePixel  = 0
    panel.Parent           = menuGui

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = panel

    local title = Instance.new("TextLabel")
    title.Name            = "Title"
    title.Size            = UDim2.new(1, -16, 0, 40)
    title.Position        = UDim2.new(0, 8, 0, 8)
    title.BackgroundTransparency = 1
    title.Font            = Enum.Font.GothamBold
    title.TextSize        = 18
    title.TextColor3      = Color3.fromRGB(245, 193, 74)
    title.Text            = "Upgrades"
    title.Parent          = panel

    local closeBtn = Instance.new("TextButton")
    closeBtn.Name            = "Close"
    closeBtn.Size            = UDim2.new(0, 32, 0, 32)
    closeBtn.Position        = UDim2.new(1, -40, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.Font            = Enum.Font.GothamBold
    closeBtn.TextSize        = 16
    closeBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
    closeBtn.Text            = "✕"
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent          = panel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    -- Scroll frame for upgrade buttons
    local scroll = Instance.new("ScrollingFrame")
    scroll.Name                = "Scroll"
    scroll.Size                = UDim2.new(1, -16, 1, -58)
    scroll.Position            = UDim2.new(0, 8, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel     = 0
    scroll.ScrollBarThickness  = 4
    scroll.CanvasSize          = UDim2.new(0, 0, 0, #upgradeOrder * 72)
    scroll.Parent              = panel

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding   = UDim.new(0, 8)
    listLayout.Parent    = scroll

    -- Create a button per upgrade type
    for _, upgradeType in ipairs(upgradeOrder) do
        local config = UpgradeConfig[upgradeType]

        local btn = Instance.new("TextButton")
        btn.Name             = upgradeType
        btn.Size             = UDim2.new(1, 0, 0, 60)
        btn.BackgroundColor3 = Color3.fromRGB(40, 100, 160)
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 13
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
        btn.TextWrapped      = true
        btn.Text             = config.name
        btn.BorderSizePixel  = 0
        btn.Parent           = scroll

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        upgradeButtons[upgradeType] = btn

        btn.MouseButton1Click:Connect(function()
            local ok, result = remotes.PurchaseUpgrade:InvokeServer(upgradeType)
            if not ok then
                -- Flash red briefly
                btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                task.wait(0.3)
                updateButtonStates()
            end
        end)
    end

    -- Toggle menu
    openBtn.MouseButton1Click:Connect(function()
        menuGui.Enabled = not menuGui.Enabled
        updateButtonStates()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        menuGui.Enabled = false
    end)

    -- Listen for remote updates
    remotes.UpdateCoins.OnClientEvent:Connect(function(data)
        currentCoins = data.coins
        if menuGui.Enabled then updateButtonStates() end
    end)

    remotes.UpdateUpgrades.OnClientEvent:Connect(function(data)
        currentUpgrades = data
        if menuGui.Enabled then updateButtonStates() end
    end)

    print("[UpgradeUI] Initialized")
end

return UpgradeUI
