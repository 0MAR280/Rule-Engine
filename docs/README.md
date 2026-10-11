# Rule Engine docs

The Rule Engine evaluates a rule as **context + conditions + rewards**. If a later reward fails, it applies `rollbackRewards` for the rewards that already succeeded.

The engine lives in [`src/shared/Modules/RuleEngine`](../src/shared/Modules/RuleEngine). Types are in [`src/shared/Modules/Types/Types.luau`](../src/shared/Modules/Types/Types.luau). Enums are in [`src/shared/Modules/Data/ENUMS.luau`](../src/shared/Modules/Data/ENUMS.luau).

## Contents

| Doc | What it covers |
| --- | --- |
| [Engine](Engine.md) | Public API, run order, context, return values, rollback |
| [Rules](Rules.md) | `RuleData`, `Condition`, `Reward`, `Value`, `Param`, and enums |
| [Conditions](Conditions.md) | How conditions are solved, operators, params, callbacks, payload |
| [Rewards](Rewards.md) | Reward operations, signal contract, builders, samples |
| [Architecture](Architecture.md) | Helpers, CommsHub, Data/Cache services, paths |
| [Testing](Testing.md) | Specs, the test place, and how to read results |
| [Extending](Extending.md) | Adding a condition operator or a reward case |

## Quick start

```lua
local RuleEngine = require(Modules.RuleEngine)
local ENUMS = require(Modules.Data.ENUMS)

local conditionsPassed, rewardsApplied, rollbackApplied, err = RuleEngine.excuteRule(player, {
    context = ENUMS.ContextTypes.Server,
    conditions = {
        {
            name = "Has points",
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

The public entry is spelled `excuteRule`.
