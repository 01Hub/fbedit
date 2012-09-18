
/* Includes ------------------------------------------------------------------*/
#include "logicanalyser.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;
extern uint8_t FrameBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];

/* Private variables ---------------------------------------------------------*/
LGA Lga;
uint8_t lgacap[8][2]={{"D0"},{"D1"},{"D2"},{"D3"},{"D4"},{"D5"},{"D6"},{"D7"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void LgaMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D && ID==99)
      {
        /* Quit */
        Lga.Quit=1;
        break;
      }
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void LgaHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_PAINT:
      DefWindowHandler(hwin,event,param,ID);
      if (FrameCount & 1)
      {
        DrawLgaGrid();
      }
      DrawLgaData();
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void DrawLgaLine(uint16_t X1,uint16_t Y1,uint16_t X2,uint16_t Y2)
{
  uint16_t CurrentX, CurrentY, Xinc, Yinc, 
           Dx, Dy, TwoDx, TwoDy, 
           TwoDxAccumulatedError, TwoDyAccumulatedError;

  Dx = (X2-X1);
  Dy = (Y2-Y1);

  TwoDx = Dx + Dx;
  TwoDy = Dy + Dy;

  CurrentX = X1;
  CurrentY = Y1;

  Xinc = 1;
  Yinc = 1;

  if(Dx < 0)
  {
    Xinc = -1;
    Dx = -Dx;
    TwoDx = -TwoDx;
  }

  if (Dy < 0)
  {
    Yinc = -1;
    Dy = -Dy;
    TwoDy = -TwoDy;
  }
  SetFBPixel(X1,Y1);

  if ((Dx != 0) || (Dy != 0))
  {
    if (Dy <= Dx)
    { 
      TwoDxAccumulatedError = 0;
      do
      {
        CurrentX += Xinc;
        TwoDxAccumulatedError += TwoDy;
        if(TwoDxAccumulatedError > Dx)
        {
          CurrentY += Yinc;
          TwoDxAccumulatedError -= TwoDx;
        }
        SetFBPixel(CurrentX,CurrentY);
      }while (CurrentX != X2);
    }
    else
    {
      TwoDyAccumulatedError = 0; 
      do 
      {
        CurrentY += Yinc; 
        TwoDyAccumulatedError += TwoDx;
        if(TwoDyAccumulatedError>Dy) 
        {
          CurrentX += Xinc;
          TwoDyAccumulatedError -= TwoDy;
        }
        SetFBPixel(CurrentX,CurrentY);
      }while (CurrentY != Y2);
    }
  }
}

void DrawLgaGrid(void)
{
  int16_t y=LGA_TOP+16;
  int16_t x=LGA_LEFT+30;
  int16_t i=0;

  while (y<=LGA_TOP+LGA_HEIGHT-30)
  {
    DrawLgaLine(LGA_LEFT,y,LGA_LEFT+LGA_WIDTH,y);
    DrawInvWinString(LGA_LEFT+5,y-12,2,lgacap[i]);
    y+=16;
    i++;
  }
  while (x<LGA_LEFT+30+8*32)
  {
    DrawLgaLine(x,LGA_TOP,x,LGA_TOP+LGA_HEIGHT-30);
    x+=32;
  }
}

void DrawLgaByte(uint16_t x,uint8_t byte,uint8_t pbyte)
{
  uint8_t bit=1;
  uint16_t y=LGA_TOP+16;

  while (bit)
  {
    if ((byte & bit) != (pbyte & bit))
    {
      /* Transition */
      DrawLgaLine(x,y-13,x,y-3);
    }
    if (byte & bit)
    {
      /* High */
      DrawLgaLine(x,y-13,x+4,y-13);
    }
    else
    {
      /* Low */
      DrawLgaLine(x,y-3,x+4,y-3);
    }
    bit <<=1;
    y+=16;
  }
}

void DrawLgaData(void)
{
  uint16_t x=LGA_LEFT+30;
  uint8_t b=0;
  uint8_t pb=0;
  uint16_t i;
  while (i<64)
  {
    DrawLgaByte(x,b,pb);
    pb=b;
    b++;
    x+=4;
    i++;
  }
}

void LogicAnalyserSetup(void)
{
  uint32_t i;
  WINDOW* hwin;
  uint8_t caps,num;

  Cls();
  ShowCursor(1);
  Lga.Quit=0;
  /* Create logic analyser window */
  Lga.hmain=CreateWindow(0,CLASS_WINDOW,0,0,0,480,238,"Logic Analyser\0");
  SetHandler(Lga.hmain,&LgaMainHandler);
  CreateWindow(Lga.hmain,CLASS_BUTTON,99,480-75,238-25,70,20,"Quit\0");
  Lga.hlga=CreateWindow(Lga.hmain,CLASS_STATIC,1,LGA_LEFT,LGA_TOP,LGA_WIDTH,LGA_HEIGHT,0);
  SetStyle(Lga.hlga,STYLE_BLACK);
  SetHandler(Lga.hlga,&LgaHandler);

  SendEvent(Lga.hmain,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);

  while (!Lga.Quit)
  {
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus(0,caps,num);
    }
  }
  DestroyWindow(Lga.hmain);
}
