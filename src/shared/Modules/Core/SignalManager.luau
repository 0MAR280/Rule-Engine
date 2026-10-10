--!strict
-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Signal = require(Packages.Signal)

-- Modules
local Modules = ReplicatedStorage.Shared.Modules
local Types = require(Modules.Types.Types)

-- Classes
local Classes = ReplicatedStorage.Shared.Classes
local Logger = require(Classes.Logger.Class).new(script.Name)

-- Variables
local signals = {} :: { [string]: Signal }

-- Types
type Signal = Types.Signal
type SignalManager = Types.SignalManager

-- Setting
local SignalManager = {}

-- Functions
--[=[
	Checks if a signal with the given name is already registered.
	@param name string - The name of the signal to check
	@return boolean - True if the signal is registered, false otherwise and error message if any
]=]
function SignalManager.isRegistered(name: string): boolean
	local fn = "isRegistered"

	if typeof(name) ~= "string" then
		local msg = `{fn}: Signal name expected to be "string", got: {type(name)}!`
		Logger:warn(msg, name)
		return false, msg
	end

	return signals[name] ~= nil
end

--[=[
	Disconnects all connections in a signal but does not destroy the signal itself.
	@param name string - The name of the signal to clean
]=]
function SignalManager.cleanSignal(name: string): ()
	if not SignalManager.isRegistered(name) then
		return
	end

	signals[name]:DisconnectAll()
end

--[=[
	Destroys a signal and removes it from the registry.
	@param name string - The name of the signal to destroy
]=]
function SignalManager.destroySignal(name: string): ()
	if not SignalManager.isRegistered(name) then
		return
	end

	signals[name]:Destroy()
	signals[name] = nil
end

--[=[
	Returns the signal associated with the given name, creating it if it doesn't exist.
	@param name string - The name of the signal to retrieve
	@return Signal - The Signal instance associated with the name, or nil if could not make one
]=]
function SignalManager.getSignal(name: string): Signal?
	local fn = "getSignal"

	if typeof(name) ~= "string" then
		local msg = `{fn}: Signal name expected to be "string", got: {type(name)}!`
		Logger:warn(msg, name)
		return
	end
	if not SignalManager.isRegistered(name) then
		signals[name] = Signal.Fast.new()
	end

	return signals[name]
end

--[=[
	Fires the signal associated with the given name, passing any additional arguments to the connected listeners.
	@param name string - The name of the signal to fire
	@param ... any - Additional arguments to pass to the listeners
]=]
function SignalManager.fireSignal(name: string, ...: any): ()
	local signal = SignalManager.getSignal(name)

	if signal then
		signal:Fire(...)
	end
end

--[=[
	Connect a listener function to the signal associated with the given name.
	@param name string - The name of the signal to connect to
	@param listener function - The function to call when the signal is fired
	@return RBXScriptConnection - The connection object, or nil if could not connect
]=]
function SignalManager.connectToSignal(name: string, listener: (...any) -> ()): RBXScriptConnection?
	local fn = "connectToSignal"

	if typeof(name) ~= "string" then
		local msg = `{fn}: Signal name expected to be "string", got: {type(name)}!`
		Logger:warn(msg, name)
		return
	end
	if typeof(listener) ~= "function" then
		local msg = `{fn}: Listener must be a Function!`
		Logger:warn(msg)
		return
	end

	local signal = SignalManager.getSignal(name)

	if signal then
		return signal:Connect(listener)
	end

	return
end

return SignalManager :: SignalManager
