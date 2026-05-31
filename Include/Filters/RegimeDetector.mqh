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
   
   double            m_atrH1Buffer[];
   double            m_atrM15Buffer[];
   double            m_atrM5Buffer[];
   double            m_emaFastBuffer[];
   double            m_emaSlowBuffer[];

public:
                     CRegimeDetector()
                       {
                        ArraySetAsSeries(m_atrH1Buffer, true);
                        ArraySetAsSeries(m_atrM15Buffer, true);
                        ArraySetAsSeries(m_atrM5Buffer, true);
                        ArraySetAsSeries(m_emaFastBuffer, true);
                        ArraySetAsSeries(m_emaSlowBuffer, true);
                       }
                    ~CRegimeDetector()
                       {
                        IndicatorRelease(m_atrHandleH1);
                        IndicatorRelease(m_atrHandleM15);
                        IndicatorRelease(m_atrHandleM5);
                        IndicatorRelease(m_emaFastHandle);
                        IndicatorRelease(m_emaSlowHandle);
                       }

   bool              Initialize()
     {
      m_atrHandleH1 = iATR(_Symbol, PERIOD_H1, 14);
      m_atrHandleM15 = iATR(_Symbol, PERIOD_M15, 14);
      m_atrHandleM5 = iATR(_Symbol, PERIOD_M5, 14);
      
      m_emaFastHandle = iMA(_Symbol, PERIOD_M15, 20, 0, MODE_EMA, PRICE_CLOSE);
      m_emaSlowHandle = iMA(_Symbol, PERIOD_M15, 50, 0, MODE_EMA, PRICE_CLOSE);
      
      if(m_atrHandleH1 == INVALID_HANDLE || m_atrHandleM15 == INVALID_HANDLE || m_atrHandleM5 == INVALID_HANDLE ||
         m_emaFastHandle == INVALID_HANDLE || m_emaSlowHandle == INVALID_HANDLE)
         return false;
         
      return true;
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
      
      // Determine Volatility (Arbitrary baseline points for XAUUSD, should be dynamic/configurable)
      bool isHighVol = (atrH1 > 5.0); // > 50 pips H1 ATR
      bool isLowVol = (atrH1 < 1.5);  // < 15 pips H1 ATR
      
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
