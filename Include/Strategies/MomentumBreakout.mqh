#ifndef MOMENTUMBREAKOUT_MQH
#define MOMENTUMBREAKOUT_MQH

//+------------------------------------------------------------------+
//|                                             MomentumBreakout.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "IStrategy.mqh"
#include "../Core/Logger.mqh"

class CMomentumBreakout : public IStrategy
  {
private:
   int               m_bbandsHandle;
   double            m_upperBuffer[];
   double            m_lowerBuffer[];
   double            m_middleBuffer[];

public:
                     CMomentumBreakout() : IStrategy(STRATEGY_MOMENTUM_BREAKOUT, "Momentum Breakout")
                       {
                        ArraySetAsSeries(m_upperBuffer, true);
                        ArraySetAsSeries(m_lowerBuffer, true);
                        ArraySetAsSeries(m_middleBuffer, true);
                       }
                    ~CMomentumBreakout()
                       {
                        IndicatorRelease(m_bbandsHandle);
                       }

   virtual bool      Initialize() override
     {
      m_bbandsHandle = iBands(_Symbol, PERIOD_M5, 20, 0, 2.0, PRICE_CLOSE);
      if(m_bbandsHandle == INVALID_HANDLE) return false;
      return true;
     }

   virtual bool      IsRegimeAllowed(ENUM_MARKET_REGIME regime) override
     {
      // Breakouts are best transitioning from RANGE to VOLATILE or early TREND
      return (regime == REGIME_RANGE || regime == REGIME_VOLATILE || regime == REGIME_TREND);
     }

   virtual STradeSignal Evaluate(SMarketEnvironment &env) override
     {
      STradeSignal signal;
      signal.strategyId = m_strategyId;
      signal.signalType = SIGNAL_NONE;
      signal.confidence = 0.0;
      
      if(!IsRegimeAllowed(env.regime)) return signal;
      
      if(CopyBuffer(m_bbandsHandle, 1, 1, 2, m_upperBuffer) <= 0) return signal;
      if(CopyBuffer(m_bbandsHandle, 2, 1, 2, m_lowerBuffer) <= 0) return signal;
      
      double close1 = iClose(_Symbol, PERIOD_M5, 1);
      double open1 = iOpen(_Symbol, PERIOD_M5, 1);
      
      double upper1 = m_upperBuffer[0];
      double lower1 = m_lowerBuffer[0];
      double bandWidth = upper1 - lower1;
      
      // Look for Bollinger Band Squeeze expansion (implied by current strong candle breaking outside)
      // Check if previous candle broke upper band with strong momentum
      if(close1 > upper1 && (close1 - open1) > (env.atrM5 * 0.8))
        {
         signal.signalType = SIGNAL_BUY;
         signal.confidence = 75.0; // Needs adjustment by ConfidenceEngine
         signal.suggestedSL = lower1; // SL at lower band or middle band
         double tpMultiplier = (env.regime == REGIME_TREND) ? 6.0 : 4.5;
         signal.suggestedTP = close1 + (bandWidth * tpMultiplier);
         signal.comment = m_strategyName + " Buy";
        }
      else if(close1 < lower1 && (open1 - close1) > (env.atrM5 * 0.8))
        {
         signal.signalType = SIGNAL_SELL;
         signal.confidence = 75.0;
         signal.suggestedSL = upper1;
         double tpMultiplier = (env.regime == REGIME_TREND) ? 6.0 : 4.5;
         signal.suggestedTP = close1 - (bandWidth * tpMultiplier);
         signal.comment = m_strategyName + " Sell";
        }
        
      return signal;
     }
  };

#endif
