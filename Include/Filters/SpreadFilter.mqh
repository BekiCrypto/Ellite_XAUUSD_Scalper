#ifndef SPREADFILTER_MQH
#define SPREADFILTER_MQH

//+------------------------------------------------------------------+
//|                                                 SpreadFilter.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Config.mqh"
#include "../Core/Utilities.mqh"

class CSpreadFilter
  {
private:
   int               m_smaHandle;
   double            m_spreadSMA[];
   
public:
                     CSpreadFilter()
                       {
                        ArraySetAsSeries(m_spreadSMA, true);
                       }
                    ~CSpreadFilter() {}

   // Simple check against max allowed spread
   bool              IsSpreadAcceptable()
     {
      int currentSpread = CUtilities::GetCurrentSpread();
      int maxAllowed = GlobalConfig.GetMaxSpreadPoints();
      
      if(currentSpread <= maxAllowed)
         return true;
         
      return false;
     }
     
   // Can be expanded to calculate rolling average of spread over last N ticks
   // to detect sudden spread widening indicative of toxic flow or news.
   bool              IsSpreadHealthy(int currentSpread, double atrM5 = 0.0)
     {
      int maxAllowed = GlobalConfig.GetMaxSpreadPoints();
      
      // Dynamic Volatility Expansion: if volatility is high, allow a wider spread up to 1.5x of base limit
      if(atrM5 > 0.0)
        {
         // 1.0 ATR point on XAUUSD represents a $1.00 M5 price range (100 points).
         // If volatility is > 1.0, we expand acceptable spread by a factor of volatility
         double baselineATR = 1.0;
         if(atrM5 > baselineATR)
           {
            double scale = MathMin(1.5, atrM5 / baselineATR);
            maxAllowed = (int)(maxAllowed * scale);
           }
        }
      return (currentSpread <= maxAllowed);
     }
  };

#endif
