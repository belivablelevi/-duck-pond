local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C = require(ReplicatedStorage.Shared.GameConstants)

local MapBuilder = {}

function MapBuilder.build()
    -- Ground plane
    local ground = Instance.new("Part")
    ground.Name        = "Ground"
    ground.Size        = Vector3.new(200, 1, 200)
    ground.CFrame      = CFrame.new(C.POND_CENTER - Vector3.new(0, 0.5, 0))
    ground.Anchored    = true
    ground.Material    = Enum.Material.Grass
    ground.Color       = Color3.fromRGB(106, 127, 63)
    ground.CanCollide  = true
    ground.Parent      = workspace

    -- Circular pond (cylinder rotated on its side = flat disc)
    local pond = Instance.new("Part")
    pond.Name      = "Pond"
    pond.Shape     = Enum.PartType.Cylinder
    pond.Size      = Vector3.new(C.POND_HEIGHT, C.POND_RADIUS * 2, C.POND_RADIUS * 2)
    pond.CFrame    = CFrame.new(C.POND_CENTER + Vector3.new(0, 0.01, 0))
                     * CFrame.Angles(0, 0, math.pi / 2)
    pond.Anchored  = true
    pond.Material  = Enum.Material.Water
    pond.Color     = Color3.fromRGB(0, 162, 255)
    pond.CanCollide = false
    pond.Parent    = workspace

    -- Farm plots evenly distributed around the pond
    local plotsFolder = Instance.new("Folder")
    plotsFolder.Name   = "FarmPlots"
    plotsFolder.Parent = workspace

    for i = 1, C.NUM_PLOTS do
        local angle = (i - 1) / C.NUM_PLOTS * 2 * math.pi
        local x = C.POND_CENTER.X + math.cos(angle) * C.FARM_RADIUS
        local z = C.POND_CENTER.Z + math.sin(angle) * C.FARM_RADIUS

        local plot = Instance.new("Part")
        plot.Name       = "Plot_" .. i
        plot.Size       = Vector3.new(14, 0.5, 14)
        plot.CFrame     = CFrame.new(x, 0.25, z)
        plot.Anchored   = true
        plot.Material   = Enum.Material.Grass
        plot.Color      = Color3.fromRGB(90, 110, 55)
        plot.CanCollide = true
        plot.Parent     = plotsFolder

        -- Owner tag (empty until player claims it)
        local ownerVal = Instance.new("StringValue")
        ownerVal.Name   = "Owner"
        ownerVal.Value  = ""
        ownerVal.Parent = plot

        -- Folder that will hold deposited duck models
        local slots = Instance.new("Folder")
        slots.Name   = "Slots"
        slots.Parent = plot

        -- Deposit prompt (active when player is near own plot)
        local depositPrompt = Instance.new("ProximityPrompt")
        depositPrompt.Name                   = "DepositPrompt"
        depositPrompt.ObjectText             = "Your Farm"
        depositPrompt.ActionText             = "Deposit Ducks"
        depositPrompt.MaxActivationDistance  = C.DEPOSIT_DISTANCE
        depositPrompt.RequiresLineOfSight    = false
        depositPrompt.Enabled                = false
        depositPrompt.Parent                 = plot

        -- Collect income prompt
        local collectPrompt = Instance.new("ProximityPrompt")
        collectPrompt.Name                   = "CollectPrompt"
        collectPrompt.ObjectText             = "Farm Income"
        collectPrompt.ActionText             = "Collect Coins"
        collectPrompt.MaxActivationDistance  = C.COLLECT_DISTANCE
        collectPrompt.RequiresLineOfSight    = false
        collectPrompt.Enabled                = false
        collectPrompt.Parent                 = plot
    end

    print("[MapBuilder] Map built successfully")
end

return MapBuilder
