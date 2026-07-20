local TweenService     = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local C          = require(ReplicatedStorage.Shared.GameConstants)
local DuckConfig = require(ReplicatedStorage.Shared.DuckConfig)

local DuckSpawner = {}
local activeDucks: {Part} = {}

-- Folder is created at module load time (top-level, not inside init)
local ducksFolder = Instance.new("Folder")
ducksFolder.Name   = "Ducks"
ducksFolder.Parent = workspace

local function getRandomPondPosition(): Vector3
    local angle  = math.random() * 2 * math.pi
    local radius = math.random() * (C.POND_RADIUS - 3) + 1
    return Vector3.new(
        C.POND_CENTER.X + math.cos(angle) * radius,
        C.POND_CENTER.Y + 1.5,
        C.POND_CENTER.Z + math.sin(angle) * radius
    )
end

local function startWandering(duck: Part)
    task.spawn(function()
        while duck.Parent ~= nil and not duck:GetAttribute("Caught") do
            local targetPos = getRandomPondPosition()
            local distance  = (duck.Position - targetPos).Magnitude
            local duration  = math.max(distance / C.DUCK_WANDER_SPEED, 0.1)

            local tween = TweenService:Create(
                duck,
                TweenInfo.new(duration, Enum.EasingStyle.Linear),
                { Position = targetPos }
            )
            tween:Play()
            tween.Completed:Wait()

            local pause = C.DUCK_WANDER_PAUSE_MIN
                + math.random() * (C.DUCK_WANDER_PAUSE_MAX - C.DUCK_WANDER_PAUSE_MIN)
            task.wait(pause)
        end
    end)
end

local function spawnDuck()
    if #activeDucks >= C.MAX_DUCKS_IN_POND then return end

    local rarityData = DuckConfig:GetRandomRarity()
    local position   = getRandomPondPosition()

    local duck = Instance.new("Part")
    duck.Name       = "Duck"
    duck.Size       = rarityData.size
    duck.Position   = position
    duck.Anchored   = false
    duck.CanCollide = false
    duck.Material   = Enum.Material.SmoothPlastic
    duck.Color      = rarityData.color

    duck:SetAttribute("Rarity",          rarityData.name)
    duck:SetAttribute("IncomePerMinute", rarityData.incomePerMinute)
    duck:SetAttribute("Caught",          false)

    -- ProximityPrompt — server handles Triggered in the CatchHandler task
    local prompt = Instance.new("ProximityPrompt")
    prompt.ObjectText            = rarityData.name .. " Duck"
    prompt.ActionText            = "Catch"
    prompt.MaxActivationDistance = C.BASE_NET_RANGE
    prompt.HoldDuration          = 0
    prompt.Parent                = duck

    duck.Parent = ducksFolder
    table.insert(activeDucks, duck)

    -- Remove from active list when the instance leaves the data model
    duck.AncestryChanged:Connect(function()
        if duck.Parent == nil then
            for i, d in ipairs(activeDucks) do
                if d == duck then
                    table.remove(activeDucks, i)
                    break
                end
            end
        end
    end)

    startWandering(duck)
    return duck
end

function DuckSpawner.init()
    -- Spawn 8 initial ducks, staggered 0.3 s apart
    for _ = 1, 8 do
        spawnDuck()
        task.wait(0.3)
    end

    -- Ongoing spawn loop — adds one duck every DUCK_SPAWN_INTERVAL seconds
    task.spawn(function()
        while true do
            task.wait(C.DUCK_SPAWN_INTERVAL)
            spawnDuck()
        end
    end)

    print("[DuckSpawner] Initialized — 8 ducks spawned, loop active")
end

function DuckSpawner.removeDuck(duck: Part)
    duck:SetAttribute("Caught", true)
    duck:Destroy()
end

return DuckSpawner
