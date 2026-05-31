#ifndef ORDERBLOCK_MQH
#define ORDERBLOCK_MQH

//+------------------------------------------------------------------+
//|                                                   OrderBlock.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "IStrategy.mqh"
#include "../Core/Logger.mqh"

class COrderBlock : public IStrategy
  {
private:
   int               m_lookback;

public:
                     COrderBlock() : IStrategy(STRATEGY_ORDER_BLOCK, "Order Block Mitigation")
                       {
                        m_lookback = 5; // Look back up to 5 M5 bars to find unmitigated FVGs
                       }
                    ~COrderBlock()
                       {
                        ObjectDelete(0, "OB_FVG_Top");
                        ObjectDelete(0, "OB_FVG_Bottom");
                       }

   virtual bool      Initialize() override
     {
      return true;
     }

   virtual bool      IsRegimeAllowed(ENUM_MARKET_REGIME regime) override
     {
      // FVG pullbacks are trend-continuation / structure-ride setups
      return (regime == REGIME_TREND || regime == REGIME_VOLATILE);
     }

   virtual STradeSignal Evaluate(SMarketEnvironment &env) override
     {
      STradeSignal signal;
      signal.strategyId = m_strategyId;
      signal.signalType = SIGNAL_NONE;
      signal.confidence = 0.0;
      
      if(!IsRegimeAllowed(env.regime))
        {
         ObjectDelete(0, "OB_FVG_Top");
         ObjectDelete(0, "OB_FVG_Bottom");
         return signal;
        }
      
      bool fvgFound = false;
      
      // Look back for active, unmitigated Fair Value Gaps (FVG) / Imbalances
      for(int i = 2; i <= m_lookback; i++)
        {
         double openI  = iOpen(_Symbol, PERIOD_M5, i);
         double closeI = iClose(_Symbol, PERIOD_M5, i);
         double highI  = iHigh(_Symbol, PERIOD_M5, i);
         double lowI   = iLow(_Symbol, PERIOD_M5, i);
         
         double highIP1 = iHigh(_Symbol, PERIOD_M5, i + 1); // Candle before displacement
         double lowIM1  = iLow(_Symbol, PERIOD_M5, i - 1);  // Candle after displacement
         
         double bodySize = MathAbs(closeI - openI);
         
         // 1. BULLISH FVG / ORDER BLOCK DISPLACEMENT DETECTED AT BAR i
         if(closeI > openI && bodySize > env.atrM5 * 1.2)
           {
            // Check if there is an open FVG gap between Candle i-1 Low and Candle i+1 High
            if(lowIM1 > highIP1)
              {
               // Active FVG range: Bottom = highIP1, Top = lowIM1
               double fvgBottom = highIP1;
               double fvgTop = lowIM1;
               
               // Check if it has been invalidated / fully mitigated by any intermediate candle
               bool isMitigated = false;
               for(int k = i - 1; k > 1; k--)
                 {
                  if(iClose(_Symbol, PERIOD_M5, k) < fvgBottom)
                    {
                     isMitigated = true;
                     break;
                    }
                 }
               
               if(!isMitigated)
                 {
                  if(!fvgFound)
                    {
                     fvgFound = true;
                     ObjectDelete(0, "OB_FVG_Top");
                     ObjectCreate(0, "OB_FVG_Top", OBJ_HLINE, 0, 0, fvgTop);
                     ObjectSetInteger(0, "OB_FVG_Top", OBJPROP_COLOR, clrDodgerBlue);
                     ObjectSetInteger(0, "OB_FVG_Top", OBJPROP_STYLE, STYLE_DASH);
                     ObjectSetString(0, "OB_FVG_Top", OBJPROP_TEXT, "Bullish FVG Top");
                     ObjectSetInteger(0, "OB_FVG_Top", OBJPROP_SELECTABLE, false);
                     
                     ObjectDelete(0, "OB_FVG_Bottom");
                     ObjectCreate(0, "OB_FVG_Bottom", OBJ_HLINE, 0, 0, fvgBottom);
                     ObjectSetInteger(0, "OB_FVG_Bottom", OBJPROP_COLOR, clrDodgerBlue);
                     ObjectSetInteger(0, "OB_FVG_Bottom", OBJPROP_STYLE, STYLE_DASH);
                     ObjectSetString(0, "OB_FVG_Bottom", OBJPROP_TEXT, "Bullish FVG Bottom");
                     ObjectSetInteger(0, "OB_FVG_Bottom", OBJPROP_SELECTABLE, false);
                    }
                  
                  // Recently closed candle (Candle 1) pulled back into FVG and closed bullish
                  double close1 = iClose(_Symbol, PERIOD_M5, 1);
                  double open1  = iOpen(_Symbol, PERIOD_M5, 1);
                  double low1   = iLow(_Symbol, PERIOD_M5, 1);
                  
                  if(low1 <= fvgTop && low1 >= fvgBottom && close1 > open1)
                    {
                     signal.signalType = SIGNAL_BUY;
                     signal.confidence = 80.0;
                     signal.suggestedSL = fvgBottom - (env.atrM5 * 0.5); // SL safely below FVG invalidation
                     double tpMultiplier = (env.regime == REGIME_TREND) ? 6.5 : 4.5;
                     signal.suggestedTP = close1 + (env.atrM5 * tpMultiplier);    // Ride the expansion
                     signal.comment = m_strategyName + " Buy";
                     break; // Trigger found
                    }
                 }
              }
           }
         // 2. BEARISH FVG / ORDER BLOCK DISPLACEMENT DETECTED AT BAR i
         else if(closeI < openI && bodySize > env.atrM5 * 1.2)
           {
            // Check if there is an open FVG gap between Candle i-1 High and Candle i+1 Low
            double lowIP1  = iLow(_Symbol, PERIOD_M5, i + 1); // Candle before displacement
            double highIM1 = iHigh(_Symbol, PERIOD_M5, i - 1); // Candle after displacement
            
            if(highIM1 < lowIP1)
              {
               // Active FVG range: Top = lowIP1, Bottom = highIM1
               double fvgTop = lowIP1;
               double fvgBottom = highIM1;
               
               // Check if it has been invalidated / fully mitigated by any intermediate candle
               bool isMitigated = false;
               for(int k = i - 1; k > 1; k--)
                 {
                  if(iClose(_Symbol, PERIOD_M5, k) > fvgTop)
                    {
                     isMitigated = true;
                     break;
                    }
                 }
               
               if(!isMitigated)
                 {
                  if(!fvgFound)
                    {
                     fvgFound = true;
                     ObjectDelete(0, "OB_FVG_Top");
                     ObjectCreate(0, "OB_FVG_Top", OBJ_HLINE, 0, 0, fvgTop);
                     ObjectSetInteger(0, "OB_FVG_Top", OBJPROP_COLOR, clrRed);
                     ObjectSetInteger(0, "OB_FVG_Top", OBJPROP_STYLE, STYLE_DASH);
                     ObjectSetString(0, "OB_FVG_Top", OBJPROP_TEXT, "Bearish FVG Top");
                     ObjectSetInteger(0, "OB_FVG_Top", OBJPROP_SELECTABLE, false);
                     
                     ObjectDelete(0, "OB_FVG_Bottom");
                     ObjectCreate(0, "OB_FVG_Bottom", OBJ_HLINE, 0, 0, fvgBottom);
                     ObjectSetInteger(0, "OB_FVG_Bottom", OBJPROP_COLOR, clrRed);
                     ObjectSetInteger(0, "OB_FVG_Bottom", OBJPROP_STYLE, STYLE_DASH);
                     ObjectSetString(0, "OB_FVG_Bottom", OBJPROP_TEXT, "Bearish FVG Bottom");
                     ObjectSetInteger(0, "OB_FVG_Bottom", OBJPROP_SELECTABLE, false);
                    }
                  
                  // Recently closed candle (Candle 1) pulled back into FVG and closed bearish
                  double close1 = iClose(_Symbol, PERIOD_M5, 1);
                  double open1  = iOpen(_Symbol, PERIOD_M5, 1);
                  double high1  = iHigh(_Symbol, PERIOD_M5, 1);
                  
                  if(high1 >= fvgBottom && high1 <= fvgTop && close1 < open1)
                    {
                     signal.signalType = SIGNAL_SELL;
                     signal.confidence = 80.0;
                     signal.suggestedSL = fvgTop + (env.atrM5 * 0.5); // SL safely above FVG invalidation
                     double tpMultiplier = (env.regime == REGIME_TREND) ? 6.5 : 4.5;
                     signal.suggestedTP = close1 - (env.atrM5 * tpMultiplier);
                     signal.comment = m_strategyName + " Sell";
                     break;
                    }
                 }
              }
           }
        }
      
      if(!fvgFound)
        {
         ObjectDelete(0, "OB_FVG_Top");
         ObjectDelete(0, "OB_FVG_Bottom");
        }
        
      return signal;
     }
  };

#endif

