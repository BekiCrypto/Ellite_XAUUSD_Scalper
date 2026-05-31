#ifndef RISKENGINE_MQH
#define RISKENGINE_MQH

//+------------------------------------------------------------------+
//|                                                   RiskEngine.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "DrawdownProtection.mqh"
#include "PositionSizing.mqh"
#include "../Core/Types.mqh"
#include <Trade\PositionInfo.mqh>

class CRiskEngine
  {
private:
   CDrawdownProtection *m_ddProtection;

public:
                     CRiskEngine()
                       {
                        m_ddProtection = new CDrawdownProtection();
                       }
                    ~CRiskEngine()
                       {
                        delete m_ddProtection;
                       }

   // Validate if a signal can be converted to an order
   bool              ValidateSignal(STradeSignal &signal, double &outLotSize, double avgSlippage = 0.0, uint avgLatency = 0, ENUM_MARKET_REGIME regime = REGIME_TREND)
     {
      outLotSize = 0.0;
      
      // 1. Max concurrent trades guard
      if(PositionsTotal() >= GlobalConfig.GetMaxConcurrentTrades())
        {
         return false;
        }

      // 2. Broker Execution Auto-Throttle
      if(signal.strategyId != STRATEGY_MANUAL)
        {
         if(avgLatency > GlobalConfig.GetMaxLatencyThrottle())
           {
            Log.Warning(StringFormat("Execution Auto-Throttle active: Average latency too high (%d ms > %d ms limit). Setup rejected.", 
                                     avgLatency, GlobalConfig.GetMaxLatencyThrottle()));
            return false;
           }
         if(avgSlippage > GlobalConfig.GetMaxSlippageThrottle())
           {
            Log.Warning(StringFormat("Execution Auto-Throttle active: Average slippage too high (%.1f points > %.1f points limit). Setup rejected.", 
                                     avgSlippage, GlobalConfig.GetMaxSlippageThrottle()));
            return false;
           }
        }

      // 3. Prevent duplicate entries for the same strategy
      if(signal.strategyId != STRATEGY_MANUAL)
        {
         string targetStrategy = signal.comment;
         StringReplace(targetStrategy, " Buy", "");
         StringReplace(targetStrategy, " Sell", "");
         
         CPositionInfo posInfo;
         for(int i = PositionsTotal() - 1; i >= 0; i--)
           {
            if(posInfo.SelectByIndex(i))
              {
               if(posInfo.Symbol() == _Symbol && posInfo.Magic() == GlobalConfig.GetMagicNumber())
                 {
                  string posComment = posInfo.Comment();
                  if(StringFind(posComment, targetStrategy) >= 0)
                    {
                     return false; // Strategy already has an active position
                    }
                 }
              }
           }
        }

      // 4. Drawdown & Consecutive Loss protection
      if(!m_ddProtection.IsTradingAllowed())
         return false;

      // 5. SL sanity check
      if(signal.suggestedSL == 0.0)
         return false; // Invalid signal

      // 6. Resolve Entry Price if strategy didn't specify one
      double entryPrice = signal.suggestedPrice;
      if(entryPrice == 0.0)
        {
         if(signal.signalType == SIGNAL_BUY)
            entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         else if(signal.signalType == SIGNAL_SELL)
            entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        }

      // 7. Calculate Lot Size with dynamic risk scaling
      outLotSize = CPositionSizing::CalculateLotSize(entryPrice, signal.suggestedSL, signal.confidence, regime);
      
      if(outLotSize <= 0.0)
         return false;

      return true;
     }

   // Passthrough for DD protection updates
   void              RegisterTradeResult(double pnl)
     {
      m_ddProtection.RegisterTradeResult(pnl);
     }
     
   void              ResetDailyTracking()
     {
      m_ddProtection.ResetDailyTracking();
     }

   void              UpdateRiskMetrics()
     {
      if(CheckPointer(m_ddProtection) != POINTER_INVALID)
         m_ddProtection.CheckDayChange();
     }

   int               GetConsecutiveLosses() const { return m_ddProtection.GetConsecutiveLosses(); }
  };

#endif
