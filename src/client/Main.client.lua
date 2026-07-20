local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for server to create remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 15)
if not remotesFolder then
    error("[Client] Remotes folder not found — server may not have started")
end

local Remotes = {
    UpdateInventory = remotesFolder:WaitForChild("UpdateInventory"),
    UpdateCoins     = remotesFolder:WaitForChild("UpdateCoins"),
    UpdateFarm      = remotesFolder:WaitForChild("UpdateFarm"),
    UpdateUpgrades  = remotesFolder:WaitForChild("UpdateUpgrades"),
    PurchaseUpgrade = remotesFolder:WaitForChild("PurchaseUpgrade"),
}

local HUD        = require(script.Parent.modules.HUD)
local FarmUI     = require(script.Parent.modules.FarmUI)
local UpgradeUI  = require(script.Parent.modules.UpgradeUI)

HUD.init(Remotes)
FarmUI.init(Remotes)
UpgradeUI.init(Remotes)

print("[Client] Initialized")
