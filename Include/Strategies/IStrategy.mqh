#ifndef ISTRATEGY_MQH
#define ISTRATEGY_MQH

//+------------------------------------------------------------------+
//|                                                    IStrategy.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"

// Base Interface for all strategy modules
class IStrategy
  {
protected:
   ENUM_STRATEGY_ID  m_strategyId;
   string            m_strategyName;

public:
                     IStrategy(ENUM_STRATEGY_ID id, string name) : m_strategyId(id), m_strategyName(name) {}
   virtual          ~IStrategy() {}

   // Initialization (e.g., indicator setup)
   virtual bool      Initialize() = 0;
   
   // Returns true if the strategy is allowed to trade in the current regime
   virtual bool      IsRegimeAllowed(ENUM_MARKET_REGIME regime) = 0;

   // Analyzes the market and returns a trade signal
   virtual STradeSignal Evaluate(SMarketEnvironment &env) = 0;
   
   // Accessors
   ENUM_STRATEGY_ID  GetId() const { return m_strategyId; }
   string            GetName() const { return m_strategyName; }
  };

#endif
