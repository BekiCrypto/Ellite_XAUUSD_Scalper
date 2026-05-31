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
#include "SlippageControl.mqh"

class CTradeExecutor
  {
private:
   CTrade            m_trade;
   CSlippageControl *m_slippageControl;

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
      bool success = false;
      double executionPrice = 0.0;
      
      uint startTime = GetTickCount();
      
      // Resolve requested price if it's 0.0 (market execution)
      double requestedPrice = signal.suggestedPrice;
      if(requestedPrice <= 0.0)
        {
         requestedPrice = (signal.signalType == SIGNAL_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
        }
      
      if(signal.signalType == SIGNAL_BUY)
        {
         success = m_trade.Buy(lotSize, _Symbol, signal.suggestedPrice, signal.suggestedSL, signal.suggestedTP, GlobalConfig.GetTradeComment() + " " + signal.comment);
        }
      else if(signal.signalType == SIGNAL_SELL)
        {
         success = m_trade.Sell(lotSize, _Symbol, signal.suggestedPrice, signal.suggestedSL, signal.suggestedTP, GlobalConfig.GetTradeComment() + " " + signal.comment);
        }

      uint executionTime = GetTickCount() - startTime;
      
      if(success)
        {
         executionPrice = m_trade.ResultPrice();
         if(executionPrice <= 0.0)
           {
            executionPrice = requestedPrice;
           }
         Log.Trade(StringFormat("Order executed: %s at %.3f (Lot: %.2f)", EnumToString(signal.signalType), executionPrice, lotSize));
         m_slippageControl.RecordExecution(requestedPrice, executionPrice, executionTime);
        }
      else
        {
         Log.Error(StringFormat("Execution failed: %s", m_trade.ResultRetcodeDescription()));
        }

      return success;
     }

   double            GetAvgSlippage() { return m_slippageControl.GetAverageSlippage(); }
   uint              GetAvgLatency() { return m_slippageControl.GetAverageExecutionTime(); }
  };

#endif
