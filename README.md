# Rule Engine

A declarative evaluate-and-reward engine for Luau game logic.

A rule is **context + conditions + rewards + rollbackRewards**. The engine checks that it is running in the right place (server, client, or both), evaluates every condition, and applies the rewards if they all pass. If a later reward fails, it applies `rollbackRewards` for the rewards that already succeeded.

This repository packages the engine with a small Roblox place so it can be run and tested.

**Documentation:** [`docs/`](docs/README.md)

## Where the engine lives

| Path                                                                                                             | What it is                                                                                              |
| ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| [`src/shared/Modules/RuleEngine`](src/shared/Modules/RuleEngine)                                                 | Engine entry, helpers, reward cases, and specs                                                          |
| [`src/shared/Modules/Math/ConditionCases`](src/shared/Modules/Math/ConditionCases)                               | Condition comparators                                                                                   |
| [`src/shared/Modules/RuleEngine/Helpers/SolveParam.luau`](src/shared/Modules/RuleEngine/Helpers/SolveParam.luau) | Data/cache adapter. Update this when host services move. See [`docs/SolveParam.md`](docs/SolveParam.md) |
| [`src/shared/Modules/Types/Types.luau`](src/shared/Modules/Types/Types.luau)                                     | Shared types                                                                                            |
| [`src/shared/Modules/Data/Rewards`](src/shared/Modules/Data/Rewards)                                             | Sample rewards used by the test place                                                                   |

Everything else in this repo is environment setup (services, UI, Rojo/Wally config).

## How a rule runs

`RuleEngine.executeRule(player, rule, payload?)` is the public entry (that spelling is intentional).

1. **Context** — `Server`, `Client`, or `Both` must match the current runtime.
2. **Conditions** — solved in order. The first failure returns its `onFalse` message. Rewards are not applied.
3. **Rewards** — applied in order if every condition passed.
4. **Rollback** — if reward `N` fails and `N > 1`, the engine applies `rollbackRewards` entries `1 .. N-1`.

Conditions, rewards, and rollback rewards can be an array of objects, or a function `(Player) -> (boolean, string?)`. Missing fields and empty arrays pass.

## Rule shape

```lua
{
    context: ContextType,
    conditions: { Condition } | ((Player) -> (boolean, string?))?,
    rewards: { Reward } | ((Player) -> (boolean, string?))?,
    rollbackRewards: { Reward } | ((Player) -> (boolean, string?))?,
}
```

`rollbackRewards` is the reverse of `rewards`, aligned by index. When reward 2 fails, rollback entry 1 undoes reward 1. Rollback entry 2 and later are not applied. If the first reward fails, nothing was applied, so rollback is skipped.

If `rollbackRewards` is missing, `applyRollback` still reports success. Define matching entries whenever a partial apply must be undone.

## Public API

| Function                                     | Returns                                                  | Role                        |
| -------------------------------------------- | -------------------------------------------------------- | --------------------------- |
| `executeRule(player, rule, payload?)`        | `conditionsPassed, rewardsApplied, rollbackApplied, err` | Full run                    |
| `checkConditions(player, rule, payload?)`    | `ok, err`                                                | Context and conditions only |
| `applyRewards(player, rule)`                 | `ok, err, failureIndex`                                  | Rewards only                |
| `applyRollback(player, rule, failureIndex?)` | `ok, err, failureIndex`                                  | Rollback only               |

`rollbackApplied` is `true` if rollback ran and succeeded, `false` if it ran and failed, `nil` if it was not needed.

`failureIndex` is the 1-based list entry that failed. On success it is `nil`.

## Errors

Callers get a short `err`. Details stay in the log.

- Condition `onFalse` (and function-condition reasons) are returned as-is (`"Not Enough points!"`).
- Reward and rollback failures from `executeRule` return `"Something went wrong!"`.
- `ApplyReward` returns `"A mal reward format"` or `"A runtime error"` for a bad handler.

## Operators

Condition operators: Equal, NotEqual, GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual.

Reward operators: Increment, Decrement, Set, FireSignal.

Param sources: DataPath, CachePath, Value, Now, EventPayload. DataPath and CachePath are resolved in `SolveParam`; that module must match the host Data/Cache services.

## Example

```lua
local RuleEngine = require(Modules.RuleEngine)
local ENUMS = require(Modules.Data.ENUMS)
local BALANCES = require(Modules.Data.BALANCES)
local PATHS = require(Modules.Data.PATHS)

local dataSignal = PATHS.signals.dataService.server.updatePlayerData
local cacheSignal = PATHS.signals.cacheService.server.updatePlayerData

local conditionsPassed, rewardsApplied, rollbackApplied, err = RuleEngine.executeRule(player, {
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
            name = "Grant coins",
            opType = ENUMS.RewardOpTypes.Increment,
            value = 5,
            path = dataSignal,
            params = { PATHS.userData.coins },
        },
        {
            name = "Charge points",
            opType = ENUMS.RewardOpTypes.Decrement,
            value = 10,
            path = cacheSignal,
            params = { PATHS.userCache.points },
        },
    },
    rollbackRewards = {
        {
            name = "Undo coins",
            opType = ENUMS.RewardOpTypes.Decrement,
            value = 5,
            path = dataSignal,
            params = { PATHS.userData.coins },
        },
        {
            name = "Undo points",
            opType = ENUMS.RewardOpTypes.Increment,
            value = 10,
            path = cacheSignal,
            params = { PATHS.userCache.points },
        },
    },
})
```

If “Charge points” fails, “Grant coins” has already run. The engine applies “Undo coins” and stops. “Undo points” is not applied.

Full API, rule fields, reward cases, and extension notes: [`docs/`](docs/README.md).

## Usage samples

See [`src/shared/Modules/Data/Rewards`](src/shared/Modules/Data/Rewards). Numbered files are complete `GameReward` modules used by the test place.

Sample [`6.luau`](src/shared/Modules/Data/Rewards/6.luau) is the rollback demo: grant coins and points, fail on purpose, then reverse both grants.

In the test place, touching a colored part runs `executeRule` against that sample.

## Running the test place

This is a Rojo + Wally project.

```bash
wally install
rojo serve
```

Connect Roblox Studio to the Rojo server, or open `build.rbxlx`. The place boots Data / Cache / Tool / Test / Reward services and spawns the sample reward parts.

The server runs the spec suite on boot. Watch the output for `PASS` / `FAIL` lines and a `{passed}/{total} passed` summary. See [`docs/Testing.md`](docs/Testing.md).
