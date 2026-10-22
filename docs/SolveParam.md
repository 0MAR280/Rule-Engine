# SolveParam

Module: [`src/shared/Modules/RuleEngine/Helpers/SolveParam.luau`](../src/shared/Modules/RuleEngine/Helpers/SolveParam.luau)

This is the engine’s **data adapter**. Every `DataPath` and `CachePath` param is resolved here, on both conditions and dynamic reward values.

If you drop this engine into another place and your data/cache services live somewhere else, or expose different functions, **update this module**. Leaving the test-place requires in place will make every balance check and `{ param = ... }` value fail at runtime.

## Where it sits

```text
SolveConditionValue
  └─ SolveParam
        ├─ DataPath  → DataService
        ├─ CachePath → CacheService
        ├─ Value     → param.value
        ├─ Now       → os.time()
        └─ EventPayload → WalkPayload
```

`SolveCondition` and `ApplyReward` both go through `SolveConditionValue`, so they both depend on `SolveParam`.

## Signature

```lua
solveParam(player: Player, param: Param, payload: { [string]: any }?) -> any
```

`Param` is:

```lua
{
    type: ParamOpType, -- ENUMS.ParamOpTypes.*
    path: Path?,
    value: any?,
}
```

## Param sources

| `param.type`   | Uses                    | Result                                  |
| -------------- | ----------------------- | --------------------------------------- |
| `DataPath`     | `param.path`            | Player data from `DataService`          |
| `CachePath`    | `param.path`            | Session cache from `CacheService`       |
| `Value`        | `param.value`           | The literal                             |
| `Now`          |                         | `os.time()`                             |
| `EventPayload` | `param.path`, `payload` | A field walked inside the event payload |

Unknown `type` calls `Logger:error` and throws.

`Value`, `Now`, and `EventPayload` do not touch Data/Cache services. They keep working even if those requires are wrong. `DataPath` and `CachePath` do not.

## Host service wiring (must stay in sync)

`DataPath` and `CachePath` **require the host services from hardcoded paths**. The require is inside the branch, so a missing or renamed module only blows up when a rule actually reads that param.

### Server

```lua
ServerScriptService.Services.DataService   -- DataService.getPlayerData(player, path)
ServerScriptService.Services.CacheService  -- CacheService.getPlayerData(player, path)
```

In this repo those modules are [`ServerServices/DataService.luau`](../ServerServices/DataService.luau) and [`ServerServices/CacheService.luau`](../ServerServices/CacheService.luau).

### Client

```lua
ReplicatedStorage.Shared.Services.DataService   -- DataService.getData(path)
ReplicatedStorage.Shared.Services.CacheService  -- CacheService.getData(path)
```

In this repo those modules are [`src/shared/Services/DataService.luau`](../src/shared/Services/DataService.luau) and [`src/shared/Services/CacheService.luau`](../src/shared/Services/CacheService.luau). The client getters read `Players.LocalPlayer`; they do not take a player argument.

### API the engine expects

| Context | Module                    | Function                             |
| ------- | ------------------------- | ------------------------------------ |
| Server  | DataService, CacheService | `getPlayerData(player, path) -> any` |
| Client  | DataService, CacheService | `getData(path) -> any`               |

This place’s implementations walk `path` on the player instance and return a `NumberValue.Value`, or `nil` if the instance is missing.

Which runtime is used is `RunService:IsServer()` at module load (`ENUMS.ContextTypes.Server` or `.Client`).

## When you must edit this file

Update `SolveParam` whenever any of these change in the host game:

- The DataService or CacheService **instance path** (folder name, Rojo tree, `ServerScriptService` vs a package)
- The **function names** (`getPlayerData` / `getData`)
- The **arguments** (profile object instead of `Player`, string keys instead of `Path`)
- You split persistence into more than two stores and still want a `ParamOpTypes` entry for each

Also add a branch when you add a value to `ENUMS.ParamOpTypes`. See [Extending](Extending.md).

Do not assume “the engine will find my service.” It will not. Only this file knows where data lives.

## What breaks if you skip it

A condition such as `{ param = BALANCES.points }` never reads the player. `require` errors, or `getPlayerData` is missing, so `SolveConditionValue` throws. `executeRule` treats that as a condition failure.

A reward `value` that is `{ param = ... }` fails the same way inside `ApplyReward`.

Ready-made params in [`BALANCES.luau`](../src/shared/Modules/Data/BALANCES.luau) still point at `PATHS.userData` / `PATHS.userCache`. Those paths must match what your services actually store. Changing `PATHS` without changing `SolveParam` is fine; changing services without changing `SolveParam` is not.

## Example

```lua
-- DataPath, server: DataService.getPlayerData(player, { "leaderstats", "Coins" })
{ type = ENUMS.ParamOpTypes.DataPath, path = PATHS.userData.coins }

-- CachePath
{ type = ENUMS.ParamOpTypes.CachePath, path = PATHS.userCache.points }

-- Literal (no service)
{ type = ENUMS.ParamOpTypes.Value, value = 10 }

-- Clock (no service)
{ type = ENUMS.ParamOpTypes.Now }

-- Event payload passed to executeRule / checkConditions
{ type = ENUMS.ParamOpTypes.EventPayload, path = { "amount" } }
```

`BALANCES.coins` and `BALANCES.points` are the DataPath / CachePath rows above.
