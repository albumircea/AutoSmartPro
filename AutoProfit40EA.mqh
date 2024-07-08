//+------------------------------------------------------------------+
//|                                               AutoProfit40EA.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"

#include "AutoProfit40Params.mqh"
#include <Mircea\_profitpoint\Lang\GlobalVariable.mqh>

/*
Updates:
2024.03.07 - Am mofificat  LateStart sa il puna lateStart = lateStart - 1 la inceput
2024.03.10 - Am mofificat  Fixat iara Late Start
2024.03.15 - Am fixat StopLoss/TakeProfit sa permita sa existe simultan
2024.05.13 - Added Spread Filter + move print parameters method inside parameter class


NOTES:
- INTREBARE VREAU SA FACA TRAILING CHIAR DACA FACE MEDIERE DUPA CE AJUNGE PE PROFIT SA LE SECURIZEZE ORICUM Momentan da
Sa fiu atent la bid si ask

- O metodaOnTradesChange care sa imi recalculeze TP/SL/Trailingurile daca s-au schimbat Volumelesau daca s-a schimbat ceva anume
de exemplu daca deschide un buy care ramane agatat sus eu am trailingu activat chiar daca nu mai are sens fiindca a incasat deja SL pozitiv pe suita
sa recalculez sau sa nu recalculez SL daca mi-a  dat un trade nou pe complementare sau doar sa mosteneasca trailingu de la toata successiunea <?>



TODO
- Store GlobalVariables
- Fix IsSessionTrade FOR MQL4

- flush la global variables atunci cand dau expert remove
- OnReInit
- Rename ComputeGlobalVariables
- Insert into GlobalVariables StopLoss
- LogWarning pentru Smart pentru SpreadFilter -TODO SA FAC SPREAD FILTER + EVENTUAL O CLASA SPREAD FILTER
- Daca schimb valorile Trailing sa le ia in considerare dupa ce da ok(acum le ia din global variables)
-
*/


struct STrailingValues
{
   bool              isTrailing;
   double            trailingStartPrice;
   double            trailingStepPrice;
   double            trailingCurrentSLValue;
   void              Reset()
   {
      isTrailing = false;
      trailingStartPrice = WRONG_VALUE;
      trailingStepPrice = WRONG_VALUE;
      trailingCurrentSLValue = WRONG_VALUE;
   }
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAutoSmartPro: public CExpertAdvisor
{
   //+------------------------------------------------------------------+
   //| scalingOrAveraging  - ENUM_DIRECTION_BULLISH = Scaling
   //|                     - ENUM_DIRECTION_BEARISH = Averaging
   //+------------------------------------------------------------------+
private:
   CAutoSmartProParams* _params;
   CTradeManager     _tradeManager;
   STrailingValues   _trailingValuesBuy;
   STrailingValues   _trailingValuesSell;
   double            _trailingStopAbs, _trailingStepAbs;
   CPositionInfo     _positionInfo;
   CGlobalVariableManager _globalVariableManager;
   CEquityStopService* _equityStopService;
   CCandleInfo       *_candleInfo;

   static const string IS_TRAILING_BUY, IS_TRAILING_SELL, TRAILING_START_BUY, TRAILING_START_SELL, TRAILING_STEP_BUY, TRAILING_STEP_SELL, TRAILING_STOPLOSS_BUY, TRAILING_STOPLOSS_SELL;
   const string      GLOBAL_PREFIX;

   const bool        TRADE_ON_NEW_CANDLE;
   bool              _isNewCandle;

protected:
   STradesDetails    _sTradeDetails;
public:
                     CAutoSmartPro(CAutoSmartProParams &params): TRADE_ON_NEW_CANDLE(params.GetIsNewCandleTrade()),
                     GLOBAL_PREFIX(StringFormat("%s|%s|%s|", __appShortName__, params.GetSymbol(), IntegerToString(params.GetMagic())))
   {

      _params = GetPointer(params);
      _tradeManager.SetMagic(_params.GetMagic());
      _tradeManager.SetSymbol(_params.GetSymbol());

      _trailingValuesBuy.Reset();
      _trailingValuesSell.Reset();

      _trailingStopAbs = _params.GetTrailingStop() * CSymbolInfo::GetPoint(_params.GetSymbol());
      _trailingStepAbs = _params.GetTrailingStep() * CSymbolInfo::GetPoint(_params.GetSymbol());

      //GLOBAL_PREFIX = StringFormat("%s|%s|%s|", __appShortName__, _params.GetSymbol(), IntegerToString(_params.GetMagic()));
      _globalVariableManager.SetPrefix(this.GLOBAL_PREFIX);
      _globalVariableManager.SetUsePrefix(true);

      _equityStopService = new CEquityStopService(_params.GetMagic(), _params.GetSymbol(), _params.IsCloseAtDrawDown(), _params.GetDrawDownType(), _tradeManager, _params.GetDrawDownToCloseValue());

      //TRADE_ON_NEW_CANDLE = false;
      _candleInfo = new CCandleInfo(_params.GetSymbol(), PERIOD_CURRENT);
      OnReInit();
   }
                    ~CAutoSmartPro()
   {
      SafeDelete(_equityStopService);
      SafeDelete(_candleInfo);
   }

public:
   virtual void       Main();
   virtual void       OnDeinit_(const int reason);
protected:
   virtual void       OnReInit();

protected:
   //Strategy
   virtual void               ManageTrades(ENUM_DIRECTION direction);
   virtual double             ComputeTakeProfit(ENUM_DIRECTION direction);
   virtual void               ComputeTrailingStart(ENUM_DIRECTION direction); // sa ma uit in metoda de manageBuys/Sells sa vad ce si cum
   virtual bool               CheckAveragingStep(ENUM_DIRECTION direction);
   virtual bool               CheckScalingStep(ENUM_DIRECTION direction);
   virtual bool               CheckNewCandle();
   virtual int                GetStep(ENUM_DIRECTION scalingOrAveraging, ENUM_DIRECTION direction = ENUM_DIRECTION_NEUTRAL);

   //Trailing
   virtual bool               ManageTrailing(ENUM_DIRECTION direction);
   virtual bool               CheckTrailingReference(ENUM_DIRECTION direction, const double referencePrice, const double currentPrice);
   virtual double             GetSLTrailingPrice(ENUM_DIRECTION direction, const double currentPrice);
   virtual void               AdjustTrailingValues(ENUM_DIRECTION direction, const double currentPrice, const double newStopLossPrice);
   virtual void               ResetTrailingValues(ENUM_DIRECTION direction);
   virtual double             GetTrailingReferencePrice(ENUM_DIRECTION direction);
   virtual double             GetTrailingCurrentPrice(ENUM_DIRECTION direction);
   virtual double             GetTrailingCurrentStopLoss(ENUM_DIRECTION direction);

   //Execution
   virtual long               OpenTrade(ENUM_DIRECTION direction, ENUM_DIRECTION scalingOrAveraging);
   virtual long               OpenFirstTrade(ENUM_DIRECTION direction);
   virtual bool               ModifyTrades(ENUM_DIRECTION direction, const double takeProfitPrice = 0.0, const double stopLossPrice = 0.0);
   virtual double             GetLots(ENUM_DIRECTION direction, ENUM_DIRECTION scalingOrAveraging);

   //Drawdown
   virtual void               ManageDrawDown();
   virtual bool               CheckDrawDownToClose();
   virtual double             GetDrawDown();

   //DashBoardSettings
   virtual void               ManageDashboard();
   virtual void               DisplayExpertInfo();
   virtual void               PrintInputParams(); //TODO toate valorile

   //Global Variables
   virtual void               LoadGlobalVariables(ENUM_DIRECTION direction);
   virtual bool               CheckGlobalVariables(ENUM_DIRECTION direction);
   virtual void               ComputeGlobalVariables(ENUM_DIRECTION direction);
   virtual void               UpdateGlobalVariables();
   //
};
//BUY
static const string CAutoSmartPro::IS_TRAILING_BUY = "B_IsTral";
static const string CAutoSmartPro::TRAILING_START_BUY = "B_TralStart";
static const string CAutoSmartPro::TRAILING_STEP_BUY = "B_TralStep";
static const string CAutoSmartPro::TRAILING_STOPLOSS_BUY = "B_StopLoss";
//SELL
static const string CAutoSmartPro::IS_TRAILING_SELL = "S_IsTralS";
static const string CAutoSmartPro::TRAILING_START_SELL = "S_TralStart";
static const string CAutoSmartPro::TRAILING_STEP_SELL = "S_TralStepS";
static const string CAutoSmartPro::TRAILING_STOPLOSS_SELL = "S_StopLoss";
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::Main(void)
{
   if(  !CSymbolInfo::IsSessionTrade(_params.GetSymbol()) ||
         CSymbolInfo::GetSpread(_params.GetSymbol()) > _params.GetSpreadFilter()
     )
      return;

   CTradeUtils::CalculateTradesDetails(_sTradeDetails, _params.GetMagic(), _params.GetSymbol());

   if(_equityStopService.CheckEquityStop()) //CheckLoggingForClosingAllTrades
      return;

   if(TRADE_ON_NEW_CANDLE)
      _isNewCandle = _candleInfo.IsNewCandle();


   ManageTrades(ENUM_DIRECTION_BULLISH);
   ManageTrades(ENUM_DIRECTION_BEARISH);

   UpdateGlobalVariables();
   if(_params.IsDisplayInformaion())
      DisplayExpertInfo();
}
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
void CAutoSmartPro::ManageTrades(ENUM_DIRECTION direction)
{
   if(direction == ENUM_DIRECTION_NEUTRAL)
      return;

   int positions = (direction == ENUM_DIRECTION_BULLISH)
                   ? _sTradeDetails.buyPositions
                   : _sTradeDetails.sellPositions;

   if(positions == 0 && CheckNewCandle())
   {
      OpenFirstTrade(direction); //TODO poate scot first trade intr o metoda separata
      //double tp = ComputeTakeProfit(direction);
      //ModifyTrades(direction, tp, 0.0);
      ResetTrailingValues(direction);
      ComputeTrailingStart(direction);
      return;
   }


   if(ManageTrailing(direction))
   {
      //     return; TODO think about it
   }

   if(positions > 0 && CheckNewCandle())
   {
      if(CheckAveragingStep(direction))
      {
         OpenTrade(direction, ENUM_DIRECTION_BEARISH);
         double tp = ComputeTakeProfit(direction);
         ModifyTrades(direction, tp, GetTrailingCurrentStopLoss(direction));
         ComputeTrailingStart(direction);
      }

      if(CheckScalingStep(direction))
      {
         OpenTrade(direction, ENUM_DIRECTION_BULLISH);
         ComputeTrailingStart(direction);

      }
   }
}
//+------------------------------------------------------------------+
//|
//+------------------------------------------------------------------+
bool CAutoSmartPro::CheckAveragingStep(ENUM_DIRECTION direction)
{
   int type =  CEnums::FromDirectionToMarketOrder(direction);
   ulong ticket = (direction == ENUM_DIRECTION_BULLISH)
                  ? _sTradeDetails.lowestLevelBuyPosTicket : // BUY -> lowestBUY
                  _sTradeDetails.highestLevelSellPosTicket;  // SELL -> highestSELL

   double price = CTradeUtils::StartPrice(_params.GetSymbol(), type);

   if(!_positionInfo.SelectByTicket(ticket))
   {
      int errorCode = GetLastError();
      LOG_ERROR(StringFormat("Could not select position with ticket[%s] >> [%s]:[%s]",
                             IntegerToString(ticket),
                             IntegerToString(errorCode),
                             ErrorDescription(errorCode)));
      return false;
   }

   int distance = MathAbs(CTradeUtils::DistanceBetweenTwoPricesPoints(_positionInfo.PriceOpen(), price, _positionInfo.Symbol()));

   ENUM_DIRECTION directionAveraging = ENUM_DIRECTION_BEARISH;

   if(direction == ENUM_DIRECTION_BULLISH)
   {
      //Ask - OrderOpenPrice() < 0
      return (price - _positionInfo.PriceOpen() < 0 && distance >= GetStep(directionAveraging, direction)); //_params.GetStepAveraging()
   }
   if(direction == ENUM_DIRECTION_BEARISH)
   {
      //Bid - OrderOpenPrice() > 0
      return (price - _positionInfo.PriceOpen() > 0 && distance >= GetStep(directionAveraging, direction));  //_params.GetStepAveraging()
   }

   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAutoSmartPro::CheckScalingStep(ENUM_DIRECTION direction)
{
   int type =  CEnums::FromDirectionToMarketOrder(direction);
   ulong ticket = (direction == ENUM_DIRECTION_BULLISH)
                  ? _sTradeDetails.highestLevelBuyPosTicket : // BUY -> highestBUY
                  _sTradeDetails.lowestLevelSellPosTicket;  // SELL -> lowestSELL

   double price = CTradeUtils::StartPrice(_params.GetSymbol(), type);

   if(!_positionInfo.SelectByTicket(ticket))
   {
      int errorCode = GetLastError();
      LOG_ERROR(StringFormat("Could not select position with ticket[%s] >> [%s]:[%s]",
                             IntegerToString(ticket),
                             IntegerToString(errorCode),
                             ErrorDescription(errorCode)));
      return false;
   }

   int distance = MathAbs(CTradeUtils::DistanceBetweenTwoPricesPoints(_positionInfo.PriceOpen(), price, _positionInfo.Symbol()));
   ENUM_DIRECTION directionScaling = ENUM_DIRECTION_BULLISH;

   if(direction == ENUM_DIRECTION_BULLISH)
   {
      //Ask - OrderOpenPrice() > 0
      return (price - _positionInfo.PriceOpen() > 0 && distance >= GetStep(directionScaling, direction)); //_params.GetStepScaling(
   }
   if(direction == ENUM_DIRECTION_BEARISH)
   {
      //Bid - OrderOpenPrice() < 0
      return (price - _positionInfo.PriceOpen() < 0 && distance >= GetStep(directionScaling, direction)); //_params.GetStepScaling(
   }

   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::ComputeTrailingStart(ENUM_DIRECTION direction)
{
   if(direction == ENUM_DIRECTION_BULLISH && !_trailingValuesBuy.isTrailing)
   {
      int type = CEnums::FromDirectionToMarketOrder(direction);
      double trailingStart = CRiskService::AveragingTakeProfitForBatch(type, _params.GetTrailingStart(), _params.GetMagic(), _params.GetSymbol());
      _trailingValuesBuy.trailingStartPrice = trailingStart;
   }
   else if(direction == ENUM_DIRECTION_BEARISH && !_trailingValuesSell.isTrailing)
   {
      int type = CEnums::FromDirectionToMarketOrder(direction);
      double trailingStart = CRiskService::AveragingTakeProfitForBatch(type, _params.GetTrailingStart(), _params.GetMagic(), _params.GetSymbol());
      _trailingValuesSell.trailingStartPrice = trailingStart;
   }
}
//+------------------------------------------------------------------+
//|Aici pot sa sparg in 2 metode
//|(Check)
//|(RecomputeAndPlaceStopLoss)
//+------------------------------------------------------------------+
bool CAutoSmartPro::ManageTrailing(ENUM_DIRECTION direction)
{
   double referencePrice = GetTrailingReferencePrice(direction); // IsTrailing ? TrailingStart : TrailingStep
   double currentPrice = GetTrailingCurrentPrice(direction);     //EndPrice(direction)

   if(!CheckTrailingReference(direction, referencePrice, currentPrice)) //Check if I can move SL
   {
      return false;
   }

   double newStopLossPrice = GetSLTrailingPrice(direction, currentPrice); //Compute new Trailing StopLoss

   if(ModifyTrades(direction, 0.0, newStopLossPrice)) //Execute Modification
   {
      AdjustTrailingValues(direction, currentPrice, newStopLossPrice); //Adjust Trailing Values -> so I can be able to move SL again next iteration
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAutoSmartPro::GetTrailingReferencePrice(ENUM_DIRECTION direction)
{
   bool isTrailing = (direction == ENUM_DIRECTION_BULLISH) ? _trailingValuesBuy.isTrailing : _trailingValuesSell.isTrailing;
   if(isTrailing)
   {
      //TrailingStepPrice
      return (direction == ENUM_DIRECTION_BULLISH) ? _trailingValuesBuy.trailingStepPrice : _trailingValuesSell.trailingStepPrice;
   }
//TrailingStartPrice
   return (direction == ENUM_DIRECTION_BULLISH) ? _trailingValuesBuy.trailingStartPrice : _trailingValuesSell.trailingStartPrice;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAutoSmartPro::GetTrailingCurrentPrice(ENUM_DIRECTION direction)
{
   int type = CEnums::FromDirectionToMarketOrder(direction);
   double currentPrice = CTradeUtils::EndPrice(_params.GetSymbol(), type);
   return currentPrice;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAutoSmartPro::GetTrailingCurrentStopLoss(ENUM_DIRECTION direction)
{
   if(direction == ENUM_DIRECTION_BULLISH)
      return (_trailingValuesBuy.trailingCurrentSLValue == WRONG_VALUE) ? (0.0) : _trailingValuesBuy.trailingCurrentSLValue;

   if(direction == ENUM_DIRECTION_BEARISH)
      return (_trailingValuesSell.trailingCurrentSLValue == WRONG_VALUE) ? (0.0) : _trailingValuesSell.trailingCurrentSLValue ;

   return (0.0);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::AdjustTrailingValues(ENUM_DIRECTION direction, const double currentPrice, const double newStopLossPrice)
{
   if(direction == ENUM_DIRECTION_BULLISH)
   {
      if(!_trailingValuesBuy.isTrailing)
      {
         _trailingValuesBuy.trailingStartPrice = WRONG_VALUE;
         _trailingValuesBuy.isTrailing = true;
      }

      _trailingValuesBuy.trailingStepPrice = currentPrice + _trailingStepAbs; // Bid + TrailingStep
      _trailingValuesBuy.trailingCurrentSLValue = newStopLossPrice;
   }
   else if(direction == ENUM_DIRECTION_BEARISH)
   {
      if(!_trailingValuesSell.isTrailing)
      {
         _trailingValuesSell.trailingStartPrice = WRONG_VALUE;
         _trailingValuesSell.isTrailing = true;
      }
      _trailingValuesSell.trailingStepPrice = currentPrice - _trailingStepAbs; //Ask - TrailingStep
      _trailingValuesSell.trailingCurrentSLValue = newStopLossPrice;
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long CAutoSmartPro::OpenTrade(ENUM_DIRECTION direction, ENUM_DIRECTION scalingOrAveraging)
{
// Determine the number of lots to trade based on Martingale settings
   double lots = GetLots(direction, scalingOrAveraging);

// Convert the direction into a market order type
   int orderType = CEnums::FromDirectionToMarketOrder(direction);
   if(orderType < 0)
      return false; // If conversion fails, return false

   string scalingOrAveragingStr = (scalingOrAveraging == ENUM_DIRECTION_BULLISH) ? "SC" : "AV";
   int positions = (direction == ENUM_DIRECTION_BULLISH) ? _sTradeDetails.buyPositions : _sTradeDetails.sellPositions;
// Perform market trade and check for successful ticket
   string comment = StringFormat("%s:%s,#%d", scalingOrAveragingStr, IntegerToString(_params.GetMagic()), positions);

   double stopLoss = 0.0;

   if(scalingOrAveraging == ENUM_DIRECTION_BULLISH && direction == ENUM_DIRECTION_BULLISH && _trailingValuesBuy.trailingCurrentSLValue != WRONG_VALUE)
   {
      stopLoss = _trailingValuesBuy.trailingCurrentSLValue;
   }
   else if(scalingOrAveraging == ENUM_DIRECTION_BULLISH && direction == ENUM_DIRECTION_BEARISH && _trailingValuesSell.trailingCurrentSLValue != WRONG_VALUE)
   {
      stopLoss = _trailingValuesSell.trailingCurrentSLValue;
   }
   return _tradeManager.Market(orderType, lots, stopLoss, 0.0, comment);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
long CAutoSmartPro::OpenFirstTrade(ENUM_DIRECTION direction)
{
   double lots = _params.GetLot();

   int orderType = CEnums::FromDirectionToMarketOrder(direction);
   if(orderType < 0)
      return false; // If conversion fails, return false

   string comment = StringFormat("%s,#%d", IntegerToString(_params.GetMagic()), 0);

   return _tradeManager.Market(orderType, lots, 0.0, 0.0, comment);
}
//+------------------------------------------------------------------+
//| scalingOrAveraging  - ENUM_DIRECTION_BULLISH = Scaling
//|                     - ENUM_DIRECTION_BEARISH = Averaging
//|
//|
//+------------------------------------------------------------------+
double CAutoSmartPro::GetLots(ENUM_DIRECTION direction, ENUM_DIRECTION scalingOrAveraging)
{
   double lots = _params.GetLot();

   if(direction == ENUM_DIRECTION_NEUTRAL || !_params.IsMartingale())
      return lots;

   int positions = (direction == ENUM_DIRECTION_BULLISH) ? _sTradeDetails.buyPositions : _sTradeDetails.sellPositions;

   if(scalingOrAveraging == ENUM_DIRECTION_BEARISH && positions < _params.GetLateStart())
      return lots;

   double factor = (scalingOrAveraging == ENUM_DIRECTION_BULLISH) ? _params.GetFactorScaling() : _params.GetFactorAveraging();
   double maxLot = (scalingOrAveraging == ENUM_DIRECTION_BULLISH) ? _params.GetMaxLotScaling() : _params.GetMaxLotAveraging();

   lots = CRiskService::GetVolumeBasedOnMartinGaleBatch(
             positions - (scalingOrAveraging == ENUM_DIRECTION_BEARISH ? _params.GetLateStart() : 0),//positions - ((scalingOrAveraging == ENUM_DIRECTION_BEARISH) ? _params.GetLateStart() : 0) + (scalingOrAveraging == ENUM_DIRECTION_BEARISH ? 1 : 0)//, //trebe +1 ca sa faca multiplicare altfel am trades-latestart = 0 si imi face POW(x,0)=1
             factor,
             _params.GetSymbol(),
             _params.GetLot(),
             ENUM_TYPE_MARTINGALE_MULTIPLICATION
          );

   return (lots <= maxLot) ? lots : maxLot;
}

//+------------------------------------------------------------------+
//|
//|Aici vreu sa vad:
//|Daca AM     trailing atunci sa pun trailing step la valoarea corecta si restu sa le resetez
//|Daca NU AM  trailing atunci sa recalculez totul cum fac in mod obisnuit
//+------------------------------------------------------------------+
void CAutoSmartPro::LoadGlobalVariables(ENUM_DIRECTION direction)
{
//Daca gasesc valorile pt trailing, continua
//if (!CheckGlobalVariables(direction))
//{
//   ComputeGlobalVariables(direction); //Rename
//   //return;
//}

//Daca NU gasesc valorile pt trailing, calculeaza
   ComputeGlobalVariables(direction); //Rename

   if(direction == ENUM_DIRECTION_BULLISH && !_trailingValuesBuy.isTrailing)
   {
      ResetTrailingValues(direction);
      ComputeTrailingStart(direction);
   }

   if(direction == ENUM_DIRECTION_BEARISH && !_trailingValuesSell.isTrailing)
   {
      ResetTrailingValues(direction);
      ComputeTrailingStart(direction);
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAutoSmartPro::CheckGlobalVariables(ENUM_DIRECTION direction)
{

   if(direction == ENUM_DIRECTION_BULLISH &&
         _globalVariableManager.Exists(IS_TRAILING_BUY) &&
         _globalVariableManager.Exists(TRAILING_START_BUY) &&
         _globalVariableManager.Exists(TRAILING_STEP_BUY) &&
         _globalVariableManager.Exists(TRAILING_STOPLOSS_BUY))
   {
      _trailingValuesBuy.isTrailing = (bool) _globalVariableManager.Get(IS_TRAILING_BUY);
      _trailingValuesBuy.trailingStartPrice = _globalVariableManager.Get(TRAILING_START_BUY);
      _trailingValuesBuy.trailingStepPrice = _globalVariableManager.Get(TRAILING_STEP_BUY);
      _trailingValuesBuy.trailingCurrentSLValue = _globalVariableManager.Get(TRAILING_STOPLOSS_BUY);
      return true;
   }

   if(direction == ENUM_DIRECTION_BEARISH &&
         _globalVariableManager.Exists(IS_TRAILING_SELL) &&
         _globalVariableManager.Exists(TRAILING_START_SELL) &&
         _globalVariableManager.Exists(TRAILING_STEP_SELL) &&
         _globalVariableManager.Exists(TRAILING_STOPLOSS_SELL))
   {
      _trailingValuesSell.isTrailing = (bool) _globalVariableManager.Get(IS_TRAILING_SELL);
      _trailingValuesSell.trailingStartPrice = _globalVariableManager.Get(TRAILING_START_SELL);
      _trailingValuesSell.trailingStepPrice = _globalVariableManager.Get(TRAILING_STEP_SELL);
      _trailingValuesSell.trailingCurrentSLValue = _globalVariableManager.Get(TRAILING_STOPLOSS_SELL);
      return true;
   }
   return false;
}
//+------------------------------------------------------------------+
//| 1. Sa verific daca am SL la vre-o tranzactie
//| 2. Daca am SL la acea tranzactie(direction)
//|   2a) isTrailing(direction)     = True
//|   2b) TrailingStep(direction)   = SLValue +- TRAl_STEP
//|   2c) TrailingStart(direction)  = WRONG_VALUE
//| 3. Dac nu am SL la nicio tranzactie atunci
//|   3) CompunteTrailingStart(direction)
//+------------------------------------------------------------------+
void CAutoSmartPro::ComputeGlobalVariables(ENUM_DIRECTION direction)
{

   for(int index = PositionsTotal() - 1; index >= 0 && !IsStopped(); index--)
   {
      if(!_positionInfo.SelectByIndex(index) || _positionInfo.Magic() != _params.GetMagic() || _positionInfo.Symbol() != _params.GetSymbol())
         continue;
      // StopLoss > 0 -> isTrailing = True
      if(direction == ENUM_DIRECTION_BULLISH && _positionInfo.PositionType() == POSITION_TYPE_BUY && _positionInfo.StopLoss() > 0)
      {
         _trailingValuesBuy.isTrailing = true;
         _trailingValuesBuy.trailingStartPrice = WRONG_VALUE;
         _trailingValuesBuy.trailingStepPrice = _positionInfo.StopLoss() + _trailingStepAbs;
         _trailingValuesBuy.trailingCurrentSLValue = _positionInfo.StopLoss();
         return;
      }
      // StopLoss > 0 -> isTrailing = True
      if(direction == ENUM_DIRECTION_BEARISH && _positionInfo.PositionType() == POSITION_TYPE_SELL && _positionInfo.StopLoss() > 0)
      {
         _trailingValuesSell.isTrailing = true;
         _trailingValuesSell.trailingStartPrice = WRONG_VALUE;
         _trailingValuesSell.trailingStepPrice = _positionInfo.StopLoss() - _trailingStepAbs;
         _trailingValuesSell.trailingCurrentSLValue = _positionInfo.StopLoss();
         return;
      }
   }
   if(direction == ENUM_DIRECTION_BULLISH)
   {
      _trailingValuesBuy.Reset();

   }
   else if(direction == ENUM_DIRECTION_BEARISH)
   {
      _trailingValuesSell.Reset();
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::UpdateGlobalVariables()
{
   _globalVariableManager.Set(IS_TRAILING_BUY, _trailingValuesBuy.isTrailing);
   _globalVariableManager.Set(TRAILING_START_BUY, _trailingValuesBuy.trailingStartPrice);
   _globalVariableManager.Set(TRAILING_STEP_BUY, _trailingValuesBuy.trailingStepPrice);
   _globalVariableManager.Set(TRAILING_STOPLOSS_BUY, _trailingValuesBuy.trailingCurrentSLValue);

   _globalVariableManager.Set(IS_TRAILING_SELL, _trailingValuesSell.isTrailing);
   _globalVariableManager.Set(TRAILING_START_SELL, _trailingValuesSell.trailingStartPrice);
   _globalVariableManager.Set(TRAILING_STEP_SELL, _trailingValuesSell.trailingStepPrice);
   _globalVariableManager.Set(TRAILING_STOPLOSS_SELL, _trailingValuesSell.trailingCurrentSLValue);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::OnReInit(void)
{
   CTradeUtils::CalculateTradesDetails(_sTradeDetails, _params.GetMagic(), _params.GetSymbol());


//Modify TP if needed
   if(_sTradeDetails.buyPositions > 1)
   {
      double tp = CRiskService::AveragingTakeProfitForBatch((int)POSITION_TYPE_BUY, _params.GetTakeProfit(), _params.GetMagic(), _params.GetSymbol());
      ModifyTrades(ENUM_DIRECTION_BULLISH, tp, 0.0);
   }
   if(_sTradeDetails.sellPositions > 1)
   {
      double tp = CRiskService::AveragingTakeProfitForBatch((int)POSITION_TYPE_SELL, _params.GetTakeProfit(), _params.GetMagic(), _params.GetSymbol());
      ModifyTrades(ENUM_DIRECTION_BEARISH, tp, 0.0);
   }
//Load TrailingValues
   LoadGlobalVariables(ENUM_DIRECTION_BULLISH);
   LoadGlobalVariables(ENUM_DIRECTION_BEARISH);
   UpdateGlobalVariables(); //
}
//+------------------------------------------------------------------+







//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAutoSmartPro::CheckTrailingReference(ENUM_DIRECTION direction, const double referencePrice, const double currentPrice)
{
   if(referencePrice <= 0.0)
      return false;

   if(direction == ENUM_DIRECTION_BULLISH && currentPrice >= referencePrice)
      return true;

   if(direction == ENUM_DIRECTION_BEARISH && currentPrice <= referencePrice)
      return true;

   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAutoSmartPro::GetSLTrailingPrice(ENUM_DIRECTION direction, const double currentPrice)
{
   if(direction == ENUM_DIRECTION_BULLISH)
   {
      return currentPrice - _trailingStopAbs;   // Bid - TrailingStop
   }
   if(direction == ENUM_DIRECTION_BEARISH)
   {
      return currentPrice + _trailingStopAbs;   //Ask + TrailingStop
   }
   return WRONG_VALUE;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::ResetTrailingValues(ENUM_DIRECTION direction)
{
   if(direction == ENUM_DIRECTION_BULLISH)
   {
      _trailingValuesBuy.Reset();
   }
   else if(direction == ENUM_DIRECTION_BEARISH)
   {
      _trailingValuesSell.Reset();
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CAutoSmartPro::ComputeTakeProfit(ENUM_DIRECTION direction)
{
   int type = CEnums::FromDirectionToMarketOrder(direction);
   return CRiskService::AveragingTakeProfitForBatch(type, _params.GetTakeProfit(), _params.GetMagic(), _params.GetSymbol());
}
//+------------------------------------------------------------------+
//|     Aici trebuie sa ma gandesc ca daca cumva modific TP si am SL sa nu il pun 0, sa il las la fel|
//+------------------------------------------------------------------+
bool CAutoSmartPro::ModifyTrades(ENUM_DIRECTION direction, const double takeProfitPrice = 0.0, const double stopLossPrice = 0.0)
{
   int type = CEnums::FromDirectionToMarketOrder(direction);
   return _tradeManager.ModifyMarketBatch(_params.GetMagic(), stopLossPrice, takeProfitPrice, _params.GetSymbol(), type, LOGGER_PREFIX_ERROR, true, false);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CAutoSmartPro::CheckNewCandle()
{
   if(!TRADE_ON_NEW_CANDLE)
      return true;

   return _isNewCandle;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::DisplayExpertInfo(void)
{
// hedge.DisplayHedgeDashBoard();
// return;
//   string drawDownType = (mDrawDownType == ENUM_DRAWDOWN_PERCENTAGE) ? "Percent" : "Cash";
   string space = "                                                                       ";
   string dashboard = space + "AutoProfit BETA4 Dashboard";


   dashboard += "\n" + space + "BUY IsTrailing: " + CString::FormatBool(_trailingValuesBuy.isTrailing);
   dashboard += "\n" + space + "BUY TrailingStart: " + DoubleToString(_trailingValuesBuy.trailingStartPrice, CSymbolInfo::GetDigits(_params.GetSymbol()));
   dashboard += "\n" + space + "BUY TrailingStep: " + DoubleToString(_trailingValuesBuy.trailingStepPrice, CSymbolInfo::GetDigits(_params.GetSymbol()));
   dashboard += "\n" + space + "BUY Next Lot Averaging: " + DoubleToString(GetLots(ENUM_DIRECTION_BULLISH, ENUM_DIRECTION_BEARISH), 2);
   dashboard += "\n" + space + "BUY Next Lot Scaling: " + DoubleToString(GetLots(ENUM_DIRECTION_BULLISH, ENUM_DIRECTION_BULLISH), 2);

   dashboard += "\n" + space + "SELL IsTrailing: " + CString::FormatBool(_trailingValuesSell.isTrailing);
   dashboard += "\n" + space + "SELL TrailingStart: " + DoubleToString(_trailingValuesSell.trailingStartPrice, CSymbolInfo::GetDigits(_params.GetSymbol()));
   dashboard += "\n" + space + "SELL TrailingStep: " + DoubleToString(_trailingValuesSell.trailingStepPrice, CSymbolInfo::GetDigits(_params.GetSymbol()));
   dashboard += "\n" + space + "SELL Next Lot Averaging: " + DoubleToString(GetLots(ENUM_DIRECTION_BEARISH, ENUM_DIRECTION_BEARISH), 2);
   dashboard += "\n" + space + "SELL Next Lot Scaling: " + DoubleToString(GetLots(ENUM_DIRECTION_BEARISH, ENUM_DIRECTION_BULLISH), 2);

//dashboard += "\n" + space + "GrossProfit: " + DoubleToString(_sTradeDetails.totalGrossProfit, 2);
//dashboard += "\n" + space + "Spread: " + IntegerToString(CSymbolInfo::GetSpread(mSymbol));

   dashboard += "\n" + space + "RunningProfit: " + DoubleToString(_equityStopService.GetDrawDown(), 2);
   if(_params.IsCloseAtDrawDown())
      dashboard += "\n" + space + "DrawDownToCloseValue: " + DoubleToString(_params.GetDrawDownToCloseValue(), 2);

   Comment(dashboard);
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::PrintInputParams()
{
   _params.PrintParamters();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CAutoSmartPro::OnDeinit_(const int reason)
{
   Comment("");
   _globalVariableManager.Flush();
#ifdef __MQL5__
// if(reason == REASON_PARAMETERS)
   PrintInputParams();
#endif
}



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CAutoSmartPro::GetStep(ENUM_DIRECTION scalingOrAveraging, ENUM_DIRECTION direction = ENUM_DIRECTION_NEUTRAL)
{
   if(scalingOrAveraging == ENUM_DIRECTION_BULLISH)
      return _params.GetStepScaling();

   if(scalingOrAveraging == ENUM_DIRECTION_BEARISH)
      return _params.GetStepAveraging();

   return 0;
}
//+------------------------------------------------------------------+
