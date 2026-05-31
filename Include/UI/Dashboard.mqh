#ifndef DASHBOARD_MQH
#define DASHBOARD_MQH

//+------------------------------------------------------------------+
//|                                                    Dashboard.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Constants.mqh"
#include "../Core/Config.mqh"

enum ENUM_UI_ACTION
  {
   UI_ACTION_NONE,
   UI_ACTION_TOGGLE_PAUSE,
   UI_ACTION_CLOSE_ALL,
   UI_ACTION_CLOSE_BUYS,
   UI_ACTION_CLOSE_SELLS,
   UI_ACTION_MANUAL_BUY,
   UI_ACTION_MANUAL_SELL,
   UI_ACTION_MOVE_BE,
   UI_ACTION_TOGGLE_STRATEGY_0,
   UI_ACTION_TOGGLE_STRATEGY_1,
   UI_ACTION_TOGGLE_STRATEGY_2,
   UI_ACTION_TOGGLE_STRATEGY_3,
   UI_ACTION_TOGGLE_STRATEGY_4,
   UI_ACTION_TOGGLE_STRATEGY_5
  };

class CDashboard
  {
private:
   string            m_prefix;
   bool              m_isPaused;
   
   color             m_colBg;
   color             m_colText;
   color             m_colHeader;
   color             m_colBtnActive;
   color             m_colBtnAlert;
   color             m_colValue;
   color             m_colInfo;

   void              CreateLabel(string name, int x, int y, string text, color clr, int fontSize=9, string font="Consolas")
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, font);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
     }

   void              CreateButton(string name, int x, int y, int width, int height, string text, color clrBg, color clrText, int fontSize=8)
     {
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrText);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrBg);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrText);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_STATE, false);
     }

public:
                     CDashboard()
                       {
                        m_prefix = "EliteUI_";
                        m_isPaused = false;
                        
                        m_colBg = C'14,16,18'; // Premium Dark Slate/Charcoal Theme
                        m_colText = C'200,205,210'; // Ice White / Soft Gray
                        m_colHeader = clrGold;
                        m_colBtnActive = C'40,120,180'; // Teal Steel Blue
                        m_colBtnAlert = C'220,50,80'; // Crimson Red
                        m_colValue = C'80,220,100'; // Mint Green
                        m_colInfo = C'70,160,240'; // Ice Blue
                       }
                    ~CDashboard()
                       {
                        Deinitialize();
                       }

   void              Initialize()
     {
      // Background Panel
      string bgName = m_prefix + "BG";
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, 20);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 320);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 510);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, m_colBg);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, C'60,80,100'); // Slate Border
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bgName, OBJPROP_HIDDEN, true);

      // Title
      CreateLabel(m_prefix + "Title", 25, 27, "ELITE XAUUSD COGNITIVE ENGINE", m_colHeader, 10, "Arial Bold");
      CreateLabel(m_prefix + "SubTitle", 25, 41, "by Beki | Magic: 000000 | V1.00", C'170,175,180', 8, "Arial");
      
      // SECTION 1: ACCOUNT METRICS
      CreateLabel(m_prefix + "Sep1", 20, 54, "-- ACCOUNT METRICS ---------------------------", clrDimGray);
      CreateLabel(m_prefix + "LblBalance", 25, 68, "Account Balance:", m_colText);
      CreateLabel(m_prefix + "ValBalance", 175, 68, "$0.00", clrWhite);
      
      CreateLabel(m_prefix + "LblEquity", 25, 82, "Account Equity:", m_colText);
      CreateLabel(m_prefix + "ValEquity", 175, 82, "$0.00", m_colValue);
      
      CreateLabel(m_prefix + "LblFreeMargin", 25, 96, "Margin / Level:", m_colText);
      CreateLabel(m_prefix + "ValFreeMargin", 175, 96, "$0.00 / 0.0%", m_colInfo);
      
      CreateLabel(m_prefix + "LblLeverage", 25, 110, "Leverage:", m_colText);
      CreateLabel(m_prefix + "ValLeverage", 175, 110, "1:500", clrWhite);
      
      // SECTION 2: MARKET TELEMETRY
      CreateLabel(m_prefix + "Sep2", 20, 124, "-- MARKET TELEMETRY --------------------------", clrDimGray);
      CreateLabel(m_prefix + "LblSpread", 25, 138, "Live / Max Spread:", m_colText);
      CreateLabel(m_prefix + "ValSpread", 175, 138, "0 / 0 pts", clrWhite);
      
      CreateLabel(m_prefix + "LblATR", 25, 152, "Volatility (M5 ATR):", m_colText);
      CreateLabel(m_prefix + "ValATR", 175, 152, "0.00 pts", clrWhite);
 
      CreateLabel(m_prefix + "LblSlippage", 25, 166, "Average Slippage:", m_colText);
      CreateLabel(m_prefix + "ValSlippage", 175, 166, "0.0 pts", clrWhite);
 
      CreateLabel(m_prefix + "LblLatency", 25, 180, "Average Execution:", m_colText);
      CreateLabel(m_prefix + "ValLatency", 175, 180, "0 ms", clrWhite);
 
      // SECTION 3: RISK GOVERNANCE
      CreateLabel(m_prefix + "Sep3", 20, 194, "-- RISK GOVERNANCE ---------------------------", clrDimGray);
      CreateLabel(m_prefix + "LblPnL", 25, 208, "Daily Net Profit:", m_colText);
      CreateLabel(m_prefix + "ValPnL", 175, 208, "0.00% / 0.00%", clrWhite);
      
      CreateLabel(m_prefix + "LblDrawdown", 25, 222, "Daily Peak Drawdown:", m_colText);
      CreateLabel(m_prefix + "ValDrawdown", 175, 222, "0.00% / 0.00%", clrWhite);
 
      CreateLabel(m_prefix + "LblLosses", 25, 236, "Consecutive Losses:", m_colText);
      CreateLabel(m_prefix + "ValLosses", 175, 236, "0 / 0", clrWhite);
 
      CreateLabel(m_prefix + "LblExposure", 25, 250, "Engine Exposure:", m_colText);
      CreateLabel(m_prefix + "ValExposure", 175, 250, "+0.0 pips (0 pos)", clrWhite);
 
      // SECTION 4: ENGINE STATE
      CreateLabel(m_prefix + "Sep4", 20, 264, "-- ENGINE STATE ------------------------------", clrDimGray);
      CreateLabel(m_prefix + "LblStrategy", 25, 278, "Active Strategy:", m_colText);
      CreateLabel(m_prefix + "ValStrategy", 175, 278, "NONE", clrOrange);
      
      CreateLabel(m_prefix + "LblNews", 25, 292, "News Filter Status:", m_colText);
      CreateLabel(m_prefix + "ValNews", 175, 292, "CLEAR", m_colValue);

      CreateLabel(m_prefix + "LblBroker", 25, 306, "Broker Sync Status:", m_colText);
      CreateLabel(m_prefix + "ValBroker", 175, 306, "EXCELLENT", m_colValue);
      CreateLabel(m_prefix + "ValStatus", 25, 27, "", m_colValue); // Hidden status overlay in title
 
      // SECTION 5: STRATEGY CONTROLS
      CreateLabel(m_prefix + "Sep5", 20, 320, "-- STRATEGY CONTROL (TOGGLE) ------------------", clrDimGray);
      CreateButton(m_prefix + "BtnStrat0", 25, 334, 44, 20, "TP", clrForestGreen, clrWhite, 8);
      CreateButton(m_prefix + "BtnStrat1", 73, 334, 44, 20, "MB", clrForestGreen, clrWhite, 8);
      CreateButton(m_prefix + "BtnStrat2", 121, 334, 44, 20, "LS", clrForestGreen, clrWhite, 8);
      CreateButton(m_prefix + "BtnStrat3", 169, 334, 44, 20, "SE", clrForestGreen, clrWhite, 8);
      CreateButton(m_prefix + "BtnStrat4", 217, 334, 44, 20, "MR", clrForestGreen, clrWhite, 8);
      CreateButton(m_prefix + "BtnStrat5", 265, 334, 44, 20, "OB", clrForestGreen, clrWhite, 8);
 
      // SECTION 6: MANUAL CONTROLS
      CreateLabel(m_prefix + "Sep6", 20, 362, "-- MANUAL & SPECIAL CONTROLS ------------------", clrDimGray);
      CreateButton(m_prefix + "BtnBuy", 25, 376, 135, 22, "BUY NOW", clrLimeGreen, clrWhite, 9);
      CreateButton(m_prefix + "BtnSell", 170, 376, 135, 22, "SELL NOW", clrCrimson, clrWhite, 9);
      CreateButton(m_prefix + "BtnMoveBE", 25, 403, 135, 22, "MOVE SL TO BE", clrDodgerBlue, clrWhite, 9);
      CreateButton(m_prefix + "BtnPause", 170, 403, 135, 22, "PAUSE ENGINE", m_colBtnActive, clrWhite, 9);
      CreateButton(m_prefix + "BtnCloseAll", 25, 430, 280, 24, "PANIC CLOSE ALL", m_colBtnAlert, clrWhite, 9);
      
      // FOOTER BRAND
      CreateLabel(m_prefix + "Footer", 25, 488, "t.me/tradelikeb | Systems by Beki", C'170,175,180', 8, "Arial");
      
      ChartRedraw();
     }

   void              Deinitialize()
     {
      ObjectsDeleteAll(0, m_prefix);
      ChartRedraw();
     }

   void              Update(string session, string regime, int spread, double atr, int openPositions, double pnl, double drawdown, double floatingPips, string trailStatus, string activeStrategy, string newsStatus,
                            double balance, double equity, double freeMargin, double marginLevel, string leverage,
                            double avgSlippage, uint avgLatency, int consecLosses, int maxConsecLosses, double maxDailyDrawdown, double maxDailyProfit, int maxSpread,
                            bool strat0, bool strat1, bool strat2, bool strat3, bool strat4, bool strat5)
     {
      // Title overlay status
      if(m_isPaused)
        {
         ObjectSetString(0, m_prefix + "Title", OBJPROP_TEXT, "ENGINE PAUSED (MANUAL)");
         ObjectSetInteger(0, m_prefix + "Title", OBJPROP_COLOR, clrOrange);
        }
      else
        {
         ObjectSetString(0, m_prefix + "Title", OBJPROP_TEXT, "ELITE XAUUSD COGNITIVE ENGINE");
         ObjectSetInteger(0, m_prefix + "Title", OBJPROP_COLOR, m_colHeader);
        }

      // Update SubTitle with active magic and version dynamically
      ulong magic = GlobalConfig.GetMagicNumber();
      ObjectSetString(0, m_prefix + "SubTitle", OBJPROP_TEXT, "by Beki | Magic: " + IntegerToString(magic) + " | V1.00");

      // Section 1: Account Metrics
      ObjectSetString(0, m_prefix + "ValBalance", OBJPROP_TEXT, "$" + DoubleToString(balance, 2));
      ObjectSetString(0, m_prefix + "ValEquity", OBJPROP_TEXT, "$" + DoubleToString(equity, 2));
      ObjectSetString(0, m_prefix + "ValFreeMargin", OBJPROP_TEXT, "$" + DoubleToString(freeMargin, 2) + " (" + DoubleToString(marginLevel, 1) + "%)");
      ObjectSetString(0, m_prefix + "ValLeverage", OBJPROP_TEXT, leverage);

      // Section 2: Market Telemetry
      ObjectSetString(0, m_prefix + "ValSpread", OBJPROP_TEXT, IntegerToString(spread) + " / " + IntegerToString(maxSpread) + " pts");
      ObjectSetInteger(0, m_prefix + "ValSpread", OBJPROP_COLOR, (spread > maxSpread ? clrCrimson : m_colValue));
      
      ObjectSetString(0, m_prefix + "ValATR", OBJPROP_TEXT, DoubleToString(atr, 2) + " pts (" + session + ")");
      ObjectSetString(0, m_prefix + "ValSlippage", OBJPROP_TEXT, DoubleToString(avgSlippage, 1) + " points");
      ObjectSetString(0, m_prefix + "ValLatency", OBJPROP_TEXT, IntegerToString(avgLatency) + " ms");
      
      uint maxLatency = GlobalConfig.GetMaxLatencyThrottle();
      double maxSlippage = GlobalConfig.GetMaxSlippageThrottle();
      ObjectSetInteger(0, m_prefix + "ValLatency", OBJPROP_COLOR, (avgLatency > (maxLatency * 0.8) ? clrOrange : clrWhite));

      // Section 3: Risk Governance
      double pnlCash = balance * (pnl / 100.0);
      ObjectSetString(0, m_prefix + "ValPnL", OBJPROP_TEXT, (pnl >= 0.0 ? "+" : "") + DoubleToString(pnl, 2) + "% ($" + (pnlCash >= 0.0 ? "+" : "") + DoubleToString(pnlCash, 2) + ") / " + DoubleToString(maxDailyProfit, 2) + "%");
      ObjectSetInteger(0, m_prefix + "ValPnL", OBJPROP_COLOR, (pnl >= 0.0 ? clrLimeGreen : clrCrimson));
      
      double ddCash = balance * (drawdown / 100.0);
      ObjectSetString(0, m_prefix + "ValDrawdown", OBJPROP_TEXT, DoubleToString(drawdown, 2) + "% ($" + DoubleToString(ddCash, 2) + ") / " + DoubleToString(maxDailyDrawdown, 2) + "%");
      ObjectSetInteger(0, m_prefix + "ValDrawdown", OBJPROP_COLOR, (drawdown > (maxDailyDrawdown * 0.7) ? clrCrimson : (drawdown > 0.0 ? clrOrange : clrLimeGreen)));

      ObjectSetString(0, m_prefix + "ValLosses", OBJPROP_TEXT, IntegerToString(consecLosses) + " / " + IntegerToString(maxConsecLosses));
      ObjectSetInteger(0, m_prefix + "ValLosses", OBJPROP_COLOR, (consecLosses >= maxConsecLosses ? clrCrimson : (consecLosses > 0 ? clrOrange : clrWhite)));

      ObjectSetString(0, m_prefix + "ValExposure", OBJPROP_TEXT, (floatingPips > 0 ? "+" : "") + DoubleToString(floatingPips, 1) + " pips (" + IntegerToString(openPositions) + " pos)");
      ObjectSetInteger(0, m_prefix + "ValExposure", OBJPROP_COLOR, (floatingPips > 0 ? clrLimeGreen : (floatingPips < 0 ? clrCrimson : clrWhite)));

      // Section 4: Engine State
      ObjectSetString(0, m_prefix + "ValStrategy", OBJPROP_TEXT, activeStrategy + " (" + regime + ")");
      ObjectSetInteger(0, m_prefix + "ValStrategy", OBJPROP_COLOR, (activeStrategy == "NONE" ? clrDimGray : clrCyan));
      
      ObjectSetString(0, m_prefix + "ValNews", OBJPROP_TEXT, newsStatus);
      ObjectSetInteger(0, m_prefix + "ValNews", OBJPROP_COLOR, (newsStatus == "CLEAR" ? clrLimeGreen : (newsStatus == "DISABLED" ? clrDimGray : clrCrimson)));
      
      // Dynamic Broker Sync Connection status check
      string brokerStatus = "EXCELLENT";
      color brokerCol = m_colValue;
      if(avgLatency > maxLatency || avgSlippage > maxSlippage)
        {
         brokerStatus = "THROTTLED";
         brokerCol = clrCrimson;
        }
      else if(avgLatency > (maxLatency * 0.6) || avgSlippage > (maxSlippage * 0.6))
        {
         brokerStatus = "WARNING";
         brokerCol = clrOrange;
        }
      ObjectSetString(0, m_prefix + "ValBroker", OBJPROP_TEXT, brokerStatus);
      ObjectSetInteger(0, m_prefix + "ValBroker", OBJPROP_COLOR, brokerCol);
      
      // Section 5: Strategy Button Toggles
      ObjectSetInteger(0, m_prefix + "BtnStrat0", OBJPROP_BGCOLOR, (strat0 ? clrForestGreen : clrDarkSlateGray));
      ObjectSetInteger(0, m_prefix + "BtnStrat1", OBJPROP_BGCOLOR, (strat1 ? clrForestGreen : clrDarkSlateGray));
      ObjectSetInteger(0, m_prefix + "BtnStrat2", OBJPROP_BGCOLOR, (strat2 ? clrForestGreen : clrDarkSlateGray));
      ObjectSetInteger(0, m_prefix + "BtnStrat3", OBJPROP_BGCOLOR, (strat3 ? clrForestGreen : clrDarkSlateGray));
      ObjectSetInteger(0, m_prefix + "BtnStrat4", OBJPROP_BGCOLOR, (strat4 ? clrForestGreen : clrDarkSlateGray));
      ObjectSetInteger(0, m_prefix + "BtnStrat5", OBJPROP_BGCOLOR, (strat5 ? clrForestGreen : clrDarkSlateGray));

      ChartRedraw();
     }

   ENUM_UI_ACTION    OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
     {
      if(id == CHARTEVENT_OBJECT_CLICK)
        {
         if(sparam == m_prefix + "BtnPause")
           {
            m_isPaused = !m_isPaused;
            if(m_isPaused)
              {
               ObjectSetString(0, m_prefix + "BtnPause", OBJPROP_TEXT, "RESUME ENGINE");
               ObjectSetInteger(0, m_prefix + "BtnPause", OBJPROP_BGCOLOR, clrOrange);
              }
            else
              {
               ObjectSetString(0, m_prefix + "BtnPause", OBJPROP_TEXT, "PAUSE ENGINE");
               ObjectSetInteger(0, m_prefix + "BtnPause", OBJPROP_BGCOLOR, m_colBtnActive);
              }
            ObjectSetInteger(0, m_prefix + "BtnPause", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_TOGGLE_PAUSE;
           }
         else if(sparam == m_prefix + "BtnCloseAll")
           {
            ObjectSetInteger(0, m_prefix + "BtnCloseAll", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_CLOSE_ALL;
           }
         else if(sparam == m_prefix + "BtnBuy")
           {
            ObjectSetInteger(0, m_prefix + "BtnBuy", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_MANUAL_BUY;
           }
         else if(sparam == m_prefix + "BtnSell")
           {
            ObjectSetInteger(0, m_prefix + "BtnSell", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_MANUAL_SELL;
           }
         else if(sparam == m_prefix + "BtnMoveBE")
           {
            ObjectSetInteger(0, m_prefix + "BtnMoveBE", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_MOVE_BE;
           }
         else if(sparam == m_prefix + "BtnStrat0")
           {
            ObjectSetInteger(0, m_prefix + "BtnStrat0", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_TOGGLE_STRATEGY_0;
           }
         else if(sparam == m_prefix + "BtnStrat1")
           {
            ObjectSetInteger(0, m_prefix + "BtnStrat1", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_TOGGLE_STRATEGY_1;
           }
         else if(sparam == m_prefix + "BtnStrat2")
           {
            ObjectSetInteger(0, m_prefix + "BtnStrat2", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_TOGGLE_STRATEGY_2;
           }
         else if(sparam == m_prefix + "BtnStrat3")
           {
            ObjectSetInteger(0, m_prefix + "BtnStrat3", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_TOGGLE_STRATEGY_3;
           }
         else if(sparam == m_prefix + "BtnStrat4")
           {
            ObjectSetInteger(0, m_prefix + "BtnStrat4", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_TOGGLE_STRATEGY_4;
           }
         else if(sparam == m_prefix + "BtnStrat5")
           {
            ObjectSetInteger(0, m_prefix + "BtnStrat5", OBJPROP_STATE, false);
            ChartRedraw();
            return UI_ACTION_TOGGLE_STRATEGY_5;
           }
        }
      return UI_ACTION_NONE;
     }

   bool              IsPaused() const { return m_isPaused; }
   void              SetPaused(bool paused)
     {
      m_isPaused = paused;
      string btnPauseName = m_prefix + "BtnPause";
      if(m_isPaused)
        {
         ObjectSetString(0, btnPauseName, OBJPROP_TEXT, "RESUME ENGINE");
         ObjectSetInteger(0, btnPauseName, OBJPROP_BGCOLOR, clrOrange);
        }
      else
        {
         ObjectSetString(0, btnPauseName, OBJPROP_TEXT, "PAUSE ENGINE");
         ObjectSetInteger(0, btnPauseName, OBJPROP_BGCOLOR, m_colBtnActive);
        }
      ChartRedraw();
     }
  };

#endif
