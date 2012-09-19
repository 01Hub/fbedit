
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
//SAMPLE rate[10]={{4,"33.6MHz\0"},{7,"21.0MHz\0"},{15,"10.5MHz\0"},{32,"5.1MHz\0"},{83,"2.0MHz\0"},{167,"1.0MHz\0"},{335,"500KHz\0"},{839,"200KHz\0"},{1679,"100KHz\0"}};
  SAMPLE rate[10]={{4,"33.6MHz\0"},{7,"21.0MHz\0"},{15,"10.5MHz\0"},{32,"5.1MHz\0"},{83,"2.0MHz\0"},{167,"1.0MHz\0"},{335,"500KHz\0"},{839,"200KHz\0"},{1679,"100KHz\0"}};

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
            if (Lga.dataofs>LGA_DATASIZE-64)
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
            if (Lga.dataofs>LGA_DATASIZE-64)
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
  int16_t y=LGA_TOP+LGA_BITHEIGHT;
  int16_t x=LGA_LEFT+30;
  int16_t i=0;

  while (y<=LGA_TOP+LGA_HEIGHT-30)
  {
    LgaDrawHLine(LGA_LEFT,y,LGA_WIDTH);
    DrawWinString(LGA_LEFT+5,y-12,2,lgacap[i],2);
    y+=LGA_BITHEIGHT;
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
  uint32_t y=LGA_TOP+LGA_BITHEIGHT;

  while (bit)
  {
    if ((byte & bit) != (pbyte & bit))
    {
      /* Transition */
      LgaDrawVLine(x,y-16,12);
    }
    if (byte & bit)
    {
      /* High */
      LgaDrawHLine(x,y-16,LGA_BITWIDTH);
    }
    else
    {
      /* Low */
      LgaDrawHLine(x,y-4,LGA_BITWIDTH);
    }
    bit <<=1;
    y+=LGA_BITHEIGHT;
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
    x+=LGA_BITWIDTH;
    i++;
  }
}

void LgaSample(void)
{
  uint8_t trg=0;
  uint8_t trgignore=0;
  uint8_t bit=1;
  uint32_t i;
  uint8_t byte;
  uint8_t* ptr;
  WINDOW* hwin;
  ptr=(uint8_t*)LGA_DATAPTR;
  /* Get trigger and mask */
  i=0;
  while (i<8)
  {
    hwin=GetControlHandle(Lga.hmain,i+20);
    if (hwin->state & STATE_CHECKED)
    {
      trg|=bit;
    }
    hwin=GetControlHandle(Lga.hmain,i+30);
    if (hwin->state & STATE_CHECKED)
    {
      trgignore|=bit;
    }
    bit<<=1;
    i++;
  }
  i=0;
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
  /* Sample button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,98,LGA_MAINRIGHT-75,LGA_MAINBOTTOM-50,70,20,"Sample\0");
  /* Quit button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,99,LGA_MAINRIGHT-75,LGA_MAINBOTTOM-25,70,20,"Quit\0");
  /* Fast left button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,1,LGA_LEFT,LGA_BOTTOM,20,20,"<<\0");
  /* Left button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,3,LGA_LEFT+20,LGA_BOTTOM,20,20,"<\0");
  /* Right button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,4,LGA_RIGHT-20-20,LGA_BOTTOM,20,20,">\0");
  /* Fast right button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,2,LGA_RIGHT-20,LGA_BOTTOM,20,20,">>\0");

  CreateWindow(Lga.hmain,CLASS_GROUPBOX,97,LGA_MAINRIGHT-75,LGA_TOP,70,145,"Trigger\0");

  CreateWindow(Lga.hmain,CLASS_CHKBOX,20,LGA_MAINRIGHT-70,LGA_TOP+30,30,10,"D0\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,21,LGA_MAINRIGHT-70,LGA_TOP+30+15,30,10,"D1\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,22,LGA_MAINRIGHT-70,LGA_TOP+30+30,30,10,"D2\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,23,LGA_MAINRIGHT-70,LGA_TOP+30+45,30,10,"D3\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,24,LGA_MAINRIGHT-70,LGA_TOP+30+60,30,10,"D4\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,25,LGA_MAINRIGHT-70,LGA_TOP+30+75,30,10,"D5\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,26,LGA_MAINRIGHT-70,LGA_TOP+30+90,30,10,"D6\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,27,LGA_MAINRIGHT-70,LGA_TOP+30+105,30,10,"D7\0");

  CreateWindow(Lga.hmain,CLASS_CHKBOX,30,LGA_MAINRIGHT-40,LGA_TOP+30,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,31,LGA_MAINRIGHT-40,LGA_TOP+30+15,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,32,LGA_MAINRIGHT-40,LGA_TOP+30+30,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,33,LGA_MAINRIGHT-40,LGA_TOP+30+45,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,34,LGA_MAINRIGHT-40,LGA_TOP+30+60,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,35,LGA_MAINRIGHT-40,LGA_TOP+30+75,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,36,LGA_MAINRIGHT-40,LGA_TOP+30+90,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,37,LGA_MAINRIGHT-40,LGA_TOP+30+105,30,10,0);

  /* Create logic analyser window */
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
