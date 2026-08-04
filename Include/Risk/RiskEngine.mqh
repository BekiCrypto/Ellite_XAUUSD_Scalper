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

      // 8. Simultaneous Exposure Protection: cap aggregate open + new risk to the daily drawdown ceiling.
      // Without this, N concurrent strategy positions (InpMaxConcurrentTrades) can each pass their own
      // isolated risk check while their combined worst-case loss still blows past the daily DD limit.
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double balance = AccountInfoDouble(ACCOUNT_BALANCE);
      if(tickSize > 0.0 && tickValue > 0.0 && balance > 0.0)
        {
         double slDistance = MathAbs(entryPrice - signal.suggestedSL);
         double newTradeRiskPercent = ((slDistance / tickSize) * tickValue * outLotSize / balance) * 100.0;
         double openRiskPercent = CPositionSizing::GetOpenRiskPercent();

         if(openRiskPercent + newTradeRiskPercent > GlobalConfig.GetMaxDailyDrawdown())
           {
            Log.Warning(StringFormat("Aggregate exposure guard: open risk %.2f%% + new trade %.2f%% would exceed max daily drawdown %.2f%%. Setup rejected.",
                                      openRiskPercent, newTradeRiskPercent, GlobalConfig.GetMaxDailyDrawdown()));
            return false;
           }
        }

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
      // IsTradingAllowed() calls CheckDayChange() itself and also evaluates the DD/profit/loss gates,
      // which is what arms the kill switch below. Must run every tick, not only when a signal exists,
      // or a breach on a quiet tick (no candidate trade) would never get flagged.
      if(CheckPointer(m_ddProtection) != POINTER_INVALID)
         m_ddProtection.IsTradingAllowed();
     }

   // One-shot: true exactly once on the tick the daily drawdown kill switch fires.
   bool              ConsumeDrawdownKillSwitch()
     {
      return m_ddProtection.ConsumeKillSwitch();
     }

   int               GetConsecutiveLosses() const { return m_ddProtection.GetConsecutiveLosses(); }
  };

#endif
