local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckConfig        = require(ReplicatedStorage.Shared.DuckConfig)

local FarmUI = {}

local rarityColors: {[string]: Color3} = {}
for _, r in ipairs(DuckConfig.Rarities) do
    rarityColors[r.name] = r.color
end

local function refreshFarmVisuals(plot: Part, farmDucks: {{rarity: string, incomePerMinute: number}})
    local slots = plot:FindFirstChild("Slots")
    if not slots then return end

    -- Clear old duck models
    for _, child in ipairs(slots:GetChildren()) do
        child:Destroy()
    end

    -- Place a small colored block per duck in a grid on the plot
    local cols      = 5
    local spacing   = 2.2
    local startX    = -(math.min(#farmDucks, cols) - 1) * spacing / 2
    local startZ    = -math.floor((#farmDucks - 1) / cols) * spacing / 2

    for i, duck in ipairs(farmDucks) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)

        local model = Instance.new("Part")
        model.Name       = "FarmDuck_" .. i
        model.Size       = Vector3.new(1.5, 1, 1.5)
        model.Color      = rarityColors[duck.rarity] or Color3.fromRGB(200, 200, 200)
        model.Material   = Enum.Material.SmoothPlastic
        model.Anchored   = true
        model.CanCollide = false
        model.CFrame     = plot.CFrame
                           * CFrame.new(startX + col * spacing, 0.75, startZ + row * spacing)
        model.Parent     = slots
    end
end

function FarmUI.init(remotes)
    local player    = Players.LocalPlayer
    local plotsFolder = workspace:WaitForChild("FarmPlots", 15)

    -- Find this player's plot
    local myPlot: Part? = nil

    local function findMyPlot()
        for _, plot in ipairs(plotsFolder:GetChildren()) do
            if plot:IsA("Part") and plot.Owner.Value == tostring(player.UserId) then
                myPlot = plot
                return
            end
        end
    end

    -- Poll until plot is assigned (server assigns shortly after join)
    task.spawn(function()
        for _ = 1, 20 do
            findMyPlot()
            if myPlot then break end
            task.wait(0.5)
        end
        if not myPlot then
            warn("[FarmUI] Could not find plot for player")
        end
    end)

    remotes.UpdateFarm.OnClientEvent:Connect(function(data)
        if not myPlot then findMyPlot() end
        if myPlot then
            refreshFarmVisuals(myPlot, data.ducks)
        end
    end)

    print("[FarmUI] Initialized")
end

return FarmUI
