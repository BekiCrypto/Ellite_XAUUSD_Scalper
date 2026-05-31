#ifndef SLIPPAGECONTROL_MQH
#define SLIPPAGECONTROL_MQH

//+------------------------------------------------------------------+
//|                                              SlippageControl.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Logger.mqh"
#include "../Core/Utilities.mqh"

class CSlippageControl
  {
private:
   int               m_totalTrades;
   double            m_cumulativeSlippagePoints;
   uint              m_cumulativeExecutionTime;

public:
                     CSlippageControl()
                       {
                        m_totalTrades = 0;
                        m_cumulativeSlippagePoints = 0.0;
                        m_cumulativeExecutionTime = 0;
                       }
                    ~CSlippageControl() {}

   void              RecordExecution(double requestedPrice, double actualPrice, uint executionTimeMs)
     {
      if(requestedPrice <= 0.0 || actualPrice <= 0.0) return; // Guard against uninitialized prices / calculation anomalies
      
      double slippage = MathAbs(requestedPrice - actualPrice) / _Point;
      
      m_totalTrades++;
      m_cumulativeSlippagePoints += slippage;
      m_cumulativeExecutionTime += executionTimeMs;
      
      string logMsg = StringFormat("Execution metrics: Slippage = %.1f points, Delay = %d ms", slippage, executionTimeMs);
      Log.Debug(logMsg);
      
      if(executionTimeMs > 500)
        {
         Log.Warning("High execution latency detected: " + IntegerToString(executionTimeMs) + " ms");
        }
      if(slippage > 10.0) // 10 points / 1 pip
        {
         Log.Warning("High slippage detected: " + DoubleToString(slippage, 1) + " points");
        }
     }
     
   double            GetAverageSlippage()
     {
      if(m_totalTrades == 0) return 0.0;
      return m_cumulativeSlippagePoints / m_totalTrades;
     }
     
   uint              GetAverageExecutionTime()
     {
      if(m_totalTrades == 0) return 0;
      return m_cumulativeExecutionTime / m_totalTrades;
     }
  };

#endif
