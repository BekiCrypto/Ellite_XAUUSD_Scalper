#ifndef SESSIONFILTER_MQH
#define SESSIONFILTER_MQH

//+------------------------------------------------------------------+
//|                                                SessionFilter.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Logger.mqh"

class CSessionFilter
  {
private:
   // Configurable hours (broker server time)
   int               m_asianStartHour;
   int               m_asianEndHour;
   int               m_londonStartHour;
   int               m_londonEndHour;
   int               m_nyStartHour;
   int               m_nyEndHour;

public:
                     CSessionFilter()
                       {
                        // Default IC Markets server times (GMT+2 / GMT+3 DST)
                        m_asianStartHour = 0;
                        m_asianEndHour = 8;
                        m_londonStartHour = 10;
                        m_londonEndHour = 19;
                        m_nyStartHour = 15;
                        m_nyEndHour = 23;
                       }
                    ~CSessionFilter() {}

   void              SetSessionHours(int asianStart, int asianEnd, int londonStart, int londonEnd, int nyStart, int nyEnd)
     {
      m_asianStartHour = asianStart;
      m_asianEndHour = asianEnd;
      m_londonStartHour = londonStart;
      m_londonEndHour = londonEnd;
      m_nyStartHour = nyStart;
      m_nyEndHour = nyEnd;
     }

   ENUM_SESSION      GetCurrentSession()
     {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      int currentHour = dt.hour;
      
      // Check rollover (last hour of NY session and first hour of Asian session usually have bad spreads)
      if(currentHour == 23 || currentHour == 0)
         return SESSION_ROLLOVER;

      bool isLondon = (currentHour >= m_londonStartHour && currentHour < m_londonEndHour);
      bool isNY = (currentHour >= m_nyStartHour && currentHour < m_nyEndHour);
      
      if(isLondon && isNY)
         return SESSION_OVERLAP_LON_NY;
      if(isLondon)
         return SESSION_LONDON;
      if(isNY)
         return SESSION_NY;
      if(currentHour >= m_asianStartHour && currentHour < m_asianEndHour)
         return SESSION_ASIAN;
         
      return SESSION_NONE;
     }
     
   bool              IsTradingAllowed()
     {
      if(!GlobalConfig.IsSessionFilterEnabled()) return true;
      
      ENUM_SESSION currentSession = GetCurrentSession();
      // Primary rule: Scalping is best during London, NY, and Overlap.
      // Avoid Rollover, Dead hours (None), and Asian session for pure momentum plays unless specific Asian strategy.
      if(currentSession == SESSION_LONDON || currentSession == SESSION_NY || currentSession == SESSION_OVERLAP_LON_NY)
         return true;
         
      return false;
     }
  };

#endif
