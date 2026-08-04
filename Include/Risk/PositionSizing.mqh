#ifndef POSITIONSIZING_MQH
#define POSITIONSIZING_MQH

//+------------------------------------------------------------------+
//|                                               PositionSizing.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Config.mqh"
#include "../Core/Constants.mqh"
#include "../Core/Utilities.mqh"

class CPositionSizing
  {
public:
                     CPositionSizing() {}
                    ~CPositionSizing() {}

   // Calculate lot size based on account balance, risk %, and stop loss distance
   static double     CalculateLotSize(double entryPrice, double stopLossPrice, double confidence = 100.0, ENUM_MARKET_REGIME regime = REGIME_TREND)
     {
      double riskPercent = GlobalConfig.GetRiskPercent();
      
      // Scale risk based on confidence (e.g. 75% confidence scales risk down by 25%)
      if(confidence < 100.0)
        {
         double confidenceFactor = confidence / 100.0;
         riskPercent *= confidenceFactor;
        }
        
      // Scale risk based on market regime
      if(regime == REGIME_VOLATILE)
        {
         riskPercent *= 0.5; // Volatile markets require smaller sizing
        }
      else if(regime == REGIME_CHAOTIC)
        {
         riskPercent *= 0.25; // Chaotic markets require extremely tiny sizing
        }
      else if(regime == REGIME_DEAD)
        {
         return 0.0; // Block completely in dead environments
        }
      
      if(riskPercent <= 0.0 || stopLossPrice == 0.0 || entryPrice == 0.0)
         return 0.0;
         
      double slPoints = MathAbs(entryPrice - stopLossPrice) / _Point;
      if(slPoints == 0) return 0.0;
      
      double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskAmount = accountBalance * (riskPercent / 100.0);
      
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize == 0 || tickValue == 0) return 0.0;
      
      double slDistanceRaw = MathAbs(entryPrice - stopLossPrice);
      if(slDistanceRaw == 0) return 0.0;
      
      double moneyPerLotForSL = (slDistanceRaw / tickSize) * tickValue;
      if(moneyPerLotForSL == 0) return 0.0;
      
      double lotSize = riskAmount / moneyPerLotForSL;
      
      // Normalize lot size to broker limits and user-defined minimum
      double brokerMinLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double userMinLot = GlobalConfig.GetMinLotSize();
      double minLot = MathMax(brokerMinLot, userMinLot);
      
      double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      
      lotSize = MathFloor(lotSize / stepLot) * stepLot;
      
      if(lotSize < minLot) lotSize = minLot;
      if(lotSize > maxLot) lotSize = maxLot;

      return lotSize;
     }

   // Sum of money at risk (entry-to-SL distance) across all open EA positions, as % of balance.
   // Used for Simultaneous Exposure Protection: caps aggregate risk across concurrent positions,
   // not just the risk of each individual trade in isolation.
   static double     GetOpenRiskPercent()
     {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(balance <= 0.0) return 0.0;

      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      if(tickSize <= 0.0 || tickValue <= 0.0) return 0.0;

      double totalRiskMoney = 0.0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0) continue;
         if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
         if((ulong)PositionGetInteger(POSITION_MAGIC) != GlobalConfig.GetMagicNumber()) continue;

         double sl = PositionGetDouble(POSITION_SL);
         if(sl == 0.0) continue; // no stop attached; can't quantify, don't block on the unknown

         double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
         double volume = PositionGetDouble(POSITION_VOLUME);
         double slDistance = MathAbs(openPrice - sl);

         totalRiskMoney += (slDistance / tickSize) * tickValue * volume;
        }

      return (totalRiskMoney / balance) * 100.0;
     }
  };

#endif
