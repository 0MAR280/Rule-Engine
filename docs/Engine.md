# Engine API

Module: [`src/shared/Modules/RuleEngine/init.luau`](../src/shared/Modules/RuleEngine/init.luau)

```lua
local RuleEngine = require(ReplicatedStorage.Shared.Modules.RuleEngine)
```

## Run order

`RuleEngine.executeRule(player, rule, payload?)` is the main entry. It runs these steps in order:

1. **Context** — the rule must match the current runtime (`Server`, `Client`, or `Both`).
2. **Conditions** — every condition is solved in order. The first failure stops evaluation and returns its `onFalse` message. Rewards are not applied.
3. **Rewards** — if all conditions pass, each reward is applied in order.
4. **Rollback** — if a reward after the first one fails, the engine applies `rollbackRewards` for the rewards that already succeeded.

Conditions, rewards, and rollback rewards can be an array of declarative objects, or a function `(Player) -> (boolean, string?)`.

Missing conditions, missing rewards, and empty arrays all pass.

## Public functions

### `executeRule(player, rule, payload?)`

```lua
(conditionsPassed, rewardsApplied, rollbackApplied, err)
    -> (boolean, boolean, boolean?, string?)
```

| Return             | Meaning                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| `conditionsPassed` | Context matched and every condition succeeded                                                  |
| `rewardsApplied`   | Every reward succeeded                                                                         |
| `rollbackApplied`  | `true` if rollback ran and succeeded, `false` if it ran and failed, `nil` if it was not needed |
| `err`              | Failure message, or `nil` on a full success                                                    |

`payload` is an optional table used when a condition value has `ParamOpTypes.EventPayload`. Function conditions do not receive the payload.

### `checkConditions(player, rule, payload?)`

```lua
(ok, err) -> (boolean, string?)
```

Checks context and conditions only. Does not apply rewards.

### `applyRewards(player, rule)`

```lua
(ok, err, failureIndex) -> (boolean, string?, number?)
```

Checks context and applies `rule.rewards`. On a list failure, `failureIndex` is the 1-based index of the reward that failed. On success, `failureIndex` is `nil`.

List apply failures return `"Something went wrong!"`. The specific reason is logged.

### `applyRollback(player, rule, failureIndex?)`

```lua
(ok, err, failureIndex) -> (boolean, string?, number?)
```

Checks context and applies `rule.rollbackRewards`. When `failureIndex` is a number, list rollback applies entries `1 .. failureIndex - 1` and stops at `failureIndex`.

The third return is the failed rollback entry index, and only when a list entry fails. On success it is `nil`.

List rollback failures return `"Something went wrong!"`. The specific reason is logged.

`executeRule` calls this with the failed reward index when that index is greater than 1.

## Context

Context values come from `ENUMS.ContextTypes`:

| Name     | Value | Meaning            |
| -------- | ----- | ------------------ |
| `Server` | `1`   | Only on the server |
| `Client` | `2`   | Only on the client |
| `Both`   | `3`   | Either side        |
| `nil`    |       | Treated as allowed |

The current runtime is `Server` when `RunService:IsServer()` is true, otherwise `Client`.

A mismatch returns immediately:

```text
executeRule: Context mismatch. Expected: {rule.context} Current: {currentContext}
```

`executeRule` then returns `false, false, nil, msg`.

## Error messages

Callers get a short `err` string. Details stay in the log (`Logger:warn`).

| Kind                                                                    | Returned `err`                                                                                                            |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Condition `onFalse` / function condition reason                         | That message, as-is                                                                                                       |
| Context mismatch, wrong types                                           | The specific validation message                                                                                           |
| Function condition throw                                                | The caught error, including the throw text                                                                                |
| Function reward / rollback that returns `false, reason`                 | That `reason` from `applyRewards` / `applyRollback`; `executeRule` maps reward-side failures to `"Something went wrong!"` |
| Malformed reward handler (`ApplyReward`)                                | `"A mal reward format"`                                                                                                   |
| Reward handler throw (`ApplyReward`)                                    | `"A runtime error"`                                                                                                       |
| List apply / rollback failure, or `executeRule` reward/rollback failure | `"Something went wrong!"`                                                                                                 |

Condition failures such as `"Not Enough points!"` are still returned to the caller. Reward and rollback internals are not.

## Return paths for `executeRule`

| Situation                             | Returns                                       |
| ------------------------------------- | --------------------------------------------- |
| Context mismatch                      | `false, false, nil, err`                      |
| Conditions throw (function)           | `false, false, nil, err` with the throw text  |
| Conditions fail                       | `false, false, nil, onFalse or err`           |
| Rewards succeed                       | `true, true, nil, nil`                        |
| First reward fails                    | `true, false, false, "Something went wrong!"` |
| Later reward fails, rollback succeeds | `true, false, true, "Something went wrong!"`  |
| Later reward fails, rollback fails    | `true, false, false, "Something went wrong!"` |
| Later reward fails, rollback throws   | `true, false, false, "Something went wrong!"` |
| Rewards throw                         | `true, false, false, "Something went wrong!"` |

## Rollback

`rollbackRewards` is the reverse of `rewards`, aligned by index.

When reward `N` fails and `N > 1`:

1. Rewards `1 .. N-1` have already been applied.
2. The engine applies rollback entries `1 .. N-1`.
3. Rollback entry `N` and later entries are not applied.

If the first reward fails, nothing was applied, so rollback is skipped.

If `rollbackRewards` is missing, `applyRollback` still returns success (`No rollbackRewards were defined for this rule.`). `executeRule` then reports `rollbackApplied = true` even though no reverse work ran. Define matching rollback entries when a partial apply must be undone.

See sample [`6.luau`](../src/shared/Modules/Data/Rewards/6.luau): grant coins and points, fail on purpose, then reverse both grants.

## Function rules

A function used as `conditions`, `rewards`, or `rollbackRewards` has this shape:

```lua
(player: Player) -> (boolean, string?)
```

- Return `true` (or anything other than `false`) to succeed.
- Return `false, "reason"` to fail. `applyRewards` / `applyRollback` return that `reason`. `executeRule` still returns `"Something went wrong!"` for reward and rollback failures, and logs the reason.
- A thrown error is caught, logged, and treated as a runtime failure. Function conditions still return the throw text; reward-side throws from `executeRule` return `"Something went wrong!"`.

Function rewards and function rollback do not use `failureIndex`. They run as a single operation.
