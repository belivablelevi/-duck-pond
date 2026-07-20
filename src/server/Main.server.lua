local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create Remotes folder in ReplicatedStorage so the client can find it.
local remotesFolder = Instance.new("Folder")
remotesFolder.Name   = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function makeEvent(name: string)
	local e = Instance.new("RemoteEvent")
	e.Name   = name
	e.Parent = remotesFolder
	return e
end

local function makeFunction(name: string)
	local f = Instance.new("RemoteFunction")
	f.Name   = name
	f.Parent = remotesFolder
	return f
end

local Remotes = {
	UpdateInventory = makeEvent("UpdateInventory"),
	UpdateCoins     = makeEvent("UpdateCoins"),
	UpdateFarm      = makeEvent("UpdateFarm"),
	UpdateUpgrades  = makeEvent("UpdateUpgrades"),
	PurchaseUpgrade = makeFunction("PurchaseUpgrade"),
}

-- Load all server modules (they live under ServerScriptService/Server/modules/).
local MapBuilder     = require(script.Parent.modules.MapBuilder)
local DuckSpawner    = require(script.Parent.modules.DuckSpawner)
local CatchHandler   = require(script.Parent.modules.CatchHandler)
local FarmManager    = require(script.Parent.modules.FarmManager)
local UpgradeManager = require(script.Parent.modules.UpgradeManager)
local DataManager    = require(script.Parent.modules.DataManager)

-- Single source of truth for player data on the server during a session.
-- Passed by reference to every module so all subsystems share the same table.
local playerData: {[number]: any} = {}

-- Build the map first (synchronous — creates Ground, Pond, FarmPlots).
MapBuilder.build()

-- Initialize systems in dependency order.
-- DuckSpawner.init() yields ~2.4 s spawning 8 ducks before returning,
-- which means CatchHandler.init() runs after those ducks already exist in workspace.
DuckSpawner.init()
CatchHandler.init(Remotes, playerData)
FarmManager.init(Remotes, playerData)
UpgradeManager.init(Remotes, playerData)

-- Player lifecycle -------------------------------------------------------

local function onPlayerAdded(player: Player)
	-- Load (or create) persistent data and register it in the shared table.
	local data = DataManager.loadPlayer(player)
	playerData[player.UserId] = data

	-- Claim a farm plot and wire its deposit/collect prompts.
	FarmManager.assignPlot(player)

	-- Restore farm ducks that were saved when the player last left.
	if data.farmDucks and #data.farmDucks > 0 then
		local farm = FarmManager.getFarm(player.UserId)
		if farm then
			farm.farmDucks = data.farmDucks
		end
	end

	-- Create the player's carry inventory with the correct upgraded capacity.
	CatchHandler.initPlayer(player)

	-- Apply any persistent upgrade effects (WalkSpeed, CarryCapacity, NetRange).
	UpgradeManager.applyUpgrades(player)

	-- Send initial state to the client so the HUD shows correct values immediately.
	Remotes.UpdateCoins:FireClient(player, {
		coins            = data.coins,
		uncollectedCoins = 0,
	})

	-- CatchHandler.getInventory already reflects the correct upgraded capacity.
	local inv = CatchHandler.getInventory(player)
	Remotes.UpdateInventory:FireClient(player, {
		ducks    = inv.ducks,
		capacity = inv.capacity,
	})

	Remotes.UpdateUpgrades:FireClient(player, data.upgrades)

	-- Send farm state so FarmUI renders restored ducks immediately on rejoin.
	-- Must fire after assignPlot + farm duck restore so the data is ready.
	FarmManager.fireFarmUpdate(player)
end

local function onPlayerRemoving(player: Player)
	local userId = player.UserId
	local data   = playerData[userId]

	if data then
		-- Persist farm ducks back into data before saving.
		local farm = FarmManager.getFarm(userId)
		if farm then
			data.farmDucks = farm.farmDucks
		end
		DataManager.savePlayer(player, data)
	end

	FarmManager.releasePlot(player)
	CatchHandler.removePlayer(player)
	playerData[userId] = nil
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Handle players already in game when this script runs (Studio play mode).
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

-- Save all remaining players' data on server shutdown.
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = playerData[player.UserId]
		if data then
			local farm = FarmManager.getFarm(player.UserId)
			if farm then data.farmDucks = farm.farmDucks end
			DataManager.savePlayer(player, data)
		end
	end
end)

print("[Main] Server initialized")
