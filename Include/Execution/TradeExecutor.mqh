#ifndef TRADEEXECUTOR_MQH
#define TRADEEXECUTOR_MQH

//+------------------------------------------------------------------+
//|                                                TradeExecutor.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include <Trade\Trade.mqh>
#include "../Core/Logger.mqh"
#include "../Core/Types.mqh"
#include "../Core/Constants.mqh"
#include "../Core/Utilities.mqh"
#include "SlippageControl.mqh"

class CTradeExecutor
  {
private:
   CTrade            m_trade;
   CSlippageControl *m_slippageControl;

   // Widen SL/TP to the broker's minimum stop/freeze distance so tight strategy stops
   // (e.g. LiquiditySweep's 0.2x ATR) don't get rejected outright as "invalid stops".
   void              AdjustStopsForBroker(ENUM_SIGNAL_TYPE signalType, double referencePrice, double &sl, double &tp)
     {
      long stopsLevelPoints = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
      long freezeLevelPoints = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
      double minDistance = MathMax(stopsLevelPoints, freezeLevelPoints) * _Point;
      if(minDistance <= 0.0 || referencePrice <= 0.0) return;

      if(signalType == SIGNAL_BUY)
        {
         if(sl > 0.0 && (referencePrice - sl) < minDistance)
            sl = CUtilities::NormalizePrice(referencePrice - minDistance);
         if(tp > 0.0 && (tp - referencePrice) < minDistance)
            tp = CUtilities::NormalizePrice(referencePrice + minDistance);
        }
      else if(signalType == SIGNAL_SELL)
        {
         if(sl > 0.0 && (sl - referencePrice) < minDistance)
            sl = CUtilities::NormalizePrice(referencePrice + minDistance);
         if(tp > 0.0 && (referencePrice - tp) < minDistance)
            tp = CUtilities::NormalizePrice(referencePrice - minDistance);
        }
     }

public:
                     CTradeExecutor()
                       {
                        m_trade.SetExpertMagicNumber(GlobalConfig.GetMagicNumber()); 
                        m_trade.SetDeviationInPoints(GlobalConfig.GetMaxSlippagePoints());
                        m_trade.SetTypeFilling(ORDER_FILLING_FOK); // Fill or Kill
                        
                        m_slippageControl = new CSlippageControl();
                       }
                    ~CTradeExecutor()
                       {
                        delete m_slippageControl;
                       }

   bool              ExecuteSignal(STradeSignal &signal, double lotSize)
     {
      // Resolve requested price if it's 0.0 (market execution)
      double requestedPrice = signal.suggestedPrice;
      if(requestedPrice <= 0.0)
        {
         requestedPrice = (signal.signalType == SIGNAL_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        }

      double sl = signal.suggestedSL;
      double tp = signal.suggestedTP;
      AdjustStopsForBroker(signal.signalType, requestedPrice, sl, tp);

      for(int attempt = 1; attempt <= MAX_RETRY_ATTEMPTS; attempt++)
        {
         uint startTime = GetTickCount();
         bool success = false;

         if(signal.signalType == SIGNAL_BUY)
            success = m_trade.Buy(lotSize, _Symbol, signal.suggestedPrice, sl, tp, GlobalConfig.GetTradeComment() + " " + signal.comment);
         else if(signal.signalType == SIGNAL_SELL)
            success = m_trade.Sell(lotSize, _Symbol, signal.suggestedPrice, sl, tp, GlobalConfig.GetTradeComment() + " " + signal.comment);

         uint executionTime = GetTickCount() - startTime;

         if(success)
           {
            double executionPrice = m_trade.ResultPrice();
            if(executionPrice <= 0.0)
               executionPrice = requestedPrice;
            Log.Trade(StringFormat("Order executed: %s at %.3f (Lot: %.2f, attempt %d/%d)",
                                   EnumToString(signal.signalType), executionPrice, lotSize, attempt, MAX_RETRY_ATTEMPTS));
            m_slippageControl.RecordExecution(requestedPrice, executionPrice, executionTime);
            return true;
           }

         uint retcode = m_trade.ResultRetcode();
         bool isTransient = (retcode == TRADE_RETCODE_REQUOTE || retcode == TRADE_RETCODE_PRICE_CHANGED ||
                             retcode == TRADE_RETCODE_PRICE_OFF || retcode == TRADE_RETCODE_TIMEOUT ||
                             retcode == TRADE_RETCODE_CONNECTION);

         Log.Warning(StringFormat("Execution attempt %d/%d failed: %s", attempt, MAX_RETRY_ATTEMPTS, m_trade.ResultRetcodeDescription()));

         if(!isTransient || attempt == MAX_RETRY_ATTEMPTS)
            break;

         // Refresh price/stops before retrying a transient failure (requote, timeout, etc.)
         requestedPrice = (signal.signalType == SIGNAL_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
         sl = signal.suggestedSL;
         tp = signal.suggestedTP;
         AdjustStopsForBroker(signal.signalType, requestedPrice, sl, tp);
        }

      Log.Error(StringFormat("Execution failed after %d attempt(s): %s", MAX_RETRY_ATTEMPTS, m_trade.ResultRetcodeDescription()));
      return false;
     }

   double            GetAvgSlippage() { return m_slippageControl.GetAverageSlippage(); }
   uint              GetAvgLatency() { return m_slippageControl.GetAverageExecutionTime(); }
  };

#endif
