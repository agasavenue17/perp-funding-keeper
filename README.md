# perp-funding-keeper

The keeper layer for perpetual futures markets: computes funding rates from mark/index premium (clamped to ±100 bps per period), evaluates account health factors, and batch-liquidates underwater positions — skipping healthy accounts so one bad entry never bricks a batch. Built with Foundry, with a full test suite (11 tests). Companion project to [`perp-margin-engine`](https://github.com/agasavenue17/perp-margin-engine): the keeper talks to any market that implements the small `IPerpMarket` interface.

Educational reference implementation. **Not audited, not for production use.**

## Components

| File | Role |
| --- | --- |
| `src/LiquidationKeeper.sol` | Keeper contract: pushes funding, batch-liquidates underwater accounts from a watchlist |
| `src/FundingRateLib.sol` | Premium-based funding rate math: `premium = (mark - index) / index`, clamped to ±100 bps per period |
| `src/HealthFactorLib.sol` | Maintenance-margin and health-factor math (in bps of the requirement) |
| `src/interfaces/IPerpMarket.sol` | Minimal market interface: `accrueFunding`, `liquidate`, `isLiquidatable` |
| `src/mocks/MockPerpMarket.sol` | Settable mock market for unit tests |

## How it works

**Funding.** Perpetuals stay anchored to the index price through funding: when the mark price trades above the index (longs crowding), the premium is positive and longs pay shorts. The keeper reads the mark/index pair, computes `rate = clamp(premium, -100, +100) bps`, and pushes it to the market once per funding period.

**Liquidations.** Anyone can call `checkAndLiquidate(watchlist)`. The keeper checks each account against the market, liquidates the underwater ones, and skips healthy accounts without reverting — so one bad entry never bricks a batch. The keeper earns the market's liquidator bonus per liquidation, which is the economic incentive to run it.

## Quick start

```bash
forge build
forge test -vv
```

Deployment:

1. Deploy against a live market: `LiquidationKeeper(market, indexPrice, markPrice)`
2. On the market side, register the keeper: `market.setKeeper(keeperAddress)`
3. Feed prices via `setPrices(index, mark)` (an oracle adapter in production) and call `pushFunding(periodSeconds)` each period; call `checkAndLiquidate(traders)` whenever accounts may be underwater.

## Tests

- `test/FundingRate.t.sol` — premium calculation, rate clamping at the ±100 bps cap, funding payment math, health factor at healthy / underwater / no-position boundaries, liquidatability checks incl. negative equity.
- `test/Keeper.t.sol` — funding push with clamped positive and negative premiums, zero-premium passthrough, owner-only price updates, batch liquidation that liquidates 2 of 3 watchlist accounts and skips the healthy one, empty watchlist.

## Design notes / known simplifications

- Prices are owner-pushed in the demo; production keepers pull from oracle feeds (Chainlink/Pyth) and run off-chain watchers that only submit on-chain when an account is actually near the boundary.
- Funding uses a simple premium snapshot; production systems typically use a time-weighted premium average and an interest-rate component.
- The watchlist is caller-supplied; production deployments index account sets from market events.

## License

MIT
