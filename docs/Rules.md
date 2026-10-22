# Rule data

Types: [`src/shared/Modules/Types/Types.luau`](../src/shared/Modules/Types/Types.luau)

Enums: [`src/shared/Modules/Data/ENUMS.luau`](../src/shared/Modules/Data/ENUMS.luau)

Use the enum tables. Do not hard-code the numeric values in new rules.

## `RuleData`

```lua
{
    context: ContextType,
    conditions: { Condition } | ((Player) -> (boolean, string?))?,
    rewards: { Reward } | ((Player) -> (boolean, string?))?,
    rollbackRewards: { Reward } | ((Player) -> (boolean, string?))?,
}
```

| Field             | Required | Notes                                                                 |
| ----------------- | -------- | --------------------------------------------------------------------- |
| `context`         | usually  | `ENUMS.ContextTypes.Server`, `.Client`, or `.Both`. `nil` is allowed. |
| `conditions`      | no       | Missing or `{}` passes.                                               |
| `rewards`         | no       | Missing or `{}` succeeds.                                             |
| `rollbackRewards` | no       | Used when a list reward after the first fails.                        |

A list must be a sequential array. A dictionary such as `{ name = "x" }` is rejected.

## `Condition`

```lua
{
    name: string,
    value1: Value,
    value2: Value,
    opType: ConditionOpType,
    onFalse: any?,
}
```

| Field              | Meaning                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| `name`             | Shown in logs and in the default failure message                                               |
| `value1`, `value2` | Literals, or `{ param = Param, ... }` tables resolved at runtime                               |
| `opType`           | A `ENUMS.ConditionOpTypes` value                                                               |
| `onFalse`          | Returned when this condition fails. If omitted, the message is `Condition "{name}" is not met` |

Conditions run in order. The first failure stops the rest.

## `Reward`

```lua
{
    name: string,
    opType: RewardOpType,
    value: Value,
    path: Path?,
    params: { any }?,
    unpackParams: boolean?,
}
```

| Field          | Meaning                                                                                                                                   |
| -------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `name`         | Shown in logs                                                                                                                             |
| `opType`       | A `ENUMS.RewardOpTypes` value                                                                                                             |
| `value`        | Literal, or a `{ param = Param }` table resolved before the case runs. Increment and Decrement require a number.                          |
| `path`         | Path from `CommsHub` to the signal name                                                                                                   |
| `params`       | Sequential array. For Increment, Decrement, and Set, `params[1]` is the target value path. Remaining entries are forwarded to the signal. |
| `unpackParams` | When true, extra params are sent with `table.unpack`. When false or omitted, they are sent as a table.                                    |

The engine deep-copies each reward before applying it, so `table.remove` on `params` does not mutate the original rule.

## `Value`

A value is either a literal (`10`, `"sword"`, `true`) or a table:

```lua
{
    param: Param,
    callBack: ((...any) -> any)?,
    unpackParams: boolean?,
    returnIndex: number?,
}
```

If the table has a `param` field, the engine resolves it through `SolveParam`, then optionally runs `callBack`. Any other table is used as the literal value.

## `Param`

```lua
{
    type: ParamOpType,
    path: Path?,
    value: any?,
}
```

| `type`         | Fields used | Result                                                                                |
| -------------- | ----------- | ------------------------------------------------------------------------------------- |
| `DataPath`     | `path`      | Player data at that path (`DataService`). Resolved in [SolveParam](SolveParam.md)     |
| `CachePath`    | `path`      | Session cache at that path (`CacheService`). Resolved in [SolveParam](SolveParam.md)  |
| `Value`        | `value`     | The literal `value`                                                                   |
| `Now`          |             | `os.time()`                                                                           |
| `EventPayload` | `path`      | A field walked inside the `payload` table passed to `executeRule` / `checkConditions` |

## `Path`

A path is a string or an array of strings:

```lua
"Coins"
{ "leaderstats", "Coins" }
{ "signals", "DataService", "server", "updatePlayerData" }
```

Signal paths are resolved on `CommsHub`. Data and cache paths are resolved on the player instance.

## Enums

### Context

| Name                        | Value |
| --------------------------- | ----- |
| `ENUMS.ContextTypes.Server` | `1`   |
| `ENUMS.ContextTypes.Client` | `2`   |
| `ENUMS.ContextTypes.Both`   | `3`   |

### Condition operators

| Name                 | Value | Compare |
| -------------------- | ----- | ------- |
| `Equal`              | `1`   | `==`    |
| `NotEqual`           | `2`   | `~=`    |
| `GreaterThanOrEqual` | `3`   | `>=`    |
| `GreaterThan`        | `4`   | `>`     |
| `LessThanOrEqual`    | `5`   | `<=`    |
| `LessThan`           | `6`   | `<`     |

### Reward operators

| Name         | Value |
| ------------ | ----- |
| `Increment`  | `1`   |
| `Decrement`  | `2`   |
| `Set`        | `3`   |
| `FireSignal` | `4`   |

### Param sources

| Name           | Value |
| -------------- | ----- |
| `DataPath`     | `1`   |
| `CachePath`    | `2`   |
| `Value`        | `3`   |
| `Now`          | `4`   |
| `EventPayload` | `5`   |

## `GameReward`

The test place wraps a rule as:

```lua
{
    id: number,
    ruleData: RuleData,
    attributes: {
        name: string,
        description: string,
        color: Color3,
        -- extra keys allowed
    },
}
```

`RewardService` spawns a part per entry in [`src/shared/Modules/Data/Rewards`](../src/shared/Modules/Data/Rewards).
