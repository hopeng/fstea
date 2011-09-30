//+------------------------------------------------------------------+
//| FST.mq4
//| $Author: hopeng $
//| $Rev: 8 $
//| $Date: 2011-08-25 23:38:01 +1000 (周四, 25 八月 2011) $
//+------------------------------------------------------------------+
#property copyright "hopeng"
#property link      ""

static int HA.UP = 0;
static int HA.UP.SHAVED_BOTTOM = 1;
static int HA.DOWN = 2;
static int HA.DOWN.SHAVED_TOP = 3;

static int OrderNumber = -1;
static double STO_MID_VALUE = 50.0;

static int MOMENTUM_MATRIX[4][4] = {
   PERIOD_H1, PERIOD_M15, PERIOD_M5, PERIOD_M1, // mini scalp
   PERIOD_H4, PERIOD_H1, PERIOD_M15, PERIOD_M5, // Scalp trade
   PERIOD_D1, PERIOD_H4, PERIOD_H1, PERIOD_M15, // Day trade
   PERIOD_W1, PERIOD_D1, PERIOD_H4, PERIOD_H1   // Swing trade
};

extern int haTolerance = 1;
extern int tradeStrategy = 0; // choose 0,1,2,3 from momentum matrix
extern bool enableBuy = true;
extern bool enableSell = true;

#include "OrderManager.mq4"


int init() {
   initOrderManager();
   return(0);
}

int deinit() {
   return(0);
}


int start() {
      // check if there is live order
      if (OrderSelect(OrderNumber, SELECT_BY_TICKET) && OrderCloseTime() > 0) {
         Print("Order ", OrderNumber, " closed: ", OrderClosePrice(),
               ", at ", TimeToStr(OrderCloseTime()));
         OrderNumber = 0;
         return(1);
      }
      
      // look for trade entry only if there's no live order
      if (OrderNumber <= 0) {   
         if (enableBuy && buySignal()) {
            OrderNumber = Order(OP_BUY, Ask, PositionSize(),
            PROFIT_TARGET, STOP_LOSS);         
         }
         
         if (enableSell && sellSignal()) {
            if (OrderNumber > 0) {
               Alert("There are both buy and sell signals, fix the bug!!");
               return (-1);
            }
            OrderNumber = Order(OP_SELL, Bid, PositionSize(),
            PROFIT_TARGET, STOP_LOSS);            
         }
      }
   
   /**
      Exit Strategy
   **/
   // for each open long positions
      // if HA down Close
      // cloes trade
   // for each open short position
      // if HA up Close
      // close trade
   
   return(0);
}

bool buySignal() {
   bool result = false;
   string haStateStringT1[], haStateStringT2[], haStateStringT3[];
   
   // get higher timeframe list from momentum matrix
   int timeFrame[4];
   timeFrame[0] = MOMENTUM_MATRIX[tradeStrategy][0];
   timeFrame[1] = MOMENTUM_MATRIX[tradeStrategy][1];
   timeFrame[2] = MOMENTUM_MATRIX[tradeStrategy][2];
   timeFrame[3] = MOMENTUM_MATRIX[tradeStrategy][3];
   
   // STO > 50 T0, T1, T2 and shaved bottom on T3, buy
   int stoT0 = iStochastic(NULL, timeFrame[0],9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   int stoT1 = iStochastic(NULL, timeFrame[1],9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   int stoT2 = iStochastic(NULL, timeFrame[2],9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   bool tripleScreenUp = stoT0 > STO_MID_VALUE && stoT1 > STO_MID_VALUE && stoT2 > STO_MID_VALUE;
   
   double adxT1 = iADX(NULL, timeFrame[1], 14, PRICE_CLOSE, MODE_MAIN, 0);
   int haStatusT1 = haStatusFor(timeFrame[1], 1, haStateStringT1);
   bool t1Trending = adxT1 > 30 && haStatusT1 == HA.UP;
   
   int haStatusT2 = haStatusFor(timeFrame[2], 1, haStateStringT2);
   bool t2UpClose = haStatusT2 == HA.UP;
      
   int haStatusT3 = haStatusFor(timeFrame[3], 1, haStateStringT3);
   bool t3ShavedBottom = haStatusT3 == HA.UP.SHAVED_BOTTOM;   
      
   // check that price action in up trend in progress on timeframe Lv0
      // STO > 50 and
         // 2 higher high SP + 3 higher low SP
         // or 2 higher high SP + last HA bar UP close
      
   result = tripleScreenUp && t1Trending && t2UpClose && t3ShavedBottom;   
   if (result) {
      Print("Buy signal STO=", stoT0, ":", stoT1, ":", stoT2, 
      ", adxT1=", adxT1,
      ", haStatusT1OHLC=", haStateStringT1[0], ", haStatusT2OHLC=", haStateStringT2[0], 
      ", haStatusT3OHLC=", haStateStringT3[0]);
   }      
   return (result);
}

bool sellSignal() {
   bool result = false;
   string haStateStringT1[], haStateStringT2[], haStateStringT3[];
   
   // get higher timeframe list from momentum matrix
   int timeFrame[4];
   timeFrame[0] = MOMENTUM_MATRIX[tradeStrategy][0];
   timeFrame[1] = MOMENTUM_MATRIX[tradeStrategy][1];
   timeFrame[2] = MOMENTUM_MATRIX[tradeStrategy][2];
   timeFrame[3] = MOMENTUM_MATRIX[tradeStrategy][3];
   
   // STO > 50 T0, T1, T2 and shaved bottom on T3, buy
   int stoT0 = iStochastic(NULL, timeFrame[0],9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   int stoT1 = iStochastic(NULL, timeFrame[1],9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   int stoT2 = iStochastic(NULL, timeFrame[2],9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   bool tripleScreenDown = stoT0 < STO_MID_VALUE && stoT1 < STO_MID_VALUE && stoT2 < STO_MID_VALUE;

   double adxT1 = iADX(NULL, timeFrame[1], 14, PRICE_CLOSE, MODE_MAIN, 0);
   int haStatusT1 = haStatusFor(timeFrame[1], 1, haStateStringT1);
   bool t1Trending = adxT1 > 30 && haStatusT1 == HA.DOWN;
   
   int haStatusT2 = haStatusFor(timeFrame[2], 1, haStateStringT2);
   bool t2DownClose = haStatusT2 == HA.DOWN;
      
   int haStatusT3 = haStatusFor(timeFrame[3], 1, haStateStringT3);
   bool t3ShavedTop = haStatusT3 == HA.DOWN.SHAVED_TOP;   
   
   result = tripleScreenDown && t1Trending && t2DownClose && t3ShavedTop;   
   if (result) {
      Print("Sell signal STO=", stoT0, ":", stoT1, ",:", stoT2, 
      ", adxT1=", adxT1,
      ", haStatusT1OHLC=", haStateStringT1[0], ", haStatusT2OHLC=", haStateStringT2[0], 
      ", haStatusT3OHLC=", haStateStringT3[0]);
   }      
   return (result);
}
  
int haStatusFor(int timeFrame, int barIndex, string& haStateString[]) {
   int result = -1;   
   double haHigh;
   double haLow;
   double haOpen = iCustom(NULL,timeFrame,"Heiken Ashi",2,barIndex);
   double haClose = iCustom(NULL,timeFrame,"Heiken Ashi",3,barIndex);
   double diff;
   
   if (haOpen < haClose) {
      haHigh = iCustom(NULL,timeFrame,"Heiken Ashi",1,barIndex);   
      haLow = iCustom(NULL,timeFrame,"Heiken Ashi",0,barIndex);
      diff = (haOpen - haLow) / Points;
      if (diff > haTolerance) {
         result = HA.UP;
      } else {
         result = HA.UP.SHAVED_BOTTOM;   
      }
   
   } else {
      haHigh = iCustom(NULL,timeFrame,"Heiken Ashi",0,barIndex);   
      haLow = iCustom(NULL,timeFrame,"Heiken Ashi",1,barIndex);
      diff = (haHigh - haOpen) / Points;
      if (diff > haTolerance) {
         result = HA.DOWN;
      } else {
         result = HA.DOWN.SHAVED_TOP;
      }                 
   }
   
   ArrayResize(haStateString, 1);
   haStateString[0] = toString(haOpen) + ":" 
      + toString(haHigh) + ":" + toString(haLow) + ":" 
      + toString(haClose) + ", diff=" + toString(diff);
   return (result);
}

string toString(double d) {
   return (DoubleToStr(d, Digits));
}

string getHAStatusString(int haStatus) {
   string result;
   
   switch (haStatus) {
      case 0:
         result = "HA.UP";
         break;
      case 1:
         result = "HA.UP.SHAVED_BOTTOM";      
         break;
      case 2:
         result = "HA.DOWN";      
         break;
      case 3:
         result = "HA.DOWN.SHAVED_TOP";      
         break;
      default:
         result = NULL;
         break;   
   }
   
   return (result);
}

//+------------------------------------------------------------------+