
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
      if (param==0x0D)
      {
        switch (ID)
        {
          case 1:
            /* Fast left */
            Lga.dataofs-=64;
            if (Lga.dataofs<0)
            {
              Lga.dataofs=0;
            }
            break;
          case 2:
            /* Fast right */
            Lga.dataofs+=64;
            if (Lga.dataofs<LGA_DATASIZE-64)
            {
              Lga.dataofs=LGA_DATASIZE-64;
            }
            break;
          case 3:
            /* Left */
            Lga.dataofs--;
            if (Lga.dataofs<0)
            {
              Lga.dataofs=0;
            }
            break;
          case 4:
            /* Right */
            Lga.dataofs++;
            if (Lga.dataofs<LGA_DATASIZE-64)
            {
              Lga.dataofs=LGA_DATASIZE-64;
            }
            break;
          case 98:
            /* Sample */
            Lga.Sample=1;
            break;
          case 99:
            /* Quit */
            Lga.Quit=1;
            break;
        }
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
        LgaDrawGrid();
      }
      LgaDrawData();
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void LgaDrawHLine(uint16_t x,uint16_t y,uint16_t wdt)
{
  while (wdt)
  {
    SetFBPixel(x,y);
    x++;
    wdt--;
  }
}

void LgaDrawVLine(uint16_t x,uint16_t y,uint16_t hgt)
{
  while (hgt)
  {
    SetFBPixel(x,y);
    y++;
    hgt--;
  }
}

void LgaDrawGrid(void)
{
  int16_t y=LGA_TOP+16;
  int16_t x=LGA_LEFT+30;
  int16_t i=0;

  while (y<=LGA_TOP+LGA_HEIGHT-30)
  {
    LgaDrawHLine(LGA_LEFT,y,LGA_WIDTH);
    DrawWinString(LGA_LEFT+5,y-12,2,lgacap[i],2);
    y+=16;
    i++;
  }
  while (x<LGA_LEFT+30+8*32)
  {
    LgaDrawVLine(x,LGA_TOP,LGA_HEIGHT-30);
    x+=32;
  }
}

void LgaDrawByte(uint32_t x,uint8_t byte,uint8_t pbyte)
{
  uint8_t bit=1;
  uint32_t y=LGA_TOP+16;

  while (bit)
  {
    if ((byte & bit) != (pbyte & bit))
    {
      /* Transition */
      LgaDrawVLine(x,y-13,10);
    }
    if (byte & bit)
    {
      /* High */
      LgaDrawHLine(x,y-13,4);
    }
    else
    {
      /* Low */
      LgaDrawHLine(x,y-3,4);
    }
    bit <<=1;
    y+=16;
  }
}

void LgaDrawData(void)
{
  uint32_t x=LGA_LEFT+30;
  uint32_t i=0;
  uint8_t byte;
  uint8_t pbyte;
  uint8_t* ptr;

  ptr=(uint8_t*)(LGA_DATAPTR+Lga.dataofs);
  byte=*ptr;
  pbyte=byte;
  while (i<LGA_BYTES)
  {
    LgaDrawByte(x,byte,pbyte);
    pbyte=byte;
    ptr++;
    byte=*ptr;
    x+=4;
    i++;
  }
}

void LgaSample(void)
{
  uint32_t i=0;
  uint8_t byte;
  uint8_t* ptr;
  ptr=(uint8_t*)LGA_DATAPTR;
  while (i<0x8000)
  {
    byte=Random(255);
    *ptr=byte;
    ptr++;
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
  /* Create main logic analyser window */
  Lga.hmain=CreateWindow(0,CLASS_WINDOW,0,LGA_MAINLEFT,LGA_MAINTOP,LGA_MAINWIDTH,LGA_MAINHEIGHT,"Logic Analyser\0");
  SetHandler(Lga.hmain,&LgaMainHandler);
  /* Fast left button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,1,LGA_LEFT,LGA_BOTTOM,20,20,"<<\0");
  /* Fast right button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,2,LGA_RIGHT-20,LGA_BOTTOM,20,20,"<<\0");
  /* Left button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,3,LGA_LEFT+20,LGA_BOTTOM,20,20,"<\0");
  /* Right button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,4,LGA_RIGHT-20-20,LGA_BOTTOM,20,20,"<\0");
  /* Sample button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,98,480-75,238-50,70,20,"Sample\0");
  /* Quit button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,99,480-75,238-25,70,20,"Quit\0");

  Lga.hlga=CreateWindow(Lga.hmain,CLASS_STATIC,1,LGA_LEFT,LGA_TOP,LGA_WIDTH,LGA_HEIGHT,0);
  SetStyle(Lga.hlga,STYLE_BLACK);
  SetHandler(Lga.hlga,&LgaHandler);

  SendEvent(Lga.hmain,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);
  Lga.dataofs=0;

  while (!Lga.Quit)
  {
    if (Lga.Sample)
    {
      Lga.Sample=0;
      LgaSample();
      Lga.dataofs=0;
    }
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus(0,caps,num);
    }
  }
  DestroyWindow(Lga.hmain);
}
