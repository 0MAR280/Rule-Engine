# Extending the engine

Add operators through the existing tables. Keep new files in the same shape as the current cases.

## Add a condition operator

1. Add a value to `ENUMS.ConditionOpTypes` in [`ENUMS.luau`](../src/shared/Modules/Data/ENUMS.luau).
2. Add a module under [`ConditionCases`](../src/shared/Modules/Math/ConditionCases) that returns `(v1, v2) -> boolean`.
3. Register it in [`ConditionCases/init.luau`](../src/shared/Modules/Math/ConditionCases/init.luau):

```lua
[ENUMS.ConditionOpTypes.YourOp] = require(script.YourOp),
```

4. Cover it in `Tests/Conditions.spec.luau`.

Unknown `opType` values fail closed (`false`).

## Add a reward case

1. Add a value to `ENUMS.RewardOpTypes`.
2. Add a module under [`RewardCases`](../src/shared/Modules/RuleEngine/RewardCases) that returns:

```lua
(player: Player, reward: Reward) -> (boolean, string?)
```

Return `true` on success, or `false, "reason"` on a bad reward. Throw only for unexpected runtime errors. `ApplyReward` logs `reason` and returns `"A mal reward format"` (or `"A runtime error"` if the case throws).

3. Register it in [`RewardCases/init.luau`](../src/shared/Modules/RuleEngine/RewardCases/init.luau).
4. If it fires a signal, add the name to `CommsHub`, a path to `PATHS.signals`, and a listener in a service.
5. Cover it in `Tests/RewardCases.spec.luau`.
6. Add a sample under `src/shared/Modules/Data/Rewards` if the test place should show it, and register the file in `Rewards/init.luau`.

`ApplyReward` deep-copies the reward and resolves a table `value` before calling the case. Increment/Decrement/Set take `params[1]` as the target path; copy that pattern if the new case writes data through a signal.

## Add a param source

1. Add a value to `ENUMS.ParamOpTypes`.
2. Handle it in [`SolveParam.luau`](../src/shared/Modules/RuleEngine/Helpers/SolveParam.luau). See [SolveParam.md](SolveParam.md).
3. Cover it in `Tests/Helpers.spec.luau` and a condition spec.

Unknown param types throw through `Logger:error`.

If you only moved DataService or CacheService, do not add a param type. Change the `require` paths and getter calls in `SolveParam` so `DataPath` / `CachePath` still hit the host APIs.

## Add a sample reward

Create `src/shared/Modules/Data/Rewards/N.luau` that returns a `GameReward`:

```lua
{
    id = N,
    ruleData = { ... },
    attributes = {
        name = "...",
        description = "...",
        color = Color3.fromRGB(...),
    },
}
```

Register it in `Rewards/init.luau` with a contiguous numeric key so `RewardService` ipairs over it. Add a spec in `Tests/Samples.spec.luau`.
