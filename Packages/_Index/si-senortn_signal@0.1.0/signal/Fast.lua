--------------------------------------------------------------------------------
--                           Fast Signal-like class                           --
-- This is a Signal class that is implemented in the most performant way      --
-- possible, sacrificing correctness. The event handlers will be called       --
-- directly, so it is not safe to yield in them, and it is also not safe to   --
-- connect new handlers in the middle of a handler (though it is still safe   --
-- for a handler to specifically disconnect itself)                           --
--------------------------------------------------------------------------------

local Signal = {}
Signal.prototype = {}

local Connection = {}
Connection.prototype = {}

function Connection.new(signal, handler)
	return setmetatable({
		_handler = handler,
		_signal = signal,
	}, { __index = Connection.prototype })
end

function Connection.prototype:Disconnect()
	self._signal[self] = nil
end
Connection.prototype.Destroy = Connection.prototype.Disconnect

function Signal.new()
	return setmetatable({}, { __index = Signal.prototype })
end

function Signal.prototype:Connect(fn)
	local connection = Connection.new(self, fn)
	self[connection] = true
	return connection
end

function Signal.prototype:DisconnectAll()
	table.clear(self)
end
Signal.prototype.Destroy = Signal.prototype.DisconnectAll

function Signal.prototype:Fire(...)
	if next(self) then
		for connection in pairs(self) do
			connection._handler(...)
		end
	end
end

function Signal.prototype:Wait()
	local waitingCoroutine = coroutine.running()
	local cn
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

return Signal
