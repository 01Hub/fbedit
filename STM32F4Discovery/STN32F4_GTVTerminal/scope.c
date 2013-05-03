
/* Includes ------------------------------------------------------------------*/
#include "scope.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern volatile uint16_t LineCount;
extern volatile uint32_t SecCount;
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;
extern uint32_t frequency;

/* Private variables ---------------------------------------------------------*/
SCOPE Scope;
uint8_t scopestr[10][6]={{"Ofs:"},{"Mrk:"},{"Pos:"},{"Frq:"},{"Per:"},{"Tme:"},{"Vcu:"},{"Vpp:"},{"Vmn:"},{"Vmx:"}};
uint8_t scopedbstr[4][3]={{"6\0"},{"8\0"},{"10\0"},{"12\0"}};
uint8_t scopeststr[8][4]={{"3\0"},{"15\0"},{"28\0"},{"56\0"},{"84\0"},{"112\0"},{"144\0"},{"480\0"}};
uint8_t scopecdstr[4][2]={{"2\0"},{"4\0"},{"6\0"},{"8\0"}};
uint8_t scopemagstr[18][5]={{"/9\0"},{"/8\0"},{"/7\0"},{"/6\0"},{"/5\0"},{"/4\0"},{"/3\0"},{"/2\0"},{"*1\0"},{"*2\0"},{"*3\0"},{"*4\0"},{"*5\0"},{"*6\0"},{"*7\0"},{"*8\0"},{"*9\0"},{"Auto\0"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void ScopeSetStrings(void)
{
  uint32_t rate;
  uint32_t clk=84000000;
	static uint8_t decstr[11],i;

  SetCaption(GetControlHandle(Scope.hmain,12),scopedbstr[Scope.databits]);
  SetCaption(GetControlHandle(Scope.hmain,22),scopeststr[Scope.sampletime]);
  SetCaption(GetControlHandle(Scope.hmain,32),scopecdstr[Scope.clockdiv]);
  rate=6+Scope.databits*2;
  switch (Scope.sampletime)
  {
    case 0:
      rate+=3;
      break;
    case 1:
      rate+=15;
      break;
    case 2:
      rate+=28;
      break;
    case 3:
      rate+=56;
      break;
    case 4:
      rate+=84;
      break;
    case 5:
      rate+=112;
      break;
    case 6:
      rate+=144;
      break;
    case 7:
      rate+=480;
      break;
  }
  switch (Scope.clockdiv)
  {
    case 0:
      clk/=2;
      break;
    case 1:
      clk/=4;
      break;
    case 2:
      clk/=6;
      break;
    case 3:
      clk/=8;
      break;
  }
  rate=clk/rate;
  Scope.rate=rate;

  i=BinDec32(rate,decstr);
  SetCaption(GetControlHandle(Scope.hmain,94),&decstr[i]);
  SetCaption(GetControlHandle(Scope.hmain,71),scopemagstr[Scope.magnify]);
}

void ScopeMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
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
            Scope.dataofs-=Scope.tmradd;
            if (Scope.dataofs<0)
            {
              Scope.dataofs=0;
            }
            ScopeGetData();
            break;
          case 2:
            /* Right */
            Scope.dataofs+=Scope.tmradd;
            if (Scope.dataofs>SCOPE_DATASIZE)
            {
              Scope.dataofs=SCOPE_DATASIZE;
            }
            ScopeGetData();
            break;
          case 3:
            /* Left magnify */
            if (Scope.magnify)
            {
              Scope.magnify--;
              ScopeSetStrings();
              ScopeGetData();
            }
            break;
          case 4:
            /* Right magnify */
            if (Scope.magnify<17)
            {
              Scope.magnify++;
              ScopeSetStrings();
              ScopeGetData();
            }
            break;
          case 10:
            /* Data bits left */
            if (Scope.databits)
            {
              Scope.databits--;
              ScopeSetStrings();
            }
            break;
          case 11:
            /* Data bits right */
            if (Scope.databits<3)
            {
              Scope.databits++;
              ScopeSetStrings();
            }
            break;
          case 20:
            /* Sample time left */
            if (Scope.sampletime)
            {
              Scope.sampletime--;
              ScopeSetStrings();
            }
            break;
          case 21:
            /* Sample time right */
            if (Scope.sampletime<7)
            {
              Scope.sampletime++;
              ScopeSetStrings();
            }
            break;
          case 30:
            /* Clock div left */
            if (Scope.clockdiv)
            {
              Scope.clockdiv--;
              ScopeSetStrings();
            }
            break;
          case 31:
            /* Clock div right */
            if (Scope.clockdiv<3)
            {
              Scope.clockdiv++;
              ScopeSetStrings();
            }
            break;
          case 70:
            Scope.autosample^=1;
            break;
          case 80:
            /* Trigger none */
            SetState(GetControlHandle(Scope.hmain,80),STATE_VISIBLE | STATE_CHECKED);
            ClearState(GetControlHandle(Scope.hmain,81),STATE_CHECKED);
            ClearState(GetControlHandle(Scope.hmain,82),STATE_CHECKED);
            Scope.trigger=0;
            break;
          case 81:
            /* Trigger rising */
            SetState(GetControlHandle(Scope.hmain,81),STATE_VISIBLE | STATE_CHECKED);
            ClearState(GetControlHandle(Scope.hmain,80),STATE_CHECKED);
            ClearState(GetControlHandle(Scope.hmain,82),STATE_CHECKED);
            Scope.trigger=1;
            break;
          case 82:
            /* Trigger rising */
            SetState(GetControlHandle(Scope.hmain,82),STATE_VISIBLE | STATE_CHECKED);
            ClearState(GetControlHandle(Scope.hmain,80),STATE_CHECKED);
            ClearState(GetControlHandle(Scope.hmain,81),STATE_CHECKED);
            Scope.trigger=2;
            break;
          case 98:
            /* Sample */
            Scope.Sample=1;
            break;
          case 99:
            /* Quit */
            Scope.Quit=1;
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
        Scope.tmrid=ID;
      }
      break;
    case EVENT_LUP:
      Scope.tmrid=0;
      Scope.tmrmax=25;
      Scope.tmrcnt=0;
      Scope.tmrrep=0;
      Scope.tmradd=4;
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void ScopeHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  uint16_t x;
  uint16_t* adc;

  switch (event)
  {
    case EVENT_PAINT:
      DefWindowHandler(hwin,event,param,ID);
      ScopeDrawGrid();
      ScopeDrawMark();
      ScopeDrawData();
      ScopeDrawInfo();
      break;
    case EVENT_LDOWN:
      x=param & 0xFFFF;
      Scope.mark=x+Scope.dataofs;
      break;
    case EVENT_MOVE:
      x=param & 0xFFFF;
      Scope.cur=x+Scope.dataofs;
      break;
    case EVENT_CHAR:
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void ScopeDrawDotHLine(uint16_t x,uint16_t y,int16_t wdt)
{
  while (wdt>=0)
  {
    SetFBPixel(x,y);
    x+=4;
    wdt-=4;
  }
}

void ScopeDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt)
{
  while (hgt>=0)
  {
    SetFBPixel(x,y);
    y+=4;
    hgt-=4;
  }
}

void ScopeDrawGrid(void)
{
  int16_t y=SCOPE_TOP+16;
  int16_t x=SCOPE_LEFT+32;

  while (y<=SCOPE_TOP+128)
  {
    ScopeDrawDotHLine(SCOPE_LEFT,y,SCOPE_WIDTH);
    y+=16;
  }
  while (x<SCOPE_WIDTH)
  {
    ScopeDrawDotVLine(x,SCOPE_TOP,8*16);
    x+=32;
  }
}

void ScopeDrawMark(void)
{
  uint16_t x;

  if (Scope.markshow)
  {
    if ((Scope.mark>=Scope.dataofs) && (Scope.mark<Scope.dataofs+SCOPE_BYTES))
    {
      /* Draw mark */
      x=Scope.mark-Scope.dataofs+SCOPE_LEFT;
      ScopeDrawDotVLine(x,SCOPE_TOP,8*16);
    }
    if ((Scope.cur>=Scope.dataofs) && (Scope.cur<Scope.dataofs+SCOPE_BYTES))
    {
      /* Draw mark */
      x=Scope.cur-Scope.dataofs+SCOPE_LEFT;
      ScopeDrawDotVLine(x,SCOPE_TOP,8*16);
    }
  }
}

void ScopeDrawData(void)
{
  uint16_t x1,x2,y1,y2;

  x1=0;
  x2=1;
  y1=Scope.scopebuff[x1];
  while (x2<256)
  {
    y2=Scope.scopebuff[x2];
    if (y2!=255)
    {
      DrawWinLine(x1+SCOPE_LEFT,y1+SCOPE_TOP,x2+SCOPE_LEFT,y2+SCOPE_TOP);
      x1=x2;
      y1=y2;
    }
    x2++;
  }
}

uint8_t ScopeConvert(uint16_t val)
{
  switch (Scope.adcsamplebits)
  {
    case 0:
      /* 6 bits */
      val<<=1;
      break;
    case 1:
      /* 8 bits */
      val>>=1;
      break;
    case 2:
       /* 10 bits */
      val>>=3;
      break;
    case 3:
      /* 12 bits */
      val>>=5;
      break;
  }
  val=127-val;
  return val;
}

void ScopeAuto(void)
{
  uint32_t x1,x2;
  uint16_t* ptr;
  uint32_t t;
  uint32_t sample[256][2];

  x1=0;
  while (x1<256)
  {
    Scope.scopebuff[x1]=255;
    sample[x1][0]=0;
    sample[x1][1]=0;
    x1++;
  }
  x2=0;
  ptr=(uint16_t*)(SCOPE_DATAPTR+Scope.dataofs);
  while (x2<1024)
  {
    x1=(uint32_t)(((float)Scope.adcsampletime*(float)256*(float)x2)/(float)Scope.adcperiod);
    while (x1>255)
    {
      x1-=256;
    }
    sample[x1][0]+=ScopeConvert(*ptr);
    sample[x1][1]++;
    ptr+=2;
    if ((uint32_t)ptr>=SCOPE_DATAPTR+SCOPE_DATASIZE)
    {
      break;
    }
    x2++;
  }
  x1=0;
  while (x1<256)
  {
    if (sample[x1][1])
    {
      Scope.scopebuff[x1]=sample[x1][0]/sample[x1][1];
    }
    x1++;
  }
}

void ScopeMagnify(uint32_t xadd,uint32_t ptradd)
{
  uint32_t x;
  uint16_t* ptr;

  ptr=(uint16_t*)(SCOPE_DATAPTR+Scope.dataofs);
  x=0;
  while (x<256)
  {
    Scope.scopebuff[x]=255;
    x++;
  }
  x=0;
  while (x<256)
  {
    Scope.scopebuff[x]=ScopeConvert(*ptr);
    ptr+=ptradd;
    if ((uint32_t)ptr>=SCOPE_DATAPTR+SCOPE_DATASIZE)
    {
      break;
    }
    x+=xadd;
  }
}

void ScopeGetData(void)
{
  switch (Scope.magnify)
  {
    case 0:
      ScopeMagnify(1,18);
      break;
    case 1:
      ScopeMagnify(1,16);
      break;
    case 2:
      ScopeMagnify(1,14);
      break;
    case 3:
      ScopeMagnify(1,12);
      break;
    case 4:
      ScopeMagnify(1,10);
      break;
    case 5:
      ScopeMagnify(1,8);
      break;
    case 6:
      ScopeMagnify(1,6);
      break;
    case 7:
      ScopeMagnify(1,4);
      break;
    case 8:
      ScopeMagnify(1,2);
      break;
    case 9:
      ScopeMagnify(2,2);
      break;
    case 10:
      ScopeMagnify(3,2);
      break;
    case 11:
      ScopeMagnify(4,2);
      break;
    case 12:
      ScopeMagnify(5,2);
      break;
    case 13:
      ScopeMagnify(6,2);
      break;
    case 14:
      ScopeMagnify(7,2);
      break;
    case 15:
      ScopeMagnify(8,2);
      break;
    case 16:
      ScopeMagnify(9,2);
      break;
    case 17:
      /* Auto */
      ScopeAuto();
      break;
  }
}

void ScopeDrawInfo(void)
{
  /* Offset */
  DrawWinString(SCOPE_LEFT+4,SCOPE_BOTTOM-30,4,scopestr[0],1);
  DrawWinDec16(SCOPE_LEFT+28,SCOPE_BOTTOM-30,Scope.dataofs>>2,5);
  /* Mark */
  DrawWinString(SCOPE_LEFT+4,SCOPE_BOTTOM-20,4,scopestr[1],1);
  DrawWinDec16(SCOPE_LEFT+28,SCOPE_BOTTOM-20,Scope.mark>>2,5);
  /* Position */
  DrawWinString(SCOPE_LEFT+4,SCOPE_BOTTOM-10,4,scopestr[2],1);
  DrawWinDec16(SCOPE_LEFT+28,SCOPE_BOTTOM-10,Scope.cur>>2,5);

  /* Frequency */
  DrawWinString(SCOPE_LEFT+4+9*8,SCOPE_BOTTOM-40,4,scopestr[3],1);
  DrawWinDec32(SCOPE_LEFT+4+14*8,SCOPE_BOTTOM-40,Scope.adcfrequency,5);
  /* Period */
  DrawWinString(SCOPE_LEFT+4+9*8,SCOPE_BOTTOM-30,4,scopestr[4],1);
  DrawWinDec32(SCOPE_LEFT+4+14*8,SCOPE_BOTTOM-30,Scope.adcperiod,5);
  /* Time */
  DrawWinString(SCOPE_LEFT+4+9*8,SCOPE_BOTTOM-20,4,scopestr[5],1);
  DrawWinDec32(SCOPE_LEFT+4+14*8,SCOPE_BOTTOM-20,Scope.adcsampletime,5);
  /* Vcurrent */
  DrawWinString(SCOPE_LEFT+4+9*8,SCOPE_BOTTOM-10,4,scopestr[6],1);
}

void ScopeInit(void)
{
  uint16_t i;
  uint16_t* ptr;

  Scope.cur=0;
  Scope.mark=0;
  Scope.dataofs=0;
  Scope.tmrid=0;
  Scope.tmrmax=25;
  Scope.tmrcnt=0;
  Scope.tmrrep=0;
  Scope.tmradd=4;
  Scope.magnify=8;
  Scope.databits=0;
  Scope.sampletime=0;
  Scope.clockdiv=0;
  Scope.triggerlevel=0;
}

void ScopeSetup(void)
{
  uint32_t i;
  WINDOW* hwin;
  uint8_t caps,num;
  uint32_t sec;

  Cls();
  ShowCursor(1);
  Scope.Quit=0;
  /* Create main scope window */
  Scope.hmain=CreateWindow(0,CLASS_WINDOW,0,SCOPE_MAINLEFT,SCOPE_MAINTOP,SCOPE_MAINWIDTH,SCOPE_MAINHEIGHT,"Digital Scope\0");
  SetHandler(Scope.hmain,&ScopeMainHandler);
  /* Sample button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,98,SCOPE_MAINRIGHT-75-75,SCOPE_MAINBOTTOM-25,70,20,"Sample\0");
  /* Quit button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,99,SCOPE_MAINRIGHT-75,SCOPE_MAINBOTTOM-25,70,20,"Quit\0");
  /* Left button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,1,SCOPE_LEFT,SCOPE_BOTTOM,20,20,"<\0");
  /* Right button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,2,SCOPE_LEFT+80,SCOPE_BOTTOM,20,20,">\0");
  /* Left magnify button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,3,SCOPE_RIGHT-100,SCOPE_BOTTOM,20,20,"<\0");
  /* Magnify static */
  CreateWindow(Scope.hmain,CLASS_STATIC,71,SCOPE_RIGHT-100+20,SCOPE_BOTTOM,60,10,"\0");
  /* Right magnify button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,4,SCOPE_RIGHT-20,SCOPE_BOTTOM,20,20,">\0");
  /* Auto sample checkbox */
  CreateWindow(Scope.hmain,CLASS_CHKBOX,70,SCOPE_RIGHT+8,SCOPE_TOP+15,90,10,"Auto sample\0");
  if (Scope.autosample)
  {
    SetState(GetControlHandle(Scope.hmain,70),STATE_VISIBLE | STATE_CHECKED);
  }
  /* Trigger none checkbox */
  CreateWindow(Scope.hmain,CLASS_CHKBOX,80,SCOPE_RIGHT+16,SCOPE_TOP+45,45,10,"None\0");
  /* Trigger rising checkbox */
  CreateWindow(Scope.hmain,CLASS_CHKBOX,81,SCOPE_RIGHT+16,SCOPE_TOP+60,45,10,"Rising\0");
  /* Trigger falling checkbox */
  CreateWindow(Scope.hmain,CLASS_CHKBOX,82,SCOPE_RIGHT+16,SCOPE_TOP+75,45,10,"Falling\0");
  switch (Scope.trigger)
  {
    case 0:
      SetState(GetControlHandle(Scope.hmain,80),STATE_VISIBLE | STATE_CHECKED);
      break;
    case 1:
      SetState(GetControlHandle(Scope.hmain,81),STATE_VISIBLE | STATE_CHECKED);
      break;
    case 2:
      SetState(GetControlHandle(Scope.hmain,82),STATE_VISIBLE | STATE_CHECKED);
      break;
  }
  /* Trigger Groupbox */
  CreateWindow(Scope.hmain,CLASS_GROUPBOX,83,SCOPE_RIGHT+8,SCOPE_TOP+30,90,65,"Trigger\0");

  /* Create scope window */
  Scope.hscope=CreateWindow(Scope.hmain,CLASS_STATIC,1,SCOPE_LEFT,SCOPE_TOP,SCOPE_WIDTH,SCOPE_HEIGHT,0);
  SetStyle(Scope.hscope,STYLE_BLACK);
  SetHandler(Scope.hscope,&ScopeHandler);

  /* Databits left button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,10,SCOPE_MAINRIGHT-100,SCOPE_TOP+10,20,20,"<\0");
  /* Databits right button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,11,SCOPE_MAINRIGHT-25,SCOPE_TOP+10,20,20,">\0");
  CreateWindow(Scope.hmain,CLASS_STATIC,12,SCOPE_MAINRIGHT-80,SCOPE_TOP+10,55,20,0);

  /* Sample time left button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,20,SCOPE_MAINRIGHT-100,SCOPE_TOP+50,20,20,"<\0");
  /* Sample time right button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,21,SCOPE_MAINRIGHT-25,SCOPE_TOP+50,20,20,">\0");
  CreateWindow(Scope.hmain,CLASS_STATIC,22,SCOPE_MAINRIGHT-80,SCOPE_TOP+50,55,20,0);

  /* Clock division left button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,30,SCOPE_MAINRIGHT-100,SCOPE_TOP+90,20,20,"<\0");
  /* Clock division right button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,31,SCOPE_MAINRIGHT-25,SCOPE_TOP+90,20,20,">\0");
  CreateWindow(Scope.hmain,CLASS_STATIC,32,SCOPE_MAINRIGHT-80,SCOPE_TOP+90,55,20,0);

  CreateWindow(Scope.hmain,CLASS_STATIC,90,SCOPE_MAINRIGHT-100,SCOPE_TOP,95,10,"Data bits\0");
  CreateWindow(Scope.hmain,CLASS_STATIC,91,SCOPE_MAINRIGHT-100,SCOPE_TOP+40,95,10,"Sample time\0");
  CreateWindow(Scope.hmain,CLASS_STATIC,92,SCOPE_MAINRIGHT-100,SCOPE_TOP+80,95,10,"Clock div\0");

  CreateWindow(Scope.hmain,CLASS_STATIC,93,SCOPE_MAINRIGHT-100,SCOPE_TOP+120,95,10,"Sample rate\0");
  CreateWindow(Scope.hmain,CLASS_STATIC,94,SCOPE_MAINRIGHT-100,SCOPE_TOP+130,95,20,0);

  ScopeSetStrings();
  SendEvent(Scope.hmain,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);
  CreateTimer(ScopeTimer);

  while (!Scope.Quit)
  {
    if ((GetKeyState(SC_ESC) && (GetKeyState(SC_L_CTRL) | GetKeyState(SC_R_CTRL))))
    {
      Scope.Quit=1;
    }
    if (Scope.Sample)
    {
      Scope.Sample=0;
      ScopeSample();
      //Scope.dataofs=0;
    }
    else if (Scope.autosample)
    {
      sec=SecCount;
      while (sec==SecCount);
      ScopeSample();
    }
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus(0,caps,num);
    }
  }
  KillTimer();
  DestroyWindow(Scope.hmain);
}

void ScopeTimer(void)
{
  if (Scope.tmrid)
  {
    Scope.tmrcnt++;
    if (Scope.tmrcnt>=Scope.tmrmax)
    {
      Scope.tmrmax=1;
      Scope.tmrcnt=0;
      SendEvent(Scope.hmain,EVENT_CHAR,0x0D,Scope.tmrid);
      Scope.tmrrep++;
      if (Scope.tmrrep>=25)
      {
        Scope.tmrrep=0;
        if (Scope.tmradd<1000)
        {
          Scope.tmradd*=10;
        }
      }
    }
  }
  Scope.markcnt++;
  if (!(Scope.markcnt & 0x0F))
  {
    Scope.markshow^=1;
  }
}

void ScopeSample(void)
{
  uint32_t sec;
  uint32_t cnt;

  Scope.adcsamplebits=Scope.databits;
  Scope.adcsamplerate=Scope.rate;
  Scope.adcsampletime=1000000000/Scope.rate;
  DAC_SPCConfig();
  DMA_SCPConfig();
  ADC_SCPConfig();
  if (Scope.trigger==1)
  {
    TIM2->CCER=0;
    sec=SecCount+5;
    cnt=TIM2->CNT;
    while (cnt==TIM2->CNT && SecCount<sec);
    /* Start ADC1 Software Conversion */
    ADC1->CR2 |= (uint32_t)ADC_CR2_SWSTART;
  }
  else if (Scope.trigger==2)
  {
    TIM2->CCER=2;
    sec=SecCount+5;
    cnt=TIM2->CNT;
    while (cnt==TIM2->CNT && SecCount<sec);
    /* Start ADC1 Software Conversion */
    ADC1->CR2 |= (uint32_t)ADC_CR2_SWSTART;
  }
  else
  {
    ADC1->CR2 |= (uint32_t)ADC_CR2_SWSTART;
  }
  while (DMA_GetFlagStatus(DMA2_Stream0,DMA_FLAG_TCIF0)==RESET);
  ADC_Cmd(ADC1, DISABLE);
  ADC_Cmd(ADC2, DISABLE);
  Scope.adcfrequency=frequency;
  Scope.adcperiod=1000000000/Scope.adcfrequency;
  ScopeGetData();
}

void DMA_SCPConfig(void)
{
  DMA_InitTypeDef       DMA_InitStructure;

  DMA_DeInit(DMA2_Stream0);
  DMA_StructInit(&DMA_InitStructure);
  /* DMA2 Stream0 channel0 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_0;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)ADC_CDR_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)SCOPE_DATAPTR;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = SCOPE_DATASIZE/4;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Word;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Word;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA2_Stream0, &DMA_InitStructure);
  /* DMA2_Stream0 enable */
  DMA_Cmd(DMA2_Stream0, ENABLE);
}

void ADC_SCPConfig(void)
{
  ADC_CommonInitTypeDef ADC_CommonInitStructure;
  ADC_InitTypeDef       ADC_InitStructure;

  ADC_StructInit(&ADC_InitStructure);
  ADC_CommonStructInit(&ADC_CommonInitStructure);

  /* ADC Common Init **********************************************************/
  ADC_CommonInitStructure.ADC_Mode = ADC_DualMode_RegSimult;
  ADC_CommonInitStructure.ADC_Prescaler = (uint32_t)Scope.clockdiv<<16;
  ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_2;
  ADC_CommonInitStructure.ADC_TwoSamplingDelay = ADC_TwoSamplingDelay_5Cycles;
  ADC_CommonInit(&ADC_CommonInitStructure);

  /* ADC1 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = (3-Scope.adcsamplebits)<<24;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_T1_CC1;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* ADC1 regular channel11 configuration *************************************/
  ADC_RegularChannelConfig(ADC1, ADC_Channel_11, 1, Scope.sampletime);
  /* Enable ADC1 DMA */
  ADC_DMACmd(ADC1, ENABLE);

  /* ADC2 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = (3-Scope.adcsamplebits)<<24;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_T1_CC1;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC2, &ADC_InitStructure);
  /* ADC2 regular channel12 configuration *************************************/
  ADC_RegularChannelConfig(ADC2, ADC_Channel_12, 1, Scope.sampletime);

  ADC_MultiModeDMARequestAfterLastTransferCmd(ENABLE);
  ADC_Cmd(ADC1, ENABLE);
  ADC_Cmd(ADC2, ENABLE);
}

void DAC_SPCConfig(void)
{
  DAC_InitTypeDef  DAC_InitStructure;

  /* DAC channel2 Configuration */
  DAC_StructInit(&DAC_InitStructure);
  DAC_InitStructure.DAC_Trigger = DAC_Trigger_None;
  DAC_InitStructure.DAC_WaveGeneration = DAC_WaveGeneration_None;
  DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Enable;
  DAC_Init(DAC_Channel_2, &DAC_InitStructure);
  /* Enable DAC Channel2 */
  DAC_Cmd(DAC_Channel_2, ENABLE);
}
