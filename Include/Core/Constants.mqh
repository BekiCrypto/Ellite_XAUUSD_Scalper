#ifndef CONSTANTS_MQH
#define CONSTANTS_MQH

//+------------------------------------------------------------------+
//|                                                    Constants.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

//--- System Constants
#define SYSTEM_NAME "Elite XAUUSD Scalper"
#define SYSTEM_VERSION "1.00"
#define MAX_RETRY_ATTEMPTS 3

//--- Market Regimes
enum ENUM_MARKET_REGIME
  {
   REGIME_TREND,      // Strong directional movement
   REGIME_RANGE,      // Bound between clear S/R levels
   REGIME_VOLATILE,   // High ATR, choppy directional moves
   REGIME_CHAOTIC,    // High ATR, unpredictable/news-driven
   REGIME_DEAD        // Low ATR, no participation
  };

//--- Trading Sessions
enum ENUM_SESSION
  {
   SESSION_ASIAN,
   SESSION_LONDON,
   SESSION_NY,
   SESSION_OVERLAP_LON_NY,
   SESSION_ROLLOVER,
   SESSION_NONE
  };

//--- Strategy IDs
enum ENUM_STRATEGY_ID
  {
   STRATEGY_TREND_PULLBACK,
   STRATEGY_MOMENTUM_BREAKOUT,
   STRATEGY_LIQUIDITY_SWEEP,
   STRATEGY_SESSION_EXPANSION,
   STRATEGY_MEAN_REVERSION,
   STRATEGY_ORDER_BLOCK,
   STRATEGY_MANUAL
  };

//--- Signal Types
enum ENUM_SIGNAL_TYPE
  {
   SIGNAL_NONE,
   SIGNAL_BUY,
   SIGNAL_SELL
  };

//--- H1 macro directional bias (SDD Module 9: "H1: Macro directional bias")
enum ENUM_TREND_DIRECTION
  {
   TREND_UP,
   TREND_DOWN,
   TREND_NEUTRAL
  };

#endif
