-- Library
local TypeCheckerLib = {}

-- Functions
-- Private

-- Public
-- Getters
--[=[
	Gets the type of the given data.
    @param data: any - The data to get the type of.
    @return string - The type of the data.
]=]
function TypeCheckerLib.getType(data: any): string
	if data == nil then
		return "nil"
	end

	if TypeCheckerLib.isInstance(data) then
		data = data :: Instance
		return data.ClassName
	end

	return typeof(data)
end

-- Checks
--[=[
	Checks if the given data is an Instance.
    @param data: any - The data to check.
    @return boolean - True if the data is an Instance, false otherwise.
]=]
function TypeCheckerLib.isInstance(data: any): boolean
	return typeof(data) == "Instance"
end

--[=[
	Checks if the given data is an Instance of a specific class.
    @param data: any - The data to check.
    @param className: string - The class name to check against.
    @return boolean - True if the data is an Instance of the given class, false otherwise.
]=]
function TypeCheckerLib.isInstanceOf(data: any, className: string): boolean
	return TypeCheckerLib.isInstance(data) and data:IsA(className)
end

--[=[
	Checks if the given instance is a specific class or a subclass.
    @param instance: Instance - The instance to check.
    @param className: string - The class name to check against.
    @return boolean - True if the instance is of the given class or a subclass, false otherwise.
]=]
function TypeCheckerLib.isA(instance: Instance, className: string): boolean
	return TypeCheckerLib.isInstance(instance) and instance:IsA(className)
end

--[=[
	Checks if the given instance is a BasePart or a subclass of it.
    @param instance: Instance - The instance to check.
    @return boolean - True if the instance is a BasePart, false otherwise.
]=]
function TypeCheckerLib.isBasePart(instance: Instance): boolean
	return TypeCheckerLib.isA(instance, "BasePart")
end

--[=[
	Checks if the given instance is a specific type of BasePart.
    @param instance: Instance - The instance to check.
    @param partType: string - The specific BasePart type (e.g., "Part", "WedgePart", "UnionOperation").
    @return boolean - True if the instance matches the part type, false otherwise.
]=]
function TypeCheckerLib.isPartType(instance: Instance, partType: string): boolean
	return TypeCheckerLib.isA(instance, partType)
end

--[=[
	Checks if the given object is an RBXScriptConnection.
    @param connection: RBXScriptConnection - The object to check.
    @return boolean - True if the object is an RBXScriptConnection, false otherwise.
]=]
function TypeCheckerLib.isRBXScriptConnection(connection: any): boolean
	return typeof(connection) == "RBXScriptConnection"
end

--[=[
	Checks if the given object is an Enum.
    @param enum: any - The object to check.
    @return boolean - True if the object is an Enum, false otherwise.
]=]
function TypeCheckerLib.isEnum(enum: any): boolean
	return typeof(enum) == "Enum"
end

--[=[
	Checks if the given object is an EnumItem.
    @param enumItem: any - The object to check.
    @return boolean - True if the object is an EnumItem, false otherwise.
]=]
function TypeCheckerLib.isEnumItem(enumItem: any): boolean
	return typeof(enumItem) == "EnumItem"
end

return TypeCheckerLib
