//+------------------------------------------------------------------+
//|                                                     TZ-Pivot.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright Shimodax"
#property link      "http://www.strategybuilderfx.com"

#property  indicator_separate_window

/* Introduction:

   Calculation of pivot and similar levels based on time zones.
   If you want to modify the colors, please scroll down to line
   200 and below (where it says "Calculate Levels") and change
   the colors.  Valid color names can be obtained by placing
   the curor on a color name (e.g. somewhere in the word "Orange"
   and pressing F1).
   
   Time-Zone Inputs:

   LocalTimeZone: TimeZone for which MT4 shows your local time, 
                  e.g. 1 or 2 for Europe (GMT+1 or GMT+2 (daylight 
                  savings time).  Use zero for no adjustment.
                  The MetaQuotes demo server uses GMT +2.
                  
   DestTimeZone:  TimeZone for the session from which to calculate
                  the levels (e.g. 1 or 2 for the European session
                  (without or with daylight savings time).  
                  Use zero for GMT
           
                  
   Example: If your MT server is living in the EST (Eastern Standard Time, 
            GMT-5) zone and want to calculate the levels for the London trading
            session (European time in summer GMT+1), then enter -5 for 
            LocalTimeZone, 1 for Dest TimeZone. 
            
            Please understand that the LocalTimeZone setting depends on the
            time on your MetaTrader charts (for example the demo server 
            from MetaQuotes always lives in CDT (+2) or CET (+1), no matter
            what the clock on your wall says.
           
            If in doubt, leave everything to zero.
*/

extern int LocalTimeZone= 10;
extern int DestTimeZone= 10;
string per;
double alertBar;

extern bool DailyOpenCalculate = false;
//extern bool ShowComment = false;
extern bool ShowHighLowOpen = false;
//extern bool ShowSweetSpots = true;
extern bool ShowPivots = true;
extern bool ShowMidPitvot = false;
extern bool ShowFibos= false;
extern bool ShowCamarilla = true;
extern bool ShowLevelPrices = true;
extern bool DebugLogger = false;
extern bool Zones = true;
extern int       barn=300;
extern int       Length=6;

extern color BuyArea = LimeGreen;
extern color SellArea = Crimson;

extern int BuySellStart = 20;
extern int BuySellEnd = 40;
extern int BarForLabels= 0;     // number of bars from right, where lines labels will be shown
extern int LineStyle= 0;
extern int LineThickness= 1;
datetime lasttime = 0;
extern bool UseAlerts = true;
color colt3;
color colt4;
color colt5;
color colt6;
color colt7;
color colt8;
color colt9;
color colt10;

//---- ADX
int ADX_period = 14;

//---- FI
int FI_period = 14;

//---- RSI
int RSI_period = 14;

#define BUY1 "BUY1"
#define BUY2 "BUY2"
#define SELL1 "SELL1"
#define SELL2 "SELL2"

/*
   The following doesn't work yet, please leave it to 0/24:
                  
   TradingHoursFrom: First hour of the trading session in the destination
                     time zone.
                     
   TradingHoursTo: Last hour of the trading session in the destination
                   time zone (the hour starting with this value is excluded,
                   i.e. 18 means up to 17:59 o'clock)
                   
   Example: If you are lving in the EST (Eastern Standard Time, GMT-5) 
            zone and want to calculate the levels for the London trading
            session (European time GMT+1, 08:00 - 17:00), then enter
            -5 for LocalTimeZone, 1 for Dest TimeZone, 8 for HourFrom
            and 17 for hour to.
*/

int TradingHoursFrom= 0;
int TradingHoursTo= 24;
int digits; //decimal digits for symbol's price       



//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{
IndicatorShortName("SDX");
    per=Period();
	deinit();
	if (Ask>10) digits=2; else digits=4;
   Print("Period= ", Period());
   return(0);
}

int deinit()
{
ObjectsDeleteAll(0,OBJ_LABEL);
   int obj_total= ObjectsTotal();
   string gvname;
   
   for (int i= obj_total; i>=0; i--) {
      string name= ObjectName(i);
    
      if (StringSubstr(name,0,7)=="[PIVOT]") 
         ObjectDelete(name);
   }
   	gvname=Symbol()+"st";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"p";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"r1";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"r2";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"r3";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"s1";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"s2";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"s3";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"yh";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"to";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"yl";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"ds1";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"ds2";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"flm618";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"flm382";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"flp382";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"flp5";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"fhm382";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"fhp382";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"fhp618";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"h3";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"h4";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"l3";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"l4";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"mr3";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"mr2";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"mr1";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"ms1";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"ms2";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"ms3";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"bl1";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"bl2";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"bt";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"sl1";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"sl2";
   	GlobalVariableDel(gvname);
   	gvname=Symbol()+"st";
   	GlobalVariableDel(gvname);
   	
   ObjectsDeleteAll(0, OBJ_LABEL);
   ObjectsDeleteAll(0, OBJ_RECTANGLE);
   ObjectDelete("ADX"); ObjectDelete("FI"); ObjectDelete("RSI");
   ObjectDelete("Signal");
   ObjectDelete("Analysis"); ObjectDelete("Strength"); ObjectDelete("Trend");

   return(0);
}
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int start()
{

//commentator start

   int i = 0;
//   Demarker
      double valDem=iDeMarker(NULL, 0, 13, 0);
      string Dem = "DeMarker:    ";
      string DemAdd = "   No data";colt3 = Red;
     
      if (valDem < 0.30)
         {DemAdd =  "   Possible reverse to uptrend";colt3 = Yellow;}
      
      if (valDem > 0.70)
         {DemAdd =   "   Possible reverse to downtrend";colt3 = Red;}
      Dem = Dem + DemAdd;

//ATR
      double valATR=iATR(NULL, 0, 12, 0);
      string ATR = "ATR:           ";
        ATR = "   Possible trend changing " + valATR;
        colt4 = Red;
            
//AÑ
      string AC = "AC:            ";
      string ACAdd = "No data ";colt5 = Red;
      string ACAdd0 = "No data ";colt5 = Red;
      string ACAdd1 = "No data ";colt5 = Red;
      string ACAdd2 = "No data ";colt5 = Red;
      double valAC0=iAC(NULL, 0, 0);
      double valAC1=iAC(NULL, 0, 1);
      if (valAC1 < valAC0)
         {ACAdd = "Sell not advisable";colt5 = Red;}
      
      if (valAC1 > valAC0)
         {ACAdd = "Buy not advisable";colt5 = Red;}
      
      bool theeRedUpper = true;
      for(i=2; i>=0; i--)
      {
         if ( iAC(NULL, 0, i) < iAC(NULL, 0, i+1))
         {
            if ( iAC(NULL, 0, i) <= 0)
               theeRedUpper = false;
         }
         else
            theeRedUpper = false;
      }
      
      if (theeRedUpper == true)
         {ACAdd0 = "Short position";colt5 = Red;}


      bool theeGreenDown = true;
      for(i=2; i>=0; i--)
      {
         if ( iAC(NULL, 0, i) > iAC(NULL, 0, i+1))
         {
            if ( iAC(NULL, 0, i) >= 0)         
              theeGreenDown = false;
         }
         else
            theeGreenDown = false;
      }
      
      if (theeGreenDown == true)
         {ACAdd0 = "Long position";colt5 = Yellow;}


      bool twoRedUpper = true;
      for(i=1; i>=0; i--)
      {
         if ( iAC(NULL, 0, i) > iAC(NULL, 0, i+1))
            twoRedUpper = false;
      }
      
      if (twoRedUpper == true)
         {ACAdd2 = "Short position";colt5 = Red;}



      bool twoGreenDown = true;
      for(i=2; i>=0; i--)
      {
         if ( iAC(NULL, 0, i) < iAC(NULL, 0, i+1))
            twoGreenDown = false;
      }
      
      if (twoGreenDown == true)
         {ACAdd2 = "Long position";colt5 = Yellow;}
     
      if (iAC(NULL, 0, 0) < 0)
      {         
         if (theeRedUpper == true)
            {ACAdd1 = "Possible buy, ";colt5 = Yellow;} 
            
         if (theeGreenDown == true)
            {ACAdd1 = "Possible buy, ";colt5 = Yellow;}  
                  
         if (twoRedUpper == true)
           {ACAdd2 = "Possible sell, ";colt5 = Red;}         
      }
      
      if (iAC(NULL, 0, 0) > 0)
      {
         if (theeRedUpper == true)
            {ACAdd1 = "Possible sell, ";colt5 = Red;}
            
         if (theeGreenDown == true)
            {ACAdd1 = "Possible sell, ";colt5 = Red;}
                  
         if (twoGreenDown == true)
            {ACAdd2 = "Possible buy, ";colt5 = Yellow;}
      }
      
            
//        AC = AC 
 //       + "\n" + "   " +ACAdd
 //       + "\n" + "   " + ACAdd1+ ACAdd0
 //       + "\n" + "   " + ACAdd2
 //       ;

     
     
//CCI
      double valCCI=iCCI(NULL,0,12,PRICE_MEDIAN,0);
      string CCI = "CCI:            ";
      string CCIAdd = "   No data ";colt6 = Red;
      if (valCCI > 100)
        {CCIAdd =  "   Overboughted condition (possibility to corrected recession) ";colt6 = Red;}

      if (valCCI < -100)
        {CCIAdd =  "   Oversolded condition (possibility to corrected raising) ";colt6 = Red;}
        
      CCI =  CCI + CCIAdd + valCCI;

//MFI
      double valMFI=iMFI(NULL,0,14,0);
      string MFI = "MFI:            ";
      string MFIAdd = "   No data ";colt7 = Red;
      if (valMFI > 80)
        {MFIAdd =  "    potential high ";colt7 = Yellow;}

      if (valMFI < 20)
        {MFIAdd =  "    potential low ";colt7 = Red;}
        
        MFI =  MFI + MFIAdd + valMFI;
        
        
//WPR
      double valWPR=iWPR(NULL,0,14,0);
      string WPR = "R%:             ";
      string WPRAdd = "   No data ";colt8 = Red;
      if (valWPR < -80)
       {WPRAdd =  "   Oversold condition (waiting for long reversal is desirable) ";colt8 = Red;}

      if (valWPR > -20)
        {WPRAdd =  "   Overbought condition (waiting for short reversal is desirable) ";colt8 = Red;}
        
      WPR =  WPR + WPRAdd + valWPR;
       
//STOCH

      double valSTOCH=0; 
      string STOCH = "Stoch:         ";
      string STOCHAdd = "   No data ";colt9 = Red;
      if(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0)>iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0))
        {STOCHAdd =  "    Possible buy";colt9 = Yellow;}
               
      if(iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_MAIN,0)<iStochastic(NULL,0,5,3,3,MODE_SMA,0,MODE_SIGNAL,0))
        {STOCHAdd =  "    Possible sell";colt9 = Red;}   
        
      STOCH =  STOCH + STOCHAdd;


//Momentum

      double valMom=0;
      string Mom = "Momentum:  ";
      string MomAdd = "   No data ";colt10 = Red;
      if((iMomentum(NULL,0,14,PRICE_CLOSE,1) < 100) && (iMomentum(NULL,0,14,PRICE_CLOSE,0) > 100))
        {MomAdd =  "    Signal to buy";colt10 = Yellow;}
        
      if((iMomentum(NULL,0,14,PRICE_CLOSE,1) > 100) && (iMomentum(NULL,0,14,PRICE_CLOSE,0) < 100))
        {MomAdd =  "    Signal to sell";colt10 = Red;}   
        
      Mom =  Mom + MomAdd;
      
//      Comment(
 //     commentSTOCH + "\n"
//      +commentWPR + "\n"
//      +commentMFI + "\n"
//      +commentDem + "\n"
//      +commentCCI + "\n"
//      +commentMom + "\n"      
//      +commentAC + "\n"
 //     ); 

//commentator end

   static datetime timelastupdate= 0;
   static datetime lasttimeframe= 0;
   
   datetime startofday= 0,
            startofyesterday= 0;

   double today_high= 0,
            today_low= 0,
            today_open= 0,
            yesterday_high= 0,
            yesterday_open= 0,
            yesterday_low= 0,
            yesterday_close= 0;

   int idxfirstbaroftoday= 0,
       idxfirstbarofyesterday= 0,
       idxlastbarofyesterday= 0;

   
   // no need to update these buggers too often   
   if (CurTime()-timelastupdate<60 && Period()==lasttimeframe)
      return (0);
      
   lasttimeframe= Period();
   timelastupdate= CurTime();
   
   //---- exit if period is greater than daily charts
   if(Period() > 1440) {
      Alert("Error - Chart period is greater than 1 day.");
      return(-1); // then exit
   }

   if (DebugLogger) {
      Print("Local time current bar:", TimeToStr(Time[0]));
      Print("Dest  time current bar: ", TimeToStr(Time[0]- (LocalTimeZone - DestTimeZone)*3600), ", tzdiff= ", LocalTimeZone - DestTimeZone);
   }

   string gvname; double gvval;

   // let's find out which hour bars make today and yesterday
   ComputeDayIndices(LocalTimeZone, DestTimeZone, idxfirstbaroftoday, idxfirstbarofyesterday, idxlastbarofyesterday);

   startofday= Time[idxfirstbaroftoday];  // datetime (x-value) for labes on horizontal bars
   gvname=Symbol()+"st";
   gvval=startofday;
   GlobalVariableSet(gvname,gvval);
   startofyesterday= Time[idxfirstbarofyesterday];  // datetime (x-value) for labes on horizontal bars

   

   // 
   // walk forward through yestday's start and collect high/lows within the same day
   //
   yesterday_high= -99999;  // not high enough to remain alltime high
   yesterday_low=  +99999;  // not low enough to remain alltime low
   
   for (int idxbar= idxfirstbarofyesterday; idxbar>=idxlastbarofyesterday; idxbar--) {

      if (yesterday_open==0)  // grab first value for open
         yesterday_open= Open[idxbar];                      
      
      yesterday_high= MathMax(High[idxbar], yesterday_high);
      yesterday_low= MathMin(Low[idxbar], yesterday_low);
      
      // overwrite close in loop until we leave with the last iteration's value
      yesterday_close= Close[idxbar];
   }

   

   // 
   // walk forward through today and collect high/lows within the same day
   //
   today_open= Open[idxfirstbaroftoday];  // should be open of today start trading hour

   today_high= -99999; // not high enough to remain alltime high
   today_low=  +99999; // not low enough to remain alltime low
   for (int j= idxfirstbaroftoday; j>=0; j--) {
      today_high= MathMax(today_high, High[j]);
      today_low= MathMin(today_low, Low[j]);
   }
      
   
   
   // draw the vertical bars that marks the time span
   double level= (yesterday_high + yesterday_low + yesterday_close) / 3;
   SetTimeLine("YesterdayStart", "Yesterday", idxfirstbarofyesterday, Magenta, level+10*Point);
   SetTimeLine("YesterdayEnd", "Today", idxfirstbaroftoday, Magenta, level+10*Point);
   
   
   
   if (DebugLogger) 
      Print("Timezoned values: yo= ", yesterday_open, ", yc =", yesterday_close, ", yhigh= ", yesterday_high, ", ylow= ", yesterday_low, ", to= ", today_open);


   //
   //---- Calculate Levels
   //
   double p,q,d,r1,r2,r3,s1,s2,s3,bl1,bl2,sl1,sl2;
   
   d = (today_high - today_low);
   q = (yesterday_high - yesterday_low);
   p = (yesterday_high + yesterday_low + yesterday_close) / 3;
   p=NormalizeDouble(p,digits);
   gvname=Symbol()+"p";
   gvval=p;
   GlobalVariableSet(gvname,gvval);
   
   r1 = (2*p)-yesterday_low;
   r1=NormalizeDouble(r1,digits);
   gvname=Symbol()+"r1";
   gvval=r1;
   GlobalVariableSet(gvname,gvval);
   r2 = p+(yesterday_high - yesterday_low);              //	r2 = p-s1+r1;
   r2=NormalizeDouble(r2,digits);
   gvname=Symbol()+"r2";
   gvval=r2;
   GlobalVariableSet(gvname,gvval);
	r3 = (2*p)+(yesterday_high-(2*yesterday_low));
   r3=NormalizeDouble(r3,digits);
   gvname=Symbol()+"r3";
   gvval=r3;
   GlobalVariableSet(gvname,gvval);
   s1 = (2*p)-yesterday_high;
   s1=NormalizeDouble(s1,digits);
   gvname=Symbol()+"s1";
   gvval=s1;
   GlobalVariableSet(gvname,gvval);
   s2 = p-(yesterday_high - yesterday_low);              //	s2 = p-r1+s1;
   s2=NormalizeDouble(s2,digits);
   gvname=Symbol()+"s2";
   gvval=s2;
   GlobalVariableSet(gvname,gvval);
	s3 = (2*p)-((2* yesterday_high)-yesterday_low);
   s3=NormalizeDouble(s3,digits);
   gvname=Symbol()+"s3";
   gvval=s3;
   GlobalVariableSet(gvname,gvval);

   string Signal ="";
   color col;
   double open;
   if (DailyOpenCalculate == true) { open = today_open; }
   else { open = p; }
    
   bl1 = open+(BuySellStart*Point);
   bl1=NormalizeDouble(bl1,digits);
   gvname=Symbol()+"bl1";
   gvval=bl1;
   GlobalVariableSet(gvname,gvval);
   bl2 = open+(BuySellEnd*Point);
   bl2=NormalizeDouble(bl2,digits);
   gvname=Symbol()+"bl2";
   gvval=bl2;
   GlobalVariableSet(gvname,gvval);
   sl1 = open-(BuySellStart*Point);
   sl1=NormalizeDouble(sl1,digits);
   gvname=Symbol()+"sl1";
   gvval=sl1;
   GlobalVariableSet(gvname,gvval);
   sl2 = open-(BuySellEnd*Point);
   sl2=NormalizeDouble(sl2,digits);
   gvname=Symbol()+"sl2";
   gvval=sl2;
   GlobalVariableSet(gvname,gvval);
   Signal = "Waiting..."; col = Yellow;
   //---- Signal
   if(UseAlerts)
   {
   if (lasttime != Time[0])
   {
   if(Ask>(bl1-5*Point)&&Ask<(bl1+5*Point)){Signal = "SDX-TzPivots BUY Stop @ "+DoubleToStr(bl1,Digits)+""
                                              +"\n, TP @ "+DoubleToStr(bl2,Digits)+""
                                              +"\n, SL @ "+DoubleToStr(bl1-30*Point,Digits)+"";
                                              col = Yellow;
                                              Alert(Signal);
                                             }
   
   if(Ask>(bl2-5*Point)&&Ask<(bl2+5*Point)){Signal = "SDX-TzPivots BUY Stop @ "+DoubleToStr(bl2,Digits)+""
                                             +"\n, TP @ "+DoubleToStr(bl2+20*Point,Digits)+""
                                             +"\n, SL @ "+DoubleToStr(bl1-10*Point,Digits)+"";
                                             col = Yellow;
                                             Alert(Signal);
                                            }
   
   if(Bid<(sl1+5*Point)&&Bid>(sl1-5*Point)){Signal = "SDX-TzPivots SELL Stop @ "+DoubleToStr(sl1,Digits)+""
                                              +"\n, TP @ "+DoubleToStr(sl2,Digits)+""
                                              +"\n, SL @ "+DoubleToStr(sl1+30*Point,Digits)+"";
                                              col = Red;
                                              Alert(Signal);
                                             }
   
   if(Bid<(sl2+5*Point)&&Bid>(sl2-5*Point)){Signal = "SDX-TzPivots Breakout SELL Stop @ "+DoubleToStr(sl2,Digits)+""
                                             +"\n, TP @ "+DoubleToStr(sl2-20*Point,Digits)+""
                                             +"\n, SL @ "+DoubleToStr(sl1+10*Point,Digits)+"";
                                             col = Red;
                                             Alert(Signal);
                                            }
   else lasttime = Time[0];
   }
   }
                                               
   ObjectCreate("Signal", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("Signal", Signal, 8, "Arial", col);
   ObjectSet("Signal", OBJPROP_CORNER, 0);
   ObjectSet("Signal", OBJPROP_XDISTANCE, 170);
   ObjectSet("Signal", OBJPROP_YDISTANCE, 5);

   Signal = "Waiting..."; col = Yellow;
   
   ObjectCreate("Euro", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("Euro", Symbol(), 10, "Arial", MintCream);
   ObjectSet("Euro", OBJPROP_CORNER, 0);
   ObjectSet("Euro", OBJPROP_XDISTANCE, 30);
   ObjectSet("Euro", OBJPROP_YDISTANCE, 3);
   
      ObjectCreate("label18", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("label18", per, 10, "Arial", Yellow);
   ObjectSet("label18", OBJPROP_CORNER, 0);
   ObjectSet("label18", OBJPROP_XDISTANCE, 98);
   ObjectSet("label18", OBJPROP_YDISTANCE, 3);
   
   //---- Buy/Sell Area
   SetLevel("Pivot", p, Silver, LineStyle, LineThickness, startofday);
   SetLevel("BUY Level 1", bl1, BuyArea, LineStyle, LineThickness, startofday);
   SetLevel("BUY Level 2", bl2, BuyArea, LineStyle, LineThickness, startofday);
   SetLevel("SELL Level 1", sl1, SellArea, LineStyle, LineThickness, startofday);
   SetLevel("SELL Level 2", sl2, SellArea, LineStyle, LineThickness, startofday);
   
   if (DailyOpenCalculate == true)
   {
    SetLevel("Open", open, Silver, LineStyle, LineThickness, startofday);
   }
   
   //---- Zones
   Graphics(BUY1, bl1, bl2, BuyArea, startofday);
   Graphics(BUY2, bl2, bl2, BuyArea, startofday);
   Graphics(SELL1, sl1, sl2, SellArea, startofday);
   Graphics(SELL2, sl2, sl2, SellArea, startofday);
   
   

   //---- High/Low, Open
   if (ShowHighLowOpen) {
      SetLevel("Y\'s High", yesterday_high,  Orange, LineStyle, LineThickness, startofyesterday);
      SetLevel("T\'s Open", today_open,      Orange, LineStyle, LineThickness, startofday);
      SetLevel("Y\'s Low", yesterday_low,    Orange, LineStyle, LineThickness, startofyesterday);

   	gvname=Symbol()+"yh";
   	gvval=yesterday_high;
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"to";
   	gvval=today_open;
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"yl";
   	gvval=yesterday_low;
   	GlobalVariableSet(gvname,gvval);
   }


   //---- High/Low, Open
   /*if (ShowSweetSpots) {
      int ssp1, ssp2;
      double ds1, ds2;
      
      ssp1= Bid / Point;
      ssp1= ssp1 - ssp1%50;
      ssp2= ssp1 + 50;
      
      ds1= ssp1*Point;
      ds2= ssp2*Point;
      
      SetLevel(DoubleToStr(ds1,Digits), ds1,  Gold, LineStyle, LineThickness, Time[10]);
      SetLevel(DoubleToStr(ds2,Digits), ds2,  Gold, LineStyle, LineThickness, Time[10]);

   	gvname=Symbol()+"ds1";
   	gvval=ds1;
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"ds2";
   	gvval=ds2;
   	GlobalVariableSet(gvname,gvval);

   }*/
   
   //---- Pivot Lines
   if (ShowPivots==true) {
      SetLevel("R1", r1,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("R2", r2,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("R3", r3,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("S1", s1,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("S2", s2,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("S3", s3,      AliceBlue, LineStyle, LineThickness, startofday);
   }
   
   //---- Fibos of yesterday's range
   if (ShowFibos) {
      // .618, .5 and .382
      SetLevel("Low - 61.8%", yesterday_low - q*0.618,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("Low - 38.2%", yesterday_low - q*0.382,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("Low + 38.2%", yesterday_low + q*0.382,      AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("LowHigh 50%", yesterday_low + q*0.5,        AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("High - 38.2%", yesterday_high - q*0.382,    AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("High + 38.2%", yesterday_high + q*0.382,    AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("High + 61.8%", yesterday_high +  q*0.618,   AliceBlue, LineStyle, LineThickness, startofday);

   	gvname=Symbol()+"flm618";
   	gvval=yesterday_low - q*0.618;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"flm382";
   	gvval=yesterday_low - q*0.382;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"flp382";
   	gvval=yesterday_low + q*0.382;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"flp5";
   	gvval=yesterday_low + q*0.5;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"fhm382";
   	gvval=yesterday_high - q*0.382;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"fhp382";
   	gvval=yesterday_high + q*0.382;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"fhp618";
   	gvval=yesterday_high + q*0.618;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);

   }


   //----- Camarilla Lines
   if (ShowCamarilla==true) {
      
      double h4,h3,l4,l3;
	   h4 = (q*0.55)+yesterday_close;
	   h3 = (q*0.27)+yesterday_close;
	   l3 = yesterday_close-(q*0.27);	
	   l4 = yesterday_close-(q*0.55);	
	   
      SetLevel("Reversal HIGH", h3,   LightGreen, LineStyle, LineThickness, startofday);
      SetLevel("Breakout HIGH", h4,   LightGreen, LineStyle, LineThickness, startofday);
      SetLevel("Reversal LOW", l3,   Orange, LineStyle, LineThickness, startofday);
      SetLevel("Breakout LOW", l4,   Orange, LineStyle, LineThickness, startofday);

   	gvname=Symbol()+"h3";
   	gvval=h3;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"h4";
   	gvval=h4;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"l3";
   	gvval=l3;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"l4";
   	gvval=l4;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
 
  }


   //------ Midpoints Pivots 
   if (ShowMidPitvot==true) {
      // mid levels between pivots
      SetLevel("MR3", (r2+r3)/2,    AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("MR2", (r1+r2)/2,    AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("MR1", (p+r1)/2,     AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("MS1", (p+s1)/2,    AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("MS2", (s1+s2)/2,   AliceBlue, LineStyle, LineThickness, startofday);
      SetLevel("MS3", (s2+s3)/2,   AliceBlue, LineStyle, LineThickness, startofday);

   	gvname=Symbol()+"mr3";
   	gvval=(r2+r3)/2;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"mr2";
   	gvval=(r1+r2)/2;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"mr1";
   	gvval=(p+r1)/2;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"ms1";
   	gvval=(p+s1)/2;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"ms2";
   	gvval=(p+s2)/2;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	gvname=Symbol()+"ms3";
   	gvval=(p+s3)/2;
   	gvval=NormalizeDouble(gvval,digits);
   	GlobalVariableSet(gvname,gvval);
   	
   }


   //------ Comment for upper left corner
   /*if (ShowComment) {
      string comment= ""; 
      
//      comment= comment + "Range: Yesterday "+DoubleToStr(MathRound(q/Point),0)   +" pips, Today "+DoubleToStr(MathRound(d/Point),0)+" pips" + "\n";
 //     comment= comment + "Highs: Yesterday "+DoubleToStr(yesterday_high,Digits)  +", Today "+DoubleToStr(today_high,Digits) +"\n";
 //     comment= comment + "Lows:  Yesterday "+DoubleToStr(yesterday_low,Digits)   +", Today "+DoubleToStr(today_low,Digits)  +"\n";
//      comment= comment + "Close: Yesterday "+DoubleToStr(yesterday_close,Digits) + "\n";
   // comment= comment + "Pivot: " + DoubleToStr(p,Digits) + ", S1/2/3: " + DoubleToStr(s1,Digits) + "/" + DoubleToStr(s2,Digits) + "/" + DoubleToStr(s3,Digits) + "\n" ;
   // comment= comment + "Fibos: " + DoubleToStr(yesterday_low + q*0.382, Digits) + ", " + DoubleToStr(yesterday_high - q*0.382,Digits) + "\n";
      
 //     Comment(comment); 
   }*/
   
//   Comment("\n NN \n ------------------------------------------------"
//   +"\n "+Symbol()+" Trend Analysis"
//   +"\n ------------------------------------------------"
//   +"\n 1st Indicator:"
//   +"\n 2nd Indicator:"
//   +"\n 3rd Indicator:"
 //  +"\n ------------------------------------------------"
//  +"\n Analysis Result:"
 //  +"\n \n ------------------------------------------------"
//  +"\n \n Signal:");
   
   //---- Trend Analysis
   
   //---- ADX
   string ADX_Trend = "";
   color colt1;
   
   double ADXP=iADX(NULL,0,ADX_period,PRICE_CLOSE,MODE_PLUSDI,0);
   double ADXM=iADX(NULL,0,ADX_period,PRICE_CLOSE,MODE_MINUSDI,0);
   
   if ((ADXP > ADXM)) { ADX_Trend = "UP"; colt1 = Yellow; }
   if ((ADXP < ADXM)) { ADX_Trend = "DOWN"; colt1 = Red; }
   
   ObjectCreate("ADX", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("ADX",ADX_Trend,8, "Arial", colt1);
   ObjectSet("ADX", OBJPROP_CORNER, 0);
   ObjectSet("ADX", OBJPROP_XDISTANCE, 188);
   ObjectSet("ADX", OBJPROP_YDISTANCE, 23);   
   
   //---- FI
   string FI_Trend ="";
   color colt2;
   
   double FI=iForce(NULL,0,FI_period,1,PRICE_CLOSE,0);
   
   if((FI > 0)) { FI_Trend ="UP"; colt2 = Yellow; }
   if((FI < 0)) { FI_Trend ="DOWN"; colt2 = Red; }
   
   ObjectCreate("FI", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("FI",FI_Trend,8, "Arial", colt2);
   ObjectSet("FI", OBJPROP_CORNER, 0);
   ObjectSet("FI", OBJPROP_XDISTANCE, 310);
   ObjectSet("FI", OBJPROP_YDISTANCE, 23);  
   
   //---- RSI
   string RSI_Trend ="";
   color colt3;
   
   double RSI=iRSI(NULL,0,RSI_period,PRICE_CLOSE,0);
   
   if((RSI > 50)) { RSI_Trend ="UP"; colt3 = Yellow; }
   if((RSI < 50)) { RSI_Trend ="DOWN"; colt3 = Red; }

   ObjectCreate("RSI", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("RSI",RSI_Trend,8, "Arial", colt3);
   ObjectSet("RSI", OBJPROP_CORNER, 0);
   ObjectSet("RSI", OBJPROP_XDISTANCE, 432);
   ObjectSet("RSI", OBJPROP_YDISTANCE, 23);
   
   string Analysis ="", Strength ="", Trend="";
   color cola1, cola2, cola3;
   
   if(ADX_Trend=="UP"&&FI_Trend=="UP"&&RSI_Trend=="UP")
   {Analysis="UP"; cola1=Gold; Strength="[Strong]"; cola2=Yellow; Trend="BULLISH"; cola3=Yellow;}
   if(ADX_Trend=="UP"&&FI_Trend=="UP"&&RSI_Trend=="DOWN")
   {Analysis="UP"; cola1=Gold; Strength="[Weak]"; cola2=Lime; Trend="SIDEWAYS"; cola3=AliceBlue;}
   if(ADX_Trend=="UP"&&FI_Trend=="DOWN"&&RSI_Trend=="UP")
   {Analysis="UP"; cola1=Gold; Strength="[Weak]"; cola2=Lime; Trend="SIDEWAYS"; cola3=AliceBlue;}
   if(ADX_Trend=="UP"&&FI_Trend=="DOWN"&&RSI_Trend=="DOWN")
   {Analysis="DOWN"; cola1=Red; Strength="[Weak]"; cola2=Tomato; Trend="SIDEWAYS"; cola3=AliceBlue;}
   if(ADX_Trend=="DOWN"&&FI_Trend=="DOWN"&&RSI_Trend=="DOWN")
   {Analysis="DOWN"; cola1=Red; Strength="[Strong]"; cola2=Magenta; Trend="BEARISH"; cola3=Red;}
   if(ADX_Trend=="DOWN"&&FI_Trend=="DOWN"&&RSI_Trend=="UP")
   {Analysis="DOWN"; cola1=Red; Strength="[Weak]"; cola2=Tomato; Trend="SIDEWAYS"; cola3=AliceBlue;}
   if(ADX_Trend=="DOWN"&&FI_Trend=="UP"&&RSI_Trend=="DOWN")
   {Analysis="DOWN"; cola1=Red; Strength="[Weak]"; cola2=Tomato; Trend="SIDEWAYS"; cola3=AliceBlue;}
   if(ADX_Trend=="DOWN"&&FI_Trend=="UP"&&RSI_Trend=="UP")
   {Analysis="UP"; cola1=Gold; Strength="[Weak]"; cola2=Lime; Trend="SIDEWAYS"; cola3=AliceBlue;}

   ObjectCreate("Analysis", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("Analysis",Analysis,8, "Arial", cola1);
   ObjectSet("Analysis", OBJPROP_CORNER, 0);
   ObjectSet("Analysis", OBJPROP_XDISTANCE, 582);
   ObjectSet("Analysis", OBJPROP_YDISTANCE, 22);
   
   ObjectCreate("Strength", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("Strength",Strength,8, "Arial", cola2);
   ObjectSet("Strength", OBJPROP_CORNER, 0);
   ObjectSet("Strength", OBJPROP_XDISTANCE, 618);
   ObjectSet("Strength", OBJPROP_YDISTANCE, 22);
   
   ObjectCreate("Trend", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("Trend",Trend,8, "Arial", cola3);
   ObjectSet("Trend", OBJPROP_CORNER, 0);
   ObjectSet("Trend", OBJPROP_XDISTANCE, 763);
   ObjectSet("Trend", OBJPROP_YDISTANCE, 23);

   ObjectCreate("Label0", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("Label0"," Trend Analysis:-",10, "Arial",Gold);
   ObjectSet("Label0", OBJPROP_CORNER, 0);
   ObjectSet("Label0", OBJPROP_XDISTANCE, 0);
   ObjectSet("Label0", OBJPROP_YDISTANCE, 20);

   ObjectCreate("Label1", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("Label1","ADX Indicator: ",10, "Arial",Honeydew);
   ObjectSet("Label1", OBJPROP_CORNER, 0);
   ObjectSet("Label1", OBJPROP_XDISTANCE, 105);
   ObjectSet("Label1", OBJPROP_YDISTANCE, 20);
   
      ObjectCreate("Label2", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("Label2","2nd Indicator: ",10, "Arial",Honeydew);
   ObjectSet("Label2", OBJPROP_CORNER, 0);
   ObjectSet("Label2", OBJPROP_XDISTANCE, 230);
   ObjectSet("Label2", OBJPROP_YDISTANCE, 20);
   
         ObjectCreate("Label3", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("Label3","RSI Indicator: ",10, "Arial",Honeydew);
   ObjectSet("Label3", OBJPROP_CORNER, 0);
   ObjectSet("Label3", OBJPROP_XDISTANCE, 350);
   ObjectSet("Label3", OBJPROP_YDISTANCE, 20);
   
            ObjectCreate("Label4", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("Label4","Analysis Result: ",10, "Arial",Turquoise);
   ObjectSet("Label4", OBJPROP_CORNER, 0);
   ObjectSet("Label4", OBJPROP_XDISTANCE, 485);
   ObjectSet("Label4", OBJPROP_YDISTANCE, 19);
   
               ObjectCreate("Label5", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("Label5","Trend Direction: ",10, "Arial",Khaki);
   ObjectSet("Label5", OBJPROP_CORNER, 0);
   ObjectSet("Label5", OBJPROP_XDISTANCE, 670);
   ObjectSet("Label5", OBJPROP_YDISTANCE, 20);
   
                  ObjectCreate("Label6", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("Label6","Signal: ",10, "Arial",AliceBlue);
   ObjectSet("Label6", OBJPROP_CORNER, 0);
   ObjectSet("Label6", OBJPROP_XDISTANCE, 125);
   ObjectSet("Label6", OBJPROP_YDISTANCE, 2);

//commentator code start

   ObjectCreate("comment1", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment1","Stoch: ",10, "Arial",AliceBlue);
   ObjectSet("comment1", OBJPROP_CORNER, 0);
   ObjectSet("comment1", OBJPROP_XDISTANCE, 10);
   ObjectSet("comment1", OBJPROP_YDISTANCE, 38);
   
   ObjectCreate("stoch", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("stoch",STOCHAdd,8, "Arial", colt9);
   ObjectSet("stoch", OBJPROP_CORNER, 0);
   ObjectSet("stoch", OBJPROP_XDISTANCE, 63);
   ObjectSet("stoch", OBJPROP_YDISTANCE, 41); 

   ObjectCreate("comment2", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment2","R%: ",10, "Arial",Orange);
   ObjectSet("comment2", OBJPROP_CORNER, 0);
   ObjectSet("comment2", OBJPROP_XDISTANCE, 11);
   ObjectSet("comment2", OBJPROP_YDISTANCE, 52);
   
   ObjectCreate("R%", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("R%",WPRAdd,8, "Arial", colt8);
   ObjectSet("R%", OBJPROP_CORNER, 0);
   ObjectSet("R%", OBJPROP_XDISTANCE, 65);
   ObjectSet("R%", OBJPROP_YDISTANCE, 54); 
   
  ObjectCreate("comment3", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment3","MFI: ",10, "Arial",AliceBlue);
   ObjectSet("comment3", OBJPROP_CORNER, 0);
   ObjectSet("comment3", OBJPROP_XDISTANCE, 11);
   ObjectSet("comment3", OBJPROP_YDISTANCE, 65);
   
   ObjectCreate("MFI", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("MFI",MFIAdd,8, "Arial", colt7);
   ObjectSet("MFI", OBJPROP_CORNER, 0);
   ObjectSet("MFI", OBJPROP_XDISTANCE, 65);
   ObjectSet("MFI", OBJPROP_YDISTANCE, 68); 
   
   ObjectCreate("comment4", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment4","DeMarker: ",10, "Arial",AliceBlue);
   ObjectSet("comment4", OBJPROP_CORNER, 0);
   ObjectSet("comment4", OBJPROP_XDISTANCE, 11);
   ObjectSet("comment4", OBJPROP_YDISTANCE, 78);
   
   ObjectCreate("DeMarker", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("DeMarker",DemAdd,8, "Arial", colt3);
   ObjectSet("DeMarker", OBJPROP_CORNER, 0);
   ObjectSet("DeMarker", OBJPROP_XDISTANCE, 65);
   ObjectSet("DeMarker", OBJPROP_YDISTANCE, 81); 
   
   ObjectCreate("comment5", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment5","CCI: ",10, "Arial",AliceBlue);
   ObjectSet("comment5", OBJPROP_CORNER, 0);
   ObjectSet("comment5", OBJPROP_XDISTANCE, 370);
   ObjectSet("comment5", OBJPROP_YDISTANCE, 37);
   
   ObjectCreate("CCI", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("CCI",CCIAdd,8, "Arial", colt6);
   ObjectSet("CCI", OBJPROP_CORNER, 0);
   ObjectSet("CCI", OBJPROP_XDISTANCE, 435);
   ObjectSet("CCI", OBJPROP_YDISTANCE, 40);
   
   ObjectCreate("comment6", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment6","ATR: ",10, "Arial",AliceBlue);
   ObjectSet("comment6", OBJPROP_CORNER, 0);
   ObjectSet("comment6", OBJPROP_XDISTANCE, 370);
   ObjectSet("comment6", OBJPROP_YDISTANCE, 50);
   
   ObjectCreate("ATR", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("ATR",ATR,8, "Arial", colt4);
   ObjectSet("ATR", OBJPROP_CORNER, 0);
   ObjectSet("ATR", OBJPROP_XDISTANCE, 435);
   ObjectSet("ATR", OBJPROP_YDISTANCE, 52);
   
   ObjectCreate("comment7", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment7","Momentum: ",10, "Arial",LightCyan);
   ObjectSet("comment7", OBJPROP_CORNER, 0);
   ObjectSet("comment7", OBJPROP_XDISTANCE, 370);
   ObjectSet("comment7", OBJPROP_YDISTANCE, 64);
   
   ObjectCreate("Momentum", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("Momentum",MomAdd,8, "Arial", colt10);
   ObjectSet("Momentum", OBJPROP_CORNER, 0);
   ObjectSet("Momentum", OBJPROP_XDISTANCE, 435);
   ObjectSet("Momentum", OBJPROP_YDISTANCE, 66);
   
   ObjectCreate("comment8", OBJ_LABEL, WindowFind("SDX"), 0, 0);
   ObjectSetText("comment8","AC: ",10, "Arial",LawnGreen);
   ObjectSet("comment8", OBJPROP_CORNER, 0);
   ObjectSet("comment8", OBJPROP_XDISTANCE, 370);
   ObjectSet("comment8", OBJPROP_YDISTANCE, 80);
   
   ObjectCreate("AC", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("AC",ACAdd,8, "Arial", colt5);
   ObjectSet("AC", OBJPROP_CORNER, 0);
   ObjectSet("AC", OBJPROP_XDISTANCE, 445);
   ObjectSet("AC", OBJPROP_YDISTANCE, 82);

   ObjectCreate("AC1", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("AC1"," | "+ACAdd1,8, "Arial", colt5);
   ObjectSet("AC1", OBJPROP_CORNER, 0);
   ObjectSet("AC1", OBJPROP_XDISTANCE, 535);
   ObjectSet("AC1", OBJPROP_YDISTANCE, 82);
   
   ObjectCreate("AC0", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("AC0"," | "+ACAdd0,8, "Arial", colt5);
   ObjectSet("AC0", OBJPROP_CORNER, 0);
   ObjectSet("AC0", OBJPROP_XDISTANCE, 615);
   ObjectSet("AC0", OBJPROP_YDISTANCE, 82);
   
   ObjectCreate("CADD", OBJ_LABEL, 1, 0, 0);
   ObjectSetText("CADD"," | "+ACAdd2,8, "Arial", colt5);
   ObjectSet("CADD", OBJPROP_CORNER, 0);
   ObjectSet("CADD", OBJPROP_XDISTANCE, 699);
   ObjectSet("CADD", OBJPROP_YDISTANCE, 82);
//commentator code end   
   return(0);
} 
//+------------------------------------------------------------------+
//| Compute index of first/last bar of yesterday and today           |
//+------------------------------------------------------------------+
void ComputeDayIndices(int tzlocal, int tzdest, int &idxfirstbaroftoday, int &idxfirstbarofyesterday, int &idxlastbarofyesterday)
{     
   int tzdiff= tzlocal - tzdest,
       tzdiffsec= tzdiff*3600,
       dayminutes= 24 * 60,
       barsperday= dayminutes/Period();
   
   int dayofweektoday= TimeDayOfWeek(Time[0] - tzdiffsec),  // what day is today in the dest timezone?
       dayofweektofind= -1; 

   //
   // due to gaps in the data, and shift of time around weekends (due 
   // to time zone) it is not as easy as to just look back for a bar 
   // with 00:00 time
   //
   
   idxfirstbaroftoday= 0;
   idxfirstbarofyesterday= 0;
   idxlastbarofyesterday= 0;
       
   switch (dayofweektoday) {
      case 6: // sat
      case 0: // sun
      case 1: // mon
            dayofweektofind= 5; // yesterday in terms of trading was previous friday
            break;
            
      default:
            dayofweektofind= dayofweektoday -1; 
            break;
   }
   
   if (DebugLogger) {
      Print("Dayofweektoday= ", dayofweektoday);
      Print("Dayofweekyesterday= ", dayofweektofind);
   }
       
       
   // search  backwards for the last occrrence (backwards) of the day today (today's first bar)
   for (int i=1; i<=barsperday+1; i++) {
      datetime timet= Time[i] - tzdiffsec;
      if (TimeDayOfWeek(timet)!=dayofweektoday) {
         idxfirstbaroftoday= i-1;
         break;
      }
   }
   

   // search  backwards for the first occrrence (backwards) of the weekday we are looking for (yesterday's last bar)
   for (int j= 0; j<=2*barsperday+1; j++) {
      datetime timey= Time[i+j] - tzdiffsec;
      if (TimeDayOfWeek(timey)==dayofweektofind) {  // ignore saturdays (a Sa may happen due to TZ conversion)
         idxlastbarofyesterday= i+j;
         break;
      }
   }


   // search  backwards for the first occurrence of weekday before yesterday (to determine yesterday's first bar)
   for (j= 1; j<=barsperday; j++) {
      datetime timey2= Time[idxlastbarofyesterday+j] - tzdiffsec;
      if (TimeDayOfWeek(timey2)!=dayofweektofind) {  // ignore saturdays (a Sa may happen due to TZ conversion)
         idxfirstbarofyesterday= idxlastbarofyesterday+j-1;
         break;
      }
   }


   if (DebugLogger) {
      Print("Dest time zone\'s current day starts:", TimeToStr(Time[idxfirstbaroftoday]), 
                                                      " (local time), idxbar= ", idxfirstbaroftoday);

      Print("Dest time zone\'s previous day starts:", TimeToStr(Time[idxfirstbarofyesterday]), 
                                                      " (local time), idxbar= ", idxfirstbarofyesterday);
      Print("Dest time zone\'s previous day ends:", TimeToStr(Time[idxlastbarofyesterday]), 
                                                      " (local time), idxbar= ", idxlastbarofyesterday);
   }
   
}


//+------------------------------------------------------------------+
//| Helper                                                           |
//+------------------------------------------------------------------+
void SetLevel(string text, double level, color col1, int linestyle, int thickness, datetime startofday)
{
   int digits= Digits;
   string labelname= "[PIVOT] " + text + " Label",
          linename= "[PIVOT] " + text + " Line",
          pricelabel; 

   // create or move the horizontal line   
   if (ObjectFind(linename) != 0) {
      ObjectCreate(linename, OBJ_TREND, 0, startofday, level, Time[0],level);
      ObjectSet(linename, OBJPROP_STYLE, linestyle);
      ObjectSet(linename, OBJPROP_COLOR, col1);
      ObjectSet(linename, OBJPROP_WIDTH, thickness);
      ObjectSet(linename, OBJPROP_BACK, false);
   }
   else {
      ObjectMove(linename, 1, Time[0],level);
      ObjectMove(linename, 0, startofday, level);
   }
   

   // put a label on the line   
   if (ObjectFind(labelname) != 0) {
      ObjectCreate(labelname, OBJ_TEXT, 0, Time[BarForLabels], level);
   }
   else {
      ObjectMove(labelname, 0, Time[BarForLabels], level);
   }

   pricelabel= " " + text;
   if (ShowLevelPrices && StrToInteger(text)==0) 
      pricelabel= pricelabel + ": "+DoubleToStr(level, Digits);
   
   ObjectSetText(labelname, pricelabel, 8, "Arial", AliceBlue);
}
      

//+------------------------------------------------------------------+
//| Helper                                                           |
//+------------------------------------------------------------------+
void SetTimeLine(string objname, string text, int idx, color col1, double vleveltext) 
{
   string name= "[PIVOT] " + objname;
   int x= Time[idx];

   if (ObjectFind(name) != 0) 
      ObjectCreate(name, OBJ_TREND, 0, x, 0, x, 100);
   else {
      ObjectMove(name, 0, x, 0);
      ObjectMove(name, 1, x, 100);
   }
   
   ObjectSet(name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSet(name, OBJPROP_COLOR, DarkGray);
   
   if (ObjectFind(name + " Label") != 0) 
      ObjectCreate(name + " Label", OBJ_TEXT, 0, x, vleveltext);
   else
      ObjectMove(name + " Label", 0, x, vleveltext);
            
   ObjectSetText(name + " Label", text, 8, "Arial", col1);
}

//---- Zones
void Graphics(string GFX, double start, double end, color clr, datetime startofday)
{
 ObjectCreate(GFX, OBJ_RECTANGLE, 0, startofday, start, Time[0],end);
 ObjectSet(GFX, OBJPROP_COLOR, clr);
 ObjectSet(GFX, OBJPROP_BACK, Zones);
 ObjectSet(GFX, OBJPROP_RAY, false);
 ObjectMove(GFX, 1, Time[0]+99999*24,end);
 ObjectMove(GFX, 0, startofday, start);
 
 if(Zones==false)
 {
  ObjectDelete(GFX);
 }
}