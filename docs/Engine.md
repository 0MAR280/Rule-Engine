# Engine API

Module: [`src/shared/Modules/RuleEngine/init.luau`](../src/shared/Modules/RuleEngine/init.luau)

```lua
local RuleEngine = require(ReplicatedStorage.Shared.Modules.RuleEngine)
```

## Run order

`RuleEngine.excuteRule(player, rule, payload?)` is the main entry. It runs these steps in order:

1. **Context** — the rule must match the current runtime (`Server`, `Client`, or `Both`).
2. **Conditions** — every condition is solved in order. The first failure stops evaluation and returns its `onFalse` message. Rewards are not applied.
3. **Rewards** — if all conditions pass, each reward is applied in order.
4. **Rollback** — if a reward after the first one fails, the engine applies `rollbackRewards` for the rewards that already succeeded.

Conditions, rewards, and rollback rewards can be an array of declarative objects, or a function `(Player) -> (boolean, string?)`.

Missing conditions, missing rewards, and empty arrays all pass.

## Public functions

### `excuteRule(player, rule, payload?)`

```lua
(conditionsPassed, rewardsApplied, rollbackApplied, err)
    -> (boolean, boolean, boolean?, string?)
```

| Return | Meaning |
| --- | --- |
| `conditionsPassed` | Context matched and every condition succeeded |
| `rewardsApplied` | Every reward succeeded |
| `rollbackApplied` | `true` if rollback ran and succeeded, `false` if it ran and failed, `nil` if it was not needed |
| `err` | Failure message, or `nil` on a full success |

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

Checks context and applies `rule.rewards`. On a list failure, `failureIndex` is the 1-based index of the reward that failed.

### `applyRollback(player, rule, failureIndex?)`

```lua
(ok, err, operationIndex) -> (boolean, string?, number?)
```

Checks context and applies `rule.rollbackRewards`. When `failureIndex` is a number, list rollback applies entries `1 .. failureIndex - 1` and stops at `failureIndex`.

`excuteRule` calls this with the failed reward index when that index is greater than 1.

## Context

Context values come from `ENUMS.ContextTypes`:

| Name | Value | Meaning |
| --- | --- | --- |
| `Server` | `1` | Only on the server |
| `Client` | `2` | Only on the client |
| `Both` | `3` | Either side |
| `nil` | | Treated as allowed |

The current runtime is `Server` when `RunService:IsServer()` is true, otherwise `Client`.

A mismatch returns immediately:

```text
excuteRule: Context mismatch. Expected: {rule.context} Current: {currentContext}
```

`excuteRule` then returns `false, false, nil, msg`.

## Return paths for `excuteRule`

| Situation | Returns |
| --- | --- |
| Context mismatch | `false, false, nil, err` |
| Conditions throw | `false, false, nil, "A runtime error: ..."` |
| Conditions fail | `false, false, nil, onFalse or err` |
| Rewards succeed | `true, true, nil, nil` |
| First reward fails | `true, false, false, "A mal ruledata: ..."` |
| Later reward fails, rollback succeeds | `true, false, true, rollbackErr` |
| Later reward fails, rollback fails | `true, false, false, "A mal ruledata: {reason}"` |
| Later reward fails, rollback throws | `true, false, false, "A runtime error: ..."` |
| Rewards throw | `true, false, false, "A runtime error: ..."` |

A failed rollback function that returns `false, "reason"` is reported as `A mal ruledata: reason`.

## Rollback

`rollbackRewards` is the reverse of `rewards`, aligned by index.

When reward `N` fails and `N > 1`:

1. Rewards `1 .. N-1` have already been applied.
2. The engine applies rollback entries `1 .. N-1`.
3. Rollback entry `N` and later entries are not applied.

If the first reward fails, nothing was applied, so rollback is skipped.

If `rollbackRewards` is missing, `applyRollback` still returns success (`No rollbackRewards were defined for this rule.`). `excuteRule` then reports `rollbackApplied = true` even though no reverse work ran. Define matching rollback entries when a partial apply must be undone.

See sample [`6.luau`](../src/shared/Modules/Data/Rewards/6.luau): grant coins and points, fail on purpose, then reverse both grants.

## Function rules

A function used as `conditions`, `rewards`, or `rollbackRewards` has this shape:

```lua
(player: Player) -> (boolean, string?)
```

- Return `true` (or anything other than `false`) to succeed.
- Return `false, "reason"` to fail.
- A thrown error is caught and returned as a runtime error.

Function rewards and function rollback do not use `failureIndex`. They run as a single operation.
