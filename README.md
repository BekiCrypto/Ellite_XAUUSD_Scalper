# Elite XAUUSD Multi-Strategy Scalping Engine

A modular MetaTrader 5 (MQL5) Expert Advisor for autonomous XAUUSD scalping, built around
six independently-evaluated strategy modules, a confidence-scoring engine, and a multi-layer
risk governance stack — plus an optional Node.js bridge and mobile-style web dashboard for
remote monitoring.

Full design spec: [`ELITE XAUUSD MULTI-STRATEGY SCALPING ENGINE SDD.md`](ELITE%20XAUUSD%20MULTI-STRATEGY%20SCALPING%20ENGINE%20SDD.md)
Full user manual: [`ELITE_XAUUSD_SCALPING_ENGINE_DOCUMENTATION.md`](ELITE_XAUUSD_SCALPING_ENGINE_DOCUMENTATION.md)

## Status

The EA compiles and runs a full pipeline: regime detection → 6 strategies → confidence
scoring → risk validation → execution → trade management → analytics. Recent fixes:

- Recovered the `Include/Analytics/` module (`ConfidenceEngine`, `StatisticsEngine`,
  `PerformanceTracker`) that the EA's `#include`s depended on but that was missing from
  this export — without it the EA could not compile.
- Corrected the shipped default risk inputs, which were far more aggressive than the SDD's
  own spec (`InpRiskPercent` 15%→3%, `MaxDailyDrawdown` 10%→5%, `MaxDailyProfit` 25%→10%,
  matching `Experts/elitexauscalper best.set`).
- Added Simultaneous Exposure Protection: `RiskEngine` now caps aggregate open + new risk
  across concurrent positions against the daily drawdown ceiling, not just each trade in
  isolation.
- The daily-drawdown kill switch now force-closes open positions, not just blocks new
  entries.
- `RegimeDetector`'s volatility thresholds are ATR-as-%-of-price instead of fixed dollar
  amounts, so classification doesn't drift as gold's price level moves over time.
- `TradeExecutor` now clamps SL/TP to the broker's minimum stop/freeze distance and retries
  transient failures (requote/timeout) up to `MAX_RETRY_ATTEMPTS`.
- `PerformanceTracker.GetDailyPnL()` is throttled (was re-scanning full deal history every
  tick); `GetCurrentDrawdown()` now tracks the day's actual peak, matching the dashboard's
  "Daily Peak DD" label.

**Not yet done:** no strategy in this repo has been backtested. The fixes above make the
system safe to *run* (won't blow up on a missing include, won't risk-of-ruin on default
settings) — they are not evidence of a profitable edge. Run the Strategy Tester across
multiple periods and regimes (see `MQL5/Profiles/Tester/` for prior test configs) before
this touches a live account.

## Repository structure

```
Experts/EliteXAUScalper.mq5        Main EA — orchestration only
Include/Core/                      Config, constants, types, logging, utilities
Include/Filters/                   Session, spread, news, regime detection
Include/Strategies/                6 independent strategy modules (IStrategy interface)
Include/Analytics/                 Confidence scoring, trade statistics, performance tracking
Include/Risk/                      Position sizing, drawdown protection, risk engine
Include/Execution/                 Order execution, trade management, slippage tracking
Include/UI/                        On-chart dashboard
EliteXAUScalperApp/                Node.js bridge server + mobile-style web dashboard
```

## Strategies

Trend Pullback · Momentum Breakout · Liquidity Sweep · Session Expansion · Mean Reversion ·
Order Block / FVG — each gated to specific market regimes and scored by the confidence
engine before any signal reaches the risk layer. Details on indicators, entry/exit logic,
and SL/TP rules per strategy are in the [full documentation](ELITE_XAUUSD_SCALPING_ENGINE_DOCUMENTATION.md#3-deep-dive-the-6-core-trading-strategies).

## Installation

1. Open MetaTrader 5 → **File → Open Data Folder**.
2. Copy `Experts/` and `Include/` into the terminal's `MQL5/` folder.
3. Refresh the Navigator panel (or restart MT5).
4. Drag `EliteXAUScalper` onto an **XAUUSD M5** chart.
5. Enable **Allow Algo Trading** in the Common tab.
6. In Inputs, load `Experts/elitexauscalper best.set` (the safe, recommended config).
7. Compile in MetaEditor (F7) if you don't see a compiled `.ex5`.

Backtest first via Strategy Tester before any live or demo-forward run.

## Companion app (`EliteXAUScalperApp/`)

A zero-dependency Node.js bridge (`server.js`) that the EA posts telemetry to via
`WebRequest`, plus a mobile-style web dashboard for remote monitoring and manual control
(pause, panic-close, move-to-breakeven, strategy toggles).

**The account/monetization screens are UI prototypes, not wired up:** Google SSO, the USDT
BEP20 checkout, and license activation are simulated client-side with fake delays — the
server accepts any 10+ character string as a "valid" transaction hash and issues a license
unconditionally. The checkout screen displays a real-format wallet address. Don't deploy
this publicly implying it processes real payments until `/api/client/confirm-payment` is
wired to actual on-chain verification. The MT5 "Terminal Link" screen is also simulated —
your broker password is read from the form, never transmitted, and discarded (the EA's own
`WebRequest` calls, authenticated via `InpAuthToken`, are the real data path).

Run it with `node server.js` (or via the included `Dockerfile` / `docker-compose.yml`).

## Configuration

All risk, filter, and execution parameters are `input` values on the EA — see
`Experts/elitexauscalper best.set` for the recommended baseline. Key ones:

| Parameter | Default | Purpose |
|---|---|---|
| `InpRiskPercent` | 3.0% | Risk per trade, ATR/confidence/regime-adjusted |
| `InpMaxDailyDrawdown` | 5.0% | Hard stop — kill switch force-closes all positions |
| `InpMaxDailyProfit` | 10.0% | Daily target with a trailing profit lock at 50% |
| `InpMaxConcurrentTrades` | 5 | One position per strategy, capped in aggregate |
| `InpMinConfidence` | 75.0 | Minimum confidence score to act on a signal |

## Risk disclaimer

Trading gold (XAUUSD) and other leveraged instruments carries a high level of risk. Backtest
and historical performance are not indicators of future results. Verify all settings on a
demo account before deploying to live. See the full disclaimer in the
[documentation](ELITE_XAUUSD_SCALPING_ENGINE_DOCUMENTATION.md#8-regulatory--risk-disclaimer).

## Support

- Telegram: [t.me/tradelikeb](https://t.me/tradelikeb)
- Email: [Bekicrypto@gmail.com](mailto:Bekicrypto@gmail.com)
