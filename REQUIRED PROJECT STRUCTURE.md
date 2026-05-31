# REQUIRED PROJECT STRUCTURE

The MT5 EA project MUST use modular architecture.

Recommended structure:

/Experts
EliteXAUScalper.mq5

/Include/Core
Config.mqh
Constants.mqh
Types.mqh
Logger.mqh
Utilities.mqh

/Include/Filters
SessionFilter.mqh
SpreadFilter.mqh
RegimeDetector.mqh

/Include/Strategies
TrendPullback.mqh
MomentumBreakout.mqh
LiquiditySweep.mqh
SessionExpansion.mqh

/Include/Risk
RiskEngine.mqh
PositionSizing.mqh
DrawdownProtection.mqh

/Include/Execution
TradeExecutor.mqh
TradeManager.mqh
SlippageControl.mqh

/Include/Analytics
ConfidenceEngine.mqh
StatisticsEngine.mqh
PerformanceTracker.mqh

/Files
logs/
analytics/
configs/

Architecture Requirements:

* No monolithic EA logic
* No giant OnTick spaghetti
* Use clear state machines
* Use explicit enums and types
* All parameters configurable
* Strong logging at every decision point

Main EA responsibilities:

* orchestration only
* module coordination
* execution sequencing

Strategy modules MUST remain isolated and independently testable.
