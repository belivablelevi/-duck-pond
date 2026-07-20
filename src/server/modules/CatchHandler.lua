local ReplicatedStorage = game:GetService("ReplicatedStorage")

local C = require(ReplicatedStorage.Shared.GameConstants)

local CatchHandler = {}

-- inventories[userId] = {ducks: array, capacity: number}
local inventories = {}

local remotes    -- set in init
local playerData -- set in init

-- Returns the effective carry cap for a player, consulting upgrade data.
-- Called internally when capacity needs to be recalculated from raw upgrade data.
local function getCarryCap(userId)
    local data = playerData[userId]
    if not data then return C.STARTING_CARRY_CAP end
    local tierIndex = data.upgrades.CarryCapacity
    if tierIndex == 0 then return C.STARTING_CARRY_CAP end
    -- Lazy-require avoids circular dependency at startup
    local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
    return UpgradeConfig.CarryCapacity.tiers[tierIndex].value
end

-- Returns the effective net range for a player, consulting upgrade data.
local function getNetRange(userId)
    local data = playerData[userId]
    if not data then return C.BASE_NET_RANGE end
    local tierIndex = data.upgrades.NetRange
    if tierIndex == 0 then return C.BASE_NET_RANGE end
    -- Lazy-require avoids circular dependency at startup
    local UpgradeConfig = require(ReplicatedStorage.Shared.UpgradeConfig)
    return UpgradeConfig.NetRange.tiers[tierIndex].value
end

local function wirePrompt(duck)
    local prompt = duck:FindFirstChildOfClass("ProximityPrompt")
    if not prompt then return end

    prompt.Triggered:Connect(function(player)
        local userId = player.UserId
        local inv    = inventories[userId]
        if not inv then return end

        -- (1) Already-caught guard
        if duck:GetAttribute("Caught") then return end

        -- (2) Capacity check — silently fail; client HUD shows cap is full
        if #inv.ducks >= inv.capacity then return end

        -- (3) Range check — 2-stud server-side tolerance
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local range = getNetRange(userId)
        if (hrp.Position - duck.Position).Magnitude > range + 2 then return end

        -- Catch is valid — record duck data before destroying the instance
        local duckData = {
            rarity          = duck:GetAttribute("Rarity"),
            incomePerMinute = duck:GetAttribute("IncomePerMinute"),
        }
        table.insert(inv.ducks, duckData)

        -- Lazy-require: DuckSpawner is loaded by Main.server.lua before CatchHandler,
        -- so requiring it here (not at top-level) avoids a circular require at startup.
        local DuckSpawner = require(script.Parent.DuckSpawner)
        DuckSpawner.removeDuck(duck)

        -- Notify client so the HUD updates immediately
        remotes.UpdateInventory:FireClient(player, {
            ducks    = inv.ducks,
            capacity = inv.capacity,
        })
    end)
end

-- Wire ProximityPrompt.Triggered for all current AND future ducks.
function CatchHandler.init(r, pData)
    remotes    = r
    playerData = pData

    -- Existing ducks (DuckSpawner spawns 8 at startup before this runs)
    for _, duck in ipairs(workspace.Ducks:GetChildren()) do
        wirePrompt(duck)
    end

    -- Future ducks spawned by the ongoing loop
    workspace.Ducks.ChildAdded:Connect(function(child)
        if child:IsA("Part") then
            wirePrompt(child)
        end
    end)

    print("[CatchHandler] Initialized")
end

-- Create the inventory entry for a player joining the game.
function CatchHandler.initPlayer(player)
    inventories[player.UserId] = {
        ducks    = {},
        capacity = C.STARTING_CARRY_CAP,
    }
end

-- Remove the inventory entry when a player leaves.
function CatchHandler.removePlayer(player)
    inventories[player.UserId] = nil
end

-- Called by UpgradeManager after a CarryCapacity purchase.
function CatchHandler.updateCapacity(userId, newCap)
    local inv = inventories[userId]
    if inv then inv.capacity = newCap end
end

-- Returns the player's current inventory (by reference — do not mutate externally).
function CatchHandler.getInventory(player)
    return inventories[player.UserId]
end

-- Empty the player's carried-duck array and return the ducks that were in it.
-- Used by FarmManager on deposit: it receives the ducks, then CatchHandler
-- fires UpdateInventory so the client HUD reflects the cleared state.
function CatchHandler.clearInventory(player)
    local inv = inventories[player.UserId]
    if not inv then return {} end
    local ducks = inv.ducks   -- capture before clearing
    inv.ducks = {}
    remotes.UpdateInventory:FireClient(player, {
        ducks    = inv.ducks, -- sends the now-empty array
        capacity = inv.capacity,
    })
    return ducks              -- caller (FarmManager) processes these
end

return CatchHandler
