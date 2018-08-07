//+------------------------------------------------------------------+
//|                                                          EA1.mq4 |
//|                        Copyright 2014, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2014, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "..\libraries\chuckLib.mq4"


extern int DIRECTION = 0; //0 nothing, 1 long, 2 short, 3 range, 
extern bool enableLeastProfit = false;
extern bool enableTrailingSL = false;
extern bool enableAddingLosingPosition = false;
extern bool takingInterestOrder = false;
extern bool closeOrderToAvoidInterest = false;
extern int leastProfitPoints = 50;
extern int leastProfitTrigerPoints = 100;
extern int trailingPoints = 100;
extern int trailingTrigerPoints = 200;
extern int losingPositionTriggerPoint = 700;
extern double losingPositionMultiplier = 1;
extern int losingPositionProfitTarget = 100;
extern int interestPoint=10;
extern int day = 3;
extern int avoidInterestAcceptedLossPoint=0;
extern int avoidInterestNewOrderDiffPoint=100;
string message = "";
datetime curTime;


int OnInit()
{
    curTime = Time[0];   
    Print(Point());
    return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
  
}
void OnTick()
{   
   message = "";
   if (takingInterestOrder) if (!placeInterestOrder(day,22,1,interestPoint)) message += "\nSENDing ORDER FAILED" + GetLastError();
   if (closeOrderToAvoidInterest)
   {
      if (TimeDayOfWeek(TimeCurrent())==2 && TimeHour(TimeCurrent()) == 16 && TimeMinute(TimeCurrent()) == 18 && TimeSeconds(TimeCurrent())>=30)
      { 
       for (int i = OrdersTotal() - 1; i >= 0; i--)
       {
           if (OrderSelect(i, SELECT_BY_POS))
           {  
               int oType = OrderType();
               double oPrice = OrderOpenPrice();
               string oSymbol = OrderSymbol(); 
               int oTicket = OrderTicket(); 
               double oSize = OrderLots(); 
               double oSL = OrderStopLoss();
               double oTP = OrderTakeProfit();  
                  
               if (oSymbol == Symbol())
               {             
                  if (oType == OP_BUY && (StringFind(oSymbol,"EURUSD") != -1 || StringFind(oSymbol,"GBPUSD") != -1) && oPrice - Bid <= avoidInterestAcceptedLossPoint*Point())
                     {
                        double priceForLMT = Bid-avoidInterestNewOrderDiffPoint*Point();      
                        if (OrderClose(oTicket,oSize,Bid,0)) 
                           while (OrderSend(oSymbol,OP_BUYLIMIT,oSize,priceForLMT,0,oSL,oTP,"AUTO CLOSE TO AVOID INTEREST")==-1) priceForLMT = priceForLMT - Point();                           
                     }
                  if (oType == OP_SELL && (StringFind(oSymbol,"USDJPY") != -1 || StringFind(oSymbol,"USDCAD") != -1) && Ask - oPrice <= avoidInterestAcceptedLossPoint*Point())
                     {
                        double priceForLMT = Ask+avoidInterestNewOrderDiffPoint*Point();                       
                        if (OrderClose(oTicket,oSize,Ask,0))  
                           while(OrderSend(oSymbol,OP_SELLLIMIT,oSize,priceForLMT,0,oSL,oTP,"AUTO CLOSE TO AVOID INTEREST")==-1) {Alert(GetLastError());priceForLMT = priceForLMT + Point();}
                     }
               }           
           }
       }
      }
   }
   int count = 0;
   for (int i = OrdersTotal() - 1; i >= 0; i--)
    {
        if (OrderSelect(i, SELECT_BY_POS))
        {
            if (OrderSymbol() == Symbol() && (OrderType() == OP_BUY || OrderType() == OP_SELL) ) count++;
        }
    }
   if (count == 1) 
   {
      if (enableLeastProfit) if (!leastProfit(leastProfitPoints, leastProfitTrigerPoints, Symbol())) message += "\nSENDing ORDER FAILED" + GetLastError();
      if (enableTrailingSL) if (!trailingLoss(trailingPoints, trailingTrigerPoints, Symbol())) message += "\nSENDing ORDER FAILED" + GetLastError();
      if (enableAddingLosingPosition) if (!addLosingPosition(losingPositionTriggerPoint, losingPositionProfitTarget, losingPositionMultiplier, Symbol())) message += "\nSENDing ORDER FAILED" + GetLastError();
   }
   if (message != "") { Print(message); SendMail(Symbol(), message); }
   curTime = Time[0];
}
