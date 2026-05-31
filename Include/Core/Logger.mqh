#ifndef LOGGER_MQH
#define LOGGER_MQH

//+------------------------------------------------------------------+
//|                                                       Logger.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "Config.mqh"

enum ENUM_LOG_LEVEL
  {
   LOG_INFO,
   LOG_WARNING,
   LOG_ERROR,
   LOG_DEBUG,
   LOG_TRADE
  };

class CLogger
  {
private:
   string            m_logFileName;

   string            LevelToString(ENUM_LOG_LEVEL level)
     {
      switch(level)
        {
         case LOG_INFO: return "INFO";
         case LOG_WARNING: return "WARNING";
         case LOG_ERROR: return "ERROR";
         case LOG_DEBUG: return "DEBUG";
         case LOG_TRADE: return "TRADE";
        }
      return "UNKNOWN";
     }

public:
                     CLogger()
                       {
                        m_logFileName = "logs\\" + "EliteXAUScalper_" + TimeToString(TimeCurrent(), TIME_DATE) + ".csv";
                        StringReplace(m_logFileName, ".", "_");
                       }
                    ~CLogger() {}

   void              Log(ENUM_LOG_LEVEL level, string message)
     {
      string logString = StringFormat("[%s] [%s] %s", TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS), LevelToString(level), message);
      
      if(GlobalConfig.IsPrintLoggingEnabled())
        {
         Print(logString);
        }
        
      if(GlobalConfig.IsFileLoggingEnabled())
        {
         int handle = FileOpen(m_logFileName, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON);
         if(handle != INVALID_HANDLE)
           {
            FileSeek(handle, 0, SEEK_END);
            FileWrite(handle, logString);
            FileClose(handle);
           }
         else
           {
            Print("ERROR: Failed to open log file: ", m_logFileName);
           }
        }
     }

   void              Info(string message) { Log(LOG_INFO, message); }
   void              Warning(string message) { Log(LOG_WARNING, message); }
   void              Error(string message) { Log(LOG_ERROR, message); }
   void              Debug(string message) { Log(LOG_DEBUG, message); }
   void              Trade(string message) { Log(LOG_TRADE, message); }
  };

CLogger Log;

#endif
