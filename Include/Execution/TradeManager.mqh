#ifndef TRADEMANAGER_MQH
#define TRADEMANAGER_MQH

//+------------------------------------------------------------------+
//|                                                 TradeManager.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include "../Core/Logger.mqh"
#include "../Core/Utilities.mqh"

class CTradeManager
  {
private:
   CTrade            m_trade;
   CPositionInfo     m_position;

public:
                     CTradeManager()
                       {
                        m_trade.SetExpertMagicNumber(GlobalConfig.GetMagicNumber());
                       }
                    ~CTradeManager() {}

   // Call this every tick to manage open positions
   void              ManageOpenPositions(double atrM5)
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber())
              {
               ApplyTrailingStop(atrM5);
               ApplyBreakEven();
              }
           }
        }
     }

   void              CloseAll()
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber())
              {
               m_trade.PositionClose(m_position.Ticket());
              }
           }
        }
      Log.Warning("EMERGENCY CLOSE ALL executed.");
     }

   void              CloseBuys()
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber() && m_position.PositionType() == POSITION_TYPE_BUY)
              {
               m_trade.PositionClose(m_position.Ticket());
              }
           }
        }
      Log.Warning("CLOSED ALL BUYS.");
     }

   void              CloseSells()
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber() && m_position.PositionType() == POSITION_TYPE_SELL)
              {
               m_trade.PositionClose(m_position.Ticket());
              }
           }
        }
      Log.Warning("CLOSED ALL SELLS.");
     }

   void              ClosePosition(ulong ticket)
     {
      m_trade.PositionClose(ticket);
      Log.Warning("CLOSED POSITION #" + IntegerToString(ticket));
     }

   void              MoveAllToBreakEven()
     {
      int count = 0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber())
              {
               double openPrice = m_position.PriceOpen();
               double currentSL = m_position.StopLoss();
               if(m_position.PositionType() == POSITION_TYPE_BUY)
                 {
                  if(currentSL < openPrice)
                    {
                     m_trade.PositionModify(m_position.Ticket(), openPrice, m_position.TakeProfit());
                     count++;
                    }
                 }
               else if(m_position.PositionType() == POSITION_TYPE_SELL)
                 {
                  if(currentSL == 0.0 || currentSL > openPrice)
                    {
                     m_trade.PositionModify(m_position.Ticket(), openPrice, m_position.TakeProfit());
                     count++;
                    }
                 }
              }
           }
        }
      Log.Info("Manual Break-Even executed. Modified " + IntegerToString(count) + " positions.");
     }

   double            GetFloatingPips()
     {
      double pips = 0.0;
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber())
              {
               double open = m_position.PriceOpen();
               double current = m_position.PriceCurrent();
               if(m_position.PositionType() == POSITION_TYPE_BUY)
                  pips += ((current - open) / _Point) / 10.0;
               else
                  pips += ((open - current) / _Point) / 10.0;
              }
           }
        }
      return pips;
     }

   string            GetTrailStatus(double atr)
     {
      int total = PositionsTotal();
      if(total == 0) return "STANDBY";
      
      for(int i = total - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber())
              {
               double currentSL = m_position.StopLoss();
               double openPrice = m_position.PriceOpen();
               
               // If SL is better than Break Even, it's ACTIVE
               if(m_position.PositionType() == POSITION_TYPE_BUY && currentSL > openPrice)
                  return "ACTIVE (+Locked)";
               if(m_position.PositionType() == POSITION_TYPE_SELL && currentSL < openPrice && currentSL > 0.0)
                  return "ACTIVE (+Locked)";
                  
               return "ARMED (" + DoubleToString(GlobalConfig.GetTrailingActivationATR(), 1) + " ATR)";
              }
           }
        }
      return "STANDBY";
     }

   string            GetActiveStrategyName()
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(m_position.SelectByIndex(i))
           {
            if(m_position.Symbol() == _Symbol && m_position.Magic() == GlobalConfig.GetMagicNumber())
              {
               string comment = m_position.Comment();
               if(comment != "")
                 {
                  // Extract strategy name from comment "EliteXAUScalper Trend Pullback Buy"
                  string baseName = GlobalConfig.GetTradeComment();
                  StringReplace(comment, baseName + " ", "");
                  return comment;
                 }
               return "UNKNOWN";
              }
           }
        }
      return "NONE";
     }

private:
   void              ApplyTrailingStop(double atr)
     {
      // Simple ATR based trailing stop
      double currentSL = m_position.StopLoss();
      double newSL = 0.0;
      
      if(m_position.PositionType() == POSITION_TYPE_BUY)
        {
         newSL = SymbolInfoDouble(_Symbol, SYMBOL_BID) - (atr * GlobalConfig.GetTrailingActivationATR());
         if(newSL > currentSL && newSL < SymbolInfoDouble(_Symbol, SYMBOL_BID))
           {
            newSL = CUtilities::NormalizePrice(newSL);
            if(newSL != currentSL)
               m_trade.PositionModify(m_position.Ticket(), newSL, m_position.TakeProfit());
           }
        }
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
        {
         newSL = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + (atr * GlobalConfig.GetTrailingActivationATR());
         if((currentSL == 0.0 || newSL < currentSL) && newSL > SymbolInfoDouble(_Symbol, SYMBOL_ASK))
           {
            newSL = CUtilities::NormalizePrice(newSL);
            if(newSL != currentSL)
               m_trade.PositionModify(m_position.Ticket(), newSL, m_position.TakeProfit());
           }
        }
     }

   void              ApplyBreakEven()
     {
      // Move SL to Entry if price has moved 1R
      double currentSL = m_position.StopLoss();
      double entryPrice = m_position.PriceOpen();
      
      if(m_position.PositionType() == POSITION_TYPE_BUY)
        {
         double distance = SymbolInfoDouble(_Symbol, SYMBOL_BID) - entryPrice;
         if(distance > (entryPrice - currentSL) && currentSL < entryPrice) // Approximating 1R based on initial SL
           {
            m_trade.PositionModify(m_position.Ticket(), entryPrice, m_position.TakeProfit());
            Log.Info("Moved SL to Break-Even for Buy Position");
           }
        }
      else if(m_position.PositionType() == POSITION_TYPE_SELL)
        {
         double distance = entryPrice - SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         if(currentSL == 0.0) return; // shouldn't happen
         if(distance > (currentSL - entryPrice) && currentSL > entryPrice)
           {
            m_trade.PositionModify(m_position.Ticket(), entryPrice, m_position.TakeProfit());
            Log.Info("Moved SL to Break-Even for Sell Position");
           }
        }
     }
  };

#endif
