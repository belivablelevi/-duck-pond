local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UpgradeConfig     = require(ReplicatedStorage.Shared.UpgradeConfig)

local UpgradeManager = {}
local remotes
local playerData

-- Per-player CharacterAdded connections for WalkSpeed re-apply.
-- Stored so each new purchase replaces (disconnects) the old listener
-- instead of accumulating one per purchase.
local walkSpeedConns: {[number]: RBXScriptConnection} = {}

local function applyWalkSpeed(player: Player, value: number)
	local char = player.Character or player.CharacterAdded:Wait()
	local hum  = char:FindFirstChildOfClass("Humanoid")
	if hum then hum.WalkSpeed = value end
	-- Disconnect the previous respawn listener before making a new one.
	local prev = walkSpeedConns[player.UserId]
	if prev then prev:Disconnect() end
	walkSpeedConns[player.UserId] = player.CharacterAdded:Connect(function(newChar)
		local newHum = newChar:WaitForChild("Humanoid")
		newHum.WalkSpeed = value
	end)
end

local function applyNetRange(player: Player, value: number)
	-- ProximityPrompt.MaxActivationDistance is set to C.MAX_NET_RANGE at duck spawn time,
	-- so the prompt is always reachable at maximum range. The actual per-player range is
	-- enforced server-side by CatchHandler (magnitude > range + 2 guard).
	local CatchHandler = require(script.Parent.CatchHandler)
	CatchHandler.updateNetRange(player.UserId, value)
end

local function applyUpgradeEffect(player: Player, upgradeType: string, value: number)
	local userId = player.UserId
	if upgradeType == "CarryCapacity" then
		local CatchHandler = require(script.Parent.CatchHandler)
		CatchHandler.updateCapacity(userId, value)
	elseif upgradeType == "WalkSpeed" then
		applyWalkSpeed(player, value)
	elseif upgradeType == "NetRange" then
		applyNetRange(player, value)
	end
	-- FarmCapacity and IncomeMultiplier are read dynamically from playerData, no immediate apply needed
end

function UpgradeManager.init(r, pData)
	remotes    = r
	playerData = pData

	remotes.PurchaseUpgrade.OnServerInvoke = function(player: Player, upgradeType: string)
		local userId  = player.UserId
		local data    = playerData[userId]
		if not data then return false, "No data" end

		local config    = UpgradeConfig[upgradeType]
		if not config then return false, "Unknown upgrade" end

		local currentTier = data.upgrades[upgradeType]
		local nextTier    = currentTier + 1
		if nextTier > #config.tiers then return false, "Max tier reached" end

		local cost = config.tiers[nextTier].cost
		if data.coins < cost then return false, "Not enough coins" end

		-- Apply purchase
		data.coins                   -= cost
		data.upgrades[upgradeType]   = nextTier

		local newValue = config.tiers[nextTier].value
		applyUpgradeEffect(player, upgradeType, newValue)

		-- Send updated state to client
		remotes.UpdateCoins:FireClient(player, {
			coins            = data.coins,
			uncollectedCoins = 0,
		})
		remotes.UpdateUpgrades:FireClient(player, data.upgrades)

		return true, newValue
	end

	print("[UpgradeManager] Initialized")
end

function UpgradeManager.applyUpgrades(player: Player)
	local data = playerData[player.UserId]
	if not data then return end

	for upgradeType, tierIndex in pairs(data.upgrades) do
		if tierIndex > 0 then
			local config = UpgradeConfig[upgradeType]
			if config then
				local value = config.tiers[tierIndex].value
				applyUpgradeEffect(player, upgradeType, value)
			end
		end
	end
end

return UpgradeManager
