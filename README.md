# Rule Engine

A declarative evaluate-and-reward engine for Luau game logic.

You describe a rule as **context + conditions + rewards**. The engine checks that the rule is running in the right place (server, client, or both), evaluates every condition, and applies the rewards if they all pass.

This system was built a while ago. This repository packages the engine together with a small Roblox place so it can be run and tested.

## Where the engine lives

The Rule Engine itself is in these paths:

| Path | What it is |
| --- | --- |
| [`src/shared/Modules/RuleEngine`](src/shared/Modules/RuleEngine) | Engine entry point, condition/reward helpers, and reward operation cases |
| [`src/shared/Modules/Math/ConditionCases`](src/shared/Modules/Math/ConditionCases) | Comparators used when evaluating conditions (`==`, `!=`, `>`, `>=`, `<`, `<=`) |
| [`src/shared/Modules/Types/Types.luau`](src/shared/Modules/Types/Types.luau) | Shared types for rules, conditions, rewards, params, and the engine API |

Usage samples live here:

- [`src/shared/Modules/Data/Rewards`](src/shared/Modules/Data/Rewards)

Everything else in this repo is environment setup for a place that runs and tests the engine (services, UI, sample data, Rojo/Wally config).

## How a rule runs

`RuleEngine.checkAndApplyRule(player, rule, payload?)` is the main entry.

1. **Context** — the rule must match the current runtime (`Server`, `Client`, or `Both`).
2. **Conditions** — every condition is solved in order. The first failure stops evaluation and returns its `onFalse` message.
3. **Rewards** — if all conditions pass, each reward is applied.

You can also call the two halves separately:

- `RuleEngine.checkRules(player, rule, payload?)` — evaluate only
- `RuleEngine.applyRewards(player, rule)` — apply only

Conditions and rewards can be a table of declarative objects, or a function `(Player) -> (boolean, string?)`.

## Rule shape

From `Types.luau`:

```lua
{
    context: ContextType,
    conditions: { Condition } | ((Player) -> (boolean, string?))?,
    rewards: { Reward } | ((Player) -> (boolean, string?))?,
}
```

A **condition** compares two values with an operator:

```lua
{
    name: string?,
    value1: any,
    value2: any,
    opType: ConditionOpType,
    onFalse: any?, -- returned when this condition fails
}
```

A **reward** dispatches to a reward case:

```lua
{
    name: string?,
    opType: RewardOpType,
    value: Value,
    path: Path?,
    params: { any }?,
    unpackParams: boolean?,
}
```

Values can be literals, or a `{ param = Param }` table that the engine resolves at runtime (player data, cache, a constant, `os.time()`, or a field on the event payload).

## Operators

Condition operators (`src/shared/Modules/Math/ConditionCases`):

- Equal
- NotEqual
- GreaterThan
- GreaterThanOrEqual
- LessThan
- LessThanOrEqual

Reward operators (`src/shared/Modules/RuleEngine/RewardCases`):

- Increment
- Decrement
- Set
- FireSignal

Param sources used when resolving dynamic values:

- DataPath
- CachePath
- Value
- Now
- EventPayload

## Usage samples

See [`src/shared/Modules/Data/Rewards`](src/shared/Modules/Data/Rewards). Those modules build real `RuleData` objects: check a balance, charge currency, grant currency, or fire a signal (for example, give a tool).

`_Shared.luau` in that folder is a small builder for the common patterns. The numbered files (`1.luau` … `4.luau`) are complete sample rewards used by the test place.

Minimal example of the same idea:

```lua
local RuleEngine = require(Modules.RuleEngine)
local ENUMS = require(Modules.Data.ENUMS)
local BALANCES = require(Modules.Data.BALANCES)
local PATHS = require(Modules.Data.PATHS)

local rule = {
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
            name = "Charge points",
            opType = ENUMS.RewardOpTypes.Decrement,
            value = 10,
            path = PATHS.signals.cacheService.server.updatePlayerData,
            params = { PATHS.userCache.points },
        },
    },
}

local ok, err = RuleEngine.checkAndApplyRule(player, rule)
```

In the test place, touching a colored part runs `checkAndApplyRule` against one of the sample rewards.

## Running the test place

This is a Rojo + Wally project.

```bash
wally install
rojo serve
```

Then connect Roblox Studio to the Rojo server (or build `build.rbxlx` and open it). The place boots Data / Cache / Reward / Tool services and spawns the sample reward parts.
