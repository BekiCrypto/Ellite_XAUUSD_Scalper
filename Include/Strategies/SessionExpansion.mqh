#ifndef SESSIONEXPANSION_MQH
#define SESSIONEXPANSION_MQH

//+------------------------------------------------------------------+
//|                                             SessionExpansion.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "IStrategy.mqh"
#include "../Core/Logger.mqh"

class CSessionExpansion : public IStrategy
  {
private:
   double            m_asianHigh;
   double            m_asianLow;
   bool              m_asianMapped;

public:
                     CSessionExpansion() : IStrategy(STRATEGY_SESSION_EXPANSION, "Session Expansion")
                       {
                        m_asianHigh = 0;
                        m_asianLow = 0;
                        m_asianMapped = false;
                       }
                    ~CSessionExpansion()
                       {
                        ObjectDelete(0, "Asian_High");
                        ObjectDelete(0, "Asian_Low");
                       }

   virtual bool      Initialize() override
      {
       return true;
      }

   virtual bool      IsRegimeAllowed(ENUM_MARKET_REGIME regime) override
      {
       // Valid mostly in RANGE and VOLATILE going into session open
       return (regime != REGIME_DEAD && regime != REGIME_CHAOTIC);
      }

   virtual STradeSignal Evaluate(SMarketEnvironment &env) override
     {
      STradeSignal signal;
      signal.strategyId = m_strategyId;
      signal.signalType = SIGNAL_NONE;
      signal.confidence = 0.0;
      
      if(!IsRegimeAllowed(env.regime)) return signal;
      
      // Reset mapping in Asian session
      if(env.session == SESSION_ASIAN)
        {
         m_asianMapped = false;
         ObjectDelete(0, "Asian_High");
         ObjectDelete(0, "Asian_Low");
         return signal;
        }
        
      // Map Asian Range if we are in London/NY and haven't mapped yet today
      if(!m_asianMapped && (env.session == SESSION_LONDON || env.session == SESSION_NY || env.session == SESSION_OVERLAP_LON_NY))
        {
         // Find highest high and lowest low of the last 8 hours (approx Asian session)
         int startBar = 0; // Current
         int endBar = 8 * 4; // 8 hours * 4 (M15 bars) = 32 bars ago
         
         m_asianHigh = iHigh(_Symbol, PERIOD_M15, iHighest(_Symbol, PERIOD_M15, MODE_HIGH, endBar, startBar));
         m_asianLow = iLow(_Symbol, PERIOD_M15, iLowest(_Symbol, PERIOD_M15, MODE_LOW, endBar, startBar));
         m_asianMapped = true;
         
         // Create Visual Asian Range Lines on Chart
         ObjectDelete(0, "Asian_High");
         ObjectCreate(0, "Asian_High", OBJ_HLINE, 0, 0, m_asianHigh);
         ObjectSetInteger(0, "Asian_High", OBJPROP_COLOR, clrMediumOrchid);
         ObjectSetInteger(0, "Asian_High", OBJPROP_STYLE, STYLE_DOT);
         ObjectSetString(0, "Asian_High", OBJPROP_TEXT, "Asian Session High");
         ObjectSetInteger(0, "Asian_High", OBJPROP_SELECTABLE, false);
         
         ObjectDelete(0, "Asian_Low");
         ObjectCreate(0, "Asian_Low", OBJ_HLINE, 0, 0, m_asianLow);
         ObjectSetInteger(0, "Asian_Low", OBJPROP_COLOR, clrMediumOrchid);
         ObjectSetInteger(0, "Asian_Low", OBJPROP_STYLE, STYLE_DOT);
         ObjectSetString(0, "Asian_Low", OBJPROP_TEXT, "Asian Session Low");
         ObjectSetInteger(0, "Asian_Low", OBJPROP_SELECTABLE, false);
        }
        
      if(m_asianMapped)
        {
         double close1 = iClose(_Symbol, PERIOD_M5, 1);
         double open1 = iOpen(_Symbol, PERIOD_M5, 1);
         
         // London/NY Open Breakout
         if(close1 > m_asianHigh && open1 <= m_asianHigh)
           {
            signal.signalType = SIGNAL_BUY;
            signal.confidence = 75.0;
            signal.suggestedSL = m_asianLow + ((m_asianHigh - m_asianLow) * 0.5); // 50% of Asian range
            signal.suggestedTP = close1 + ((m_asianHigh - m_asianLow) * 5.0); // 5.0x Asian range expansion
            signal.comment = m_strategyName + " Buy";
            
            // Invalidate to prevent multiple entries
            m_asianMapped = false;
           }
         else if(close1 < m_asianLow && open1 >= m_asianLow)
           {
            signal.signalType = SIGNAL_SELL;
            signal.confidence = 75.0;
            signal.suggestedSL = m_asianHigh - ((m_asianHigh - m_asianLow) * 0.5);
            signal.suggestedTP = close1 - ((m_asianHigh - m_asianLow) * 5.0);
            signal.comment = m_strategyName + " Sell";
            
            m_asianMapped = false;
           }
        }
        
      return signal;
     }
  };

#endif
