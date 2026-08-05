//+------------------------------------------------------------------+
//|                                             EliteXAUScalper.mq5  |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property copyright   "Beki"
#property link        "https://t.me/tradelikeb"
#property version     "1.00"
#property description "Elite XAUUSD Multi-Strategy Scalping Engine"
#property description "Developer: Beki"
#property description "Telegram: t.me/tradelikeb"
#property description "Email: Bekicrypto@gmail.com"
#property description "WhatsApp: +971527663165"
#property strict

#include <Core/Config.mqh>
#include <Core/Constants.mqh>
#include <Core/Types.mqh>
#include <Core/Logger.mqh>
#include <Core/Utilities.mqh>

#include <Filters/SessionFilter.mqh>
#include <Filters/SpreadFilter.mqh>
#include <Filters/NewsFilter.mqh>
#include <Filters/RegimeDetector.mqh>

#include <Strategies/IStrategy.mqh>
#include <Strategies/TrendPullback.mqh>
#include <Strategies/MomentumBreakout.mqh>
#include <Strategies/LiquiditySweep.mqh>
#include <Strategies/SessionExpansion.mqh>
#include <Strategies/MeanReversion.mqh>
#include <Strategies/OrderBlock.mqh>

#include <Analytics/ConfidenceEngine.mqh>
#include <Analytics/StatisticsEngine.mqh>
#include <Analytics/PerformanceTracker.mqh>

#include <Risk/RiskEngine.mqh>
#include <Execution/TradeExecutor.mqh>
#include <Execution/TradeManager.mqh>
#include <UI/Dashboard.mqh>

//--- Input Parameters
input group "=== Systems Developer & Support ==="
input string   InpDevName     = "Beki";             // Developer Name
input string   InpDevTelegram = "t.me/tradelikeb";  // Telegram Direct
input string   InpDevEmail    = "Bekicrypto@gmail.com"; // Support Email
input string   InpDevWhatsApp = "+971527663165";    // WhatsApp Business

input group "=== Risk Management ==="
input double   InpRiskPercent = 3.0;            // Risk per trade (%)
input double   InpMinLotSize = 0.01;            // Minimum Lot Size
input double   InpMaxDailyDrawdown = 5.0;       // Max Daily Drawdown (%)
input double   InpMaxDailyProfit = 10.0;        // Max Daily Profit (%)
input int      InpMaxConsecutiveLosses = 4;     // Max Consecutive Losses
input int      InpMaxConcurrentTrades = 5;      // Max Concurrent Trades
input int      InpMaxLatencyMs = 500;           // Max Auto-Throttle Latency (ms)
input double   InpMaxSlippageThrottle = 3.0;    // Max Auto-Throttle Slippage (Points)

input group "=== Environmental Filters ==="
input bool     InpEnableSessionFilter = true;   // Enable Session Filter
input bool     InpEnableNewsFilter = true;      // Enable High-Impact USD News Filter
input int      InpNewsMinutesBefore = 30;       // Stop Trading X mins before News
input int      InpNewsMinutesAfter = 30;        // Resume Trading X mins after News
input int      InpMaxSpreadPoints = 20;         // Maximum Spread (points)
input int      InpMaxSlippagePoints = 5;        // Max Slippage (Points)
input double   InpMinConfidence = 75.0;         // Min Strategy Confidence
input double   InpTrailingActivationATR = 1.2;  // Trailing Stop Activation (ATR Multiplier)

input group "=== Identification ==="
input ulong    InpMagicNumber = 133777;         // EA Magic Number
input string   InpTradeComment = "EliteXAUScalper"; // Trade Comment
input string   InpAuthToken = "ELITE_GATEWAY_TOKEN_XYZ"; // Bridge Auth Token

input group "=== Strategy Selection ==="
input bool     InpEnableTrendPullback = true;   // Enable Trend Pullback
input bool     InpEnableMomentumBreakout = true; // Enable Momentum Breakout
input bool     InpEnableLiquiditySweep = true;  // Enable Liquidity Sweep
input bool     InpEnableSessionExpansion = true; // Enable Session Expansion
input bool     InpEnableMeanReversion = true;   // Enable Mean Reversion
input bool     InpEnableOrderBlock = true;      // Enable Order Block / FVG

//--- System Components
CSessionFilter       *SessionFlt;
CSpreadFilter        *SpreadFlt;
CNewsFilter          *NewsFlt;
CRegimeDetector      *RegimeDet;

#define NUM_STRATEGIES 6
CConfidenceEngine    *ConfEngine;
IStrategy            *Strategies[NUM_STRATEGIES];

CRiskEngine          *RiskEng;
CTradeExecutor       *Executor;
CTradeManager        *Manager;

CStatisticsEngine    *Stats;
CPerformanceTracker  *PerfTracker;
CDashboard           *UIDashboard;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Log.Info("Initializing Elite XAUUSD Scalper...");
   
   // Configure system
   GlobalConfig.SetRiskPercent(InpRiskPercent);
   GlobalConfig.SetMinLotSize(InpMinLotSize);
   GlobalConfig.SetMaxDailyDrawdown(InpMaxDailyDrawdown);
   GlobalConfig.SetMaxDailyProfit(InpMaxDailyProfit);
   GlobalConfig.SetMaxConsecutiveLosses(InpMaxConsecutiveLosses);
   GlobalConfig.SetMaxConcurrentTrades(InpMaxConcurrentTrades);
   GlobalConfig.SetThrottleParams(InpMaxLatencyMs, InpMaxSlippageThrottle);
   GlobalConfig.SetSessionFilterEnabled(InpEnableSessionFilter);
   GlobalConfig.SetNewsFilterEnabled(InpEnableNewsFilter, InpNewsMinutesBefore, InpNewsMinutesAfter);
   GlobalConfig.SetMaxSpreadPoints(InpMaxSpreadPoints);
   GlobalConfig.SetMinConfidence(InpMinConfidence);
   GlobalConfig.SetExecutionParams(InpMagicNumber, InpMaxSlippagePoints, InpTradeComment);
   GlobalConfig.SetTrailingParams(InpTrailingActivationATR);
   GlobalConfig.SetSessionFilterEnabled(InpEnableSessionFilter);
   GlobalConfig.SetStrategyEnabled(0, InpEnableTrendPullback);
   GlobalConfig.SetStrategyEnabled(1, InpEnableMomentumBreakout);
   GlobalConfig.SetStrategyEnabled(2, InpEnableLiquiditySweep);
   GlobalConfig.SetStrategyEnabled(3, InpEnableSessionExpansion);
   GlobalConfig.SetStrategyEnabled(4, InpEnableMeanReversion);
   GlobalConfig.SetStrategyEnabled(5, InpEnableOrderBlock);

   // Initialize Modules
   SessionFlt = new CSessionFilter();
   SpreadFlt = new CSpreadFilter();
   NewsFlt = new CNewsFilter();
   RegimeDet = new CRegimeDetector();
   
   if(!RegimeDet.Initialize())
     {
      Log.Error("Failed to initialize Regime Detector");
      return(INIT_FAILED);
     }

   // Initialize Strategies
   ConfEngine = new CConfidenceEngine();
   Strategies[0] = new CTrendPullback();
   Strategies[1] = new CMomentumBreakout();
   Strategies[2] = new CLiquiditySweep();
   Strategies[3] = new CSessionExpansion();
   Strategies[4] = new CMeanReversion();
   Strategies[5] = new COrderBlock();
   
   for(int i=0; i<NUM_STRATEGIES; i++)
     {
      if(!Strategies[i].Initialize())
        {
         Log.Error("Failed to initialize strategy: " + Strategies[i].GetName());
         return(INIT_FAILED);
        }
     }

   // Initialize Risk & Execution
   RiskEng = new CRiskEngine();
   Executor = new CTradeExecutor();
   Manager = new CTradeManager();

   // Initialize Analytics & UI
   Stats = new CStatisticsEngine();
   PerfTracker = new CPerformanceTracker(Stats);
   UIDashboard = new CDashboard();
   UIDashboard.Initialize();

   // Mount Indicators to Chart automatically on load
   // 1. Trend Pullback: Fast (9) and Slow (21) EMAs (Overlay on subwindow 0)
   int fastEmaHandle = ((CTrendPullback*)Strategies[0]).GetEMAFastHandle();
   int slowEmaHandle = ((CTrendPullback*)Strategies[0]).GetEMASlowHandle();
   if(fastEmaHandle != INVALID_HANDLE)
     {
      if(!ChartIndicatorAdd(0, 0, fastEmaHandle))
         Log.Warning("Failed to mount Fast EMA to chart. Error: " + IntegerToString(GetLastError()));
      else
         Log.Info("Fast EMA indicator successfully mounted to chart.");
     }
   if(slowEmaHandle != INVALID_HANDLE)
     {
      if(!ChartIndicatorAdd(0, 0, slowEmaHandle))
         Log.Warning("Failed to mount Slow EMA to chart. Error: " + IntegerToString(GetLastError()));
      else
         Log.Info("Slow EMA indicator successfully mounted to chart.");
     }

   // 2. Mean Reversion: Bollinger Bands (Overlay on subwindow 0) and RSI (Subwindow 1)
   int bbHandle = ((CMeanReversion*)Strategies[4]).GetBBandsHandle();
   int rsiHandle = ((CMeanReversion*)Strategies[4]).GetRSIHandle();
   if(bbHandle != INVALID_HANDLE)
     {
      if(!ChartIndicatorAdd(0, 0, bbHandle))
         Log.Warning("Failed to mount Bollinger Bands to chart. Error: " + IntegerToString(GetLastError()));
      else
         Log.Info("Bollinger Bands indicator successfully mounted to chart.");
     }
   if(rsiHandle != INVALID_HANDLE)
     {
      if(!ChartIndicatorAdd(0, 1, rsiHandle))
         Log.Warning("Failed to mount RSI to chart. Error: " + IntegerToString(GetLastError()));
      else
         Log.Info("RSI indicator successfully mounted to chart subwindow.");
     }

   EventSetTimer(1);
   Log.Info("Initialization Complete.");
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   EventKillTimer();
   Log.Info("Deinitializing EA...");
   delete UIDashboard;
   delete SessionFlt;
   delete SpreadFlt;
   delete NewsFlt;
   delete RegimeDet;
   
   delete ConfEngine;
   for(int i=0; i<NUM_STRATEGIES; i++) delete Strategies[i];
   
   delete RiskEng;
   delete Executor;
   delete Manager;
   
   delete PerfTracker;
   delete Stats;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Update Risk Engine day change checks
   if(CheckPointer(RiskEng) != POINTER_INVALID)
      RiskEng.UpdateRiskMetrics();

   // Kill switch: daily drawdown breach force-closes all open exposure, not just new entries
   if(CheckPointer(RiskEng) != POINTER_INVALID && RiskEng.ConsumeDrawdownKillSwitch())
     {
      Log.Error("[RISK] Daily drawdown kill switch triggered. Force-closing all open positions.");
      Manager.CloseAll();
     }

   // Pipeline Step 1: Manage Open Positions
   double atrH1 = 0.0, atrM15 = 0.0, atrM5 = 0.0;
   RegimeDet.GetATRValues(atrH1, atrM15, atrM5);
   Manager.ManageOpenPositions(atrM5);

   // Analytics Report
   PerfTracker.Update();

   // Pipeline Step 2: Fetch Environment Data for UI
   ENUM_MARKET_REGIME currentRegime = RegimeDet.DetectRegime();
   string sessionStr = EnumToString(SessionFlt.GetCurrentSession());
   int currentSpread = CUtilities::GetCurrentSpread();
   double dailyPnL = PerfTracker.GetDailyPnL();
   double currentDrawdown = PerfTracker.GetCurrentDrawdown();
   int openPositions = PositionsTotal();
   double floatingPips = Manager.GetFloatingPips();
   string trailStatus = Manager.GetTrailStatus(atrM5);
   string activeStrategy = Manager.GetActiveStrategyName();
   string newsStatus = (CheckPointer(NewsFlt) != POINTER_INVALID) ? NewsFlt.GetNewsStatus() : "UNKNOWN";
   
   // Update Dashboard
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double marginLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   string leverage = "1:" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE));
   double avgSlippage = Executor.GetAvgSlippage();
   uint avgLatency = Executor.GetAvgLatency();
   int consecLosses = RiskEng.GetConsecutiveLosses();
   
   UIDashboard.Update(sessionStr, EnumToString(currentRegime), currentSpread, atrM5, openPositions, dailyPnL, currentDrawdown, floatingPips, trailStatus, activeStrategy, newsStatus,
                      balance, equity, freeMargin, marginLevel, leverage,
                      avgSlippage, avgLatency, consecLosses, GlobalConfig.GetMaxConsecutiveLosses(),
                      GlobalConfig.GetMaxDailyDrawdown(), GlobalConfig.GetMaxDailyProfit(), GlobalConfig.GetMaxSpreadPoints(),
                      GlobalConfig.IsStrategyEnabled(0), GlobalConfig.IsStrategyEnabled(1), GlobalConfig.IsStrategyEnabled(2),
                      GlobalConfig.IsStrategyEnabled(3), GlobalConfig.IsStrategyEnabled(4), GlobalConfig.IsStrategyEnabled(5));

   // UI Override
   if(UIDashboard.IsPaused()) return;

   // Execution Guard: Concurrent trade limit
   if(PositionsTotal() >= GlobalConfig.GetMaxConcurrentTrades()) return;

   // Pipeline Step 3: Filters
   if(!SessionFlt.IsTradingAllowed()) return;
   
   bool isSpreadHealthy = SpreadFlt.IsSpreadHealthy(currentSpread, atrM5);
   bool isNewsRestricted = NewsFlt.IsNewsRestricted();

   // Pipeline Step 4: Environment Filters for NEW entries
   if(!isSpreadHealthy || isNewsRestricted) return;

   // Populate Market Environment State
   SMarketEnvironment env;
   env.regime = currentRegime;
   env.session = SessionFlt.GetCurrentSession();
   env.currentSpread = currentSpread;
   env.isSpreadHealthy = true;
   env.atrH1 = atrH1;
   env.atrM15 = atrM15;
   env.atrM5 = atrM5;
   env.trendDirection = RegimeDet.GetH1TrendDirection();
   
   // Pipeline Step 4: Strategy Selection
   STradeSignal signals[NUM_STRATEGIES];
   ZeroMemory(signals);
   for(int i=0; i<NUM_STRATEGIES; i++)
     {
      if(GlobalConfig.IsStrategyEnabled(i))
        {
         signals[i] = Strategies[i].Evaluate(env);
        }
      else
        {
         signals[i].strategyId = (ENUM_STRATEGY_ID)i;
         signals[i].signalType = SIGNAL_NONE;
         signals[i].confidence = 0.0;
         signals[i].suggestedPrice = 0.0;
         signals[i].suggestedSL = 0.0;
         signals[i].suggestedTP = 0.0;
         signals[i].comment = "";
        }
     }
     
   // Pipeline Step 5: Confidence Scoring
   STradeSignal bestSignal = ConfEngine.ProcessSignals(signals, NUM_STRATEGIES, env);
   
   if(bestSignal.signalType != SIGNAL_NONE)
     {
      // Pipeline Step 6: Risk Validation
      double lotSize = 0.0;
      if(RiskEng.ValidateSignal(bestSignal, lotSize, avgSlippage, avgLatency, currentRegime))
        {
         // Pipeline Step 7: Execution
         if(Executor.ExecuteSignal(bestSignal, lotSize))
           {
            Log.Info("Trade successfully initiated.");
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Chart Event function                                             |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   ENUM_UI_ACTION action = UIDashboard.OnEvent(id, lparam, dparam, sparam);
   
   if(action == UI_ACTION_CLOSE_ALL)
     {
      Manager.CloseAll();
     }
   else if(action == UI_ACTION_CLOSE_BUYS)
     {
      Manager.CloseBuys();
     }
   else if(action == UI_ACTION_CLOSE_SELLS)
     {
      Manager.CloseSells();
     }
   else if(action == UI_ACTION_MOVE_BE)
     {
      Manager.MoveAllToBreakEven();
     }
   else if(action == UI_ACTION_TOGGLE_STRATEGY_0)
     {
      GlobalConfig.SetStrategyEnabled(0, !GlobalConfig.IsStrategyEnabled(0));
     }
   else if(action == UI_ACTION_TOGGLE_STRATEGY_1)
     {
      GlobalConfig.SetStrategyEnabled(1, !GlobalConfig.IsStrategyEnabled(1));
     }
   else if(action == UI_ACTION_TOGGLE_STRATEGY_2)
     {
      GlobalConfig.SetStrategyEnabled(2, !GlobalConfig.IsStrategyEnabled(2));
     }
   else if(action == UI_ACTION_TOGGLE_STRATEGY_3)
     {
      GlobalConfig.SetStrategyEnabled(3, !GlobalConfig.IsStrategyEnabled(3));
     }
   else if(action == UI_ACTION_TOGGLE_STRATEGY_4)
     {
      GlobalConfig.SetStrategyEnabled(4, !GlobalConfig.IsStrategyEnabled(4));
     }
   else if(action == UI_ACTION_TOGGLE_STRATEGY_5)
     {
      GlobalConfig.SetStrategyEnabled(5, !GlobalConfig.IsStrategyEnabled(5));
     }
   else if(action == UI_ACTION_MANUAL_BUY || action == UI_ACTION_MANUAL_SELL)
     {
      double atrH1 = 0.0, atrM15 = 0.0, atrM5 = 0.0;
      RegimeDet.GetATRValues(atrH1, atrM15, atrM5);
      
      STradeSignal manualSignal;
      manualSignal.strategyId = STRATEGY_MANUAL;
      manualSignal.signalType = (action == UI_ACTION_MANUAL_BUY) ? SIGNAL_BUY : SIGNAL_SELL;
      manualSignal.confidence = 100.0;
      
      double entryPrice = (action == UI_ACTION_MANUAL_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      manualSignal.suggestedPrice = entryPrice;
      
      double atrDist = (atrM5 > 0.0) ? atrM5 : (15.0 * _Point * 10.0); // 15 pips fallback
      
      if(action == UI_ACTION_MANUAL_BUY)
        {
         manualSignal.suggestedSL = entryPrice - (atrDist * 2.0);
         manualSignal.suggestedTP = entryPrice + (atrDist * 4.0);
         manualSignal.comment = "Manual Execution Buy";
        }
      else
        {
         manualSignal.suggestedSL = entryPrice + (atrDist * 2.0);
         manualSignal.suggestedTP = entryPrice - (atrDist * 4.0);
         manualSignal.comment = "Manual Execution Sell";
        }
        
      double lotSize = 0.0;
      if(RiskEng.ValidateSignal(manualSignal, lotSize))
        {
         if(Executor.ExecuteSignal(manualSignal, lotSize))
           {
            Log.Info("Manual trade successfully executed.");
           }
        }
      else
        {
         Log.Warning("Manual execution rejected by Risk Engine.");
        }
     }
  }

//+------------------------------------------------------------------+
//| Trade Transaction Event (Used to track closed trades for stats)  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   // Check if a deal has been added to history
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
     {
      ulong ticket = trans.deal;
      if(ticket > 0)
        {
         if(HistoryDealSelect(ticket))
           {
            // Verify magic number and symbol
            if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == GlobalConfig.GetMagicNumber() &&
               HistoryDealGetString(ticket, DEAL_SYMBOL) == _Symbol)
              {
               long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
               // Process outbound deals (closing or reversing positions) to update stats and consecutive losses
               if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_INOUT)
                 {
                  double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
                  double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
                  double swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
                  double netPnL = profit + commission + swap;
                  
                  // Register the trade result in the stats and risk engine
                  if(CheckPointer(Stats) != POINTER_INVALID)
                     Stats.RegisterTrade(netPnL);
                     
                  if(CheckPointer(RiskEng) != POINTER_INVALID)
                     RiskEng.RegisterTradeResult(netPnL);
                     
                  Log.Info(StringFormat("[TRADE] Position closed by deal #%I64u. Net Profit/Loss: %.2f (Profit: %.2f, Comm: %.2f, Swap: %.2f)", 
                                        ticket, netPnL, profit, commission, swap));
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Processes incoming REST commands from the remote mobile UI       |
//+------------------------------------------------------------------+
void ProcessGatewayCommands(string response)
  {
   if(response == "") return;
   
   // 1. Pause Engine Override
   if(StringFind(response, "\"type\":\"PAUSE_TOGGLE\"") >= 0)
     {
      Log.Info("[BRIDGE] Remote command received: PAUSE_TOGGLE");
      UIDashboard.SetPaused(!UIDashboard.IsPaused());
     }
     
   // 2. Adjust Stop Loss to Entry price
   if(StringFind(response, "\"type\":\"MOVE_BE\"") >= 0)
     {
      Log.Info("[BRIDGE] Remote command received: MOVE_BE");
      Manager.MoveAllToBreakEven();
     }
     
   // 3. Emergency Liquidate positions
   if(StringFind(response, "\"type\":\"PANIC_CLOSE\"") >= 0)
     {
      Log.Info("[BRIDGE] Remote command received: PANIC_CLOSE");
      Manager.CloseAll();
     }
     
   // 4. Remote Strategy switches
   if(StringFind(response, "\"type\":\"STRATEGY_TOGGLE\"") >= 0)
     {
      if(StringFind(response, "\"strategyId\":\"TP\"") >= 0)
        {
         GlobalConfig.SetStrategyEnabled(0, !GlobalConfig.IsStrategyEnabled(0));
         Log.Info("[BRIDGE] Strategy Trend Pullback (TP) toggled.");
        }
      else if(StringFind(response, "\"strategyId\":\"MB\"") >= 0)
        {
         GlobalConfig.SetStrategyEnabled(1, !GlobalConfig.IsStrategyEnabled(1));
         Log.Info("[BRIDGE] Strategy Momentum Breakout (MB) toggled.");
        }
      else if(StringFind(response, "\"strategyId\":\"LS\"") >= 0)
        {
         GlobalConfig.SetStrategyEnabled(2, !GlobalConfig.IsStrategyEnabled(2));
         Log.Info("[BRIDGE] Strategy Liquidity Sweep (LS) toggled.");
        }
      else if(StringFind(response, "\"strategyId\":\"SE\"") >= 0)
        {
         GlobalConfig.SetStrategyEnabled(3, !GlobalConfig.IsStrategyEnabled(3));
         Log.Info("[BRIDGE] Strategy Session Expansion (SE) toggled.");
        }
      else if(StringFind(response, "\"strategyId\":\"MR\"") >= 0)
        {
         GlobalConfig.SetStrategyEnabled(4, !GlobalConfig.IsStrategyEnabled(4));
         Log.Info("[BRIDGE] Strategy Mean Reversion (MR) toggled.");
        }
      else if(StringFind(response, "\"strategyId\":\"OB\"") >= 0)
        {
         GlobalConfig.SetStrategyEnabled(5, !GlobalConfig.IsStrategyEnabled(5));
         Log.Info("[BRIDGE] Strategy Order Block (OB) toggled.");
        }
     }
     
   // 5. Manual remote Buy/Sell execution
   if(StringFind(response, "\"type\":\"MANUAL_TRADE\"") >= 0)
     {
      bool isBuy = (StringFind(response, "\"direction\":\"BUY\"") >= 0);
      Log.Info(StringFormat("[BRIDGE] Remote manual trade command: %s", isBuy ? "BUY" : "SELL"));
      
      double atrH1 = 0.0, atrM15 = 0.0, atrM5 = 0.0;
      RegimeDet.GetATRValues(atrH1, atrM15, atrM5);
      
      STradeSignal manualSignal;
      manualSignal.strategyId = STRATEGY_MANUAL;
      manualSignal.signalType = isBuy ? SIGNAL_BUY : SIGNAL_SELL;
      manualSignal.confidence = 100.0;
      
      double entryPrice = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      manualSignal.suggestedPrice = entryPrice;
      
      double atrDist = (atrM5 > 0.0) ? atrM5 : (15.0 * _Point * 10.0); // 15 pips fallback
      
      if(isBuy)
        {
         manualSignal.suggestedSL = entryPrice - (atrDist * 2.0);
         manualSignal.suggestedTP = entryPrice + (atrDist * 4.0);
         manualSignal.comment = "Remote Mobile Buy";
        }
      else
        {
         manualSignal.suggestedSL = entryPrice + (atrDist * 2.0);
         manualSignal.suggestedTP = entryPrice - (atrDist * 4.0);
         manualSignal.comment = "Remote Mobile Sell";
        }
        
      double lotSize = 0.0;
      if(RiskEng.ValidateSignal(manualSignal, lotSize))
        {
         if(Executor.ExecuteSignal(manualSignal, lotSize))
           {
            Log.Info("[BRIDGE] Remote manual trade executed on terminal.");
           }
        }
       else
        {
         Log.Warning("[BRIDGE] Remote manual trade rejected by Risk Engine.");
        }
      }
      
    // 6. Close individual position by ticket
    if(StringFind(response, "\"type\":\"CLOSE_TICKET\"") >= 0)
      {
       int ticketStart = StringFind(response, "\"ticket\":");
       if(ticketStart >= 0)
         {
          ticketStart += 9; // length of "\"ticket\":"
          int ticketEnd = StringFind(response, ",", ticketStart);
          if(ticketEnd < 0) ticketEnd = StringFind(response, "}", ticketStart);
          
          if(ticketEnd > ticketStart)
            {
             string ticketStr = StringSubstr(response, ticketStart, ticketEnd - ticketStart);
             ulong ticket = StringToInteger(ticketStr);
             if(ticket > 0)
               {
                Log.Info(StringFormat("[BRIDGE] Remote command received: CLOSE_TICKET #%I64u", ticket));
                Manager.ClosePosition(ticket);
               }
            }
         }
      }
   }

//+------------------------------------------------------------------+
//| Generates a JSON array of currently open positions for sync       |
//+------------------------------------------------------------------+
string GetOpenPositionsJSON()
  {
   string json = "[";
   int total = PositionsTotal();
   bool first = true;
   
   for(int i = 0; i < total; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket > 0)
        {
         string symbol = PositionGetString(POSITION_SYMBOL);
         if(symbol == _Symbol)
           {
            ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double volume = PositionGetDouble(POSITION_VOLUME);
            double priceOpen = PositionGetDouble(POSITION_PRICE_OPEN);
            double priceCurrent = PositionGetDouble(POSITION_PRICE_CURRENT);
            double sl = PositionGetDouble(POSITION_SL);
            double tp = PositionGetDouble(POSITION_TP);
            double profit = PositionGetDouble(POSITION_PROFIT);
            
            string posStr = StringFormat(
               "{\"ticket\":%I64u,\"symbol\":\"%s\",\"type\":%d,\"volume\":%.2f,\"priceOpen\":%.5f,\"priceCurrent\":%.5f,\"sl\":%.5f,\"tp\":%.5f,\"profit\":%.2f}",
               ticket, symbol, (int)type, volume, priceOpen, priceCurrent, sl, tp, profit
            );
            
            if(!first)
               json += ",";
            json += posStr;
            first = false;
           }
        }
     }
   json += "]";
   return json;
  }

//+------------------------------------------------------------------+
//| Expert 1-Second Timer Sync Loop                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   if(MQLInfoInteger(MQL_TESTER)) return; // Bypasses network sync inside Strategy Tester to prevent log flooding and WebRequest tester warnings
   
   // Fetch indicator and environmental context
   double atrH1 = 0.0, atrM15 = 0.0, atrM5 = 0.0;
   RegimeDet.GetATRValues(atrH1, atrM15, atrM5);
   
   // Gather account metrics
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   double fMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double mLevel = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
   string lev = "1:" + IntegerToString((int)AccountInfoInteger(ACCOUNT_LEVERAGE));
   
   // Gather risk governance metrics
   double pnl = PerfTracker.GetDailyPnL();
   double dd = PerfTracker.GetCurrentDrawdown();
   double exposure = Manager.GetFloatingPips();
   int consecLosses = RiskEng.GetConsecutiveLosses();
   string news = (CheckPointer(NewsFlt) != POINTER_INVALID) ? NewsFlt.GetNewsStatus() : "UNKNOWN";
   
   // Market telemetry values
   double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int spread = CUtilities::GetCurrentSpread();
   ENUM_MARKET_REGIME regime = RegimeDet.DetectRegime();
   string sessionStr = EnumToString(SessionFlt.GetCurrentSession());
   
   // Execution metrics
   int openPos = PositionsTotal();
   uint latency = Executor.GetAvgLatency();
   double slippage = Executor.GetAvgSlippage();
   string activeStrat = Manager.GetActiveStrategyName();
   string trailStatus = Manager.GetTrailStatus(atrM5);

   // Format Telemetry JSON body
   string positionsJson = GetOpenPositionsJSON();
   string json = StringFormat(
      "{\"authToken\":\"%s\",\"magicNumber\":%I64u,\"balance\":%.2f,\"equity\":%.2f,\"freeMargin\":%.2f,\"marginLevel\":%.2f,\"leverage\":\"%s\","
      "\"dailyPnL\":%.2f,\"currentDrawdown\":%.2f,\"floatingExposure\":%.2f,\"consecutiveLosses\":%d,\"newsStatus\":\"%s\","
      "\"currentPrice\":%.5f,\"currentSpread\":%d,\"currentATR\":%.2f,\"currentRegime\":\"%s\",\"currentSession\":\"%s\","
      "\"openPositionsCount\":%d,\"averageLatency\":%u,\"averageSlippage\":%.1f,\"activeStrategy\":\"%s\",\"trailStatus\":\"%s\","
      "\"positions\":%s}",
      InpAuthToken, InpMagicNumber, bal, eq, fMargin, mLevel, lev,
      pnl, dd, exposure, consecLosses, news,
      price, spread, atrM5, EnumToString(regime), sessionStr,
      openPos, latency, slippage, activeStrat, trailStatus,
      positionsJson
   );

   uchar data[];
   StringToCharArray(json, data, 0, WHOLE_ARRAY, CP_UTF8);
   
   uchar result[];
   string responseHeaders;
   string url = "http://127.0.0.1:3000/api/mt5/telemetry";
   
   ResetLastError();
   // Post telemetry with a stable 1000ms timeout (prevents thread blocking while accommodating Wine latency)
   int res = WebRequest("POST", url, "", "", 1000, data, ArraySize(data), result, responseHeaders);
   
   if(res == 200)
     {
      string response = CharArrayToString(result, 0, WHOLE_ARRAY, CP_UTF8);
      ProcessGatewayCommands(response);
     }
   else if(res == -1)
     {
      int error = GetLastError();
      static bool warned = false;
      if(!warned)
        {
         Log.Warning("WebRequest Sync failed. Verify whitelist. Code: " + IntegerToString(error));
         warned = true;
        }
     }
  }

