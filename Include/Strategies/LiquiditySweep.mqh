#ifndef LIQUIDITYSWEEP_MQH
#define LIQUIDITYSWEEP_MQH

//+------------------------------------------------------------------+
//|                                               LiquiditySweep.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "IStrategy.mqh"
#include "../Core/Logger.mqh"

class CLiquiditySweep : public IStrategy
  {
private:
   int               m_lookbackPeriods;

public:
                     CLiquiditySweep() : IStrategy(STRATEGY_LIQUIDITY_SWEEP, "Liquidity Sweep")
                       {
                        m_lookbackPeriods = 20; // Lookback for swing highs/lows
                       }
                    ~CLiquiditySweep()
                       {
                        ObjectDelete(0, "Sweep_High");
                        ObjectDelete(0, "Sweep_Low");
                       }

   virtual bool      Initialize() override
     {
      return true;
     }

   virtual bool      IsRegimeAllowed(ENUM_MARKET_REGIME regime) override
     {
      // Sweeps are best in RANGE and VOLATILE regimes (stop hunts)
      return (regime == REGIME_RANGE || regime == REGIME_VOLATILE || regime == REGIME_CHAOTIC);
     }

   virtual STradeSignal Evaluate(SMarketEnvironment &env) override
     {
      STradeSignal signal;
      signal.strategyId = m_strategyId;
      signal.signalType = SIGNAL_NONE;
      signal.confidence = 0.0;
      
      if(!IsRegimeAllowed(env.regime)) return signal;
      
      // Basic Logic: Find highest high over M15 lookback
      double highestHigh = iHigh(_Symbol, PERIOD_M15, iHighest(_Symbol, PERIOD_M15, MODE_HIGH, m_lookbackPeriods, 2));
      double lowestLow = iLow(_Symbol, PERIOD_M15, iLowest(_Symbol, PERIOD_M15, MODE_LOW, m_lookbackPeriods, 2));
      
      // Create Sweep Target Levels on Chart
      ObjectDelete(0, "Sweep_High");
      ObjectCreate(0, "Sweep_High", OBJ_HLINE, 0, 0, highestHigh);
      ObjectSetInteger(0, "Sweep_High", OBJPROP_COLOR, clrDarkOrange);
      ObjectSetInteger(0, "Sweep_High", OBJPROP_STYLE, STYLE_DASHDOT);
      ObjectSetString(0, "Sweep_High", OBJPROP_TEXT, "Sweep Target High");
      ObjectSetInteger(0, "Sweep_High", OBJPROP_SELECTABLE, false);
      
      ObjectDelete(0, "Sweep_Low");
      ObjectCreate(0, "Sweep_Low", OBJ_HLINE, 0, 0, lowestLow);
      ObjectSetInteger(0, "Sweep_Low", OBJPROP_COLOR, clrDarkOrange);
      ObjectSetInteger(0, "Sweep_Low", OBJPROP_STYLE, STYLE_DASHDOT);
      ObjectSetString(0, "Sweep_Low", OBJPROP_TEXT, "Sweep Target Low");
      ObjectSetInteger(0, "Sweep_Low", OBJPROP_SELECTABLE, false);
      
      double close1 = iClose(_Symbol, PERIOD_M5, 1);
      double high1 = iHigh(_Symbol, PERIOD_M5, 1);
      double low1 = iLow(_Symbol, PERIOD_M5, 1);
      
      // Sweep High (Stop Hunt): Price went above recent highest high, but closed below it (pin bar / rejection)
      if(high1 > highestHigh && close1 < highestHigh)
        {
         // Strong rejection?
         if((high1 - close1) > (env.atrM5 * 0.7))
           {
            signal.signalType = SIGNAL_SELL;
            signal.confidence = 85.0; // High confidence setup
            signal.suggestedSL = high1 + (env.atrM5 * 0.2); // SL just above the sweep wick
            signal.suggestedTP = close1 - (env.atrM15 * 5.0); // Target significantly lower for trailing
            signal.comment = m_strategyName + " Sell";
           }
        }
      // Sweep Low: Price went below recent lowest low, but closed above it
      else if(low1 < lowestLow && close1 > lowestLow)
        {
         if((close1 - low1) > (env.atrM5 * 0.7))
           {
            signal.signalType = SIGNAL_BUY;
            signal.confidence = 80.0;
            signal.suggestedSL = low1 - (env.atrM5 * 0.2);
            signal.suggestedTP = close1 + (env.atrM15 * 5.0); // Target significantly higher for trailing
            signal.comment = m_strategyName + " Buy";
           }
        }
        
      return signal;
     }
  };

#endif
