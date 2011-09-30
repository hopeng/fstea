//+------------------------------------------------------------------+
//|                                                     Reporter.mq4 |
//|                               Copyright ?2011, JBM Haopeng Huang |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright ?2011, JBM Haopeng Huang"
#property link      ""

#define POSITION_TRADE 0
#define POSITION_TRADE_SHORT 1
#define SWING_TRADE 2
#define SWING_TRADE_SHORT 3
#define DAY_TRADE 4
#define DAY_TRADE_SHORT 5
#define SCALP_TRADE 6
#define SCALP_TRADE_SHORT 7


string TRADE_TYPES[] = {"Position Trades", "Position Trades", "Swing Trades", "Swing Trades", "Day Trades", "Day Trades", "Scalp trades", "Scalp trades"}; 


void sendMessages(int tripleScreenResult[][], string currencyList[], double stochValues[][], string subject) {
   string reportResult[];
   generateReport(tripleScreenResult, currencyList, stochValues, reportResult);
   string emailString;
   for (int i=0; i<ArraySize(reportResult); i++) {
      Alert(reportResult[i]);
      emailString = StringConcatenate(emailString, reportResult[i], "\n");
   }
   
   SendMail(subject, emailString);
   return;
}
      
void generateReport(int tripleScreenResult[][], string CURRENCY_LIST[], double stochValues[][], string& result[]) {
   string tradeOpportunities[8];
   initStringArray(tradeOpportunities, "");
   
   int i, j;   
   for (i=0; i<ArrayRange(tripleScreenResult, 0); i++) {
      for (j=0; j<ArrayRange(tripleScreenResult, 1); j++) {
         if (tripleScreenResult[i][j] != 0) {
            tradeOpportunities[i] = StringConcatenate(tradeOpportunities[i], CURRENCY_LIST[j], "\n");  
         }
      }
   }
   
   // construct trade opportunities messaages
   string longTradesMessage = "BUY OPPORTUNITIES\n";
   string shortTradesMessage = "SELL OPPORTUNITIES\n";
   for (i=0; i<ArraySize(tradeOpportunities); i++) {
      if (StringLen(tradeOpportunities[i]) == 0) {
         tradeOpportunities[i] = "N/A\n";
      }
      if (i % 2 == 0) {
         longTradesMessage = StringConcatenate(longTradesMessage, TRADE_TYPES[i], "\n", tradeOpportunities[i], "\n");
      } else {
         shortTradesMessage = StringConcatenate(shortTradesMessage, TRADE_TYPES[i], "\n", tradeOpportunities[i], "\n");
      }
   }
   
   // construct stochastics values messages
   string stochValuesMessage = "symbol, bid, ask, monthly, weekly, daily, 4hr, 1hr, 15min\n";
   for (i=0; i<ArrayRange(stochValues, 0); i++) {
      bool isTripleScreenPair = false;
      for (int k=0; k<ArrayRange(tripleScreenResult, 0); k++) {
         isTripleScreenPair = isTripleScreenPair || (tripleScreenResult[k][i] != 0);
      }
      if (isTripleScreenPair) {
         stochValuesMessage = StringConcatenate(stochValuesMessage, CURRENCY_LIST[i]);
         double bid = MarketInfo(CURRENCY_LIST[i], MODE_BID);
         double ask = MarketInfo(CURRENCY_LIST[i], MODE_ASK);
         stochValuesMessage = StringConcatenate(stochValuesMessage, ", ", bid, ", ", ask);
      
         int dim2ndRange = ArrayRange(stochValues, 1);
         for (j=0; j<dim2ndRange; j++) {
            stochValuesMessage = StringConcatenate(stochValuesMessage, ", ", stochValues[i][j]);
         }
         stochValuesMessage = StringConcatenate(stochValuesMessage, "\n");
      }
   }

   ArrayResize(result, 3);
   result[0] = longTradesMessage;
   result[1] = shortTradesMessage;
   result[2] = stochValuesMessage;

   return;   
}
   
bool equal(int arr1[][], int arr2[][]) {
   int i, j;
   if (ArrayRange(arr1, 0) != ArrayRange(arr2, 0) || ArrayRange(arr1, 1) != ArrayRange(arr2, 1)) {
      return (false);
   }
   
   for (i=0; i<ArrayRange(arr1, 0); i++) {
      for (j=0; j<ArrayRange(arr1, 1); j++) {
         if (arr1[i][j] != arr2[i][j]) {
            return (false);
         }
      }
   }
   
   return (true);
}

string toString(int arr[][]) {
   string result;
   for (int i=0; i<ArrayRange(arr, 0); i++) {
      for (int j=0; j<ArrayRange(arr, 1); j++) {
         result = StringConcatenate(result, arr[i][j], ", ");
      }
   }
   
   return (result);
}

void initStringArray(string& arr[], string value) {
   for (int i=0; i<ArraySize(arr); i++) {
      arr[i] = value;
   }
}

