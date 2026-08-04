#ifndef STATISTICSENGINE_MQH
#define STATISTICSENGINE_MQH

//+------------------------------------------------------------------+
//|                                             StatisticsEngine.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

class CStatisticsEngine
  {
private:
   int               m_totalTrades;
   int               m_winningTrades;
   int               m_losingTrades;
   double            m_totalProfit;
   double            m_totalLoss;

public:
                     CStatisticsEngine()
                       {
                        m_totalTrades = 0;
                        m_winningTrades = 0;
                        m_losingTrades = 0;
                        m_totalProfit = 0.0;
                        m_totalLoss = 0.0;
                       }
                    ~CStatisticsEngine() {}

   void              RegisterTrade(double pnl)
     {
      m_totalTrades++;
      if(pnl > 0)
        {
         m_winningTrades++;
         m_totalProfit += pnl;
        }
      else
        {
         m_losingTrades++;
         m_totalLoss += MathAbs(pnl);
        }
     }

   double            GetWinRate()
     {
      if(m_totalTrades == 0) return 0.0;
      return ((double)m_winningTrades / (double)m_totalTrades) * 100.0;
     }

   double            GetProfitFactor()
     {
      if(m_totalLoss == 0.0) return m_totalProfit > 0 ? 999.0 : 0.0;
      return m_totalProfit / m_totalLoss;
     }

   double            GetExpectancy()
     {
      if(m_totalTrades == 0) return 0.0;
      double winProb = (double)m_winningTrades / m_totalTrades;
      double lossProb = (double)m_losingTrades / m_totalTrades;
      double avgWin = m_winningTrades > 0 ? m_totalProfit / m_winningTrades : 0.0;
      double avgLoss = m_losingTrades > 0 ? m_totalLoss / m_losingTrades : 0.0;
      
      return (winProb * avgWin) - (lossProb * avgLoss);
     }
     
   int               GetTotalTrades() { return m_totalTrades; }
  };

#endif
