
/* Includes ------------------------------------------------------------------*/
#include "wavegenerator.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern volatile uint16_t LineCount;
extern volatile uint32_t SecCount;
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;

/* Private variables ---------------------------------------------------------*/
WAVE Wave;
DAC_InitTypeDef  DAC_InitStructure;
DMA_InitTypeDef DMA_InitStructure;
const uint16_t SineWave[256]={2048,2098,2148,2199,2249,2299,2348,2398,2447,2497,2545,2594,2642,2690,2738,2785,2831,2878,2923,2968,3013,3057,3100,3143,3185,3227,3267,3307,3347,3385,3423,3459,3495,3531,3565,3598,3630,3662,3692,3722,3750,3777,3804,3829,3853,3876,3898,3919,3939,3958,3975,3992,4007,4021,4034,4045,4056,4065,4073,4080,4085,4089,4093,4094,4095,4094,4093,4089,4085,4080,4073,4065,4056,4045,4034,4021,4007,3992,3975,3958,3939,3919,3898,3876,3853,3829,3804,3777,3750,3722,3692,3662,3630,3598,3565,3531,3495,3459,3423,3385,3347,3307,3267,3227,3185,3143,3100,3057,3013,2968,2923,2878,2831,2785,2738,2690,2642,2594,2545,2497,2447,2398,2348,2299,2249,2199,2148,2098,2048,1998,1948,1897,1847,1797,1748,1698,1649,1599,1551,1502,1454,1406,1358,1311,1265,1218,1173,1128,1083,1039,996,953,911,869,829,789,749,711,673,637,601,565,531,498,466,434,404,374,346,319,292,267,243,220,198,177,157,138,121,104,89,75,62,51,40,31,23,16,11,7,3,2,1,2,3,7,11,16,23,31,40,51,62,75,89,104,121,138,157,177,198,220,243,267,292,319,346,374,404,434,466,498,531,565,601,637,673,711,749,789,829,869,911,953,996,1039,1083,1128,1173,1218,1265,1311,1358,1406,1454,1502,1551,1599,1649,1698,1748,1797,1847,1897,1948,1998};
const uint16_t TriangleWave[256]={2048,2080,2112,2144,2176,2208,2240,2272,2304,2336,2368,2400,2432,2464,2496,2528,2560,2592,2624,2656,2688,2720,2752,2784,2816,2848,2880,2912,2944,2976,3008,3040,3072,3104,3136,3168,3200,3232,3264,3296,3328,3360,3392,3424,3456,3488,3520,3552,3584,3616,3648,3680,3712,3744,3776,3808,3840,3872,3904,3936,3968,4000,4032,4064,4092,4060,4028,3996,3964,3932,3900,3868,3836,3804,3772,3740,3708,3676,3644,3612,3580,3548,3516,3484,3452,3420,3388,3356,3324,3292,3260,3228,3196,3164,3132,3100,3068,3036,3004,2972,2940,2908,2876,2844,2812,2780,2748,2716,2684,2652,2620,2588,2556,2524,2492,2460,2428,2396,2364,2332,2300,2268,2236,2204,2172,2140,2108,2076,2044,2012,1980,1948,1916,1884,1852,1820,1788,1756,1724,1692,1660,1628,1596,1564,1532,1500,1468,1436,1404,1372,1340,1308,1276,1244,1212,1180,1148,1116,1084,1052,1020,988,956,924,892,860,828,796,764,732,700,668,636,604,572,540,508,476,444,412,380,348,316,284,252,220,188,156,124,92,60,28,0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,480,512,544,576,608,640,672,704,736,768,800,832,864,896,928,960,992,1024,1056,1088,1120,1152,1184,1216,1248,1280,1312,1344,1376,1408,1440,1472,1504,1536,1568,1600,1632,1664,1696,1728,1760,1792,1824,1856,1888,1920,1952,1984,2016};
const uint16_t SquareWave[256]={4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,4095,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
const uint16_t SawtoothWave[256]={2048,2064,2080,2096,2112,2128,2144,2160,2176,2192,2208,2224,2240,2256,2272,2288,2304,2320,2336,2352,2368,2384,2400,2416,2432,2448,2464,2480,2496,2512,2528,2544,2560,2576,2592,2608,2624,2640,2656,2672,2688,2704,2720,2736,2752,2768,2784,2800,2816,2832,2848,2864,2880,2896,2912,2928,2944,2960,2976,2992,3008,3024,3040,3056,3072,3088,3104,3120,3136,3152,3168,3184,3200,3216,3232,3248,3264,3280,3296,3312,3328,3344,3360,3376,3392,3408,3424,3440,3456,3472,3488,3504,3520,3536,3552,3568,3584,3600,3616,3632,3648,3664,3680,3696,3712,3728,3744,3760,3776,3792,3808,3824,3840,3856,3872,3888,3904,3920,3936,3952,3968,3984,4000,4016,4032,4048,4064,4080,0,16,32,48,64,80,96,112,128,144,160,176,192,208,224,240,256,272,288,304,320,336,352,368,384,400,416,432,448,464,480,496,512,528,544,560,576,592,608,624,640,656,672,688,704,720,736,752,768,784,800,816,832,848,864,880,896,912,928,944,960,976,992,1008,1024,1040,1056,1072,1088,1104,1120,1136,1152,1168,1184,1200,1216,1232,1248,1264,1280,1296,1312,1328,1344,1360,1376,1392,1408,1424,1440,1456,1472,1488,1504,1520,1536,1552,1568,1584,1600,1616,1632,1648,1664,1680,1696,1712,1728,1744,1760,1776,1792,1808,1824,1840,1856,1872,1888,1904,1920,1936,1952,1968,1984,2000,2016,2032};
const uint16_t RevSawtoothWave[256]={2048,2032,2016,2000,1984,1968,1952,1936,1920,1904,1888,1872,1856,1840,1824,1808,1792,1776,1760,1744,1728,1712,1696,1680,1664,1648,1632,1616,1600,1584,1568,1552,1536,1520,1504,1488,1472,1456,1440,1424,1408,1392,1376,1360,1344,1328,1312,1296,1280,1264,1248,1232,1216,1200,1184,1168,1152,1136,1120,1104,1088,1072,1056,1040,1024,1008,992,976,960,944,928,912,896,880,864,848,832,816,800,784,768,752,736,720,704,688,672,656,640,624,608,592,576,560,544,528,512,496,480,464,448,432,416,400,384,368,352,336,320,304,288,272,256,240,224,208,192,176,160,144,128,112,96,80,64,48,32,16,0,4080,4064,4048,4032,4016,4000,3984,3968,3952,3936,3920,3904,3888,3872,3856,3840,3824,3808,3792,3776,3760,3744,3728,3712,3696,3680,3664,3648,3632,3616,3600,3584,3568,3552,3536,3520,3504,3488,3472,3456,3440,3424,3408,3392,3376,3360,3344,3328,3312,3296,3280,3264,3248,3232,3216,3200,3184,3168,3152,3136,3120,3104,3088,3072,3056,3040,3024,3008,2992,2976,2960,2944,2928,2912,2896,2880,2864,2848,2832,2816,2800,2784,2768,2752,2736,2720,2704,2688,2672,2656,2640,2624,2608,2592,2576,2560,2544,2528,2512,2496,2480,2464,2448,2432,2416,2400,2384,2368,2352,2336,2320,2304,2288,2272,2256,2240,2224,2208,2192,2176,2160,2144,2128,2112,2096,2080,2064};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void WaveFrequencyToClock()
{
  uint32_t clkdiv;
  uint32_t clk;

  clkdiv=1;
  while (1)
  {
    clk=(84000000*Wave.magnify)/256;
    clk /=clkdiv;
    clk /=Wave.frequency;
    if (clk<=65535)
    {
      break;
    }
    clkdiv++;
  }
  Wave.timer=clk-1;
  Wave.timerdiv=clkdiv-1;
}

void WaveClockToFrequency(void)
{
  uint32_t frq;

  frq=(84000000*Wave.magnify)/256;
  frq /=(Wave.timerdiv+1);
  frq /=(Wave.timer+1);
  Wave.frequency=frq;
}

void WaveSetStrings()
{
	static uint8_t ampdecstr[6],i;
	static uint8_t ofsdecstr[6];
	static uint8_t magdecstr[6];
	static uint8_t frqdecstr[11];

  i=BinDec16(Wave.amplitude,ampdecstr);
  SetCaption(GetControlHandle(Wave.hmain,12),&ampdecstr[i]);
  i=BinDec16(Wave.dcoffset,ofsdecstr);
  SetCaption(GetControlHandle(Wave.hmain,22),&ofsdecstr[i]);
  i=BinDec16(Wave.magnify,magdecstr);
  SetCaption(GetControlHandle(Wave.hmain,32),&magdecstr[i]);
  Wave.frequency=(((84000000/(Wave.timerdiv+1))/(Wave.timer+1))*Wave.magnify)/256;
  i=BinDec32(Wave.frequency,frqdecstr);
  SetCaption(GetControlHandle(Wave.hmain,3),&frqdecstr[i]);
}

void WaveMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  int32_t frq,f;

  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D)
      {
        switch (ID)
        {
          case 1:
            /* Frequency down */
            frq=Wave.frequency;
            Wave.frequency-=Wave.tmradd;
            if (Wave.frequency<1)
            {
              Wave.frequency=1;
            }
            f=Wave.frequency;
            while (1)
            {
              Wave.frequency=f;
              WaveFrequencyToClock();
              WaveClockToFrequency();
              if (frq!=Wave.frequency)
              {
                break;
              }
              f--;
            }
            WaveSetStrings();
            TIM6->PSC=Wave.timerdiv;
            TIM6->CNT=0;
            TIM6->ARR=Wave.timer;
            break;
          case 2:
            /* Frequency up */
            frq=Wave.frequency;
            Wave.frequency+=Wave.tmradd;
            if (Wave.frequency>WAVE_MAXFRQ)
            {
              Wave.frequency=WAVE_MAXFRQ;
            }
            f=Wave.frequency;
            while (1)
            {
              Wave.frequency=f;
              WaveFrequencyToClock();
              WaveClockToFrequency();
              if (frq!=Wave.frequency)
              {
                break;
              }
              f++;
            }
            WaveSetStrings();
            TIM6->PSC=Wave.timerdiv;
            TIM6->CNT=0;
            TIM6->ARR=Wave.timer;
            break;
          case 10:
            if (Wave.amplitude)
            {
              Wave.amplitude--;
              WaveGetData();
              WaveSetStrings();
            }
            break;
          case 11:
            if (Wave.amplitude<100)
            {
              Wave.amplitude++;
              WaveGetData();
              WaveSetStrings();
            }
            break;
          case 20:
            if (Wave.dcoffset)
            {
              Wave.dcoffset--;
              WaveGetData();
              WaveSetStrings();
            }
            break;
          case 21:
            if (Wave.dcoffset<100)
            {
              Wave.dcoffset++;
              WaveGetData();
              WaveSetStrings();
            }
            break;
          case 30:
            if (Wave.magnify>1)
            {
              Wave.magnify>>=1;
              WaveGetData();
              WaveSetStrings();
              if (Wave.enable)
              {
                WaveConfig();
              }
            }
            break;
          case 31:
            if (Wave.magnify<16)
            {
              Wave.magnify<<=1;
              WaveGetData();
              WaveSetStrings();
              if (Wave.enable)
              {
                WaveConfig();
              }
            }
            break;
          case 70:
            Wave.enable^=1;
            WaveConfig();
            break;
          case 80:
          case 81:
          case 82:
          case 83:
          case 84:
          case 85:
            CheckGroup(Wave.hmain,80,85,ID);
            Wave.waveform=ID-80;
            WaveGetData();
            break;
          case 99:
            /* Quit */
            Wave.Quit=1;
            break;
        }
      }
      break;
    case EVENT_LDOWN:
      if (ID>=1 && ID<=2)
      {
      if (ID>=1 && ID<=2)
      {
        Wave.tmrid=ID;
      }
      }
      break;
    case EVENT_LUP:
      Wave.tmrid=0;
      Wave.tmrmax=25;
      Wave.tmrcnt=0;
      Wave.tmrrep=0;
      Wave.tmradd=4;
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void WaveHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  uint16_t x;
  uint16_t* adc;

  switch (event)
  {
    case EVENT_PAINT:
      DefWindowHandler(hwin,event,param,ID);
      WaveDrawGrid();
      WaveDrawData();
      break;
    case EVENT_CHAR:
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void WaveDrawDotHLine(uint16_t x,uint16_t y,int16_t wdt)
{
  while (wdt>=0)
  {
    SetFBPixel(x,y);
    x+=4;
    wdt-=4;
  }
}

void WaveDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt)
{
  while (hgt>=0)
  {
    SetFBPixel(x,y);
    y+=4;
    hgt-=4;
  }
}

void WaveDrawGrid(void)
{
  int16_t y=WAVE_TOP+16;
  int16_t x=WAVE_LEFT+32;

  while (y<=WAVE_TOP+128)
  {
    WaveDrawDotHLine(WAVE_LEFT,y,WAVE_WIDTH);
    y+=16;
  }
  while (x<WAVE_WIDTH)
  {
    WaveDrawDotVLine(x,WAVE_TOP,8*16);
    x+=32;
  }
}

void WaveDrawData(void)
{
  uint16_t x1,x2,y1,y2;

  x1=0;
  x2=Wave.magnify;
  y1=Wave.wavebuff[x1];
  while (x2<256)
  {
    y2=Wave.wavebuff[x2/Wave.magnify];
    DrawWinLine(x1+WAVE_LEFT,y1+WAVE_TOP,x2+WAVE_LEFT,y2+WAVE_TOP);
    x1=x2;
    y1=y2;
    x2+=Wave.magnify;
  }
  y2=Wave.wavebuff[0];
  DrawWinLine(x1+WAVE_LEFT,y1+WAVE_TOP,x2+WAVE_LEFT,y2+WAVE_TOP);
}

void WaveGetData()
{
  uint16_t* ptr;
  int32_t w,wrnd;
  uint32_t x;

  switch (Wave.waveform)
  {
    case 0:
      ptr=(uint16_t*) SineWave;
      break;
    case 1:
      ptr=(uint16_t*) TriangleWave;
      break;
    case 2:
      ptr=(uint16_t*) SquareWave;
      break;
    case 3:
      ptr=(uint16_t*) SawtoothWave;
      break;
    case 4:
      ptr=(uint16_t*) RevSawtoothWave;
      break;
  }
  x=0;
  wrnd=2048+Random(256);
  while (x<256/Wave.magnify)
  {
    if (Wave.waveform==5)
    {
      w=Random(256);
      if (w>=128)
      {
        wrnd+=w;
        if (wrnd>4095)
        {
          wrnd=4095;
        }
      }
      else
      {
        wrnd-=w;
        if (wrnd<0)
        {
          wrnd=0;
        }
      }
      w=wrnd;
    }
    else
    {
      w=*ptr;
    }
    w=((w*Wave.amplitude)/100)+2048-((2048*Wave.amplitude)/100);
    if (w*Wave.amplitude>50)
    {
      w+=((8192*(Wave.dcoffset-50))/100);
    }
    else if (w*Wave.amplitude<50)
    {
      w-=((8192*(50-Wave.dcoffset))/100);
    }
    if (w>4095)
    {
      w=4095;
    }
    else if (w<0)
    {
      w=0;
    }
    Wave.wavebuff[x]=127-(w>>5);
    Wave.wave[x]=w;
    ptr+=Wave.magnify;
    x++;
  }
}

void WaveInit(void)
{
  Wave.amplitude=50;
  Wave.dcoffset=50;
  Wave.magnify=1;
  Wave.timer=0xFF;
  WaveGetData();
}

void WaveSetup(void)
{
  uint32_t i;
  WINDOW* hwin;
  uint8_t caps,num;
  uint32_t sec;

  Cls();
  ShowCursor(1);
  Wave.Quit=0;
  /* Create main scope window */
  Wave.hmain=CreateWindow(0,CLASS_WINDOW,0,WAVE_MAINLEFT,WAVE_MAINTOP,WAVE_MAINWIDTH,WAVE_MAINHEIGHT,"Wave Generator\0");
  SetHandler(Wave.hmain,&WaveMainHandler);
  /* Quit button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,99,WAVE_MAINRIGHT-75,WAVE_MAINBOTTOM-25,70,20,"Quit\0");
  /* Left button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,1,WAVE_LEFT,WAVE_BOTTOM,20,20,"<\0");
  /* Frequency static */
  CreateWindow(Wave.hmain,CLASS_STATIC,3,WAVE_LEFT+100,WAVE_BOTTOM,55,20,0);
  /* Right button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,2,WAVE_RIGHT-20,WAVE_BOTTOM,20,20,">\0");
  /* Enable checkbox */
  CreateWindow(Wave.hmain,CLASS_CHKBOX,70,WAVE_RIGHT+8,WAVE_TOP+15,90,10,"Enable\0");
  if (Wave.enable)
  {
    SetState(GetControlHandle(Wave.hmain,70),STATE_VISIBLE | STATE_CHECKED);
  }
  /* Sinwave checkbox */
  CreateWindow(Wave.hmain,CLASS_CHKBOX,80,WAVE_RIGHT+16,WAVE_TOP+45,45,10,"Sine\0");
  /* Trianglewave checkbox */
  CreateWindow(Wave.hmain,CLASS_CHKBOX,81,WAVE_RIGHT+16,WAVE_TOP+60,45,10,"Triangle\0");
  /* Squarewave checkbox */
  CreateWindow(Wave.hmain,CLASS_CHKBOX,82,WAVE_RIGHT+16,WAVE_TOP+75,45,10,"Square\0");
  /* Sawtoothwave checkbox */
  CreateWindow(Wave.hmain,CLASS_CHKBOX,83,WAVE_RIGHT+16,WAVE_TOP+90,45,10,"Sawtooth\0");
  /* Rev Sawtoothwave checkbox */
  CreateWindow(Wave.hmain,CLASS_CHKBOX,84,WAVE_RIGHT+16,WAVE_TOP+105,45,10,"Rev Sawt\0");
  /* Noise checkbox */
  CreateWindow(Wave.hmain,CLASS_CHKBOX,85,WAVE_RIGHT+16,WAVE_TOP+120,45,10,"Noise\0");
  SetState(GetControlHandle(Wave.hmain,80+Wave.waveform),STATE_VISIBLE | STATE_CHECKED);
  /* Wave Groupbox */
  CreateWindow(Wave.hmain,CLASS_GROUPBOX,86,WAVE_RIGHT+8,WAVE_TOP+30,90,110,"Wave\0");

  /* Create wave window */
  Wave.hwave=CreateWindow(Wave.hmain,CLASS_STATIC,1,WAVE_LEFT,WAVE_TOP,WAVE_WIDTH,WAVE_HEIGHT,0);
  SetStyle(Wave.hwave,STYLE_BLACK);
  SetHandler(Wave.hwave,&WaveHandler);

  CreateWindow(Wave.hmain,CLASS_STATIC,90,WAVE_MAINRIGHT-100,WAVE_TOP,95,10,"Amplitude\0");
  /* Amplitude left button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,10,WAVE_MAINRIGHT-100,WAVE_TOP+10,20,20,"<\0");
  /* Amplitude right button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,11,WAVE_MAINRIGHT-25,WAVE_TOP+10,20,20,">\0");
  CreateWindow(Wave.hmain,CLASS_STATIC,12,WAVE_MAINRIGHT-80,WAVE_TOP+10,55,20,0);

  CreateWindow(Wave.hmain,CLASS_STATIC,91,WAVE_MAINRIGHT-100,WAVE_TOP+40,95,10,"DC Offset\0");
  /* DC Offset left button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,20,WAVE_MAINRIGHT-100,WAVE_TOP+50,20,20,"<\0");
  /* DC Offset right button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,21,WAVE_MAINRIGHT-25,WAVE_TOP+50,20,20,">\0");
  CreateWindow(Wave.hmain,CLASS_STATIC,22,WAVE_MAINRIGHT-80,WAVE_TOP+50,55,20,0);

  CreateWindow(Wave.hmain,CLASS_STATIC,92,WAVE_MAINRIGHT-100,WAVE_TOP+80,95,10,"Multiply\0");
  /* Multiply left button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,30,WAVE_MAINRIGHT-100,WAVE_TOP+90,20,20,"<\0");
  /* Multiply right button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,31,WAVE_MAINRIGHT-25,WAVE_TOP+90,20,20,">\0");
  CreateWindow(Wave.hmain,CLASS_STATIC,32,WAVE_MAINRIGHT-80,WAVE_TOP+90,55,20,0);

  WaveSetStrings();
  SendEvent(Wave.hmain,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);
  CreateTimer(WaveTimer);

  while (!Wave.Quit)
  {
    if ((GetKeyState(SC_ESC) && (GetKeyState(SC_L_CTRL) | GetKeyState(SC_R_CTRL))))
    {
      Wave.Quit=1;
    }
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus(0,caps,num);
    }
  }
  KillTimer();
  DestroyWindow(Wave.hmain);
}

void WaveTimer(void)
{
  if (Wave.tmrid)
  {
    Wave.tmrcnt++;
    if (Wave.tmrcnt>=Wave.tmrmax)
    {
      Wave.tmrmax=1;
      Wave.tmrcnt=0;
      SendEvent(Wave.hmain,EVENT_CHAR,0x0D,Wave.tmrid);
      Wave.tmrrep++;
      if (Wave.tmrrep>=25)
      {
        Wave.tmrrep=0;
        if (Wave.tmradd<1000)
        {
          Wave.tmradd*=10;
        }
      }
    }
  }
}

/**
  * @brief  DAC Channel1 Wave Configuration
  * @param  None
  * @retval None
  */
void WaveConfig()
{
  DAC_DeInit();
  DMA_DeInit(DMA1_Stream5);
  if (Wave.enable)
  {
    /* DAC channel1 Configuration */
    DAC_InitStructure.DAC_Trigger = DAC_Trigger_T6_TRGO;
    DAC_InitStructure.DAC_WaveGeneration = DAC_WaveGeneration_None;
    DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Enable;
    DAC_Init(DAC_Channel_1, &DAC_InitStructure);
    /* DAC channel2 Configuration */
    DAC_InitStructure.DAC_Trigger = DAC_Trigger_None;
    DAC_InitStructure.DAC_WaveGeneration = DAC_WaveGeneration_None;
    DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Enable;
    DAC_Init(DAC_Channel_2, &DAC_InitStructure);
    /* DMA1_Stream5 channel7 configuration **************************************/  
    DMA_InitStructure.DMA_Channel = DMA_Channel_7;  
    DMA_InitStructure.DMA_PeripheralBaseAddr = DAC_DHR12R1_ADDRESS;
    DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&Wave.wave;
    DMA_InitStructure.DMA_BufferSize = 256/Wave.magnify;
    DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
    DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
    DMA_InitStructure.DMA_DIR = DMA_DIR_MemoryToPeripheral;
    DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
    DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
    DMA_InitStructure.DMA_Mode = DMA_Mode_Circular;
    DMA_InitStructure.DMA_Priority = DMA_Priority_High;
    DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
    DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
    DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
    DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
    DMA_Init(DMA1_Stream5, &DMA_InitStructure);    
    /* Enable DMA1_Stream5 */
    DMA_Cmd(DMA1_Stream5, ENABLE);
    /* Enable DAC Channel1 */
    DAC_Cmd(DAC_Channel_1, ENABLE);
    /* Enable DMA for DAC Channel1 */
    DAC_DMACmd(DAC_Channel_1, ENABLE);
  }
}
