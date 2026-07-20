local ReplicatedStorage = game:GetService("ReplicatedStorage")

local C = require(ReplicatedStorage.Shared.GameConstants)

local FarmManager = {}

-- playerFarms[userId] = {plot: Part, farmDucks: [{rarity, incomePerMinute}], uncollectedCoins: number}
local playerFarms: {[number]: any} = {}

local remotes
local playerData

-- Returns the effective farm duck cap for a player, consulting upgrade data.
-- Lazy-requires UpgradeConfig to avoid circular dependency at startup.
local function getFarmCap(userId: number): number
    local data = playerData[userId]
    if not data then return 8 end
    local tierIndex = data.upgrades.FarmCapacity
    if tierIndex == 0 then return 8 end
    local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
    return UpgradeConfig.FarmCapacity.tiers[tierIndex].value
end

-- Returns the effective income multiplier for a player, consulting upgrade data.
-- Lazy-requires UpgradeConfig to avoid circular dependency at startup.
local function getIncomeMultiplier(userId: number): number
    local data = playerData[userId]
    if not data then return 1 end
    local tierIndex = data.upgrades.IncomeMultiplier
    if tierIndex == 0 then return 1 end
    local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
    return UpgradeConfig.IncomeMultiplier.tiers[tierIndex].value
end

-- Returns the maximum uncollected-coins buffer for a farm.
-- Cap = sum of base income rates * INCOME_CAP_MULTIPLIER (converted to per-second).
local function getIncomeCap(farm): number
    local totalBase = 0
    for _, duck in ipairs(farm.farmDucks) do
        totalBase += duck.incomePerMinute
    end
    return totalBase * C.INCOME_CAP_MULTIPLIER / 60
end

local function fireFarmUpdate(player: Player, farm)
    remotes.UpdateFarm:FireClient(player, {
        ducks            = farm.farmDucks,
        uncollectedCoins = farm.uncollectedCoins,
        incomeCap        = getIncomeCap(farm),
    })
end

local function fireCoinsUpdate(player: Player, userId: number)
    local data = playerData[userId]
    if data then
        remotes.UpdateCoins:FireClient(player, {
            coins            = data.coins,
            uncollectedCoins = playerFarms[userId] and playerFarms[userId].uncollectedCoins or 0,
        })
    end
end

-- Wire the DepositPrompt on a plot for a specific owning player.
-- Only the plot owner's triggered event is accepted.
-- Returns the RBXScriptConnection so the caller can disconnect it on release.
local function wireDepositPrompt(plot: Part, player: Player): RBXScriptConnection?
    local depositPrompt = plot:FindFirstChild("DepositPrompt")
    if not depositPrompt then return nil end
    depositPrompt.Enabled = false  -- enabled by setDepositEnabled when player carries ducks
    depositPrompt.ObjectText = player.Name .. "'s Farm"

    return depositPrompt.Triggered:Connect(function(triggeringPlayer: Player)
        if triggeringPlayer ~= player then return end

        -- Lazy-require: CatchHandler is loaded before FarmManager by Main.server.lua
        local CatchHandler = require(script.Parent.CatchHandler)
        local carried = CatchHandler.clearInventory(player)
        if #carried == 0 then return end

        local userId = player.UserId
        local farm   = playerFarms[userId]
        if not farm then return end

        local cap = getFarmCap(userId)
        for _, duck in ipairs(carried) do
            if #farm.farmDucks >= cap then break end
            table.insert(farm.farmDucks, duck)
        end

        fireFarmUpdate(player, farm)
    end)
end

-- Wire the CollectPrompt on a plot for a specific owning player.
-- Transfers floored uncollected coins into playerData.coins.
-- Returns the RBXScriptConnection so the caller can disconnect it on release.
local function wireCollectPrompt(plot: Part, player: Player): RBXScriptConnection?
    local collectPrompt = plot:FindFirstChild("CollectPrompt")
    if not collectPrompt then return nil end
    collectPrompt.Enabled = false  -- enabled by income tick once coins accrue

    return collectPrompt.Triggered:Connect(function(triggeringPlayer: Player)
        if triggeringPlayer ~= player then return end

        local userId = player.UserId
        local farm   = playerFarms[userId]
        local data   = playerData[userId]
        if not farm or not data then return end

        local collected = math.floor(farm.uncollectedCoins)
        if collected <= 0 then return end

        data.coins            += collected
        farm.uncollectedCoins  = farm.uncollectedCoins - collected
        collectPrompt.Enabled  = farm.uncollectedCoins >= 1
        fireCoinsUpdate(player, userId)
        fireFarmUpdate(player, farm)
    end)
end

-- Initialise FarmManager: store remotes + playerData references and start the income tick loop.
-- Prompt wiring happens in assignPlot, not here.
function FarmManager.init(r, pData)
    remotes    = r
    playerData = pData

    -- Passive income tick loop
    task.spawn(function()
        while true do
            task.wait(C.INCOME_TICK_INTERVAL)
            for userId, farm in pairs(playerFarms) do
                if #farm.farmDucks == 0 then continue end

                local data = playerData[userId]
                if not data then continue end

                local player = game:GetService("Players"):GetPlayerByUserId(userId)
                if not player then continue end

                local multiplier = getIncomeMultiplier(userId)
                local cap        = getIncomeCap(farm)
                local tickEarned = 0

                for _, duck in ipairs(farm.farmDucks) do
                    tickEarned += (duck.incomePerMinute / 60) * multiplier
                end

                farm.uncollectedCoins = math.min(farm.uncollectedCoins + tickEarned, cap)
                remotes.UpdateCoins:FireClient(player, {
                    coins            = data.coins,
                    uncollectedCoins = farm.uncollectedCoins,
                })

                -- Show collect prompt as soon as at least 1 coin has accrued
                local collectPrompt = farm.plot:FindFirstChild("CollectPrompt")
                if collectPrompt and not collectPrompt.Enabled and farm.uncollectedCoins >= 1 then
                    collectPrompt.Enabled = true
                end
            end
        end
    end)

    print("[FarmManager] Initialized")
end

-- Assign the first available farm plot (Owner.Value == "") to a player.
-- Creates the playerFarms entry and wires deposit/collect prompts.
function FarmManager.assignPlot(player: Player)
    local plotsFolder = workspace:WaitForChild("FarmPlots", 10)
    if not plotsFolder then
        warn("[FarmManager] FarmPlots folder not found for " .. player.Name)
        return
    end

    for _, plot in ipairs(plotsFolder:GetChildren()) do
        if plot:IsA("Part") and plot.Owner.Value == "" then
            plot.Owner.Value = tostring(player.UserId)

            playerFarms[player.UserId] = {
                plot             = plot,
                farmDucks        = {},
                uncollectedCoins = 0,
            }

            -- Store connections so releasePlot can disconnect them and
            -- prevent stale handler accumulation on repeated plot assignments.
            playerFarms[player.UserId].depositConn = wireDepositPrompt(plot, player)
            playerFarms[player.UserId].collectConn = wireCollectPrompt(plot, player)

            -- Floating label so the player can spot their plot from a distance
            local billboard = Instance.new("BillboardGui")
            billboard.Name            = "PlotLabel"
            billboard.Size            = UDim2.new(0, 160, 0, 40)
            billboard.StudsOffset     = Vector3.new(0, 4, 0)
            billboard.AlwaysOnTop     = false
            billboard.Parent          = plot

            local label = Instance.new("TextLabel")
            label.Size                = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.Font                = Enum.Font.GothamBold
            label.TextSize            = 16
            label.TextColor3          = Color3.fromRGB(245, 193, 74)
            label.TextStrokeTransparency = 0
            label.Text                = "🏠 " .. player.Name .. "'s Farm"
            label.Parent              = billboard
            playerFarms[player.UserId].billboard = billboard

            print("[FarmManager] Assigned plot " .. plot.Name .. " to " .. player.Name)
            return
        end
    end
    warn("[FarmManager] No free plots available for " .. player.Name)
end

-- Release a player's plot on leave: clear Owner, disable prompts,
-- disconnect stored handlers to prevent stale closure accumulation, remove farm entry.
function FarmManager.releasePlot(player: Player)
    local farm = playerFarms[player.UserId]
    if not farm then return end

    -- Disconnect prompt listeners and remove plot label before clearing the entry.
    if farm.depositConn then farm.depositConn:Disconnect() end
    if farm.collectConn then farm.collectConn:Disconnect() end
    if farm.billboard then farm.billboard:Destroy() end

    farm.plot.Owner.Value = ""
    local depositPrompt = farm.plot:FindFirstChild("DepositPrompt")
    local collectPrompt = farm.plot:FindFirstChild("CollectPrompt")
    if depositPrompt then depositPrompt.Enabled = false end
    if collectPrompt then collectPrompt.Enabled = false end

    playerFarms[player.UserId] = nil
    print("[FarmManager] Released plot for " .. player.Name)
end

-- Called by CatchHandler to show/hide the deposit prompt based on inventory state.
function FarmManager.setDepositEnabled(userId: number, enabled: boolean)
    local farm = playerFarms[userId]
    if not farm then return end
    local prompt = farm.plot:FindFirstChild("DepositPrompt")
    if prompt then prompt.Enabled = enabled end
end

-- Returns the farm entry for a given userId (used by Main.server.lua and UpgradeManager).
function FarmManager.getFarm(userId: number)
    return playerFarms[userId]
end

-- Fires UpdateFarm to the player using the current farm state.
-- Used by Main.server.lua on player join to sync restored farm ducks to the client.
function FarmManager.fireFarmUpdate(player: Player)
    local farm = playerFarms[player.UserId]
    if farm then
        fireFarmUpdate(player, farm)
    end
end

return FarmManager
