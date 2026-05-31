#ifndef CONFIG_MQH
#define CONFIG_MQH

//+------------------------------------------------------------------+
//|                                                       Config.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

class CConfig
  {
private:
   // Risk parameters
   double            m_riskPercent;
   double            m_minLotSize;
   double            m_maxDailyDrawdown;
   double            m_maxDailyProfit;
   int               m_maxConsecutiveLosses;
   int               m_maxConcurrentTrades;
   bool              m_strategyEnabled[6];
   
   // Filter parameters
   int               m_maxSpreadPoints;
   double            m_minConfidenceThreshold;
   
   // Logging
   bool              m_enableFileLogging;
   bool              m_enablePrintLogging;

   double            m_trailingActivationATR;
   int               m_maxSlippagePoints;
   uint              m_maxLatencyThrottle;
   double            m_maxSlippageThrottle;
   ulong             m_magicNumber;
   string            m_tradeComment;
   // Environment Filters
   bool              m_enableSessionFilter;
   bool              m_enableNewsFilter;
   int               m_newsMinutesBefore;
   int               m_newsMinutesAfter;

public:
                     CConfig()
                       {
                        m_riskPercent = 1.0;
                        m_minLotSize = 0.01;
                        m_maxDailyDrawdown = 5.0;
                        m_maxConsecutiveLosses = 3;
                        m_maxConcurrentTrades = 3;
                        for(int i = 0; i < 6; i++)
                           m_strategyEnabled[i] = true;
                        m_maxSpreadPoints = 20; 
                        m_minConfidenceThreshold = 75.0;
                        m_enableFileLogging = true;
                        m_enablePrintLogging = true;
                        
                        m_maxDailyProfit = 10.0;
                        m_trailingActivationATR = 1.5;
                        m_maxSlippagePoints = 5;
                        m_maxLatencyThrottle = 500;
                        m_maxSlippageThrottle = 3.0;
                        m_magicNumber = 1337;
                        m_tradeComment = "EliteXAUScalper";
                        m_enableSessionFilter = true;
                        m_enableNewsFilter = true;
                        m_newsMinutesBefore = 30;
                        m_newsMinutesAfter = 30;
                       }
                    ~CConfig() {}

   // Setters
   void              SetRiskPercent(double risk) { m_riskPercent = MathMax(0.1, risk); }
   void              SetMinLotSize(double lot) { m_minLotSize = MathMax(0.01, lot); }
   void              SetMaxDailyDrawdown(double dd) { m_maxDailyDrawdown = MathMax(1.0, dd); }
   void              SetMaxDailyProfit(double profit) { m_maxDailyProfit = MathMax(1.0, profit); }
   void              SetMaxConsecutiveLosses(int losses) { m_maxConsecutiveLosses = MathMax(1, MathMin(losses, 10)); }
   void              SetMaxSpreadPoints(int spread) { m_maxSpreadPoints = MathMax(5, spread); }
   void              SetMinConfidence(double conf) { m_minConfidenceThreshold = MathMax(50.0, MathMin(conf, 100.0)); }
   void              SetLogging(bool file, bool print) { m_enableFileLogging = file; m_enablePrintLogging = print; }
   void              SetExecutionParams(ulong magic, int slippage, string comment) { m_magicNumber = magic; m_maxSlippagePoints = MathMax(1, slippage); m_tradeComment = comment; }
   void              SetTrailingParams(double activation) { m_trailingActivationATR = MathMax(0.5, activation); }
   void              SetSessionFilterEnabled(bool enable) { m_enableSessionFilter = enable; }
   void              SetNewsFilterEnabled(bool enable, int minBefore, int minAfter) { m_enableNewsFilter = enable; m_newsMinutesBefore = MathMax(0, minBefore); m_newsMinutesAfter = MathMax(0, minAfter); }
   void              SetMaxConcurrentTrades(int max) { m_maxConcurrentTrades = MathMax(1, max); }
   void              SetStrategyEnabled(int strategyId, bool enabled) { if(strategyId >= 0 && strategyId < 6) m_strategyEnabled[strategyId] = enabled; }
   void              SetThrottleParams(uint maxLatency, double maxSlippage) { m_maxLatencyThrottle = MathMax(100, maxLatency); m_maxSlippageThrottle = MathMax(0.5, maxSlippage); }

   // Getters
   double            GetRiskPercent() const { return m_riskPercent; }
   double            GetMinLotSize() const { return m_minLotSize; }
   double            GetMaxDailyDrawdown() const { return m_maxDailyDrawdown; }
   double            GetMaxDailyProfit() const { return m_maxDailyProfit; }
   int               GetMaxConsecutiveLosses() const { return m_maxConsecutiveLosses; }
   int               GetMaxSpreadPoints() const { return m_maxSpreadPoints; }
   double            GetMinConfidence() const { return m_minConfidenceThreshold; }
   ulong             GetMagicNumber() const { return m_magicNumber; }
   int               GetMaxSlippagePoints() const { return m_maxSlippagePoints; }
   string            GetTradeComment() const { return m_tradeComment; }
   double            GetTrailingActivationATR() const { return m_trailingActivationATR; }
   uint              GetMaxLatencyThrottle() const { return m_maxLatencyThrottle; }
   double            GetMaxSlippageThrottle() const { return m_maxSlippageThrottle; }
   bool              IsFileLoggingEnabled() const { return m_enableFileLogging; }
   bool              IsPrintLoggingEnabled() const { return m_enablePrintLogging; }
   bool              IsSessionFilterEnabled() const { return m_enableSessionFilter; }
   bool              IsNewsFilterEnabled() const { return m_enableNewsFilter; }
   int               GetNewsMinutesBefore() const { return m_newsMinutesBefore; }
   int               GetNewsMinutesAfter() const { return m_newsMinutesAfter; }
   int               GetMaxConcurrentTrades() const { return m_maxConcurrentTrades; }
   bool              IsStrategyEnabled(int strategyId) const { if(strategyId >= 0 && strategyId < 6) return m_strategyEnabled[strategyId]; return false; }
  };

// Global singleton instance
CConfig GlobalConfig;

#endif
