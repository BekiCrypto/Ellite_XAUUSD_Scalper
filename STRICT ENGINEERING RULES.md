# STRICT ENGINEERING RULES

The system MUST NOT use:

* martingale
* grid averaging
* averaging losers
* infinite recovery logic
* fake high-win-rate optimization
* repainting indicators
* excessive indicator stacking
* curve-fit-only parameters
* overtrading logic
* always-in-market logic

The system MUST prioritize:

* survivability
* modularity
* clean architecture
* deterministic behavior
* low coupling
* explicit state management
* strict risk governance
* configurable parameters
* clear logging
* maintainability

The codebase MUST be:

* modular
* production-oriented
* extensible
* fully commented
* separated by responsibility

Each module MUST be isolated:

* regime detection
* strategy engines
* confidence engine
* risk engine
* execution engine
* trade management
* session handling
* logging

The system MUST support:

* M1/M3/M5 execution
* H1/M15 context filtering
* one-trade-at-a-time initially
* ATR-adjusted sizing
* dynamic stop loss
* dynamic take profit
* spread filtering
* session filtering
* confidence-based execution

The system MUST avoid overfitting.

Backtests MUST prioritize:

* robustness
* stability
* drawdown control
* cross-period survivability

The system MUST be optimized specifically for:

* XAUUSD
* IC Markets MT5
* London session
* New York session
* lower timeframe scalping

Execution quality matters more than signal frequency.
