#ifndef REGIMEDETECTOR_MQH
#define REGIMEDETECTOR_MQH

//+------------------------------------------------------------------+
//|                                               RegimeDetector.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Types.mqh"

class CRegimeDetector
  {
private:
   int               m_atrHandleH1;
   int               m_atrHandleM15;
   int               m_atrHandleM5;
   
   int               m_emaFastHandle;
   int               m_emaSlowHandle;
   int               m_emaH1FastHandle;
   int               m_emaH1SlowHandle;

   double            m_atrH1Buffer[];
   double            m_atrM15Buffer[];
   double            m_atrM5Buffer[];
   double            m_emaFastBuffer[];
   double            m_emaSlowBuffer[];
   double            m_emaH1FastBuffer[];
   double            m_emaH1SlowBuffer[];

public:
                     CRegimeDetector()
                       {
                        ArraySetAsSeries(m_atrH1Buffer, true);
                        ArraySetAsSeries(m_atrM15Buffer, true);
                        ArraySetAsSeries(m_atrM5Buffer, true);
                        ArraySetAsSeries(m_emaFastBuffer, true);
                        ArraySetAsSeries(m_emaSlowBuffer, true);
                        ArraySetAsSeries(m_emaH1FastBuffer, true);
                        ArraySetAsSeries(m_emaH1SlowBuffer, true);
                       }
                    ~CRegimeDetector()
                       {
                        IndicatorRelease(m_atrHandleH1);
                        IndicatorRelease(m_atrHandleM15);
                        IndicatorRelease(m_atrHandleM5);
                        IndicatorRelease(m_emaFastHandle);
                        IndicatorRelease(m_emaSlowHandle);
                        IndicatorRelease(m_emaH1FastHandle);
                        IndicatorRelease(m_emaH1SlowHandle);
                       }

   bool              Initialize()
     {
      m_atrHandleH1 = iATR(_Symbol, PERIOD_H1, 14);
      m_atrHandleM15 = iATR(_Symbol, PERIOD_M15, 14);
      m_atrHandleM5 = iATR(_Symbol, PERIOD_M5, 14);

      m_emaFastHandle = iMA(_Symbol, PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
      m_emaSlowHandle = iMA(_Symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
      m_emaH1FastHandle = iMA(_Symbol, PERIOD_H1, 20, 0, MODE_EMA, PRICE_CLOSE);
      m_emaH1SlowHandle = iMA(_Symbol, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);

      if(m_atrHandleH1 == INVALID_HANDLE || m_atrHandleM15 == INVALID_HANDLE || m_atrHandleM5 == INVALID_HANDLE ||
         m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE ||
         m_emaH1FastHandle == INVALID_HANDLE || m_emaH1SlowHandle == INVALID_HANDLE)
         return false;

      return true;
     }

   // SDD Module 9 (Multi-Timeframe Engine): H1 macro directional bias for lower-timeframe
   // strategies to filter against, so reversal-style setups don't fight the higher-timeframe trend.
   ENUM_TREND_DIRECTION GetH1TrendDirection()
     {
      if(CopyBuffer(m_emaH1FastHandle, 0, 0, 1, m_emaH1FastBuffer) <= 0) return TREND_NEUTRAL;
      if(CopyBuffer(m_emaH1SlowHandle, 0, 0, 1, m_emaH1SlowBuffer) <= 0) return TREND_NEUTRAL;

      double fast = m_emaH1FastBuffer[0];
      double slow = m_emaH1SlowBuffer[0];
      if(slow == 0.0) return TREND_NEUTRAL;

      // Require a meaningful separation (not just fast > slow by a hair) before calling it a bias
      double separationPercent = MathAbs(fast - slow) / slow * 100.0;
      if(separationPercent < 0.05) return TREND_NEUTRAL;

      return (fast > slow) ? TREND_UP : TREND_DOWN;
     }

   ENUM_MARKET_REGIME DetectRegime()
     {
      if(CopyBuffer(m_atrHandleH1, 0, 0, 2, m_atrH1Buffer) <= 0) return REGIME_DEAD;
      if(CopyBuffer(m_atrHandleM15, 0, 0, 2, m_atrM15Buffer) <= 0) return REGIME_DEAD;
      if(CopyBuffer(m_emaFastHandle, 0, 0, 2, m_emaFastBuffer) <= 0) return REGIME_DEAD;
      if(CopyBuffer(m_emaSlowHandle, 0, 0, 2, m_emaSlowBuffer) <= 0) return REGIME_DEAD;

      double atrH1 = m_atrH1Buffer[0];
      double atrM15 = m_atrM15Buffer[0];

      double fastEma = m_emaFastBuffer[0];
      double slowEma = m_emaSlowBuffer[0];

      // Volatility thresholds as % of price, not fixed dollars: gold's price level drifts materially
      // over time (e.g. ~$1800 to ~$3000+), so a fixed $5/$1.5 ATR band silently drifts out of
      // calibration. 0.25%/0.075% reproduce the original $5/$1.5 split at ~$2000 gold and stay
      // correct as the price level moves.
      double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(currentPrice <= 0.0) return REGIME_DEAD; // no valid price feed, don't guess

      double atrH1PercentOfPrice = (atrH1 / currentPrice) * 100.0;
      bool isHighVol = (atrH1PercentOfPrice > 0.25);
      bool isLowVol = (atrH1PercentOfPrice < 0.075);

      if(isLowVol) return REGIME_DEAD;
      
      // Determine Trend
      double emaDistance = MathAbs(fastEma - slowEma);
      bool isTrending = (emaDistance > atrM15 * 0.5); // Clear separation
      
      if(isTrending && !isHighVol)
         return REGIME_TREND;
         
      if(!isTrending && !isHighVol)
         return REGIME_RANGE;
         
      if(isTrending && isHighVol)
         return REGIME_VOLATILE;
         
      if(!isTrending && isHighVol)
         return REGIME_CHAOTIC;
         
      return REGIME_RANGE; // Fallback
     }
     
   void              GetATRValues(double &h1, double &m15, double &m5)
     {
      CopyBuffer(m_atrHandleH1, 0, 0, 1, m_atrH1Buffer);
      CopyBuffer(m_atrHandleM15, 0, 0, 1, m_atrM15Buffer);
      CopyBuffer(m_atrHandleM5, 0, 0, 1, m_atrM5Buffer);
      
      h1 = m_atrH1Buffer[0];
      m15 = m_atrM15Buffer[0];
      m5 = m_atrM5Buffer[0];
     }
  };

#endif
