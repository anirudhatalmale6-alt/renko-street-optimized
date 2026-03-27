//+------------------------------------------------------------------+
//|                                             RenkoStreet Tren.mq4 |
//|                                   Copyright@ 2020,TradingMT4.Com |
//|                                       https://www.tradingmt4.com |
//+------------------------------------------------------------------+
#property copyright "Copyright@ 2020,TradingMT4.Com"
#property link      "https://www.tradingmt4.com"
#property version   "2.1"
//#property strict

#property indicator_separate_window
#property indicator_minimum 0.0
#property indicator_maximum 0.1
#property indicator_buffers 3
#property indicator_color1 Black
#property indicator_color2 Lime
#property indicator_color3 Red

extern int Gi_76 = 13;
double G_ibuf_80[];
double G_ibuf_84[];
double G_ibuf_88[];

// RenkoStreet Trading System
int init()
  {
   SetIndexStyle(0, DRAW_NONE);
   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 4);
   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 4);
   IndicatorDigits(Digits + 1);
   SetIndexBuffer(0, G_ibuf_80);
   SetIndexBuffer(1, G_ibuf_84);
   SetIndexBuffer(2, G_ibuf_88);
   IndicatorShortName(WindowExpertName()+" ("+IntegerToString(Gi_76)+")");
   return (0);
  }

// RenkoStreet Trading System
int start()
  {
   double Ld_0;
   double Ld_8;
   double Ld_16;
   int Li_24 = IndicatorCounted();
   double Ld_28 = 0;
   double Ld_36 = 0;
   double Ld_unused_44 = 0;
   double Ld_unused_52 = 0;
   double Ld_60 = 0;
   double Ld_unused_68 = 0;
   double low_76 = 0;
   double high_84 = 0;
   if(Li_24 > 0)
      Li_24--;
   int Li_92 = Bars - Li_24;
   for(int Li_96 = 0; Li_96 < Bars; Li_96++)
     {
      high_84 = High[iHighest(NULL, 0, MODE_HIGH, Gi_76, Li_96)];
      low_76 = Low[iLowest(NULL, 0, MODE_LOW, Gi_76, Li_96)];
      Ld_16 = (High[Li_96] + Low[Li_96]) / 2.0;
      if(high_84 - low_76 == 0.0)
         Ld_28 = 0.67 * Ld_36 + (-0.33);
      else
         Ld_28 = 0.66 * ((Ld_16 - low_76) / (high_84 - low_76) - 0.5) + 0.67 * Ld_36;
      Ld_28 = MathMin(MathMax(Ld_28, -0.999), 0.999);
      if(1 - Ld_28 == 0.0)
         G_ibuf_80[Li_96] = Ld_60 / 2.0 + 0.5;
      else
         G_ibuf_80[Li_96] = MathLog((Ld_28 + 1.0) / (1 - Ld_28)) / 2.0 + Ld_60 / 2.0;
      Ld_36 = Ld_28;
      Ld_60 = G_ibuf_80[Li_96];
     }
   bool Li_100 = TRUE;
   for(Li_96 = Bars; Li_96 >= 0; Li_96--)
     {
      Ld_8 = G_ibuf_80[Li_96];
      Ld_0 = G_ibuf_80[Li_96 + 1];
      if((Ld_8 < 0.0 && Ld_0 > 0.0) || Ld_8 < 0.0)
         Li_100 = FALSE;
      if((Ld_8 > 0.0 && Ld_0 < 0.0) || Ld_8 > 0.0)
         Li_100 = TRUE;
      if(!Li_100)
        {
         G_ibuf_88[Li_96] = 1;
         G_ibuf_84[Li_96] = 0.0;
        }
      else
        {
         G_ibuf_84[Li_96] = 1;
         G_ibuf_88[Li_96] = 0.0;
        }
     }
   return (0);
  }
//+------------------------------------------------------------------+
