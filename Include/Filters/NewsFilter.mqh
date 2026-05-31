#ifndef NEWSFILTER_MQH
#define NEWSFILTER_MQH

//+------------------------------------------------------------------+
//|                                                   NewsFilter.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Config.mqh"
#include "../Core/Logger.mqh"

class CNewsFilter
  {
private:
   bool              m_isNewsActive;
   string            m_activeNewsName;
   datetime          m_lastCheckTime;

public:
                     CNewsFilter() : m_isNewsActive(false), m_activeNewsName(""), m_lastCheckTime(0) {}
                    ~CNewsFilter() {}

   bool              IsNewsRestricted()
     {
      if(!GlobalConfig.IsNewsFilterEnabled())
         return false;

      // Only check the calendar every 1 minute to save CPU
      datetime currentTime = TimeCurrent();
      if(currentTime - m_lastCheckTime < 60 && m_lastCheckTime != 0)
         return m_isNewsActive;
         
      m_lastCheckTime = currentTime;
      m_isNewsActive = false;
      m_activeNewsName = "CLEARED";

      MqlCalendarValue values[];
      datetime fromTime = currentTime - (GlobalConfig.GetNewsMinutesAfter() * 60);
      datetime toTime = currentTime + (GlobalConfig.GetNewsMinutesBefore() * 60);

      // Check USD News
      if(CalendarValueHistory(values, fromTime, toTime, NULL, "USD"))
        {
         for(int i = 0; i < ArraySize(values); i++)
           {
            MqlCalendarEvent event;
            if(CalendarEventById(values[i].event_id, event))
              {
               if(event.importance == CALENDAR_IMPORTANCE_HIGH)
                 {
                  m_isNewsActive = true;
                  m_activeNewsName = "HIGH IMPACT USD";
                  Log.Warning(StringFormat("News Filter ACTIVE: High Impact USD event around %s", TimeToString(values[i].time, TIME_MINUTES)));
                  return true;
                 }
              }
           }
        }
        
      return false;
     }
     
   string            GetNewsStatus()
     {
      if(!GlobalConfig.IsNewsFilterEnabled()) return "DISABLED";
      return m_isNewsActive ? "BLOCKED" : "CLEAR";
     }
  };

#endif
