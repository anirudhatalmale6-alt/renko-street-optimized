//+------------------------------------------------------------------+
//|                                             RenkoStreet Tren.mq4 |
//|                                   Copyright@ 2020,TradingMT4.Com |
//|                                       https://www.tradingmt4.com |
//+------------------------------------------------------------------+
//| Optimized version v2                                              |
//|   1. Converted start() to OnCalculate() with prev_calculated     |
//|   2. Incremental recalculation: only ~50 bars per tick           |
//|   3. Fixed: timeframe switch now triggers full recalculation     |
//|   4. Added: customizable Up/Down histogram colours               |
//|   5. All signals and logic preserved exactly                     |
//+------------------------------------------------------------------+
#property copyright "Copyright@ 2020,TradingMT4.Com"
#property link      "https://www.tradingmt4.com"
#property version   "2.1"
#property strict

#property indicator_separate_window
#property indicator_minimum 0.0
#property indicator_maximum 0.1
#property indicator_buffers 3
#property indicator_color1 Black
#property indicator_color2 Lime
#property indicator_color3 Red

extern int    Gi_76     = 13;
extern color  UpColor   = clrLime;
extern color  DownColor = clrRed;

double G_ibuf_80[];
double G_ibuf_84[];
double G_ibuf_88[];

// Convergence depth: with 0.67 decay, 50 bars gives error < 1e-9.
#define RECALC_DEPTH 50

// Track whether a full calculation has been completed since last init.
static bool g_fullCalcDone = false;
// Track bar count to detect data loading / timeframe changes.
static int  g_lastBars = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   SetIndexStyle(0, DRAW_NONE);
   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 4);
   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 4);
   SetIndexBuffer(0, G_ibuf_80);
   SetIndexBuffer(1, G_ibuf_84);
   SetIndexBuffer(2, G_ibuf_88);
   SetIndexLabel(1, "Up");
   SetIndexLabel(2, "Down");
   IndicatorDigits(Digits + 1);
   IndicatorShortName(WindowExpertName() + " (" + IntegerToString(Gi_76) + ")");

   // Apply user-chosen colours
   SetIndexStyle(1, DRAW_HISTOGRAM, STYLE_SOLID, 4, UpColor);
   SetIndexStyle(2, DRAW_HISTOGRAM, STYLE_SOLID, 4, DownColor);

   // Force full recalculation on next OnCalculate call
   g_fullCalcDone = false;
   g_lastBars     = 0;

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   int bars = Bars;

   // Not enough data yet — return 0 so MT4 retries with prev_calculated=0
   if(bars < Gi_76 + 1)
      return(0);

   //--- Determine whether we need a full recalculation
   bool needFullCalc = false;

   if(!g_fullCalcDone)
      needFullCalc = true;                    // Never completed a full calc since init
   else if(prev_calculated == 0)
      needFullCalc = true;                    // MT4 is asking for full recalc
   else if(bars > g_lastBars + RECALC_DEPTH)
      needFullCalc = true;                    // Many new bars loaded (e.g. data backfill)

   g_lastBars = bars;

   //--- Set recalculation range
   int limit;
   if(needFullCalc)
      limit = bars - 1;                       // Full history
   else
      limit = MathMin(RECALC_DEPTH, bars - 1); // Incremental: convergence depth only

   //--- Phase 1: Fisher Transform (bar 0 → limit)
   //    Recursive chain with 0.67 decay per bar.
   double Ld_28 = 0.0;
   double Ld_36 = 0.0;
   double Ld_60 = 0.0;
   double high_val, low_val, mid;

   for(int i = 0; i <= limit; i++)
     {
      high_val = High[iHighest(NULL, 0, MODE_HIGH, Gi_76, i)];
      low_val  = Low[iLowest(NULL, 0, MODE_LOW, Gi_76, i)];
      mid      = (High[i] + Low[i]) / 2.0;

      if(high_val - low_val == 0.0)
         Ld_28 = 0.67 * Ld_36 + (-0.33);
      else
         Ld_28 = 0.66 * ((mid - low_val) / (high_val - low_val) - 0.5) + 0.67 * Ld_36;

      Ld_28 = MathMin(MathMax(Ld_28, -0.999), 0.999);

      if(1.0 - Ld_28 == 0.0)
         G_ibuf_80[i] = Ld_60 / 2.0 + 0.5;
      else
         G_ibuf_80[i] = MathLog((Ld_28 + 1.0) / (1.0 - Ld_28)) / 2.0 + Ld_60 / 2.0;

      Ld_36 = Ld_28;
      Ld_60 = G_ibuf_80[i];
     }

   //--- Phase 2: Colour assignment (recalculated range only)
   bool trend_up = true;

   // Seed trend state from the bar just past our recalculated range
   if(limit < bars - 1)
     {
      if(G_ibuf_88[limit + 1] == 1.0)
         trend_up = false;
      else
         trend_up = true;
     }

   double curr, prev_val;
   for(int i = limit; i >= 0; i--)
     {
      curr     = G_ibuf_80[i];
      prev_val = (i + 1 < bars) ? G_ibuf_80[i + 1] : 0.0;

      if((curr < 0.0 && prev_val > 0.0) || curr < 0.0)
         trend_up = false;
      if((curr > 0.0 && prev_val < 0.0) || curr > 0.0)
         trend_up = true;

      if(!trend_up)
        {
         G_ibuf_88[i] = 1.0;
         G_ibuf_84[i] = 0.0;
        }
      else
        {
         G_ibuf_84[i] = 1.0;
         G_ibuf_88[i] = 0.0;
        }
     }

   g_fullCalcDone = true;
   return(rates_total);
  }
//+------------------------------------------------------------------+
