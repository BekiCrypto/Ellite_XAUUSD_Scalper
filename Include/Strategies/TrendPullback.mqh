#ifndef TRENDPULLBACK_MQH
#define TRENDPULLBACK_MQH

//+------------------------------------------------------------------+
//|                                                TrendPullback.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "IStrategy.mqh"
#include "../Core/Logger.mqh"

class CTrendPullback : public IStrategy
  {
private:
   int               m_emaFastHandle;
   int               m_emaSlowHandle;
   double            m_emaFastBuffer[];
   double            m_emaSlowBuffer[];

public:
                     CTrendPullback() : IStrategy(STRATEGY_TREND_PULLBACK, "Trend Pullback")
                       {
                        ArraySetAsSeries(m_emaFastBuffer, true);
                        ArraySetAsSeries(m_emaSlowBuffer, true);
                       }
                    ~CTrendPullback()
                       {
                        IndicatorRelease(m_emaFastHandle);
                        IndicatorRelease(m_emaSlowHandle);
                       }
   int               GetEMAFastHandle() const { return m_emaFastHandle; }
   int               GetEMASlowHandle() const { return m_emaSlowHandle; }

   virtual bool      Initialize() override
     {
      m_emaFastHandle = iMA(_Symbol, PERIOD_M5, 9, 0, MODE_EMA, PRICE_CLOSE);
      m_emaSlowHandle = iMA(_Symbol, PERIOD_M5, 21, 0, MODE_EMA, PRICE_CLOSE);
      
      if(m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE)
         return false;
      return true;
     }

   virtual bool      IsRegimeAllowed(ENUM_MARKET_REGIME regime) override
     {
      return (regime == REGIME_TREND || regime == REGIME_VOLATILE);
     }

   virtual STradeSignal Evaluate(SMarketEnvironment &env) override
     {
      STradeSignal signal;
      signal.strategyId = m_strategyId;
      signal.signalType = SIGNAL_NONE;
      signal.confidence = 0.0;
      
      if(!IsRegimeAllowed(env.regime)) return signal;
      
      if(CopyBuffer(m_emaFastHandle, 0, 1, 2, m_emaFastBuffer) <= 0) return signal;
      if(CopyBuffer(m_emaSlowHandle, 0, 1, 2, m_emaSlowBuffer) <= 0) return signal;
      
      double close1 = iClose(_Symbol, PERIOD_M5, 1);
      double close2 = iClose(_Symbol, PERIOD_M5, 2);
      
      double fastEma = m_emaFastBuffer[0];
      double slowEma = m_emaSlowBuffer[0];
      
      // Basic logic: Fast EMA > Slow EMA (Uptrend) -> Price pulls back to Fast EMA -> Rejection (Close > Fast EMA)
      if(fastEma > slowEma)
        {
         if(close2 < fastEma && close1 > fastEma)
           {
            signal.signalType = SIGNAL_BUY;
            signal.confidence = 80.0;
            signal.suggestedSL = slowEma - (env.atrM5 * 0.5); // SL below slow EMA
            double tpMultiplier = (env.regime == REGIME_TREND) ? 6.5 : 4.5;
            signal.suggestedTP = close1 + (env.atrM5 * tpMultiplier);  // Extended TP for trailing
            signal.comment = m_strategyName + " Buy";
           }
        }
      else if(fastEma < slowEma)
        {
         if(close2 > fastEma && close1 < fastEma)
           {
            signal.signalType = SIGNAL_SELL;
            signal.confidence = 80.0;
            signal.suggestedSL = slowEma + (env.atrM5 * 0.5);
            double tpMultiplier = (env.regime == REGIME_TREND) ? 6.5 : 4.5;
            signal.suggestedTP = close1 - (env.atrM5 * tpMultiplier);
            signal.comment = m_strategyName + " Sell";
           }
        }
        
      return signal;
     }
  };

#endif
