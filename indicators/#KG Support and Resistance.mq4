//+------------------------------------------------------------------+
//|                                      KG Support & Resistance.mq4 |
//|                      Copyright © 2007, MetaQuotes Software Corp. |
//|                                        http://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Kang_Gun"
#property link      "http://www.free-knowledge.com"

#property indicator_chart_window
#property indicator_buffers 8
#property indicator_color1 Yellow
#property indicator_color2 Yellow
#property indicator_color3 LimeGreen
#property indicator_color4 LimeGreen
#property indicator_color5 Blue
#property indicator_color6 Blue
#property indicator_color7 Red
#property indicator_color8 Red
//---- input parameters

//---- buffers
double ExtMapBuffer1[];
double ExtMapBuffer2[];
double ExtMapBuffer3[];
double ExtMapBuffer4[];
double ExtMapBuffer5[];
double ExtMapBuffer6[];
double ExtMapBuffer7[];
double ExtMapBuffer8[];
int KG;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
  {
//---- indicators
   SetIndexStyle(0,DRAW_ARROW,STYLE_DOT,1,Yellow);
   SetIndexDrawBegin(0,KG-1);
   SetIndexBuffer(0,ExtMapBuffer1);
   SetIndexLabel(0,"Resistance M15");
   SetIndexArrow(0, 158);
   SetIndexStyle(1,DRAW_ARROW,STYLE_DOT,1,Yellow);
   SetIndexDrawBegin(1,KG-1);
   SetIndexBuffer(1,ExtMapBuffer2);
   SetIndexLabel(1,"Support M15");
   SetIndexArrow(1, 158);
   SetIndexStyle(2,DRAW_ARROW,STYLE_DOT,1,LimeGreen);
   SetIndexDrawBegin(2,KG-1);
   SetIndexBuffer(2,ExtMapBuffer3);
   SetIndexLabel(2,"Resistance H1");
   SetIndexArrow(2, 158);
   SetIndexStyle(3,DRAW_ARROW,STYLE_DOT,1,LimeGreen);
   SetIndexDrawBegin(3,KG-1);
   SetIndexBuffer(3,ExtMapBuffer4);
   SetIndexLabel(3,"Support H1");
   SetIndexArrow(3, 158);
   SetIndexStyle(4,DRAW_ARROW,STYLE_DOT,1,Blue);
   SetIndexDrawBegin(4,KG-1);
   SetIndexBuffer(4,ExtMapBuffer5);
   SetIndexLabel(4,"Resistance H4");
   SetIndexArrow(4, 158);
   SetIndexStyle(5,DRAW_ARROW,STYLE_DOT,1,Blue);
   SetIndexDrawBegin(5,KG-1);
   SetIndexBuffer(5,ExtMapBuffer6);
   SetIndexLabel(5,"Support H4");
   SetIndexArrow(5, 158);
   SetIndexStyle(6,DRAW_ARROW,STYLE_DOT,1,Red);
   SetIndexDrawBegin(6,KG-1);
   SetIndexBuffer(6,ExtMapBuffer7);
   SetIndexLabel(6,"Resistance D1");
   SetIndexArrow(6, 158);
   SetIndexStyle(7,DRAW_ARROW,STYLE_DOT,1,Red);
   SetIndexDrawBegin(7,KG-1);
   SetIndexBuffer(7,ExtMapBuffer8);
   SetIndexLabel(7,"Support D1");
   SetIndexArrow(7, 158);
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Custor indicator deinitialization function                       |
//+------------------------------------------------------------------+
int deinit()
  {
   return(0);
  }
//------------------------------------------------------------------  
bool Fractal (string M,int P, int shift)
  {
   if (Period()>P) return(-1);
   P=P/Period()*2+MathCeil(P/Period()/2);
   if (shift<P)return(-1);
   if (shift>Bars-P)return(-1); 
   for (int i=1;i<=P;i++)
     {
      if (M=="U")
        {
         if (High[shift+i]>High[shift])return(-1);
         if (High[shift-i]>=High[shift])return(-1);     
        }
      if (M=="L")
        {
         if (Low[shift+i]<Low[shift])return(-1);
         if (Low[shift-i]<=Low[shift])return(-1);
        }        
     }
   return(1);   
  }  
//------------------------------------------------------------------
int start()
  {
   int D1=1440, H4=240, H1=60, M15=15;
   KG=Bars;
      while(KG>=0)
      {
       if (Fractal("U",M15,KG)==1) ExtMapBuffer1[KG]=High[KG];
       else ExtMapBuffer1[KG]=ExtMapBuffer1[KG+1];
       if (Fractal("L",M15,KG)==1) ExtMapBuffer2[KG]=Low[KG];
       else ExtMapBuffer2[KG]=ExtMapBuffer2[KG+1];
       if (Fractal("U",H1,KG)==1) ExtMapBuffer3[KG]=High[KG];
       else ExtMapBuffer3[KG]=ExtMapBuffer3[KG+1];
       if (Fractal("L",H1,KG)==1) ExtMapBuffer4[KG]=Low[KG];
       else ExtMapBuffer4[KG]=ExtMapBuffer4[KG+1];
       if (Fractal("U",H4,KG)==1) ExtMapBuffer5[KG]=High[KG];
       else ExtMapBuffer5[KG]=ExtMapBuffer5[KG+1];
       if (Fractal("L",H4,KG)==1) ExtMapBuffer6[KG]=Low[KG];
       else ExtMapBuffer6[KG]=ExtMapBuffer6[KG+1];
       if (Fractal("U",D1,KG)==1) ExtMapBuffer7[KG]=High[KG];
       else ExtMapBuffer7[KG]=ExtMapBuffer7[KG+1];
       if (Fractal("L",D1,KG)==1) ExtMapBuffer8[KG]=Low[KG];
       else ExtMapBuffer8[KG]=ExtMapBuffer8[KG+1];
       KG--;
      }
  
 
   return(0);
  }
//+------------------------------------------------------------------+