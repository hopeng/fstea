//+------------------------------------------------------------------+
//| FST.mq4
//| $Author: hopeng $
//| $Rev: 12 $
//| $Date: 2011-09-09 23:32:09 +1000 (周五, 09 九月 2011) $
//+------------------------------------------------------------------+
#property copyright "hopeng"
#property link      ""

#define SLEEP_OK     250
#define SLEEP_ERR    250

extern int Magic = 43420;             // Magic number to distinguish this expert from others on the same account 
extern int Slippage=3;
extern int PROFIT_TARGET = 20;  
extern int STOP_LOSS = 20;  
extern int MMType=0;                  // Money management method - 0 = None (Fixed order size)
                                             // 1 = Fixed Fractional, 2 = Fixed % at risk
extern double RiskPercent = 1.0;         // Money management master control (use with caution!!!)  
extern double Lots = 0.01;                // Size of each order (if not using money management)
extern bool StpMode = true;           // Set TRUE for brokers that don't accept market orders with built in stops

static double     MinLots;
static double     MaxLots;
static double     StepLots;
static double     Points;

static color      clBuy = DodgerBlue;
static color      clSell = Crimson;

#include <stdlib.mqh>
#include <stderror.mqh>
#include <WinUser32.mqh>

void initOrderManager() {
   MinLots = MarketInfo(Symbol(), MODE_MINLOT);
   MaxLots = MarketInfo(Symbol(), MODE_MAXLOT);
   StepLots = MarketInfo(Symbol(), MODE_LOTSTEP);   
   Points = Point * 10;
}

//+------------------------------------------------------------------+
//| Places an order                                                  |
//+------------------------------------------------------------------+
int Order(int Type, double Entry, double Quantity, 
          int takeProfitPips, int stopLossPips, string comment="") 
{
   string TypeStr;
   color  TypeCol;
   int    ErrorCode, Ticket;
   double Price, FillPrice;
   double stopPrice;
   double targetPrice;
   Price = NormalizeDouble(Entry, Digits);
   
   switch (Type) {
      case OP_BUY: 
         TypeStr = "BUY";
         TypeCol = clBuy;
         targetPrice = Ask + Points * takeProfitPips; 
         stopPrice = Ask - Points * stopLossPips;
         break; 
      case OP_SELL: 
         TypeStr = "SELL";
         TypeCol = clSell;
         targetPrice = Bid - Points * takeProfitPips; 
         stopPrice = Bid + Points * stopLossPips;
         break;
      default:    
         Print("Unknown order type ", Type);
         break; 
   }
      
   if (StpMode) {
      Ticket = OrderSend(Symbol(), Type, Quantity, Price, Slippage,
               0, 0, comment, Magic, 0, TypeCol);
   } else {
      Ticket = OrderSend(Symbol(), Type, Quantity, Price, Slippage,
               stopPrice, targetPrice, comment, Magic, 0, TypeCol);
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
         if (StpMode && ((stopPrice > 0) || (targetPrice > 0))) {  
            if (OrderModify(Ticket, FillPrice, stopPrice, targetPrice, 0, TypeCol)) {
               Sleep(SLEEP_OK);
               return (Ticket);
            } 	
   	   }
   	   
      } else {
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
         targetPrice, ", Stop = ", stopPrice, ", Current Bid = ", Bid,
         ", Current Ask = ", Ask);
   Sleep(SLEEP_ERR);
	
   return (-1);
}

double PositionSize()
{
   double Size, TickValue;
   
   TickValue = MarketInfo(Symbol(), MODE_TICKVALUE);

   switch (MMType) {
   case 1:
      Size = 0.0001 * AccountEquity() * RiskPercent;
      break;
   case 2:
      Size = 0.01 * AccountEquity() * RiskPercent / (STOP_LOSS * TickValue);
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