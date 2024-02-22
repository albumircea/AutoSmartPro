//+------------------------------------------------------------------+
//|                                                     PPAuto40.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include "AutoProfit40EA.mqh"


LOGGER_DEFINE_FILENAME("AutoProfit40");
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
BEGIN_INPUT(CAutoProfit40Params)
INPUT(int, Magic, 1);               //Magic
INPUT(bool, Martingale, false);     //Use Martingale
INPUT(double, FactorAveraging, 1.0);         //Multiplier Averaging
INPUT(double, FactorScaling, 1.0);         //Multiplier Scaling
INPUT(int, TakeProfit, 500);        //TakeProfit (Pipette/Points)
INPUT(int, StepAveraging, 2000);              //Step (Pipette/Points) Averaging
INPUT(int, StepScaling, 2000);              //Step (Pipette/Points) Scaling
INPUT(double, Lot, 0.0);            //Lots(0.0 = MinLot)
INPUT(double, MaxLotAveraging, 1);           //Max Lot Averaging
INPUT(double, MaxLotScaling, 1);           //Max Lot Scaling
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT(int, TrailingStop, 100);
INPUT(int, TrailingStart, 1000);
INPUT(int, TrailingStep, 50);
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
INPUT(int, LateStart, 5);          //Late Start Averaging (DoNotUse = 0)
INPUT(bool,IsNewCandleTrade,true); //Trade only on new candle
//INPUT_SEP("Exit");
INPUT(bool, CloseAtDrawDown, true); //Close at drawdown (Drawdown on EA)
INPUT(ENUM_DRAWDOWN_TYPE, DrawDownType, ENUM_DRAWDOWN_PERCENTAGE); //Drawdown Type
INPUT(double, DrawDownToCloseValue, 5);  //Drawdown to close
//INPUT_SEP("Pause");
INPUT(int, MaxTrades, 100);        //Max Trades
INPUT(int, SpreadFilter, 50);      //Spread Filter
//INPUT_SEP("Miscelaneous");
INPUT(bool, DisplayInformaion, false);//Display Information Status
END_INPUT
//+------------------------------------------------------------------+
DECLARE_EA(CAutoProfit40, true, "AutoProfit40");
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
