//+------------------------------------------------------------------+
//|                                                Triple Screen.mq4 |
//|                               Copyright ?2011, JBM Haopeng Huang |
//|                                                                  |
//+------------------------------------------------------------------+
#include "Reporter.mq4"

#property copyright "Copyright ?2011, JBM Haopeng Huang"
#property link      ""

#define CURRENCY_LIST_SIZE 28

extern string APP_NAME = "Triple Screen Report V3";
static double MID_VAL = 50.0;
static string CURRENCY_LIST[CURRENCY_LIST_SIZE] = {
               "AUDCAD", "AUDJPY", "AUDNZD", "AUDSGD", "AUDUSD", "CADCHF", "CADJPY",
               "CHFJPY", "EURAUD", "EURCAD", "EURCHF", "EURGBP", "EURJPY", "EURNZD", 
               "EURUSD", "GBPAUD", "GBPCAD", "GBPCHF", "GBPJPY", "GBPUSD", "NZDJPY", 
               "NZDUSD", "USDCAD", "USDCHF", "USDCNY", "USDHKD", "USDJPY", "USDSGD"
               };

int tripleScreenResult[8][CURRENCY_LIST_SIZE];
int previousResult[8][CURRENCY_LIST_SIZE];
double stochValues[CURRENCY_LIST_SIZE][6];

int init()                                      // Spec. funct. init()
{
   Alert(APP_NAME, ". Function init() triggered at start");
   return;                                     
}   

int start()
{
   Alert(APP_NAME, ". Starting");
   bool firstRun = true;
   while (!IsStopped()) {
      if (!firstRun) {
         bool hasData = RefreshRates();         
         if (hasData) Alert("Refreshed with new data");
      } else {
         firstRun = false;
      }
      ArrayCopy(previousResult, tripleScreenResult);
      for (int i=0; i<ArraySize(CURRENCY_LIST); i++) {
         checkTripleScreen(CURRENCY_LIST[i], i);
      }
      
      if (!equal(tripleScreenResult, previousResult)) {
         sendMessages(tripleScreenResult, CURRENCY_LIST, stochValues, APP_NAME);     
      } else {
         Alert("Triple screen results are the same as previous. Not sending messages");
      }
         
      Sleep(30*60*1000);
   } 
      
   return;   
}

void checkTripleScreen(string pair, int index) {
   double stochMonthly, stochWeekly, stochDaily, stoch4hr, stoch1hr, stoch15min, stoch5min;
   stochMonthly = iStochastic(pair, PERIOD_MN1,9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   stochWeekly = iStochastic(pair, PERIOD_W1, 9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   stochDaily = iStochastic(pair, PERIOD_D1, 9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   stoch4hr = iStochastic(pair, PERIOD_H4, 9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   stoch1hr = iStochastic(pair, PERIOD_H1, 9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);
   stoch15min = iStochastic(pair, PERIOD_M15, 9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);      
   stoch5min = iStochastic(pair, PERIOD_M5, 9, 3, 3, MODE_SMA, 0, MODE_MAIN, 0);      

   stochValues[index][0] = stochMonthly; 
   stochValues[index][1] = stochWeekly; 
   stochValues[index][2] = stochDaily; 
   stochValues[index][3] = stoch4hr; 
   stochValues[index][4] = stoch1hr; 
   stochValues[index][5] = stoch15min; 
         
   // Position trades
   int positionTrade = tripleScreen(stochMonthly, stochWeekly, stochDaily, stoch4hr);
   addResult(POSITION_TRADE, positionTrade, index);

   // Swing trades
   int swingTrade = tripleScreen(stochWeekly, stochDaily, stoch4hr, stoch1hr);
   addResult(SWING_TRADE, swingTrade, index);
   
   // Day Trades      
   int dayTrade = tripleScreen(stochDaily, stoch4hr, stoch1hr, stoch15min);
   addResult(DAY_TRADE, dayTrade, index);

   // Scalp Trades
   int scalpTrade = tripleScreen(stoch4hr, stoch1hr, stoch15min, stoch5min);
   addResult(SCALP_TRADE, scalpTrade, index);
}

int tripleScreen(double value1, double value2, double value3, double valueEntry) {
   if (value1 > MID_VAL && value2 > MID_VAL && value3 > MID_VAL && valueEntry < MID_VAL) {
      return (1); // long entry opportunity
   } else if (value1 < MID_VAL && value2 < MID_VAL && value3 < MID_VAL && valueEntry > MID_VAL) {
      return (-1); // short entry opportunity
   } else {
      return (0); // no trade
   }     
}

void addResult(int tradeType, int scanResult, int index) {
   if (scanResult == 1) {
      tripleScreenResult[tradeType][index] = scanResult;
      tripleScreenResult[tradeType+1][index] = 0;         
 
   } else if (scanResult == -1) {
      tripleScreenResult[tradeType][index] = 0;         
      tripleScreenResult[tradeType+1][index] = scanResult;         
 
   } else if (scanResult == 0) {
      tripleScreenResult[tradeType][index] = 0;            
      tripleScreenResult[tradeType+1][index] = 0;         
   }
}
   
int deinit()                                    // Spec. funct. deinit()
   {
   Alert(APP_NAME, ". Function deinit() triggered at deinitialization");   // Alert
   return;                                      // Exit deinit()
}
 