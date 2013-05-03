
/* Includes ------------------------------------------------------------------*/
#include "HSClock.h"
#include "keycodes.h"

/* External variables --------------------------------------------------------*/
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;
extern uint32_t frequency;

/* Private variables ---------------------------------------------------------*/
HSCLK HSClk;
uint8_t hsclkstr[2][10]={{"Frequency:"},{"Dutycycle:"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void HSClkFrequencyToClock(void)
{
  uint32_t clkdiv;
  uint32_t clk;

  clkdiv=1;
  while (1)
  {
    clk=168000000;
    clk /=clkdiv;
    clk /=HSClk.frq;
    if (clk<=65535)
    {
      break;
    }
    clkdiv++;
  }
  HSClk.clk=clk;
  HSClk.clkdiv=clkdiv;
}

void HSClkClockToFrequency(void)
{
  uint32_t frq;

  frq=168000000;
  frq /=HSClk.clkdiv;
  frq /=HSClk.clk;
  HSClk.frq=frq;
}

void HSClkSetTimer(void)
{
  int32_t duty;

  TIM10->CR1&=~TIM_CR1_CEN;
  TIM10->PSC=HSClk.clkdiv-1;
  TIM10->ARR=HSClk.clk-1;
  /* Set the Capture Compare Register value */
  duty=((HSClk.clk*HSClk.duty)/100)+1;
  TIM10->CCR1=duty-1;
  TIM10->CNT=0;
  TIM10->CR1|=TIM_CR1_CEN;
}

void HSClkMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
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
            /* Frequency left */
            frq=HSClk.frq;
            HSClk.frq-=HSClk.tmradd;
            if (HSClk.frq<1)
            {
              HSClk.frq=1;
            }
            f=HSClk.frq;
            while (1)
            {
              HSClk.frq=f;
              HSClkFrequencyToClock();
              HSClkClockToFrequency();
              if (frq!=HSClk.frq)
              {
                break;
              }
              f--;
            }
            HSClkSetTimer();
            break;
          case 2:
            /* Frequency right */
            frq=HSClk.frq;
            HSClk.frq+=HSClk.tmradd;
            if (HSClk.frq>HSCLK_MAXFRQ)
            {
              HSClk.frq=HSCLK_MAXFRQ;
              HSClkFrequencyToClock();
            }
            else
            {
              f=HSClk.frq;
              while (1)
              {
                HSClk.frq=f;
                HSClkFrequencyToClock();
                HSClkClockToFrequency();
                if (frq!=HSClk.frq)
                {
                  break;
                }
                f++;
              }
            }
            HSClkSetTimer();
            break;
          case 3:
            /* Duty left */
            if (HSClk.duty)
            {
              HSClk.duty--;
              HSClkSetTimer();
            }
            break;
          case 4:
            /* Duty right */
            if (HSClk.duty<100)
            {
              HSClk.duty++;
              HSClkSetTimer();
            }
            break;
          case 99:
            /* Quit */
            HSClk.Quit=1;
            break;
        }
      }
      break;
    case EVENT_LDOWN:
      if (ID>=1 && ID<=4)
      {
        HSClk.tmrid=ID;
      }
      break;
    case EVENT_LUP:
      HSClk.tmrid=0;
      HSClk.tmrmax=25;
      HSClk.tmrcnt=0;
      HSClk.tmrrep=0;
      HSClk.tmradd=1;
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
      HSClkDrawGrid();
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
    x+=4;
    wdt-=4;
  }
}

void HSClkDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt)
{
  while (hgt>=0)
  {
    SetFBPixel(x,y);
    y+=4;
    hgt-=4;
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
  wdt=(HSCLK_WIDTH-8)-wdt;
  HSClkDrawHLine(x,HSCLK_BOTTOM-38-4,wdt);
  x+=wdt;
  HSClkDrawVLine(x,HSCLK_TOP+4,HSCLK_HEIGHT-38-8);
}

void HSClkDrawInfo(void)
{
  /* Frequency */
  DrawWinString(HSCLK_LEFT+4,HSCLK_BOTTOM-15,10,hsclkstr[0],1);
  DrawWinDec32(HSCLK_LEFT+4+10*8,HSCLK_BOTTOM-15,HSClk.frq,1);
  /* Dutycycle */
  DrawWinString(HSCLK_LEFT+4+150,HSCLK_BOTTOM-15,10,hsclkstr[1],1);
  DrawWinDec16(HSCLK_LEFT+4+150+10*8,HSCLK_BOTTOM-15,HSClk.duty,1);
}

void HSClkInit(void)
{
  HSClk.tmrid=0;
  HSClk.tmrmax=25;
  HSClk.tmrcnt=0;
  HSClk.tmrrep=0;
  HSClk.tmradd=1;
  HSClk.duty=50;
  HSClk.frq=1000000;
  HSClkFrequencyToClock();
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
  /* Frequency left button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,1,HSCLK_LEFT,HSCLK_BOTTOM,20,20,"<\0");
  /* Frequency right button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,2,HSCLK_LEFT+80,HSCLK_BOTTOM,20,20,">\0");
  /* Duty left button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,3,HSCLK_RIGHT-80,HSCLK_BOTTOM,20,20,"<\0");
  /* Duty right button */
  CreateWindow(HSClk.hmain,CLASS_BUTTON,4,HSCLK_RIGHT-20,HSCLK_BOTTOM,20,20,">\0");

  /* Create HSClk window */
  HSClk.hhsclk=CreateWindow(HSClk.hmain,CLASS_STATIC,1,HSCLK_LEFT,HSCLK_TOP,HSCLK_WIDTH,HSCLK_HEIGHT,0);
  SetStyle(HSClk.hhsclk,STYLE_BLACK);
  SetHandler(HSClk.hhsclk,&HSClkHandler);

  SendEvent(HSClk.hmain,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);
  CreateTimer(HSClkTimer);

  while (!HSClk.Quit)
  {
    if ((GetKeyState(SC_ESC) && (GetKeyState(SC_L_CTRL) | GetKeyState(SC_R_CTRL))))
    {
      HSClk.Quit=1;
    }
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
      HSClk.tmrrep++;
      if (HSClk.tmrrep>=25)
      {
        HSClk.tmrrep=0;
        if (HSClk.tmradd<1000000)
        {
          HSClk.tmradd*=10;
        }
      }
    }
  }
}
