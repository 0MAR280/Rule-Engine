# Testing

Specs: [`src/shared/Modules/RuleEngine/Tests`](../src/shared/Modules/RuleEngine/Tests)

Runner: [`ServerServices/TestService.luau`](../ServerServices/TestService.luau)

The server runs the suite on boot, after Data, Cache, and Tool services, before the sample reward parts spawn.

## Output

Each spec prints `PASS` or `FAIL`. The summary is `{passed}/{total} passed`, for example `70/70 passed`.

Specs assert caller-facing return values. Condition `onFalse` strings are returned as-is. Malformed reward handlers return `"A mal reward format"`. `excuteRule` reward and rollback failures return `"Somthing went wrong!"`. Specific reasons show up in the server log, not in `err`. `applyRollback` reports a failure index only when a list entry fails.

A suite crash is caught by `TestService` so the place still boots.

## Suites

| Suite | File | Covers |
| --- | --- | --- |
| Engine | `Engine.spec.luau` | `excuteRule`, context, function rules, rollback, payload |
| Conditions | `Conditions.spec.luau` | All six operators, params, callbacks |
| RewardCases | `RewardCases.spec.luau` | Increment, Decrement, Set, FireSignal, invalid input |
| Helpers | `Helpers.spec.luau` | `CheckContext`, `WalkPayload`, `SolveParam` |
| Samples | `Samples.spec.luau` | Each numbered reward, pass and fail paths |

The harness in `Harness.luau` builds a folder that mimics the player data tree (`leaderstats.Coins`, `SessionStats.Points`, `Backpack`). Specs use that tree with the real Data/Cache/Tool listeners.

## Running

```bash
wally install
rojo serve
```

Connect Roblox Studio to Rojo, or open `build.rbxlx`. Watch the server log for the `{passed}/{total} passed` line.

Touching a colored part still runs `excuteRule` against that sample. Sample 6 is the rollback demo: balances return to what they were.
