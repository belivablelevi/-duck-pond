local DataStoreService  = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local C                 = require(ReplicatedStorage.Shared.GameConstants)

local DataManager = {}
local store = DataStoreService:GetDataStore(C.DATASTORE_NAME)

local function defaultData()
    return {
        coins       = 0,
        feathers    = 0,
        ducksCaught = 0,
        upgrades = {
            CarryCapacity    = 0,
            WalkSpeed        = 0,
            NetRange         = 0,
            FarmCapacity     = 0,
            IncomeMultiplier = 0,
        },
        farmDucks = {},
    }
end

function DataManager.loadPlayer(player: Player)
    local key    = "player_" .. player.UserId
    local ok, result = pcall(function()
        return store:GetAsync(key)
    end)

    if ok and result then
        -- Merge saved data with default to handle new fields added in updates
        local default = defaultData()
        for k, v in pairs(result) do
            default[k] = v
        end
        -- Ensure upgrades table has all keys
        for upgradeType in pairs(defaultData().upgrades) do
            if default.upgrades[upgradeType] == nil then
                default.upgrades[upgradeType] = 0
            end
        end
        print("[DataManager] Loaded data for " .. player.Name)
        return default
    else
        if not ok then
            warn("[DataManager] Failed to load data for " .. player.Name .. ": " .. tostring(result))
        end
        print("[DataManager] Creating default data for " .. player.Name)
        return defaultData()
    end
end

function DataManager.savePlayer(player: Player, data)
    local key = "player_" .. player.UserId
    local ok, err = pcall(function()
        store:SetAsync(key, data)
    end)
    if not ok then
        warn("[DataManager] Failed to save data for " .. player.Name .. ": " .. tostring(err))
    else
        print("[DataManager] Saved data for " .. player.Name)
    end
end

return DataManager
