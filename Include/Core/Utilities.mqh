#ifndef UTILITIES_MQH
#define UTILITIES_MQH

//+------------------------------------------------------------------+
//|                                                    Utilities.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

class CUtilities
  {
public:
   // Normalize price to instrument digits
   static double     NormalizePrice(double price)
     {
      return NormalizeDouble(price, _Digits);
     }

   // Convert points to real price double
   static double     PointsToPrice(int points)
     {
      return points * _Point;
     }

   // Convert pip value to points (Assuming 1 pip = 10 points for standard forex, but XAUUSD is different)
   // Usually 1 pip = 10 points in XAUUSD as well if Digits=2, but can be 100 if Digits=3.
   // We will rely on Points directly for safety.
   static int        PriceDifferenceInPoints(double price1, double price2)
     {
      return (int)MathRound(MathAbs(price1 - price2) / _Point);
     }
     
   // Get current spread in points
   static int        GetCurrentSpread()
     {
      return (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
     }
     
   // Get Tick Value
   static double     GetTickValue()
     {
      return SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
     }
  };

#endif
