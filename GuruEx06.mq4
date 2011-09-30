//+------------------------------------------------------------------+
//|                                                     GuruEx06.mq4 |
//|  Copyright © 2010-11, Marketing Dreams Ltd. All Rights Reserved. |
//|                                         http://trading-gurus.com |
//|                                                                  |
//| GuruTrader™ example 6                                            |
//| Version 1.03                                                     |
//|                                                                  |
//| A modified version of our first example robot.                   |
//| Instead of "random" entries this one enters on the breakout from |
//| a range, a bit like our fourth example robot.                    |
//| It ends up looking a lot like the "London Breakout" robots that  |
//| seem to be all the rage at the moment.                           |
//|                                                                  |
//| Wealth Warning! This expert is for educational purposes only.    |
//| It should NEVER be used on a live account. Past performance is   |
//| in no way indicative of future results!                          |
//+------------------------------------------------------------------+
//+ Revision History                                                 +
//+                                                                  +
//+ 1.03 - January 3rd 2011                                          +
//+        Changed long entry to work from ask instead of bid price  +
//+        Added FixedStart/RangeControl input settings to make      +
//+        optimization easier                                       +
//+ 1.02 - November 28th 2010                                        +
//+        Added money management, EntryGap, TrailingStop and        +
//+        automatic DP adjustment                                   +
//+ 1.01 - August 15th 2010                                          +
//+        Added display of "overnight" range on chart               +
//+        Fixed bug when trading session continues overnight        +
//+        Changed time handling to match MQL5 version               +
//+        Changed default settings to 30/30                         + 
//+        Added "FadeEntry" input setting                           +
//+ 1.00 - May 1st 2010                                              +
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010-11, Marketing Dreams Ltd."
#property link      "http://community.trading-gurus.com/threads/8-London-Breakout-System"

#define SLEEP_OK     250
#define SLEEP_ERR    250

#define SECS_PER_HOUR 3600
#define SECS_PER_DAY 86400

//---- input parameters
extern int        Magic = 12350;             // Magic number to distinguish this expert from others on the same account 
extern int        MaxSlippage=3;
extern int        ProfitTarget=30;  
extern int        StopLoss=30;  
extern int        MMType=0;                  // Money management method - 0 = None (Fixed order size)
                                             // 1 = Fixed Fractional, 2 = Fixed % at risk
extern double     Lots = 0.1;                // Size of each order (if not using money management)
extern double     RiskPercent = 1.0;         // Money management master control (use with caution!!!)  
extern int        StartTradingHour=8;        // Must use server time, not local time
extern bool       FixedStart=TRUE;           // Set to true to use fixed range start time, false for fixed duration range
extern int        RangeControl=1;            // Range start time, or range duration
extern int        EntryGap = 1;              // Gap between overnight range and entry price  
extern bool       TrailingStop = FALSE;      // Set TRUE to use a trailing stop
extern bool       FadeEntry = FALSE;         // Set TRUE to take trade in opposite direction to signal
extern bool       StpMode = FALSE;           // Set TRUE for brokers that don't accept market orders with built in stops
extern color      RangeColour=Turquoise;     // Colour of overnight range box

//---- static variables
static int        Dig;
static int        Stops;
static double     Points;

static bool       Initialized = FALSE;
static bool       Running = FALSE;
static bool       Started = FALSE;
static bool       Finished = TRUE;
static int        Target;
static int        Stop;
static int        Gap;
static int        OrderNumber;
static int        Slippage;
static double     MinLots;
static double     MaxLots;
static double     StepLots;
static double     RangeMax;
static double     RangeMin;
static double     BestPrice;
static int        BoxCount = 1;
static datetime   NightStarted;
static datetime   StartTrading;              // Start of trading session
static datetime   StartRange;                // Start of overnight session

static color      clBuy = DodgerBlue;
static color      clSell = Crimson;

//+------------------------------------------------------------------+
//| Utility functions                                                |
//+------------------------------------------------------------------+
#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>

//+------------------------------------------------------------------+
//| Expert helper functions                                          |
//+------------------------------------------------------------------+

int mod(int a, int b) {
  return(a - b * (a / b));
}

void DrawRange(datetime Start, double Max, datetime End, double Min)
{
   int Range;
   string Name, Label;
   
   Range = (Max - Min) / Points;
   
   Comment("High = ", DoubleToStr(Max, Dig),
           ", Low = ", DoubleToStr(Min, Dig),
           ", Range ", Range);
   
   Name = "GuruEx06Range" + BoxCount;
   Label = "Max " + DoubleToStr(Max, Dig) + ", Min " + DoubleToStr(Min, Dig) + ", Range " + Range;
   ObjectCreate(Name, OBJ_RECTANGLE, 0, Start, Max, End, Min);
   ObjectSet(Name, OBJPROP_COLOR, RangeColour);
   ObjectSetText(Name, Label);

   BoxCount++;
}

//+------------------------------------------------------------------+
//| Calculates position size                                         |
//+------------------------------------------------------------------+
double PositionSize()
{
   double Size, TickValue;
   
   TickValue = MarketInfo(Symbol(), MODE_TICKVALUE);

   switch (MMType) {
   case 1:
      Size = 0.0001 * AccountEquity() * RiskPercent;
      break;
   case 2:
      Size = 0.01 * AccountEquity() * RiskPercent / (Stop * TickValue);
      break;
   default:
      Size = Lots;
      break;
   }
      
   if (Size > MaxLots)
      Size = MaxLots;
   else if (Size < MinLots)
      Size = MinLots;
   else
      Size = MinLots + StepLots * MathFloor((Size - MinLots)/ StepLots);

   Print("Account currency = ", AccountCurrency(), ", Free Margin = ", AccountFreeMargin(), ", Leverage = ", AccountLeverage());
   Print("Money Management Type = ", MMType, ", Tick Value = ", TickValue, ", Size = ", Size);

   return (Size);
}

//+------------------------------------------------------------------+
//| Modifies an order                                                  |
//+------------------------------------------------------------------+
int Modify(int Ticket, double TargetPrice, double StopPrice)
{
   int ErrorCode;
   string TypeStr;
   color  TypeCol;
   double OrderPrice;
   
   if (OrderSelect(Ticket, SELECT_BY_TICKET) != TRUE) {
      ErrorCode = GetLastError();
      Print("Error selecting order ", Ticket, " to modify: ",
            ErrorDescription(ErrorCode), " (", ErrorCode, ")");
      return(-1);
   }
   
   switch (OrderType()) {
       case OP_BUY: 
          TypeStr = "BUY";
          TypeCol = clBuy;
          break; 
       case OP_BUYLIMIT: 
          TypeStr = "BUY Limit";
          TypeCol = clBuy;
          break; 
       case OP_BUYSTOP:
          TypeStr = "BUY Stop";
          TypeCol = clBuy;
          break; 
       case OP_SELL: 
          TypeStr = "SELL";
          TypeCol = clSell;
          break; 
       case OP_SELLLIMIT: 
          TypeStr = "SELL Limit";
          TypeCol = clSell;
          break; 
       case OP_SELLSTOP: 
          TypeStr = "SELL Stop";
          TypeCol = clSell;
          break; 
   }

   if (OrderModify(Ticket, OrderOpenPrice(), NormalizeDouble(StopPrice, Dig), NormalizeDouble(TargetPrice, Dig), 0, TypeCol)) {
      Sleep(SLEEP_OK);
      return (Ticket);
   } 	
   	
   ErrorCode = GetLastError();
   RefreshRates();
   Print("Error modifying ", TypeStr, " order ", Ticket,": ", ErrorDescription(ErrorCode),
         " (", ErrorCode, ")", ", Entry = ", DoubleToStr(OrderOpenPrice(), Dig), ", Target = ",
         DoubleToStr(TargetPrice, Dig), ", Stop = ", DoubleToStr(StopPrice, Dig),
         ", Bid = ", DoubleToStr(Bid, Dig), ", Ask = ", DoubleToStr(Ask, Dig), " at ", TimeToStr(TimeCurrent()));
   Sleep(SLEEP_ERR);
	
   return (-1);
}

//+------------------------------------------------------------------+
//| Places an order                                                  |
//+------------------------------------------------------------------+
int Order(int Type, double Entry, double Quantity, 
          double TargetPrice, double StopPrice, string comment="") 
{
   string TypeStr;
   color  TypeCol;
   int    ErrorCode, Ticket;
   double Price, FillPrice;

   Price = NormalizeDouble(Entry, Dig);
   
   switch (Type) {
      case OP_BUY: 
         TypeStr = "BUY";
         TypeCol = clBuy;
         break; 
      case OP_SELL: 
         TypeStr = "SELL";
         TypeCol = clSell;
         break;
      default:    
         Print("Unknown order type ", Type);
         break; 
   }
      
   if (StpMode) {
      Ticket = OrderSend(Symbol(), Type, Quantity, Price, Slippage,
               0, 0, comment, Magic, 0, TypeCol);
   }
   else {
      Ticket = OrderSend(Symbol(), Type, Quantity, Price, Slippage,
               StopPrice, TargetPrice, comment, Magic, 0, TypeCol);
   }      
   if (Ticket >= 0) {
      Sleep(SLEEP_OK);
      if (OrderSelect(Ticket, SELECT_BY_TICKET) == TRUE) {
         FillPrice = OrderOpenPrice();
         if (Entry != FillPrice) {
            RefreshRates();
            Print("Slippage on order ", Ticket, " - Requested = ",
                  Entry, ", Fill = ", FillPrice, ", Current Bid = ",
                  Bid, ", Current Ask = ", Ask);
         }
         if (StpMode && ((StopPrice > 0) || (TargetPrice > 0))) {         
            if (OrderModify(Ticket, FillPrice, StopPrice, TargetPrice, 0, TypeCol)) {
               Sleep(SLEEP_OK);
               return (Ticket);
            } 	
   	   }
      }
      else {
         ErrorCode = GetLastError();
         Print("Error selecting new order ", Ticket, ": ",
               ErrorDescription(ErrorCode), " (", ErrorCode, ")");
      }
      return (Ticket);
   } 	
   	
   ErrorCode = GetLastError();
   RefreshRates();
   Print("Error opening ", TypeStr, " order: ", ErrorDescription(ErrorCode),
         " (", ErrorCode, ")", ", Entry = ", Price, ", Target = ",
         TargetPrice, ", Stop = ", StopPrice, ", Current Bid = ", Bid,
         ", Current Ask = ", Ask);
   Sleep(SLEEP_ERR);
	
   return (-1);
}

//+------------------------------------------------------------------+
//| Performs system initialisation                                   |
//+------------------------------------------------------------------+
void InitSystem()
{
   Running = FALSE;
   
   RefreshRates();
   
   RangeMax = 99999.9;
   RangeMin = 0;
   
   Initialized = TRUE;
}
         
//+--------------------------------------------------------------------+
//| Implements a trailing stop (Assumes correct order already selected)|
//+--------------------------------------------------------------------+
int TrailStop()
{
   int ErrorCode;
   double NewStop;

   switch (OrderType()) {
       case OP_BUY: 
       case OP_BUYLIMIT: 
       case OP_BUYSTOP:
          if (Bid > BestPrice) {
             BestPrice = Bid;
             NewStop = NormalizeDouble(BestPrice - Stop * Points, Dig);
             if (OrderStopLoss() < NewStop) {
                Modify(OrderNumber, OrderTakeProfit(), NewStop);
             }
          }
          break; 
       case OP_SELL: 
       case OP_SELLLIMIT: 
       case OP_SELLSTOP: 
          if (Ask < BestPrice) {
             BestPrice = Ask;
             NewStop = NormalizeDouble(BestPrice + Stop * Points, Dig);
             if (OrderStopLoss() > NewStop) {
                Modify(OrderNumber, OrderTakeProfit(), NewStop);
             }
          }
          break; 
   }
   return(0);
}
   
//+------------------------------------------------------------------+
//| Checks which trading session we are in at the moment             |
//| 1 = Morning/Day, 2 = Afternoon/Overnight                         |  
//+------------------------------------------------------------------+
int CheckSession()
{
   int Now;
   
   Now = mod(TimeCurrent(), SECS_PER_DAY);
   
   if (StartRange > StartTrading) {
      if ((Now < StartTrading) || (Now >= StartRange)) {
         return(2);
      }
   }
   else {
      if ((Now >= StartRange) && (Now < StartTrading)) {
         return(2);
      }
   }
   
   if (StartRange > StartTrading) {
      if ((Now >= StartTrading) && (Now < StartRange)) {
         return(1);
      }
   }
   else {
      if ((Now >= StartTrading) || (Now < StartRange)) {
         return(1);
      }
   }

   return(0);   
}


//+------------------------------------------------------------------+
//| The Start of a Brand New Trading Day                             |
//+------------------------------------------------------------------+
void StartDay()
{
   datetime Now, Today, Yesterday, SessionStart;

   Started = FALSE;
   Finished = TRUE;
   OrderNumber = 0;
   
   Today = TimeCurrent();   
   Now = mod(Today, SECS_PER_DAY);
   Today -= Now;
   Yesterday = Today - SECS_PER_DAY;
   if (Now > StartRange) {        // Overnight range or not yet midnight
      SessionStart = Today + StartRange;
   }
   else {                         // Overnight session
      SessionStart = Yesterday + StartRange;                           
   }
   
   Print("Trading session started at ",
         TimeToStr(TimeCurrent(), TIME_SECONDS),
         ", High = ", DoubleToStr(RangeMax, Dig),
         ", Low = ", DoubleToStr(RangeMin, Dig));
         
   Print("Yesterday = ", TimeToStr(Yesterday, TIME_DATE | TIME_SECONDS),
         ", Today = ", TimeToStr(Today, TIME_DATE | TIME_SECONDS),
         ", Session Start = ", TimeToStr(SessionStart, TIME_DATE | TIME_SECONDS));
         
   DrawRange(SessionStart, RangeMax, Today + StartTrading, RangeMin);
}
   
//+------------------------------------------------------------------+
//| The Start of a Brand New Ranging Night                           |
//+------------------------------------------------------------------+
void StartNight()
{
   RangeMax = Ask;
   RangeMin = Bid;
   NightStarted = TimeCurrent();
   Started = TRUE;

      
   Print("Overnight session started at ",
         TimeToStr(TimeCurrent(), TIME_SECONDS),
         ", Bid = ", DoubleToStr(Bid, Dig),
         ", Ask = ", DoubleToStr(Ask, Dig));
}

//+------------------------------------------------------------------+
//| Checks for entry to a trade                                      |
//+------------------------------------------------------------------+
int CheckEntry()
{
   int Session;

   Session = CheckSession();
   
   switch(Session) {
   case 1:
      if (!Finished) {
         StartDay();
      }
      else if (OrderNumber <= 0) {
         if ((!FadeEntry && (Ask >= RangeMax + (Gap * Points))) || (FadeEntry && (Bid <= RangeMin - (Gap * Points)))) {
            // Broken out higher (or fading short breakout) so GO LONG!
            OrderNumber = Order(OP_BUY, Ask, PositionSize(),
                  Ask + (Points * Target), Bid - (Points * Stop));
            if (OrderNumber > 0) {
               BestPrice = 0.0;
               return(1);
            }   
         }
         else if ((!FadeEntry && (Bid <= RangeMin - (Gap * Points))) || (FadeEntry && (Ask >= RangeMax + (Gap * Points)))) {
            // Broken out lower  (or fading long breakout) so GO SHORT!
            OrderNumber = Order(OP_SELL, Bid, PositionSize(),
                  Bid - (Points * Target), Ask + (Points * Stop)); 
            if (OrderNumber > 0) {
               BestPrice = 99999.9;
               return(1);
            }   
         }
      }
      return(0);
  
   case 2:
      if ((!Started) ||
          (TimeCurrent() > NightStarted + SECS_PER_DAY)) {
         StartNight();
      }
      else {      
         if (Ask > RangeMax)
            RangeMax = Ask;
         if (Bid < RangeMin)
            RangeMin = Bid;
      }
      Finished = FALSE;
      return(0);

   default:   
      return(0);
   }   
}

//+------------------------------------------------------------------+
//| Checks for exit from a trade                                     |
//+------------------------------------------------------------------+
int CheckExit()
{
   int ErrorCode;

   if (OrderSelect(OrderNumber, SELECT_BY_TICKET) != TRUE) {
      ErrorCode = GetLastError();
      Print("Error selecting order ", OrderNumber, ": ",
            ErrorDescription(ErrorCode), " (", ErrorCode, ")");
      return(-1);
   }
   else if (OrderCloseTime() > 0) {
      Print("Order ", OrderNumber, " closed: ", OrderClosePrice(),
            ", at ", TimeToStr(OrderCloseTime()));
      OrderNumber = 0;
      return(1);
   }
   else if (TrailingStop) {
      TrailStop();
   }

   return(0);
}
   
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int init()
{
   Dig = MarketInfo(Symbol(), MODE_DIGITS);
   Points = MarketInfo(Symbol(), MODE_POINT);
   Stops = MarketInfo(Symbol(), MODE_STOPLEVEL);
   MinLots = MarketInfo(Symbol(), MODE_MINLOT);
   MaxLots = MarketInfo(Symbol(), MODE_MAXLOT);
   StepLots = MarketInfo(Symbol(), MODE_LOTSTEP);
   
   Print("Stops = ", Stops, ", Digits = ", Dig, ", Points = ", DoubleToStr(Points, Dig));
   
   Slippage = MaxSlippage;
   Target = ProfitTarget;
   Stop = StopLoss;
   Gap = EntryGap;
   if ((Dig == 3) || (Dig == 5)) {
      Slippage *= 10;
      Target *= 10;
      Stop *= 10;
      Gap *= 10;
   }
   
   if (!IsDemo() && !IsTesting()) {
      MessageBox("Wealth Warning! This expert is for educational purposes only." +
            " It should NEVER be used on a live account." +
            " Past performance is in no way indicative of future results!\n\n" +
            " Copyright © 2010, Marketing Dreams Ltd. All Rights Reserved.\n" +
            " http://trading-gurus.com");
      Print("Initialization Failure");
      return(-1);
   }

   StartTrading = StartTradingHour * SECS_PER_HOUR;
   if (FixedStart)
      StartRange = mod(RangeControl, 24) * SECS_PER_HOUR;
   else
      StartRange = mod(StartTradingHour - RangeControl, 24) * SECS_PER_HOUR;

   InitSystem();

   Print("Initialized OK");

   return(0);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit()
{
   if (!IsTesting())
      ObjectsDeleteAll(0, OBJ_RECTANGLE);
          
    Print("DeInitialized OK");
   
    return(0);
}

//+------------------------------------------------------------------+
//| Expert start function                                            |
//| Executed on every tick                                           |
//+------------------------------------------------------------------+
int start()
{
   if (!Initialized) {
      return(-1);
   }
   
   if (Running) {                         // Are we in a trade at the moment?
      if (CheckExit() > 0) {              // Yes - Last trade complete?
         Initialized = FALSE;             // Yes - Indicate we need to reinitialise
         InitSystem();                    //  and start all over again!
      }
   }
   else if (CheckEntry() > 0) {           // Entered a trade?
      Running = TRUE;                     // Yes - Indicate that we're in a trade
   }
   
   return(0);
}

