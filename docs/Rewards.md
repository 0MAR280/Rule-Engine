# Rewards

Cases: [`src/shared/Modules/RuleEngine/RewardCases`](../src/shared/Modules/RuleEngine/RewardCases)

Helpers: [`ApplyReward.luau`](../src/shared/Modules/RuleEngine/Helpers/ApplyReward.luau), [`ApplyRewards.luau`](../src/shared/Modules/RuleEngine/Helpers/ApplyRewards.luau)

Builders: [`src/shared/Modules/Data/Rewards/_Shared.luau`](../src/shared/Modules/Data/Rewards/_Shared.luau)

Samples: [`src/shared/Modules/Data/Rewards`](../src/shared/Modules/Data/Rewards)

## Applying a list

`ApplyRewards` walks the array with `ipairs` and stops at the first failure. An optional `stopIndex` skips that index and everything after it. Rollback uses this to reverse only the rewards that already ran.

Each reward is deep-copied, then:

1. If `value` is a table, it is resolved with `SolveConditionValue` (no event payload).
2. The matching `RewardCases[opType]` handler runs.
3. The copy is cleared.

Unknown `opType` fails with `Unknown operation type {opType} for reward {name}`.

A handler that returns `false, err` is returned to the caller as `"A mal reward format"`. A thrown error is returned as `"A runtime error"`. The specific `err` is logged in both cases.

## Signal contract

Every built-in case fires a signal through `CommsHub` + `SignalManager`.

`reward.path` is a path on `CommsHub` that must resolve to a **signal name string**, for example `"DataService:UpdatePlayerData"`.

In this place those names are defined in [`CommsHub.luau`](../src/shared/Modules/Core/CommsHub.luau) and addressed with [`PATHS.signals`](../src/shared/Modules/Data/PATHS.luau):

```lua
PATHS.signals.dataService.server.updatePlayerData
-- { "signals", "DataService", "server", "updatePlayerData" }
-- -> "DataService:UpdatePlayerData"
```

A listener must already be connected. `DataService` and `CacheService` listen for update/set. `ToolService` listens for `giveTool`.

`params` must be a sequential array, or empty. A dictionary fails. Sift does not treat `{}` as an array; the engine allows empty tables anyway.

### Increment

Adds `reward.value` (a number) to the value at `params[1]`.

Fires:

```text
signal(player, valuePath, function(current: number) return current + value end, extra...)
```

`DataService` / `CacheService` `updatePlayerData` handlers expect that callback.

Requires a signal path, a number `value`, and a valid target path as `params[1]`. Leftover `params` after the path are extra signal args. An empty leftover table is omitted; passing `{}` is truthy and any consumer expecting optional paramter would deal with it as `true`.

### Decrement

Same as Increment, subtracting `value`.

### Set

Writes `reward.value` as-is (any type) to `params[1]`.

Fires:

```text
signal(player, valuePath, newValue, extra...)
```

Use the `setPlayerData` signal, not `updatePlayerData`.

### FireSignal

Fires the signal with the player and `params` only. No target path is consumed.

```text
-- unpackParams = true
signal(player, table.unpack(params))

-- unpackParams = false or omitted
signal(player, params)
```

`params` may be omitted or empty.

## Builders

`_Shared.luau` builds the common place patterns. Paths come from `PATHS.userData` (persisted coins) and `PATHS.userCache` (session points / playtime).

| Builder                                               | Op         | Writes                                          |
| ----------------------------------------------------- | ---------- | ----------------------------------------------- |
| `Shared.reward(currency, amount, path)`               | Increment  | `userData[currency]`                            |
| `Shared.cacheReward(currency, amount, path)`          | Increment  | `userCache[currency]`                           |
| `Shared.payment(currency, amount, path)`              | Decrement  | `userData[currency]`                            |
| `Shared.cachePayment(currency, amount, path)`         | Decrement  | `userCache[currency]`                           |
| `Shared.set(currency, value, path)`                   | Set        | `userData[currency]`                            |
| `Shared.cacheSet(currency, value, path)`              | Set        | `userCache[currency]`                           |
| `Shared.fireSignal(name, path, params, unpackParams)` | FireSignal | none                                            |
| `Shared.balanceRule(currency, price, rewards)`        |            | Server rule: `balance >= price`, then `rewards` |

Pass the matching signal path: `updatePlayerData` for increment/decrement, `setPlayerData` for set.

## Samples

`RewardService` spawns one anchored part per sample. Touching it runs `executeRule` for that `ruleData`.

| Sample                                                | Case                  | What it does                                                       |
| ----------------------------------------------------- | --------------------- | ------------------------------------------------------------------ |
| [`1.luau`](../src/shared/Modules/Data/Rewards/1.luau) | Increment + Decrement | Trade 10 points for 5 coins                                        |
| [`2.luau`](../src/shared/Modules/Data/Rewards/2.luau) | Set                   | Set coins to 50 if they are not already 50                         |
| [`3.luau`](../src/shared/Modules/Data/Rewards/3.luau) | Increment             | Grant 15 coins while under 100                                     |
| [`4.luau`](../src/shared/Modules/Data/Rewards/4.luau) | FireSignal            | Charge 10 coins and 10 points, then give a sword                   |
| [`5.luau`](../src/shared/Modules/Data/Rewards/5.luau) | Decrement             | Spend 10 points when points are greater than 10                    |
| [`6.luau`](../src/shared/Modules/Data/Rewards/6.luau) | Rollback              | Grant 25 coins and 10 points, fail on purpose, then roll both back |

## Example

```lua
{
    name = "Charge points",
    opType = ENUMS.RewardOpTypes.Decrement,
    value = 10,
    path = PATHS.signals.cacheService.server.updatePlayerData,
    params = { PATHS.userCache.points },
}
```

Same thing through the builder:

```lua
Shared.cachePayment("points", 10, PATHS.signals.cacheService.server.updatePlayerData)
```
