-- // Services // --

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- // Variables // --

--> Libraries

local Promise = require(script.Parent.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Parent.Signal)
local ClientRemoteProperty = require(script.Parent.ClientRemoteProperty)
local Types = require(script.Parent.Parent.Types)
local DiffUtils = require(script.Parent.Parent.DiffUtils)

--> General

local ClientRemoteTable = {}
ClientRemoteTable.__index = ClientRemoteTable
setmetatable(ClientRemoteTable, ClientRemoteProperty)

-- // Functions // --

function ClientRemoteTable.new(re, inboundMiddleware, outboudMiddleware)
	
	local self = ClientRemoteProperty.new(re, inboundMiddleware, outboudMiddleware)
	setmetatable(self, ClientRemoteTable)

	self._readyPromise:cancel()

	local resolveOnReadyPromise

	self._readyPromise = Promise.new(function(resolve)
		resolveOnReadyPromise = resolve
	end)

	self._changed:Disconnect()
	self._changed = self._rs:Connect(function(diff)

		local changed = DiffUtils.HasChanges(diff)
		DiffUtils.Apply(self._value or {}, diff)

		if not self._ready then
			self._ready = true
			resolveOnReadyPromise(self._value)
		end

		if changed then
			self.Changed:Fire(self._value)
		end

	end)

	return self

end

-- // Init // --

return ClientRemoteTable