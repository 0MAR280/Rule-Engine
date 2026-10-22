# Conditions

Helpers:

- [`SolveAllConditions.luau`](../src/shared/Modules/RuleEngine/Helpers/SolveAllConditions.luau)
- [`SolveCondition.luau`](../src/shared/Modules/RuleEngine/Helpers/SolveCondition.luau)
- [`SolveConditionValue.luau`](../src/shared/Modules/RuleEngine/Helpers/SolveConditionValue.luau)
- [`SolveParam.luau`](../src/shared/Modules/RuleEngine/Helpers/SolveParam.luau) — dedicated notes in [SolveParam.md](SolveParam.md)
- [`WalkPayload.luau`](../src/shared/Modules/RuleEngine/Helpers/WalkPayload.luau)

Comparators: [`src/shared/Modules/Math/ConditionCases`](../src/shared/Modules/Math/ConditionCases)

## Evaluation

`checkConditions` / `executeRule`:

1. Reject a context mismatch.
2. If `conditions` is missing, pass.
3. If it is a function, call `conditions(player)` and return that result. The payload is not passed.
4. If it is an array (including `{}`), evaluate each condition in order.
5. Anything else fails: expected a function or an array.

For each array condition:

1. Deep-copy the condition.
2. If `value1` or `value2` is a table, resolve it with `SolveConditionValue`.
3. Look up `conditionCases[opType]`.
4. Run the comparator inside `pcall`.
5. Succeed only when the comparator returns exactly `true`.

A `nil` condition is treated as satisfied. An unknown `opType` fails closed.

The first failing condition returns `false, condition.onFalse` or, if `onFalse` is omitted, `Condition "{name}" is not met`.

## Operators

Each comparator is `(v1, v2) -> boolean` and expects numbers for ordered compares:

| Operator             | True when  |
| -------------------- | ---------- |
| `Equal`              | `v1 == v2` |
| `NotEqual`           | `v1 ~= v2` |
| `GreaterThan`        | `v1 > v2`  |
| `GreaterThanOrEqual` | `v1 >= v2` |
| `LessThan`           | `v1 < v2`  |
| `LessThanOrEqual`    | `v1 <= v2` |

A comparator that throws is treated as a failed condition.

## Resolving values

A literal is used as-is:

```lua
value1 = 10
value2 = 10
```

A table with `param` is resolved:

```lua
value1 = { param = BALANCES.points }
value2 = 10
```

`BALANCES` in [`src/shared/Modules/Data/BALANCES.luau`](../src/shared/Modules/Data/BALANCES.luau) already holds `DataPath` / `CachePath` params for `coins`, `points`, and `playtime`.

### Param sources

Full wiring, expected service APIs, and what to change in a host game: [SolveParam.md](SolveParam.md).

**DataPath** reads `DataService.getPlayerData(player, path)` on the server, or `DataService.getData(path)` on the client.

**CachePath** reads `CacheService` the same way.

**Value** returns `param.value`.

**Now** returns `os.time()`.

**EventPayload** walks `payload` with `param.path`. Missing payload, missing path, or a non-table node returns `nil`.

```lua
RuleEngine.checkConditions(player, {
    context = ENUMS.ContextTypes.Server,
    conditions = {
        {
            name = "Payload amount",
            value1 = {
                param = {
                    type = ENUMS.ParamOpTypes.EventPayload,
                    path = { "amount" },
                },
            },
            value2 = 10,
            opType = ENUMS.ConditionOpTypes.Equal,
            onFalse = "amount mismatch",
        },
    },
}, { amount = 10 })
```

### Callbacks

After the param is resolved, an optional `callBack` can reshape it.

```lua
value1 = {
    param = {
        type = ENUMS.ParamOpTypes.Value,
        value = { 10, 20 },
    },
    callBack = function(values)
        return values[1] + values[2]
    end,
    unpackParams = false,
}
```

| Field                             | Behavior                                                                 |
| --------------------------------- | ------------------------------------------------------------------------ |
| `unpackParams = true`             | `callBack(table.unpack(resolved))`. The resolved value must be an array. |
| `unpackParams = false` or omitted | `callBack(resolved)`                                                     |
| `returnIndex = n`                 | After the callback (or without one), pick index `n` from an array result |

Unknown param types and invalid callback setup call `Logger:error` and throw.

## Example

```lua
{
    name = "Coins below cap",
    value1 = { param = BALANCES.coins },
    value2 = 100,
    opType = ENUMS.ConditionOpTypes.LessThan,
    onFalse = "Coins cap of 100 reached!",
}
```
