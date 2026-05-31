#ifndef MEANREVERSION_MQH
#define MEANREVERSION_MQH

//+------------------------------------------------------------------+
//|                                               MeanReversion.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "IStrategy.mqh"
#include "../Core/Logger.mqh"

class CMeanReversion : public IStrategy
  {
private:
   int               m_bbandsHandle;
   int               m_rsiHandle;
   double            m_upperBuffer[];
   double            m_lowerBuffer[];
   double            m_rsiBuffer[];

public:
   CMeanReversion() : IStrategy(STRATEGY_MEAN_REVERSION, "Mean Reversion")
                       {
                        ArraySetAsSeries(m_upperBuffer, true);
                        ArraySetAsSeries(m_lowerBuffer, true);
                        ArraySetAsSeries(m_rsiBuffer, true);
                       }
                    ~CMeanReversion()
                       {
                        IndicatorRelease(m_bbandsHandle);
                        IndicatorRelease(m_rsiHandle);
                       }
   int               GetBBandsHandle() const { return m_bbandsHandle; }
   int               GetRSIHandle() const { return m_rsiHandle; }

   virtual bool      Initialize() override
     {
      // Bollinger Bands on M5: Period 20, Deviation 2.0, close price
      m_bbandsHandle = iBands(_Symbol, PERIOD_M5, 20, 0, 2.0, PRICE_CLOSE);
      // RSI on M5: Period 14, close price
      m_rsiHandle = iRSI(_Symbol, PERIOD_M5, 14, PRICE_CLOSE);
      
      if(m_bbandsHandle == INVALID_HANDLE || m_rsiHandle == INVALID_HANDLE)
         return false;
      return true;
     }

   virtual bool      IsRegimeAllowed(ENUM_MARKET_REGIME regime) override
     {
      // Mean reversion excels in bound/ranging or highly volatile choppy markets
      return (regime == REGIME_RANGE || regime == REGIME_VOLATILE);
     }

   virtual STradeSignal Evaluate(SMarketEnvironment &env) override
     {
      STradeSignal signal;
      signal.strategyId = m_strategyId;
      signal.signalType = SIGNAL_NONE;
      signal.confidence = 0.0;
      
      if(!IsRegimeAllowed(env.regime)) return signal;
      
      if(CopyBuffer(m_bbandsHandle, 1, 1, 2, m_upperBuffer) <= 0) return signal;
      if(CopyBuffer(m_bbandsHandle, 2, 1, 2, m_lowerBuffer) <= 0) return signal;
      if(CopyBuffer(m_rsiHandle, 0, 1, 2, m_rsiBuffer) <= 0) return signal;
      
      double close1 = iClose(_Symbol, PERIOD_M5, 1);
      double open1 = iOpen(_Symbol, PERIOD_M5, 1);
      double high1 = iHigh(_Symbol, PERIOD_M5, 1);
      double low1 = iLow(_Symbol, PERIOD_M5, 1);
      
      double upper1 = m_upperBuffer[0];
      double lower1 = m_lowerBuffer[0];
      double rsi1 = m_rsiBuffer[0];
      
      // BUY: Price touched/went below lower band, RSI was oversold (<30), and candle closes bullish
      if(low1 < lower1 && rsi1 < 30.0 && close1 > open1)
        {
         signal.signalType = SIGNAL_BUY;
         signal.confidence = 80.0;
         signal.suggestedSL = lower1 - (env.atrM5 * 1.5); // SL 1.5 ATR below lower band for room
         double tpMultiplier = (env.regime == REGIME_VOLATILE) ? 5.5 : 4.0;
         signal.suggestedTP = close1 + (env.atrM5 * tpMultiplier);  // Ride it to opposite band and beyond
         signal.comment = m_strategyName + " Buy";
        }
      // SELL: Price touched/went above upper band, RSI was overbought (>70), and candle closes bearish
      else if(high1 > upper1 && rsi1 > 70.0 && close1 < open1)
        {
         signal.signalType = SIGNAL_SELL;
         signal.confidence = 80.0;
         signal.suggestedSL = upper1 + (env.atrM5 * 1.5);
         double tpMultiplier = (env.regime == REGIME_VOLATILE) ? 5.5 : 4.0;
         signal.suggestedTP = close1 - (env.atrM5 * tpMultiplier);
         signal.comment = m_strategyName + " Sell";
        }
        
      return signal;
     }
  };

#endif
