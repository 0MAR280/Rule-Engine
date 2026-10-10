-- Module
local PATHS = {}

PATHS.userData = {
	leaderstats = { `leaderstats` },
	coins = { `leaderstats`, `Coins` },
}

PATHS.userCache = {
	sessionstats = { `SessionStats` },
	points = { `SessionStats`, `Points` },
	playtime = { `SessionStats`, `Playtime` },
}

PATHS.signals = {
	dataService = {
		server = {
			updatePlayerData = { "signals", "DataService", "server", "updatePlayerData" },
			setPlayerData = { "signals", "DataService", "server", "setPlayerData" },
		},
	},

	cacheService = {
		server = {
			updatePlayerData = { "signals", "CacheService", "server", "updatePlayerData" },
			setPlayerData = { "signals", "CacheService", "server", "setPlayerData" },
		},
	},

	toolService = {
		server = {
			giveTool = { "signals", "ToolService", "server", "giveTool" },
		},
	},
}

return PATHS
