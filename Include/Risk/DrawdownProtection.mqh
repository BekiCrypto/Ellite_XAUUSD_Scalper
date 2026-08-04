#ifndef DRAWDOWNPROTECTION_MQH
#define DRAWDOWNPROTECTION_MQH

//+------------------------------------------------------------------+
//|                                           DrawdownProtection.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Config.mqh"
#include "../Core/Logger.mqh"

class CDrawdownProtection
  {
private:
   double            m_startOfDayBalance;
   int               m_consecutiveLosses;
   double            m_peakDailyProfitPercent;
   bool              m_profitLockActivated;
   datetime          m_lastDay;
   bool              m_consecLossesLogged;
   bool              m_drawdownLogged;
   bool              m_profitLockLogged;
   bool              m_profitTargetLogged;
   bool              m_killSwitchPending;

public:
                     CDrawdownProtection()
                       {
                        m_consecutiveLosses = 0;
                        m_lastDay = 0;
                        ResetDailyTracking();
                       }
                    ~CDrawdownProtection() {}

   int               GetConsecutiveLosses() const { return m_consecutiveLosses; }

   // One-shot trigger: true exactly once, the tick the daily DD kill switch first fires.
   // Lets the caller force-close open exposure instead of only blocking new entries.
   bool              ConsumeKillSwitch()
     {
      if(m_killSwitchPending)
        {
         m_killSwitchPending = false;
         return true;
        }
      return false;
     }

    // Call this at the start of a new day
   void              ResetDailyTracking()
     {
      m_startOfDayBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      m_peakDailyProfitPercent = 0.0;
      m_profitLockActivated = false;
      m_consecutiveLosses = 0;
      m_consecLossesLogged = false;
      m_drawdownLogged = false;
      m_profitLockLogged = false;
      m_profitTargetLogged = false;
      m_killSwitchPending = false;
     }

   // Call this when a trade closes
   void              RegisterTradeResult(double pnl)
     {
      if(pnl < 0)
        {
         m_consecutiveLosses++;
        }
      else if(pnl > 0)
        {
         m_consecutiveLosses = 0;
        }
      
      // Reset logged flags to allow fresh logging on any post-trade state transitions
      m_consecLossesLogged = false;
      m_drawdownLogged = false;
      m_profitLockLogged = false;
      m_profitTargetLogged = false;
     }

   // Evaluate day change boundaries on every tick
   void              CheckDayChange()
     {
      datetime currentDay = TimeCurrent() - (TimeCurrent() % 86400);
      
      // Handle first tick run or day boundary transition
      if(m_lastDay == 0)
        {
         m_lastDay = currentDay;
         
         // Reconstruct start-of-day balance in case of EA middle-of-day restart
         double closedProfit = 0.0;
         HistorySelect(currentDay, INT_MAX);
         for(int i = 0; i < HistoryDealsTotal(); i++)
           {
            ulong ticket = HistoryDealGetTicket(i);
            if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
              {
               closedProfit += HistoryDealGetDouble(ticket, DEAL_PROFIT);
               closedProfit += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
               closedProfit += HistoryDealGetDouble(ticket, DEAL_SWAP);
              }
           }
         m_startOfDayBalance = AccountInfoDouble(ACCOUNT_BALANCE) - closedProfit;
        }
      else if(currentDay != m_lastDay)
        {
         Log.Info(StringFormat("[RISK] New day detected (%s). Resetting daily drawdown and profit tracking.", TimeToString(TimeCurrent(), TIME_DATE)));
         ResetDailyTracking();
         m_lastDay = currentDay;
        }
     }

   // Check if trading should be halted
   bool              IsTradingAllowed()
     {
      CheckDayChange();

      // 1. Max Consecutive Losses check
      if(m_consecutiveLosses >= GlobalConfig.GetMaxConsecutiveLosses())
        {
         if(!m_consecLossesLogged)
           {
            Log.Warning(StringFormat("Max consecutive losses (%d) reached. Trading suspended for the day.", m_consecutiveLosses));
            m_consecLossesLogged = true;
           }
         return false;
        }
        
      // 2. Max Daily Drawdown & Profit check
      double startOfDayBalance = m_startOfDayBalance;
      double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(startOfDayBalance > 0)
        {
         double drawdownPercent = ((startOfDayBalance - currentEquity) / startOfDayBalance) * 100.0;
         if(drawdownPercent >= GlobalConfig.GetMaxDailyDrawdown())
           {
            if(!m_drawdownLogged)
              {
               Log.Error(StringFormat("Max daily drawdown %.2f%% reached! Kill switch activated. Balance: %.2f, Equity: %.2f",
                                      drawdownPercent, startOfDayBalance, currentEquity));
               m_drawdownLogged = true;
               m_killSwitchPending = true;
              }
            return false;
           }
           
         double profitPercent = ((currentEquity - startOfDayBalance) / startOfDayBalance) * 100.0;
         
         // Update peak daily profit percent
         if(profitPercent > m_peakDailyProfitPercent)
           {
            m_peakDailyProfitPercent = profitPercent;
           }
           
         double targetLimit = GlobalConfig.GetMaxDailyProfit();
         
         // Activate trailing profit lock if peak profit reaches 50% of the daily target limit
         if(m_peakDailyProfitPercent >= (targetLimit * 0.5))
           {
            m_profitLockActivated = true;
           }
           
         // Enforce trailing Daily Profit Lock floor
         if(m_profitLockActivated)
           {
            double lockFloor = m_peakDailyProfitPercent * 0.5;
            if(profitPercent < lockFloor)
              {
               if(!m_profitLockLogged)
                 {
                  Log.Warning(StringFormat("Trailing Daily Profit Lock triggered! Peak: %.2f%%, Current: %.2f%%, Locked Floor: %.2f%%. Secure daily gains.", 
                                           m_peakDailyProfitPercent, profitPercent, lockFloor));
                  m_profitLockLogged = true;
                 }
               return false;
              }
           }
           
         if(profitPercent >= targetLimit)
           {
            if(!m_profitTargetLogged)
              {
               Log.Info(StringFormat("Max daily profit %.2f%% reached! Target hit, trading suspended.", profitPercent));
               m_profitTargetLogged = true;
              }
            return false;
           }
        }
        
      return true;
     }
  };

#endif
