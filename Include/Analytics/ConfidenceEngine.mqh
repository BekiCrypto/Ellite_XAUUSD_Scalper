#ifndef CONFIDENCEENGINE_MQH
#define CONFIDENCEENGINE_MQH

//+------------------------------------------------------------------+
//|                                             ConfidenceEngine.mqh |
//|                                    Elite XAUUSD Scalping Engine  |
//+------------------------------------------------------------------+
#property strict

#include "../Core/Types.mqh"
#include "../Core/Config.mqh"

class CConfidenceEngine
  {
public:
                     CConfidenceEngine() {}
                    ~CConfidenceEngine() {}

   // Processes an array of signals and returns the best one that meets the threshold
   STradeSignal      ProcessSignals(STradeSignal &signals[], int count, SMarketEnvironment &env)
     {
      STradeSignal bestSignal;
      bestSignal.signalType = SIGNAL_NONE;
      bestSignal.confidence = 0.0;
      
      for(int i = 0; i < count; i++)
        {
         if(signals[i].signalType == SIGNAL_NONE) continue;
         
         double adjustedConfidence = AdjustConfidence(signals[i], env);
         signals[i].confidence = adjustedConfidence;
         
         if(adjustedConfidence >= GlobalConfig.GetMinConfidence() && adjustedConfidence > bestSignal.confidence)
           {
            bestSignal = signals[i];
           }
        }
        
      return bestSignal;
     }

private:
   // Dynamically adjust confidence based on regime and session
   double            AdjustConfidence(STradeSignal &signal, SMarketEnvironment &env)
     {
      double conf = signal.confidence;
      
      // 1. Momentum Breakout Adjustments
      if(signal.strategyId == STRATEGY_MOMENTUM_BREAKOUT)
        {
         if(env.regime == REGIME_RANGE)
            conf -= 30.0;
         else if(env.regime == REGIME_TREND)
            conf += 10.0;
        }
         
      // 2. Trend Pullback Boost in trend regimes
      if(signal.strategyId == STRATEGY_TREND_PULLBACK && env.regime == REGIME_TREND)
         conf += 10.0;
         
      // 3. Mean Reversion Adjustments
      if(signal.strategyId == STRATEGY_MEAN_REVERSION)
        {
         if(env.regime == REGIME_RANGE)
            conf += 15.0;
         else if(env.regime == REGIME_TREND)
            conf -= 35.0;
        }
        
      // 4. Order Block Mitigation Adjustments
      if(signal.strategyId == STRATEGY_ORDER_BLOCK)
        {
         if(env.regime == REGIME_TREND || env.regime == REGIME_VOLATILE)
            conf += 10.0;
         else if(env.regime == REGIME_RANGE || env.regime == REGIME_DEAD)
            conf -= 30.0;
        }

      // 5. Liquidity Sweep Rejection (Stop Hunt) Adjustments
      if(signal.strategyId == STRATEGY_LIQUIDITY_SWEEP)
        {
         if(env.regime == REGIME_RANGE || env.regime == REGIME_VOLATILE)
            conf += 10.0;
         else if(env.regime == REGIME_DEAD)
            conf -= 25.0;
        }

      // 6. Session Breakout Adjustments (Boost NY/London, penalize quiet hours)
      if(signal.strategyId == STRATEGY_SESSION_EXPANSION)
        {
         if(env.session == SESSION_LONDON || env.session == SESSION_NY || env.session == SESSION_OVERLAP_LON_NY)
            conf += 15.0;
         else
            conf -= 20.0;
        }
         
      // Penalize any strategy if spread is borderline
      if(env.currentSpread > GlobalConfig.GetMaxSpreadPoints() * 0.8)
         conf -= 15.0; // Reduce confidence if spread is 80% of max allowed
         
      // Cap at 100
      return MathMin(conf, 100.0);
     }
  };

#endif
