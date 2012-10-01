
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
uint8_t lgastr[8][6]={{"Ofs:"},{"Mrk:"},{"Pos:"},{"Bytes:"},{"Hex:"},{"Bin:"},{"Time:"},{"Trns:"}};
uint8_t lgacap[8][2]={{"D0"},{"D1"},{"D2"},{"D3"},{"D4"},{"D5"},{"D6"},{"D7"}};
LGASAMPLE lgarate[LGA_RATEMAX]={{10000000,1680,"100KHz\0"},{5000000,840,"200KHz\0"},{2000000,336,"500KHz\0"},{1000000,168,"1.0MHz\0"},{500000,84,"2.0MHz\0"},{196429,33,"5.1MHz\0"},{95238,16,"10.5MHz\0"},{47619,8,"21.0MHz\0"},{29762,5,"33.6MHz\0"}};

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
            /* Left */
            Lga.dataofs-=Lga.tmradd;
            if (Lga.dataofs<0)
            {
              Lga.dataofs=0;
            }
            break;
          case 2:
            /* Right */
            Lga.dataofs+=Lga.tmradd;
            if (Lga.dataofs>LGA_DATASIZE-64)
            {
              Lga.dataofs=LGA_DATASIZE-64;
            }
            break;
          case 40:
            /* Rate Left */
            if (Lga.rate)
            {
              Lga.rate--;
              SetCaption(GetControlHandle(Lga.hmain,41),lgarate[Lga.rate].str);
            }
            break;
          case 42:
            /* Rate Right */
            if (Lga.rate<LGA_RATEMAX-1)
            {
              Lga.rate++;
              SetCaption(GetControlHandle(Lga.hmain,41),lgarate[Lga.rate].str);
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
          default:
            DefWindowHandler(hwin,event,param,ID);
            break;
        }
      }
      break;
    case EVENT_LDOWN:
      if (ID>=1 && ID<=2)
      {
        Lga.tmrid=ID;
      }
      break;
    case EVENT_LUP:
      Lga.tmrid=0;
      Lga.tmrmax=25;
      Lga.tmrcnt=0;
      Lga.tmrrep=0;
      Lga.tmradd=1;
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void LgaHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  uint16_t x,y,pos;

  switch (event)
  {
    case EVENT_PAINT:
      DefWindowHandler(hwin,event,param,ID);
      if (FrameCount & 1)
      {
        LgaDrawGrid();
      }
      LgaDrawMark();
      LgaDrawData();
      LgaDrawInfo();
      break;
    case EVENT_LDOWN:
      x=param & 0xFFFF;
      y=param>>16;
      if (x>30)
      {
        Lga.mark=((x-30)/4)+Lga.dataofs;
      }
      break;
    case EVENT_MOVE:
      x=param & 0xFFFF;
      y=param>>16;
      if (x>30)
      {
        Lga.cur=((x-30)/4)+Lga.dataofs;
      }
      Lga.curbit=y/LGA_BITHEIGHT;
      break;
    case EVENT_CHAR:
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void LgaDrawDotHLine(uint16_t x,uint16_t y,int16_t wdt)
{
  while (wdt>=0)
  {
    SetFBPixel(x,y);
    x+=2;
    wdt-=2;
  }
}

void LgaDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt)
{
  while (hgt>=0)
  {
    SetFBPixel(x,y);
    y+=2;
    hgt-=2;
  }
}

void LgaDrawHLine(uint16_t x,uint16_t y,int16_t wdt)
{
  while (wdt)
  {
    SetFBPixel(x,y);
    x++;
    wdt--;
  }
}

void LgaDrawVLine(uint16_t x,uint16_t y,int16_t hgt)
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
    LgaDrawDotHLine(LGA_LEFT,y,LGA_WIDTH);
    DrawWinString(LGA_LEFT+5,y-12,2,lgacap[i],2);
    y+=LGA_BITHEIGHT;
    i++;
  }
  while (x<LGA_LEFT+30+8*32)
  {
    LgaDrawDotVLine(x,LGA_TOP,LGA_BITHEIGHT*8);
    x+=32;
  }
}

void LgaDrawMark(void)
{
  uint16_t x;

  if (Lga.markshow)
  {
    if ((Lga.mark>=Lga.dataofs) && (Lga.mark<Lga.dataofs+LGA_BYTES))
    {
      /* Draw mark */
      x=(Lga.mark-Lga.dataofs)*4+30+2;
      LgaDrawDotVLine(x,LGA_TOP,LGA_BITHEIGHT*8);
    }
    if ((Lga.cur>=Lga.dataofs) && (Lga.cur<Lga.dataofs+LGA_BYTES))
    {
      /* Draw mark */
      x=(Lga.cur-Lga.dataofs)*4+30+2;
      LgaDrawDotVLine(x,LGA_TOP,LGA_BITHEIGHT*8);
    }
  }
}

void LgaDrawInfo(void)
{
  uint16_t nbytes;
  uint8_t byte,pbyte,bit;
  uint8_t* ptr;
  uint64_t time;
  uint16_t ntrans;

  /* Offset */
  DrawWinString(LGA_LEFT+4,LGA_BOTTOM-30,4,lgastr[0],1);
  DrawWinDec16(LGA_LEFT+4+4*8,LGA_BOTTOM-30,Lga.dataofs,1);
  /* Mark */
  DrawWinString(LGA_LEFT+4,LGA_BOTTOM-20,4,lgastr[1],1);
  DrawWinDec16(LGA_LEFT+4+4*8,LGA_BOTTOM-20,Lga.mark,1);
  /* Position */
  DrawWinString(LGA_LEFT+4,LGA_BOTTOM-10,4,lgastr[2],1);
  DrawWinDec16(LGA_LEFT+4+4*8,LGA_BOTTOM-10,Lga.cur,1);

  /* Bytes */
  nbytes=Lga.cur-Lga.mark;
  if (Lga.cur<Lga.mark)
  {
    nbytes=Lga.mark-Lga.cur;
  }
  DrawWinString(LGA_LEFT+4+32+48,LGA_BOTTOM-30,6,lgastr[3],1);
  DrawWinDec16(LGA_LEFT+4+32+48+48,LGA_BOTTOM-30,nbytes,1);
  ptr=(uint8_t*)(LGA_DATAPTR+Lga.cur);
  byte=*ptr;
  /* Hex */
  DrawWinString(LGA_LEFT+4+32+48,LGA_BOTTOM-20,4,lgastr[4],1);
  DrawWinHex8(LGA_LEFT+4+32+48+48,LGA_BOTTOM-20,byte,1);
  /* Bin */
  DrawWinString(LGA_LEFT+4+32+48,LGA_BOTTOM-10,4,lgastr[5],1);
  DrawWinBin8(LGA_LEFT+4+32+48+48,LGA_BOTTOM-10,byte,1);

  /* Time in pico seconds */
  DrawWinString(LGA_LEFT+4+32+48+48+48,LGA_BOTTOM-30,5,lgastr[6],1);
  time=(lgarate[Lga.rate].cnt*nbytes*1000)/168;
  DrawWinDec32(LGA_LEFT+4+32+48+48+48+40,LGA_BOTTOM-30,time,1);
  /* Transitions */
  DrawWinString(LGA_LEFT+4+32+48+48+48,LGA_BOTTOM-20,5,lgastr[7],1);
  if (Lga.curbit<8)
  {
    ntrans=0;
    bit=1<<Lga.curbit;
    if (Lga.cur<Lga.mark)
    {
      ptr=(uint8_t*)(LGA_DATAPTR+Lga.cur);
    }
    else
    {
      ptr=(uint8_t*)(LGA_DATAPTR+Lga.mark);
    }
    while (nbytes)
    {
      pbyte=byte;
      ptr++;
      nbytes--;
      byte=*ptr;
      if ((pbyte & bit)==0 && (byte & bit)!=0)
      {
        ntrans++;
      }
    }
    DrawWinDec16(LGA_LEFT+4+32+48+48+48+40,LGA_BOTTOM-20,ntrans,1);
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
      LgaDrawHLine(x,y-16,LGA_BITWIDTH+1);
    }
    else
    {
      /* Low */
      LgaDrawHLine(x,y-4,LGA_BITWIDTH+1);
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
  uint32_t i;
  uint8_t byte;
  uint8_t* ptr;

  ptr=(uint8_t*)LGA_DATAPTR;
  TIM8->CNT=lgarate[Lga.rate].cnt-2;
  TIM8->ARR=lgarate[Lga.rate].cnt-1;
  DMA_LGAConfig();
  TIM_DMACmd(TIM8, TIM_DMA_Update, ENABLE);
  /* DMA2_Stream1 enable */
  DMA_Cmd(DMA2_Stream1, ENABLE);
  LgaWaitForTrigger();
  while (DMA_GetFlagStatus(DMA2_Stream1,DMA_FLAG_TCIF1)==RESET);
  DMA_DeInit(DMA2_Stream1);
  TIM_Cmd(TIM8, DISABLE);
  DMA_Cmd(DMA2_Stream1, DISABLE);
}

void LgaInit(void)
{
  Lga.cur=0;
  Lga.mark=0;
  Lga.dataofs=0;
  Lga.rate=LGA_RATEMAX-1;
  Lga.tmrid=0;
  Lga.tmrmax=25;
  Lga.tmrcnt=0;
  Lga.tmrrep=0;
  Lga.tmradd=1;
}

void LgaSetup(void)
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
  CreateWindow(Lga.hmain,CLASS_BUTTON,98,LGA_MAINRIGHT-75-75,LGA_MAINBOTTOM-25,70,20,"Sample\0");
  /* Quit button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,99,LGA_MAINRIGHT-75,LGA_MAINBOTTOM-25,70,20,"Quit\0");
  /* Left button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,1,LGA_LEFT,LGA_BOTTOM,20,20,"<\0");
  /* Right button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,2,LGA_RIGHT-20,LGA_BOTTOM,20,20,">\0");
  /* Trigger checkboxes */
  CreateWindow(Lga.hmain,CLASS_CHKBOX,20,LGA_MAINRIGHT-140,LGA_TOP+30,30,10,"D0\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,21,LGA_MAINRIGHT-140,LGA_TOP+30+15,30,10,"D1\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,22,LGA_MAINRIGHT-140,LGA_TOP+30+30,30,10,"D2\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,23,LGA_MAINRIGHT-140,LGA_TOP+30+45,30,10,"D3\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,24,LGA_MAINRIGHT-140,LGA_TOP+30+60,30,10,"D4\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,25,LGA_MAINRIGHT-140,LGA_TOP+30+75,30,10,"D5\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,26,LGA_MAINRIGHT-140,LGA_TOP+30+90,30,10,"D6\0");
  CreateWindow(Lga.hmain,CLASS_CHKBOX,27,LGA_MAINRIGHT-140,LGA_TOP+30+105,30,10,"D7\0");
  i=0;
  while (i<8)
  {
    SetStyle(GetControlHandle(Lga.hmain,i+20),STYLE_RIGHT | STYLE_CANFOCUS);
    i++;
  }
  /* Mask checkboxes */
  CreateWindow(Lga.hmain,CLASS_CHKBOX,30,LGA_MAINRIGHT-55,LGA_TOP+30,30,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,31,LGA_MAINRIGHT-55,LGA_TOP+30+15,10,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,32,LGA_MAINRIGHT-55,LGA_TOP+30+30,10,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,33,LGA_MAINRIGHT-55,LGA_TOP+30+45,10,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,34,LGA_MAINRIGHT-55,LGA_TOP+30+60,10,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,35,LGA_MAINRIGHT-55,LGA_TOP+30+75,10,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,36,LGA_MAINRIGHT-55,LGA_TOP+30+90,10,10,0);
  CreateWindow(Lga.hmain,CLASS_CHKBOX,37,LGA_MAINRIGHT-55,LGA_TOP+30+105,10,10,0);
  /* Groupbox */
  CreateWindow(Lga.hmain,CLASS_GROUPBOX,97,LGA_MAINRIGHT-75-75,LGA_TOP+5,145,150,"Trigger\0");
  /* Rate Left button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,40,LGA_MAINRIGHT-150,LGA_MAINBOTTOM-50,20,20,"<\0");
  /* Rate */
  CreateWindow(Lga.hmain,CLASS_STATIC,41,LGA_MAINRIGHT-150+20,LGA_MAINBOTTOM-50,105,20,0);
  SetCaption(GetControlHandle(Lga.hmain,41),lgarate[Lga.rate].str);
  /* Rate Right button */
  CreateWindow(Lga.hmain,CLASS_BUTTON,42,LGA_MAINRIGHT-25,LGA_MAINBOTTOM-50,20,20,">\0");
  /* Create logic analyser window */
  Lga.hlga=CreateWindow(Lga.hmain,CLASS_STATIC,1,LGA_LEFT,LGA_TOP,LGA_WIDTH,LGA_HEIGHT,0);
  SetStyle(Lga.hlga,STYLE_BLACK);
  SetHandler(Lga.hlga,&LgaHandler);
  SendEvent(Lga.hmain,EVENT_ACTIVATE,0,0);

  DrawStatus(0,Caps,Num);
  CreateTimer(LgaTimer);

  while (!Lga.Quit)
  {
    if (Lga.Sample)
    {
      Lga.Sample=0;
      SetState(Lga.hmain,STATE_VISIBLE);
      SetStyle(Lga.hmain,STYLE_LEFT);
      LgaSample();
      SetStyle(Lga.hmain,STYLE_LEFT | STYLE_CANFOCUS);
      SetState(Lga.hmain,STATE_VISIBLE | STATE_FOCUS);
      Lga.dataofs=0;
      Lga.cur=0;
      Lga.mark=0;
    }
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus(0,caps,num);
    }
  }
  KillTimer();
  DestroyWindow(Lga.hmain);
}

void LgaWaitForTrigger(void)
{
  uint8_t bit=1;
  uint8_t trg=0;
  uint8_t trgmask=0;
  WINDOW* hwin;
  uint16_t fc;
  uint32_t tmp,i;

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
      trgmask|=bit;
    }
    bit<<=1;
    i++;
  }
  if (trgmask)
  {
    tmp = trg & trgmask;
    fc=FrameCount+50*5;
    /* Wait while conditions are met */
    while (FrameCount!=fc)
    {
      if (((GPIOE->IDR>>8) & trgmask) != tmp)
      {
        break;
      }
    }
    /* Wait until conditions are met */
    while (FrameCount!=fc)
    {
      if (((GPIOE->IDR>>8) & trgmask) == tmp)
      {
        break;
      }
    }
  }
  TIM8->CR1 |= TIM_CR1_CEN;
}

void DMA_LGAConfig(void)
{
  DMA_InitTypeDef       DMA_InitStructure;

  DMA_DeInit(DMA2_Stream1);
  /* DMA2 Stream1 channel7 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_7;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = PE_IDR_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = LGA_DATAPTR;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = LGA_DATASIZE;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA2_Stream1, &DMA_InitStructure);
}

void LgaTimer(void)
{
  if (Lga.tmrid)
  {
    Lga.tmrcnt++;
    if (Lga.tmrcnt>=Lga.tmrmax)
    {
      Lga.tmrmax=1;
      Lga.tmrcnt=0;
      SendEvent(Lga.hmain,EVENT_CHAR,0x0D,Lga.tmrid);
      Lga.tmrrep++;
      if (Lga.tmrrep>=25)
      {
        Lga.tmrrep=0;
        if (Lga.tmradd<1000)
        {
          Lga.tmradd*=10;
        }
      }
    }
  }
  Lga.markcnt++;
  if (!(Lga.markcnt & 0x0F))
  {
    Lga.markshow^=1;
  }
}
