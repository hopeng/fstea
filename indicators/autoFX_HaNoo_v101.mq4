/*
+------------------------------------------------------------------+
|                                                     autoFX_HaNoo |
|                                     Copyright 2005, AutoFX Corp. |
|                                                      version 1.0 |
|                                                                  |
|                                  o idea and realization by matt  |
| o realization and rewritten/enhanced to MQL4 by NOO@AutoFX Corp. |
+------------------------------------------------------------------+
for going long you must have the HA in White, 
Awesome Oscilator > 0, and Close[1] > 200 day EMA.  The reverse is 
true for going short.  The exit is ofcourse when the HA turns colors.
*/

#property copyright "Copyright 2005, AutoFX Corp."
#property link      "http://www.AutoFX.cn/"

#include <stdlib.mqh>

// V.*******************************************************
// ****          Variables Declared                     ****
// ****   variables declared here are GLOBAL in scope   ****
// *********************************************************
extern double Lots = 1.0;
extern int    Slippage = 2;
extern int    UseDefaultSeting = 1;
extern int    StopLoss = 50; 
extern int    TakeProfit = 0;
extern int    TrailingStop = 30;
extern int    ProfitKeep = 10;

double   LotMM = 0;
datetime NewBarTime;
int      DebugMsg = 0;

string CurrentSymbol;
int    CurrentPeriod;
double CurrentPoint;

int    MagicNumber = 20050907;
string MagicName = "HaNoo";
int    ServerTimeZone = 0;
   
double haOpen[3],haHigh[3],haLow[3],haClose[3];  //indicators: Heiken Ashi
int    haDirection[3];

double ema;  //indicators: ema
double ao;  //indicators: ao


//+------------------------------------------------------------------+
int init() { 
   CurrentSymbol = Symbol();
   CurrentPeriod = Period();
   CurrentPoint  = MarketInfo (CurrentSymbol, MODE_POINT);
   
// C.*****************************************************
// ***   Main Script Conditions                        ***
// *******************************************************
   if(TakeProfit<10) {
      Print("TakeProfit<10");
      return(-1);
   }
   if(Bars < 300) {
      Print("Bars less than 300, Not enough bars on chart.");
      return(-1);
   }
   
// P.***********************************************************
// *** Define Parameter in different period                  ***
// *************************************************************
   switch(CurrentPeriod) {
      case 30:  //30min
         if(UseDefaultSeting==1) { StopLoss=50; TakeProfit=0; TrailingStop=30; ProfitKeep=10; }
         break;
      case 60:  //1H
         if(UseDefaultSeting==1) { StopLoss=50; TakeProfit=0; TrailingStop=30; ProfitKeep=10; }
         break;         
      default:
         Comment("\n","Current Period ( ",CurrentPeriod," ) IS NOT GOOD for Trade by this Experts. ");
         return(0);
         break;
   }
   
   return(0);
}  //close for init()

//+------------------------------------------------------------------+
int start()
{
// T.**********************************************
// *** Trade in TimeZone                        ***
// ************************************************
   if(TimeHour(CurTime()) + ServerTimeZone >= 19 || TimeHour(CurTime()) + ServerTimeZone <= 0) {
      Comment ("\n","Current Time : ",TimeToStr(CurTime())," ( GTM=", ServerTimeZone," ) is NOT GOOD for Trade by this Robot",
               "\n");
      return(0);
   }
   

// I.*****************************************************
// ***    Messages & Screen Output Setting             ***
// *******************************************************
   if(NewBarTime != Time[0]) {ObjectsDeleteAll(0, OBJ_ARROW); NewBarTime = Time[0];}
   //DebugMsg = 0;    //999 for nothing
   DebugMsg ++;
   if(DebugMsg>1) DebugMsg=0;
   
// I.*****************************************************
// ***    Get Indicators Results                       ***
// *******************************************************
   haLow[0]  =iCustom(NULL,0,"#HeikenAshi",0,0);
   haHigh[0] =iCustom(NULL,0,"#HeikenAshi",1,0);
   haOpen[0] =iCustom(NULL,0,"#HeikenAshi",2,0);
   haClose[0]=iCustom(NULL,0,"#HeikenAshi",3,0);
   if (haOpen[0] < haClose[0] && haHigh[0] > haLow[0]) haDirection[0] =  1;
   if (haOpen[0] > haClose[0] && haHigh[0] < haLow[0]) haDirection[0] = -1;

   haLow[1]  =iCustom(NULL,0,"#HeikenAshi",0,1);
   haHigh[1] =iCustom(NULL,0,"#HeikenAshi",1,1);
   haOpen[1] =iCustom(NULL,0,"#HeikenAshi",2,1);
   haClose[1]=iCustom(NULL,0,"#HeikenAshi",3,1);
   if (haOpen[1] < haClose[1] && haHigh[1] > haLow[1]) haDirection[1] =  1;
   if (haOpen[1] > haClose[1] && haHigh[1] < haLow[1]) haDirection[1] = -1;

   haLow[2]  =iCustom(NULL,0,"#HeikenAshi",0,2);
   haHigh[2] =iCustom(NULL,0,"#HeikenAshi",1,2);
   haOpen[2] =iCustom(NULL,0,"#HeikenAshi",2,2);
   haClose[2]=iCustom(NULL,0,"#HeikenAshi",3,2);
   if (haOpen[2] < haClose[2] && haHigh[2] > haLow[2]) haDirection[2] =  1;
   if (haOpen[2] > haClose[2] && haHigh[2] < haLow[2]) haDirection[2] = -1;

   ema=iMA(NULL,0,200,1,MODE_EMA,PRICE_CLOSE,1);  //ema200
   ao=iAO(NULL, 0, 0);


// L.1******************************************************
// ****       LONG / SHORT TRADE LOGIC                  ****
// *********************************************************
   //Direction
   bool GoLong_DIR = false, GoShort_DIR = false;
   if(ao>0 && Close[1]>ema) GoLong_DIR =true;
   if(ao<0 && Close[1]<ema) GoShort_DIR=true;

   //Momentum 
   bool GoLong_MOM = false, GoShort_MOM = false;
   GoLong_MOM =true; GoShort_MOM=true;

   //open order in BAR
   bool GoLong_BAR = false, GoShort_BAR = false,  CloseLong_BAR = false, CloseShort_BAR = false;
   GoShort_BAR=true;  GoLong_BAR =true;


   //Entry Sign
   bool GoLong_SIN = false, GoShort_SIN = false;
   if(haDirection[2]==-1 && haDirection[1]==1) GoLong_SIN =true;
   if(haDirection[2]== 1 && haDirection[1]==1) GoShort_SIN=true;
   

   //Exit Sign
   bool CloseLong_SIN = false, CloseShort_SIN = false;
   if(GoLong_SIN ==true ) CloseShort_SIN = true;
   if(GoShort_SIN==true ) CloseLong_SIN  = true;
   
       
   //LONG and SHORT TRADE LOGIC
   bool GoLong = false, CloseLong = false, GoShort = false, CloseShort = false;
   GoLong  = GoLong_DIR  && GoLong_MOM  && GoLong_SIN  && GoLong_BAR;
   GoShort = GoShort_DIR && GoShort_MOM && GoShort_SIN && GoShort_BAR;
   CloseLong  = CloseLong_SIN && CloseLong_BAR;
   CloseShort = CloseShort_SIN && CloseShort_BAR; 



// O.*******************************************************
// ****            Pending Order Management             ****
// *********************************************************
   int   OrderResult;
   int   TradesTotal=0, TradesBUY=0, TradesSELL=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if( OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false )  continue;
      if( OrderSymbol() != CurrentSymbol || OrderMagicNumber() != MagicNumber )  continue;

      OrderResult = 0;
      switch(OrderType())
      {
         case OP_BUY:
            // close order if trigger exit sign
            if(CloseLong==true) OrderResult = OrderClose(OrderTicket(),OrderLots(),Bid,0,White);
            if( OrderResult ==-1 ) ReportError("in OP_BUY close"); else { TradesBUY ++; TradesTotal ++; }
            break;
         case OP_SELL:
            // close order if trigger exit sign
            if(CloseShort==true) OrderResult = OrderClose(OrderTicket(),OrderLots(),Ask,0,Red);
            if( OrderResult ==-1 ) ReportError("in OP_SELL close"); else { TradesSELL ++; TradesTotal ++; }
            break;
      }
   }


// S.1******************************************************
// ****       calculate TakeProfit and StopLoss for     ****
// ****    (B)id (sell, short) and (A)sk(buy, long)     ****
// *********************************************************
   double  CalcStopLossBUY=0,CalcTakeProfitBUY=0;
   double  CalcStopLossSELL=0,CalcTakeProfitSELL=0;
   
   CalcStopLossBUY=Ask-(StopLoss * CurrentPoint);
   CalcTakeProfitBUY = Bid+(TakeProfit * CurrentPoint);

   CalcStopLossSELL=Bid+(StopLoss * CurrentPoint);
   CalcTakeProfitSELL = Ask-(TakeProfit * CurrentPoint);

   if(TakeProfit==0) {CalcTakeProfitBUY=0; CalcTakeProfitSELL=0;}
   if(StopLoss==0)   {CalcStopLossBUY=0; CalcStopLossSELL=0;}


// O.*******************************************************
// ****      Open Long/Short Trade Order                ****
// *********************************************************
   // place new orders based on direction
      OrderResult = 0;
      
      if(GoLong==true && TradesBUY<1)
      {
         OrderResult = OrderSend(Symbol(),OP_BUY,LotMM,Ask,Slippage,CalcStopLossBUY,CalcTakeProfitBUY,MagicName+" BUY "+CurrentPeriod,MagicNumber,0,White);
         if( OrderResult == -1 )  ReportError ("in OP_BUY open");
         if( OrderResult !=  0 )  { return(0); }
      }
        
      if(GoShort==true && TradesSELL<1)
      {
         OrderResult = OrderSend(Symbol(),OP_SELL,LotMM,Bid,Slippage,CalcStopLossSELL,CalcTakeProfitSELL,MagicName+" SEL "+CurrentPeriod,MagicNumber,0,Red);
         if( OrderResult == -1 )  ReportError ("in OP_SELL open");
         if( OrderResult !=  0 )  { return(0); }
      }
      
   
// T.3******************************************************
// **** Stop Loss & TrailingStop Management             ****
// *********************************************************
      for(i=0;i<OrdersTotal();i++)
      {
         if( OrderSelect(i, SELECT_BY_POS, MODE_TRADES) == false )  continue;
         if( OrderSymbol() != CurrentSymbol || OrderMagicNumber() != MagicNumber )  continue;
         OrderResult = 0;
         
         if(OrderType()==OP_BUY)
         {
            if( OrderProfit()>0 )
            {
               if( ProfitKeep!=0 && TrailingStop!=0 && OrderStopLoss()!=0 && Bid-OrderStopLoss()>ProfitKeep*CurrentPoint+TrailingStop*CurrentPoint && Bid-OrderOpenPrice()>ProfitKeep*CurrentPoint+TrailingStop*CurrentPoint ) { OrderResult = OrderModify(OrderTicket(),OrderOpenPrice(),Bid-TrailingStop*CurrentPoint,OrderTakeProfit(),0,BlueViolet); }
               if( OrderResult ==-1 ) ReportError("in OP_BUY modify");
            }
         }
         
         if(OrderType()==OP_SELL)
         {
            if( OrderProfit()>0 )
            {
               if( ProfitKeep!=0 && TrailingStop!=0 && OrderStopLoss()!=0 && OrderStopLoss()-Ask>ProfitKeep*CurrentPoint+TrailingStop*CurrentPoint && OrderOpenPrice()-Ask>ProfitKeep*CurrentPoint+TrailingStop*CurrentPoint ) { OrderResult = OrderModify(OrderTicket(),OrderOpenPrice(),Ask+TrailingStop*CurrentPoint,OrderTakeProfit(),0,Cyan); }
               if( OrderResult ==-1 ) ReportError("in OP_SELL modify");
            }
         }

      } // close for if(cnt=0;cnt<total;cnt++)


// R.*******************************************************
// ****           Debug Messages                        ****
// *********************************************************
   if(DebugMsg != 999)
   {
      switch(DebugMsg) {
         case 0:
         Comment ("\n","AO=",ao,
                  "\n","ema=",ema,"Close[1]=",Close[1],
                  "\n",
                  "\n","GoLong_DIR= ",GoLong_DIR," GoShort_DIR= ",GoShort_DIR,
                  "\n",
                  "\n","[HA0] Direction=",haDirection[0],
                  "\n","[HA1] Direction=",haDirection[1],
                  "\n","[HA2] Direction=",haDirection[2],
                  "\n",
                  "\n","GoLong_SIN= ",GoLong_SIN," GoShort_SIN= ",GoShort_SIN,
                  "\n","CloseLong_SIN= ",CloseLong_SIN," CloseShort_SIN= ",CloseShort_SIN,
                  "\n",
                  "\n","GoLong= ",GoLong," CloseLong= ",CloseLong," GoShort= ",GoShort," CloseShort= ",CloseShort,
                  "\n");
         break;
         case 1: 
         Comment ("\n","(",CurrentSymbol,") Trades Total= ",TradesTotal, " Lots= ",LotMM,
                  "\n",
                  "\n",TradesBUY,".onBUY ", TradesSELL,".onSELL ",
                  "\n",
                  "\n","BarTime= ",TimeToStr(NewBarTime)," (GTM= ", ServerTimeZone,") ",
                  "\n",
                  "\n","StopLoss= ",StopLoss, " TakeProfit= ",TakeProfit, " TrailingStop= ",TrailingStop, " ProfitKeep= ",ProfitKeep,
                  "\n","AccountBalance= ",AccountBalance(),
                  "\n","FreeMargin= ",AccountFreeMargin(),
                  "\n");
         break;
      }
   }//close for if(DebugMsg != 999)


   return(0);

} // close for start


//+------------------------------------------------------------------+
void ReportError (string ErrMsg)
{
   int err = GetLastError();
   Print("Error(",err,"): ", ErrorDescription(err)," ( ",ErrMsg," ) ");
}

