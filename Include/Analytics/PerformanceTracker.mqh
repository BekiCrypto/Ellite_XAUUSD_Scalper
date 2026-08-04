#ifndef PERFORMANCETRACKER_MQH
#define PERFORMANCETRACKER_MQH

//+------------------------------------------------------------------+
//|                                           PerformanceTracker.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "StatisticsEngine.mqh"
#include "../Core/Logger.mqh"

class CPerformanceTracker
  {
private:
   CStatisticsEngine *m_stats;
   uint              m_lastReportTime;
   uint              m_reportIntervalMs;
   double            m_cachedDailyPnL;
   uint              m_lastPnLCalcMs;
   double            m_peakDrawdownToday;
   datetime          m_lastDrawdownDay;

public:
                     CPerformanceTracker(CStatisticsEngine *stats)
                       {
                        m_stats = stats;
                        m_lastReportTime = GetTickCount();
                        m_reportIntervalMs = 3600000; // 1 hour
                        m_cachedDailyPnL = 0.0;
                        m_lastPnLCalcMs = 0;
                        m_peakDrawdownToday = 0.0;
                        m_lastDrawdownDay = 0;
                       }
                    ~CPerformanceTracker() {}

   void              Update()
     {
      uint currentTime = GetTickCount();
      if(currentTime - m_lastReportTime >= m_reportIntervalMs)
        {
         GenerateReport();
         m_lastReportTime = currentTime;
        }
     }

   void              GenerateReport()
     {
      int trades = m_stats.GetTotalTrades();
      if(trades == 0) return;
      
      double winRate = m_stats.GetWinRate();
      double pf = m_stats.GetProfitFactor();
      double expectancy = m_stats.GetExpectancy();
      
      string report = StringFormat("--- PERFORMANCE REPORT ---\nTrades: %d | WinRate: %.1f%% | PF: %.2f | Exp: %.2f", 
                                   trades, winRate, pf, expectancy);
                                   
      Log.Info(report);
      
      // Can be extended to write to JSON/CSV for external dashboarding
     }

   double            GetDailyPnL()
     {
      // Scanning full deal history is too expensive to redo on every tick (called every OnTick for
      // dashboard/telemetry); cache for 1s, same throttle pattern as CNewsFilter's calendar check.
      uint nowMs = GetTickCount();
      if(m_lastPnLCalcMs != 0 && (nowMs - m_lastPnLCalcMs) < 1000)
         return m_cachedDailyPnL;

      // Let's get today's closed profit
      double closedProfit = 0.0;
      datetime startOfDay = TimeCurrent() - (TimeCurrent() % 86400);
      HistorySelect(startOfDay, INT_MAX);
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
      double currentPnL = closedProfit + AccountInfoDouble(ACCOUNT_PROFIT);
      double startOfDayBalance = AccountInfoDouble(ACCOUNT_BALANCE) - closedProfit;

      m_cachedDailyPnL = (startOfDayBalance > 0) ? (currentPnL / startOfDayBalance) * 100.0 : 0.0;
      m_lastPnLCalcMs = nowMs;
      return m_cachedDailyPnL;
     }

   // Dashboard labels this "Daily Peak Drawdown" (per the documented dual-readout spec), so it must
   // track the day's high-water mark, not just the instantaneous balance-vs-equity gap.
   double            GetCurrentDrawdown()
     {
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(balance == 0) return 0.0;

      double dd = ((balance - equity) / balance) * 100.0;
      if(dd < 0.0) dd = 0.0;

      datetime today = TimeCurrent() - (TimeCurrent() % 86400);
      if(today != m_lastDrawdownDay)
        {
         m_peakDrawdownToday = 0.0;
         m_lastDrawdownDay = today;
        }
      if(dd > m_peakDrawdownToday)
         m_peakDrawdownToday = dd;

      return m_peakDrawdownToday;
     }
  };

#endif
