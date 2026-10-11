# Rule Engine

A declarative evaluate-and-reward engine for Luau game logic.

You describe a rule as **context + conditions + rewards**. The engine checks that the rule is running in the right place (server, client, or both), evaluates every condition, and applies the rewards if they all pass. If a later reward fails, it rolls back the rewards that already applied.

This system was built a while ago. This repository packages the engine together with a small Roblox place so it can be run and tested.

**Documentation:** [`docs/`](docs/README.md)

## Where the engine lives

| Path | What it is |
| --- | --- |
| [`src/shared/Modules/RuleEngine`](src/shared/Modules/RuleEngine) | Engine entry point, helpers, reward cases, and specs |
| [`src/shared/Modules/Math/ConditionCases`](src/shared/Modules/Math/ConditionCases) | Condition comparators |
| [`src/shared/Modules/Types/Types.luau`](src/shared/Modules/Types/Types.luau) | Shared types |
| [`src/shared/Modules/Data/Rewards`](src/shared/Modules/Data/Rewards) | Sample rewards used by the test place |

Everything else in this repo is environment setup (services, UI, Rojo/Wally config).

## Quick start

```lua
local RuleEngine = require(Modules.RuleEngine)
local ENUMS = require(Modules.Data.ENUMS)
local BALANCES = require(Modules.Data.BALANCES)
local PATHS = require(Modules.Data.PATHS)

local conditionsPassed, rewardsApplied, rollbackApplied, err = RuleEngine.excuteRule(player, {
    context = ENUMS.ContextTypes.Server,
    conditions = {
        {
            name = "Check Balance",
            value1 = { param = BALANCES.points },
            value2 = 10,
            opType = ENUMS.ConditionOpTypes.GreaterThanOrEqual,
            onFalse = "Not Enough points!",
        },
    },
    rewards = {
        {
            name = "Charge points",
            opType = ENUMS.RewardOpTypes.Decrement,
            value = 10,
            path = PATHS.signals.cacheService.server.updatePlayerData,
            params = { PATHS.userCache.points },
        },
    },
})
```

The public entry is spelled `excuteRule`. Full API, rule shapes, reward cases, rollback, and extension notes are in [`docs/`](docs/README.md).

In the test place, touching a colored part runs `excuteRule` against one of the sample rewards.

## Running the test place

This is a Rojo + Wally project.

```bash
wally install
rojo serve
```

Then connect Roblox Studio to the Rojo server (or build `build.rbxlx` and open it). The place boots Data / Cache / Tool / Test / Reward services and spawns the sample reward parts.

The server runs the spec suite on boot. Watch the output for `PASS` / `FAIL` lines and a `{passed}/{total} passed` summary. See [`docs/Testing.md`](docs/Testing.md).
