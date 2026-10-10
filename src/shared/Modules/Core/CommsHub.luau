-- Module
local hub = {}

hub.signals = {}
hub.networks = {}

hub.signals.DataService = {
	server = {
		updatePlayerData = "DataService:UpdatePlayerData",
		setPlayerData = "DataService:SetPlayerData",
	},
	client = {},
}

hub.signals.CacheService = {
	server = {
		updatePlayerData = "CacheService:UpdatePlayerData",
		setPlayerData = "CacheService:SetPlayerData",
	},
	client = {},
}

hub.signals.ToolService = {
	server = {
		giveTool = "ToolService:GiveTool",
	},
	client = {},
}

return hub
