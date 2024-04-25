-- // Services // --

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Variables // --

--> Libraries

local RemoteProperty = require(script.Parent.RemoteProperty)
local Types = require(script.Parent.Parent.Types)
local Util = require(script.Parent.Parent.Util)
local DiffUtils = require(script.Parent.Parent.DiffUtils)

local None = Util.None

--> General

local RemoteTable = {}
RemoteTable.__index = RemoteTable
setmetatable(RemoteTable, RemoteProperty)

-- // Functions // --

function RemoteTable.new(parent, name, initialValue, inboundMiddleware, outboundMiddleware)

    local self = RemoteProperty.new(parent, name, initialValue, inboundMiddleware, outboundMiddleware)
    setmetatable(self, RemoteTable)

    self._playerReplicated = {}

	self._playerRemoving:Disconnect()
	self._playerRemoving = Players.PlayerRemoving:Connect(function(player)
		self._perPlayer[player] = nil
		self._playerReplicated[player] = nil
	end)

	self._request:Disconnect()
	self._request = self._rs:Connect(function(player)

		local playerValue = self._perPlayer[player]
		local value = if playerValue == nil then self._value elseif playerValue == None then nil else playerValue
		
		local diff = DiffUtils.Get({}, value)

		self._playerReplicated[player] = value
		self._rs:Fire(player, diff)

	end)

    return self

end

function RemoteTable:Set(value: any)
	
	self._value = value
	table.clear(self._perPlayer)

	for _, player in ipairs(Players:GetPlayers()) do
		local diff = DiffUtils.Get(self._playerReplicated[player], value)
		self._playerReplicated[player] = value
		self._rs:Fire(player, diff)
	end

end

function RemoteTable:SetTop(value: any)
	self._value = value
	for _, player in ipairs(Players:GetPlayers()) do
		if self._perPlayer[player] == nil then
			local diff = DiffUtils.Get(self._playerReplicated[player], value)
			self._playerReplicated[player] = value
			self._rs:Fire(player, diff)	
		end
	end
end

function RemoteTable:SetFilter(predicate: (Player, any) -> boolean, value: any)
	for _, player in ipairs(Players:GetPlayers()) do
		if predicate(player, value) then
			self:SetFor(player, value)
		end
	end
end

function RemoteTable:SetFor(player: Player, value: any)

	local diff = DiffUtils.Get(self._playerReplicated[player], value)
	self._playerReplicated[player] = value

	if player.Parent then
		self._perPlayer[player] = if value == nil then None else value
	end

	self._rs:Fire(player, diff)

end

function RemoteTable:SetForList(players: { Player }, value: any)
	for _, player in ipairs(players) do
		self:SetFor(player, value)
	end
end

function RemoteTable:ClearFor(player: Player)

	if self._perPlayer[player] == nil then
		return
	end

	local diff = DiffUtils.Get(self._perPlayer[player], self._value)
	self._playerReplicated[player] = self._value

	self._perPlayer[player] = nil
	self._rs:Fire(player, diff)

end

function RemoteTable:ClearForList(players: { Player })
	for _, player in ipairs(players) do
		self:ClearFor(player)
	end
end

function RemoteTable:ClearFilter(predicate: (Player) -> boolean)
	for _, player in ipairs(Players:GetPlayers()) do
		if predicate(player) then
			self:ClearFor(player)
		end
	end
end

function RemoteTable:Get(): any
	return self._value
end

function RemoteTable:GetFor(player: Player): any
	local playerValue = self._perPlayer[player]
	local value = if playerValue == nil then self._value elseif playerValue == None then nil else playerValue
	return value
end

function RemoteTable:Destroy()
	self._rs:Destroy()
	self._playerRemoving:Disconnect()
end

-- // Init // --

return RemoteTable