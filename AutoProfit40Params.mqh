//+------------------------------------------------------------------+
//|                                           AutoProfit40Params.mqh |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"



#include <Mircea/_profitpoint/Base/ExpertBase.mqh>
#include <Mircea/_profitpoint/Trade/TradeManager.mqh>
#include <Mircea/RiskManagement/RiskService.mqh>
#include <Mircea/_profitpoint/Mql/CandleInfo.mqh>
#include <Mircea/RiskManagement/RiskService.mqh>
#include <Mircea/RiskManagement/EquityStopService.mqh>
#include <Mircea/ExpertAdvisors/Hedge/HedgeCandles.mqh>




const ulong __authorizedAccounts[] = {522562,533331,533332};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAutoSmartProParams : public CAppParams
{
                     ObjectAttrProtected(int, Magic);
                     ObjectAttrBoolProtected(Martingale);
                     ObjectAttrProtected(double, FactorAveraging);
                     ObjectAttrProtected(double, FactorScaling);
                     ObjectAttrProtected(int, TakeProfit);
                     ObjectAttrProtected(int, StepAveraging);
                     ObjectAttrProtected(int, StepScaling);
                     ObjectAttrProtected(double, Lot);
                     ObjectAttrProtected(double, MaxLotAveraging);
                     ObjectAttrProtected(double, MaxLotScaling);
                     ObjectAttrProtected(int, TrailingStop);
                     ObjectAttrProtected(int, TrailingStart);
                     ObjectAttrProtected(int, TrailingStep);
                     ObjectAttrProtected(bool, IsNewCandleTrade);
                     ObjectAttrProtected(int, LateStart);
                     ObjectAttrBoolProtected(CloseAtDrawDown);
                     ObjectAttrProtected(ENUM_DRAWDOWN_TYPE, DrawDownType);
                     ObjectAttrProtected(double, DrawDownToCloseValue);
                     ObjectAttrProtected(int, MaxTrades);
                     ObjectAttrProtected(int, SpreadFilter);
                     ObjectAttrBoolProtected(DisplayInformaion);
                     //21
                     ObjectAttrProtected(string, Symbol);
                     

public:
   virtual void              CAutoSmartProParams::PrintParamters(void)
   {
      string msg = StringFormat("%s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s, %s = %s",
                                nameOf(mMagic), IntegerToString(mMagic),
                                nameOf(mIsMartingale), CString::FormatBool(mIsMartingale),
                                nameOf(mFactorAveraging), DoubleToString(mFactorAveraging, 5),
                                nameOf(mFactorScaling), DoubleToString(mFactorScaling, 5),

                                nameOf(mTakeProfit), IntegerToString(mTakeProfit),
                                nameOf(mStepAveraging), IntegerToString(mStepAveraging),
                                nameOf(mStepScaling), IntegerToString(mStepScaling, 3),
                                nameOf(mMaxLot), DoubleToString(mLot, 2),
                                nameOf(mMaxLotAveraging), DoubleToString(mMaxLotAveraging, 2),
                                nameOf(mMaxLotScaling), DoubleToString(mMaxLotScaling, 2),

                                nameOf(mTrailingStop), IntegerToString(mTrailingStop),
                                nameOf(mTrailingStart), IntegerToString(mTrailingStart),
                                nameOf(mTrailingStep), IntegerToString(mTrailingStep),

                                nameOf(mIsNewCandleTrade), CString::FormatBool(mIsNewCandleTrade),
                                nameOf(mLateStart), IntegerToString(mLateStart),
                                nameOf(mIsCloseAtDrawDown), CString::FormatBool(mIsCloseAtDrawDown),
                                nameOf(mDrawDownType), EnumToString(mDrawDownType),
                                nameOf(mDrawDownToCloseValue), DoubleToString(mDrawDownToCloseValue, 3),

                                nameOf(mMaxTrades), IntegerToString(mMaxTrades),
                                nameOf(mSpreadFilter),  IntegerToString(mSpreadFilter),
                                nameOf(mIsDisplayInformaion), CString::FormatBool(mIsDisplayInformaion)
                               );

      Print(msg);
   }


public:
   bool               Check() override
   {

      //if(!CMQLInfo::IsTesting_()) return false;

      //if(!CAuthorization::Authorize(__authorizedAccounts))
      //{
      //   Alert("This Expert Advisor is only available on demo accounts or strategy tester");
      //   return false;
      //}


      if(mMagic <= 0)
      {
         Alert("Magic Number cannot be negative");
         return false;
      }
      if(mStepAveraging <= 0 || mStepScaling <= 0)
      {
         Alert("Step cannot pe negative or zero");
         return false;
      }
      if(mFactorAveraging == 0 || mFactorAveraging == 0)
      {
         Alert("Multiplier cannot be zero");
         return false;
      }
      if(CString::IsEmptyOrNull(mSymbol))
      {
         mSymbol = Symbol();
      }

      string message = NULL;
      mLot = (mLot != 0.0) ? mLot : CSymbolInfo::GetMinLot(mSymbol);

      if(!CTradeUtils::IsLotsValid(mMaxLotAveraging, mSymbol, message) ||
            !CTradeUtils::IsLotsValid(mMaxLotScaling, mSymbol, message) ||
            !CTradeUtils::IsLotsValid(mLot, mSymbol, message)
        )
      {
         Alert(message);
         return false;
      }


      return true;
   }




};
//+------------------------------------------------------------------+
