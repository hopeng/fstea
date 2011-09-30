//+------------------------------------------------------------------+
//|                                                 Accumulation.mq4 |
//|                      Copyright © 2005, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, MetaQuotes Software Corp."
#property link      "http://www.metaquotes.net/"

#property indicator_separate_window
#property indicator_buffers 1
#property indicator_color1 LightSeaGreen
//---- buffers
double ExtMapBuffer1[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
   IndicatorShortName("A/D");
//---- indicators
   SetIndexStyle(0,DRAW_LINE);
   SetIndexBuffer(0,ExtMapBuffer1);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Accumulation/Distribution                                        |
//+------------------------------------------------------------------+
int start()
  {
   int i,counted_bars=IndicatorCounted();
//----
   i=Bars-counted_bars-1;
   while(i>=0)
     {
      double high =High[i];
      double low  =Low[i];
      double open =Open[i];
      double close=Close[i];
      ExtMapBuffer1[i]=(close-low)-(high-close);
      if(ExtMapBuffer1[i]!=0)
        {
         double diff=high-low;
         if(0==diff)
            ExtMapBuffer1[i]=0;
         else
           {
            ExtMapBuffer1[i]/=diff;
            ExtMapBuffer1[i]*=Volume[i];
           }
        }
      if(i<Bars-1) ExtMapBuffer1[i]+=ExtMapBuffer1[i+1];
      i--;
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+