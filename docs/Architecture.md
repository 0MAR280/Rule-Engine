# Architecture

The Rule Engine is a shared Luau module. The rest of this repository is a small Roblox place that hosts it: data, cache, tools, sample parts, and tests.

```text
excuteRule
  ├─ CheckContext
  ├─ checkConditions
  │    └─ SolveAllConditions → SolveCondition → SolveConditionValue → SolveParam
  │         ├─ DataPath / CachePath → DataService / CacheService
  │         ├─ Value / Now
  │         └─ EventPayload → WalkPayload
  ├─ applyRewards → ApplyRewards → ApplyReward → RewardCases[opType]
  │         └─ SignalManager.fireSignal(CommsHub path)
  └─ applyRollback → ApplyRewards(..., failureIndex)
```

## Layout

| Path | Role |
| --- | --- |
| `src/shared/Modules/RuleEngine` | Engine entry, helpers, reward cases, tests |
| `src/shared/Modules/Math/ConditionCases` | Condition comparators |
| `src/shared/Modules/Types/Types.luau` | Shared types |
| `src/shared/Modules/Data/ENUMS.luau` | Context, param, condition, and reward enums |
| `src/shared/Modules/Data/PATHS.luau` | Data, cache, and signal paths |
| `src/shared/Modules/Data/BALANCES.luau` | Ready-made params for coins, points, playtime |
| `src/shared/Modules/Data/Rewards` | Sample `GameReward` modules |
| `src/shared/Modules/Core/CommsHub.luau` | Signal name tree |
| `src/shared/Modules/Core/SignalManager.luau` | Named signals |
| `ServerServices/DataService.luau` | Server coins (`leaderstats.Coins`) |
| `ServerServices/CacheService.luau` | Server points and playtime (`SessionStats`) |
| `ServerServices/ToolService.luau` | `giveTool` listener |
| `ServerServices/RewardService.luau` | Sample parts that call `excuteRule` |
| `ServerServices/TestService.luau` | Runs the engine specs on boot |

## Helpers

| Helper | Job |
| --- | --- |
| `CheckContext` | Compare `rule.context` to the current runtime |
| `SolveAllConditions` | First-failing condition wins |
| `SolveCondition` | Resolve values, run a comparator |
| `SolveConditionValue` | Literal vs `{ param }`, callbacks, `returnIndex` |
| `SolveParam` | DataPath, CachePath, Value, Now, EventPayload |
| `WalkPayload` | Walk a payload table by path; fail closed to `nil` |
| `ApplyReward` | Resolve dynamic `value`, dispatch to a reward case |
| `ApplyRewards` | Apply a list, optional `stopIndex` |

## Signals

Reward cases do not write player data themselves. They fire a CommsHub signal. A service must listen and apply the change.

`PATHS.signals.*.server.updatePlayerData` maps to `CommsHub.signals.*.server.updatePlayerData`, which is a string name such as `"DataService:UpdatePlayerData"`.

`DataService` and `CacheService` connect:

- **update** — `(player, path, callback)` where `callback` is `(current: number) -> number`. Used by Increment and Decrement.
- **set** — `(player, path, newValue)`. Used by Set.

`ToolService` connects `giveTool` as `(player, toolName, ...)`.

To add a custom reward, add a CommsHub name, a `PATHS` entry, a listener, and either `FireSignal` or a new reward case.

## Player data in the test place

On join, the server creates:

```text
player
  leaderstats
    Coins (NumberValue)      -- DataPath
  SessionStats
    Points (NumberValue)     -- CachePath, +1 per second
    Playtime (NumberValue)   -- CachePath, +1 per second
```

Client mirrors of `getData` live under `src/shared/Services`.

## Paths

```lua
PATHS.userData.coins   -- { "leaderstats", "Coins" }
PATHS.userCache.points -- { "SessionStats", "Points" }
```

Increment, Decrement, and Set take that path as `params[1]`. The remaining `params` are extra arguments to the signal.
