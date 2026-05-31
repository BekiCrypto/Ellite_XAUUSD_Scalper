# ELITE XAUUSD MULTI-STRATEGY SCALPING ENGINE

## System Design Document (SDD) + Engineering Request

# OBJECTIVE

Design and implement a production-oriented autonomous XAUUSD multi-strategy scalping engine optimized for:

* XAUUSD only
* MT5 execution environment
* IC Markets broker
* M1 / M3 / M5 scalping
* controlled aggressive execution
* long-term survivability
* modular extensibility
* institutional-style architecture
* autonomous execution with strong risk governance

The system MUST prioritize:

* execution discipline
* market regime adaptation
* volatility awareness
* liquidity behavior
* risk containment

The system MUST NOT use:

* martingale
* grid averaging
* infinite recovery systems
* fake high-win-rate logic
* indicator spam
* curve-fit-only logic

---

# HIGH LEVEL ARCHITECTURE

System Flow:

Tick/Market Data
↓
Session Filter
↓
Spread Filter
↓
Market Regime Detector
↓
Strategy Selection Engine
↓
Confidence Scoring Engine
↓
Risk Engine
↓
Execution Engine
↓
Trade Management Engine
↓
Logging + Analytics

---

# TARGET ENVIRONMENT

## Broker

IC Markets MT5

## Asset

XAUUSD only

## Primary Execution Timeframes

* M1
* M3
* M5

## Context Timeframes

* M15
* H1

## Runtime Environment

MetaTrader 5 Expert Advisor (MQL5)

## External Research Layer

Python-based analytics stack may be added later.

---

# CORE DESIGN PRINCIPLES

1. Multi-strategy architecture
2. Regime-aware execution
3. Adaptive volatility handling
4. Session-aware trading
5. Confidence-based execution
6. Strict risk governance
7. One-trade-at-a-time discipline
8. Modular extensibility
9. High observability/logging
10. Long-term robustness over short-term optimization

---

# MODULES

# MODULE 1 — SESSION FILTER

Purpose:
Allow trading only during high-quality XAUUSD liquidity periods.

## Allowed Sessions

* London Open
* New York Open
* London/NY overlap

## Avoid

* rollover
* dead liquidity periods
* abnormal spreads
* low-volume chop

## Configurable Parameters

* session start/end times
* timezone handling
* session enable/disable flags

---

# MODULE 2 — SPREAD FILTER

Purpose:
Prevent low expectancy scalping entries.

## Rules

Do not trade if:

* spread exceeds configurable threshold
* spread spikes abnormally

## Features

* dynamic spread monitoring
* volatility-aware spread logic

---

# MODULE 3 — MARKET REGIME DETECTOR

Purpose:
Classify current market conditions before strategy activation.

## Possible Outputs

* TREND
* RANGE
* VOLATILE
* CHAOTIC
* DEAD

## Inputs

* ATR
* candle expansion
* volatility
* directional slope
* compression
* recent range behavior

## Notes

No strategy may execute before regime classification.

---

# MODULE 4 — STRATEGY ENGINE

System MUST support multiple strategy modules.

Each strategy only activates under valid regimes.

---

## STRATEGY A — TREND PULLBACK

### Objective

Join continuation after controlled pullback.

### Conditions

* EMA alignment
* directional momentum
* controlled retracement
* continuation confirmation

### Primary Regime

TREND

---

## STRATEGY B — MOMENTUM BREAKOUT

### Objective

Capture volatility expansion continuation.

### Conditions

* compression
* breakout
* impulse confirmation
* momentum continuation

### Primary Regime

VOLATILE TREND

---

## STRATEGY C — LIQUIDITY SWEEP REVERSAL

### Objective

Exploit stop-hunt reversals.

### Conditions

* sweep of previous high/low
* rejection behavior
* displacement candle
* reversal confirmation

### Primary Regime

RANGE / VOLATILE

---

## STRATEGY D — SESSION EXPANSION

### Objective

Capture London/NY expansion moves.

### Conditions

* Asian compression
* session breakout
* volatility expansion

### Primary Regime

SESSION OPEN

---

# MODULE 5 — CONFIDENCE SCORING ENGINE

Purpose:
Prevent weak entries.

## Example Scoring Components

* trend alignment
* session confluence
* ATR health
* spread quality
* breakout quality
* liquidity sweep quality
* volatility quality

## Output

0–100 confidence score.

## Trade Rule

Only execute above configurable confidence threshold.

---

# MODULE 6 — RISK ENGINE

Purpose:
Capital preservation and exposure control.

## Requirements

### Dynamic Position Sizing

* ATR-adjusted
* percentage risk-based
* no fixed lot dependency

### Max Risk Per Trade

Configurable:
0.25%–0.75%

### Daily Drawdown Protection

Example:
Stop trading after -3%.

### Consecutive Loss Protection

Cooldown after configurable losing streak.

### Simultaneous Exposure Protection

One-trade-at-a-time initially.

### News Lock

Optional future module.

---

# MODULE 7 — EXECUTION ENGINE

Purpose:
Reliable MT5 execution.

## Features

* market orders
* SL placement
* TP placement
* slippage handling
* execution retries
* spread validation before entry

---

# MODULE 8 — TRADE MANAGEMENT ENGINE

Purpose:
Manage open trades dynamically.

## Features

### Dynamic Stop Loss

ATR-based.

### Break-even Logic

Move SL after confirmation.

### Partial Profit Taking

Scale out position.

### Trailing Logic

Adaptive trailing stop.

### Time-based Exit

Optional forced exit logic.

---

# MODULE 9 — MULTI-TIMEFRAME ENGINE

Purpose:
Use higher timeframe context for lower timeframe execution.

## H1

Macro directional bias.

## M15

Structure and liquidity zones.

## M5

Setup preparation.

## M1

Execution trigger.

---

# MODULE 10 — LOGGING + ANALYTICS

Purpose:
Research, debugging, optimization.

## Required Logs

* trade entries
* exits
* confidence scores
* regime classification
* spread state
* ATR state
* session state
* strategy used
* PnL

## Export

CSV or JSON logs.

---

# NON-FUNCTIONAL REQUIREMENTS

## Code Quality

* modular
* readable
* maintainable
* documented
* extensible

## Performance

* low-latency decision handling
* minimal blocking logic
* optimized calculations

## Fault Tolerance

* handle MT5 disconnects
* handle broker issues
* fail safely

## Security

* no hardcoded credentials
* configurable settings

---

# CONFIGURATION REQUIREMENTS

All critical values MUST be configurable:

* risk %
* ATR periods
* EMA lengths
* confidence thresholds
* spread limits
* session windows
* cooldown timers
* TP/SL multipliers
* max daily loss
* max trades/day

---

# PHASED DEVELOPMENT PLAN

## VERSION 1

Core execution engine:

* regime detector
* trend pullback
* breakout engine
* liquidity sweep
* confidence scoring
* risk management
* logging

## VERSION 2

Enhancements:

* session expansion engine
* advanced trailing logic
* optimization framework
* dashboard analytics

## VERSION 3

Advanced:

* ML-assisted filtering
* news integration
* reinforcement learning research
* portfolio orchestration

---

# IMPORTANT CONSTRAINTS

The system MUST prioritize:

* robustness
* survivability
* disciplined execution

The system MUST avoid:

* overtrading
* curve-fit logic
* unrealistic backtest optimization
* martingale exposure
* grid recovery systems

---

# DELIVERABLES REQUIRED

1. Full MT5 Expert Advisor source code
2. Modular architecture
3. Separate strategy modules
4. Configurable parameters
5. Logging subsystem
6. Risk engine
7. Documentation
8. Backtesting instructions
9. Optimization instructions
10. Deployment guide

---

# FINAL OBJECTIVE

Build a robust, extensible, regime-aware XAUUSD autonomous scalping engine capable of:

* adaptive strategy selection
* controlled aggressive execution
* strong capital protection
* scalable future evolution
* institutional-grade architectural discipline
