
/* Includes ------------------------------------------------------------------*/
#include "HSClock.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;
extern uint8_t FrameBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];
extern uint32_t frequency;

/* Private variables ---------------------------------------------------------*/
HSCLK HSClk;
uint8_t hsclkstr[2][10]={{"Frequency:"},{"Dutycycle:"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void FrequencyToClock(void)
{
  uint32_t clkdiv;
  uint32_t clk;

  clkdiv=1;
  while (1)
  {
    clk==84000000;
    clk /=clkdiv;
    clk /=HSClk.frq;
    if (clk<=65535)
    {
      break;
    }
  }
  HSClk.clk=clk;
  HSClk.clkdiv=clkdiv;
}

void ClockToFrequency(void)
{
  uint32_t frq;

  frq=84000000;
  frq /=HSClk.clkdiv;
  frq /=HSClk.clk;
  HSClk.frq=frq;
}

void HSClkSetTimer(void)
{
  int32_t duty;
  TIM1->PSC=HSClk.clkdiv-1;
  TIM1->ARR=HSClk.clk-1;
  /* Set the Capture Compare Register value */
  duty=((HSClk.clk*HSClk.duty)/100)+1;
  TIM1->CCR1=duty-1;
  TIM1->CNT=0;
}

void HSClkMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  int32_t frq;

  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D)
      {
        switch (ID)
        {
          case 1:
            /* Fast left */
            frq=HSClk.frq;
            HSClk.frq-=100;
            if (HSClk.frq<1)
            {
              HSClk.frq=1;
            }
            while (1)
            {
              FrequencyToClock();
              ClockToFrequency();
              if (frq!=HSClk.frq)
              {
                break;
              }
              HSClk.frq--;
            }
            HSClkSetTimer();
            break;
          case 2:
            /* Fast right */
            frq=HSClk.frq;
            HSClk.frq+=100;
            if (HSClk.frq>21000000)
            {
              HSClk.frq=21000000;
            }
            while (1)
            {
              FrequencyToClock();
              ClockToFrequency();
              if (frq!=HSClk.frq)
              {
                break;
              }
              HSClk.frq++;
            }
            HSClkSetTimer();
            break;
          case 3:
            /* Left */
            frq=HSClk.frq;
            HSClk.frq-=1;
            if (HSClk.frq<1)
            {
              HSClk.frq=1;
            }
            while (1)
            {
              FrequencyToClock();
              ClockToFrequency();
              if (frq!=HSClk.frq)
              {
                break;
              }
              HSClk.frq--;
            }
            HSClkSetTimer();
            break;
          case 4:
            /* Right */
            frq=HSClk.frq;
            HSClk.frq+=1;
            if (HSClk.frq>21000000)
            {
              HSClk.frq=21000000;
            }
            while (1)
            {
              FrequencyToClock();
              ClockToFrequency();
              if (frq!=HSClk.frq)
              {
                break;
              }
              HSClk.frq++;
            }
            HSClkSetTimer();
            break;
          case 99:
            /* Quit */
            HSClk.Quit=1;
            break;
        }
      }
    case EVENT_LUP:
      HSClk.tmrid=0;
      HSClk.tmrmax=32;
      HSClk.tmrcnt=0;
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void HSClkHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  uint16_t x;

  switch (event)
  {
    case EVENT_PAINT:
      DefWindowHandler(hwin,event,param,ID);
      if (FrameCount & 1)
      {
        HSClkDrawGrid();
      }
      HSClkDrawData();
      HSClkDrawInfo();
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void HSClkDrawDotHLine(uint16_t x,uint16_t y,int16_t wdt)
{
  while (wdt>=0)
  {
    SetFBPixel(x,y);
    x+=2;
    wdt-=2;
  }
}

void HSClkDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt)
{
  while (hgt>=0)
  {
    SetFBPixel(x,y);
    y+=2;
    hgt-=2;
  }
}

void HSClkDrawHLine(uint16_t x,uint16_t y,int16_t wdt)
{
  while (wdt)
  {
    SetFBPixel(x,y);
    x++;
    wdt--;
  }
}

void HSClkDrawVLine(uint16_t x,uint16_t y,int16_t hgt)
{
  while (hgt)
  {
    SetFBPixel(x,y);
    y++;
    hgt--;
  }
}

void HSClkDrawGrid(void)
{
  int16_t y=HSCLK_TOP+16;
  int16_t x=HSCLK_LEFT+32;

  while (y<=HSCLK_BOTTOM-30)
  {
    HSClkDrawDotHLine(HSCLK_LEFT,y,HSCLK_WIDTH);
    y+=16;
  }
  while (x<HSCLK_WIDTH)
  {
    HSClkDrawDotVLine(x,HSCLK_TOP,8*16);
    x+=32;
  }
}

void HSClkDrawData(void)
{
  uint16_t wdt,x;
  HSClkDrawVLine(HSCLK_LEFT+4,HSCLK_TOP+4,HSCLK_HEIGHT-38-8);
  wdt=((HSCLK_WIDTH-8)*HSClk.duty)/100;
  HSClkDrawHLine(HSCLK_LEFT+4,HSCLK_TOP+4,wdt);
  x=wdt+HSCLK_LEFT+4;
  HSClkDrawVLine(x,HSCLK_TOP+4,HSCLK_HEIGHT-38-8);
  wdt=(HSCLK_WIDTH-8)-8;
  HSClkDrawHLine(x,HSCLK_TOP+4,wdt);
  x+=wdt;
  HSClkDrawVLine(x,HSCLK_TOP+4,HSCLK_HEIGHT-38-8);
}

void HSClkDrawInfo(void)
{
  /* Frequency */
  DrawWinString(HSCLK_LEFT+4,HSCLK_BOTTOM-15,10,hsclkstr[0],1);
  DrawWinDec32(HSCLK_LEFT+4+11*8,HSCLK_BOTTOM-15,HSClk.frq,5);
  /* Dutycycle */
  DrawWinString(HSCLK_LEFT+4+128,HSCLK_BOTTOM-15,10,hsclkstr[1],1);
  DrawWinDec16(HSCLK_LEFT+4+128+11*8,HSCLK_BOTTOM-15,HSClk.duty,5);
}

void HSClkSetup(void)
{
  uint32_t i;
  WINDOW* hwin;
  uint8_t caps,num;

  Cls();
  ShowCursor(1);
  HSClk.Quit=0;
  /* Create main HSClk window */
  HSClk.hmain=CreateWindow(0,CLASS_WINDOW,0,HSCLK_MAINLEFT,HSCLK_MAINTOP,HSCLK_MAINWIDTH,HSCLK_MAINHEIGHT,"High Speed Clock\0");
  SetHandler(HSClk.hmain,&HSClkMainHandler);
  /* Quit button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,99,HSCLK_MAINRIGHT-75,HSCLK_MAINBOTTOM-25,70,20,"Quit\0");
  /* Fast left button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,1,HSCLK_LEFT,HSCLK_BOTTOM,20,20,"<<\0");
  /* Left button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,3,HSCLK_LEFT+20,HSCLK_BOTTOM,20,20,"<\0");
  /* Right button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,4,HSCLK_RIGHT-20-20,HSCLK_BOTTOM,20,20,">\0");
  /* Fast right button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,2,HSCLK_RIGHT-20,HSCLK_BOTTOM,20,20,">>\0");

  /* Create HSClk window */
  HSClk.hhsclk=CreateWindow(HSClk.hmain,CLASS_STATIC,1,HSCLK_LEFT,HSCLK_TOP,HSCLK_WIDTH,HSCLK_HEIGHT,0);
  SetStyle(HSClk.hhsclk,STYLE_BLACK);
  SetHandler(HSClk.hhsclk,&HSClkHandler);

  SendEvent(HSClk.hmain,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);
  HSClk.tmrid=0;
  HSClk.tmrmax=32;
  HSClk.tmrcnt=0;
  HSClk.frq=1000000;
  FrequencyToClock();
  HSClk.duty=50;
  CreateTimer(HSClkTimer);

  while (!HSClk.Quit)
  {
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus(0,caps,num);
    }
  }
  KillTimer();
  DestroyWindow(HSClk.hmain);
}

void HSClkTimer(void)
{
  if (HSClk.tmrid)
  {
    HSClk.tmrcnt++;
    if (HSClk.tmrcnt>=HSClk.tmrmax)
    {
      HSClk.tmrmax=1;
      HSClk.tmrcnt=0;
      SendEvent(HSClk.hmain,EVENT_CHAR,0x0D,HSClk.tmrid);
    }
  }
}
