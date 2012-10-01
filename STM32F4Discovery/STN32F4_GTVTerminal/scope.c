
/* Includes ------------------------------------------------------------------*/
#include "scope.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;
extern uint8_t FrameBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];
extern uint32_t frequency;

/* Private variables ---------------------------------------------------------*/
SCOPE Scope;
uint8_t scopestr[9][6]={{"Ofs:"},{"Mrk:"},{"Pos:"},{"Frq:"},{"Tme:"},{"Vcu:"},{"Vpp:"},{"Vmn:"},{"Vmx:"}};
uint8_t scopedbstr[4][3]={{"6\0"},{"8\0"},{"10\0"},{"12\0"}};
uint8_t scopeststr[8][4]={{"3\0"},{"15\0"},{"28\0"},{"56\0"},{"84\0"},{"112\0"},{"144\0"},{"480\0"}};
uint8_t scopecdstr[4][2]={{"2\0"},{"4\0"},{"6\0"},{"8\0"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void ScopeSetStrings(void)
{
  uint32_t rate;
  uint32_t clk=84000000;
	uint8_t decstr[11];
  uint8_t i,d;
  uint32_t dm;

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
  i=0;
  dm=1000000000;
  while (i<10)
  {
    d=rate/dm;
    rate-=d*dm;
    decstr[i]=d | 0x30;
    i++;
    dm /=10;
  }
  decstr[i]=0;
  i=0;
  while (i<9 && decstr[i]==0x30)
  {
    decstr[i]=0x20;
    i++;
  }
  SetCaption(GetControlHandle(Scope.hmain,95),decstr);
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
            break;
          case 2:
            /* Right */
            Scope.dataofs+=Scope.tmradd;
            if (Scope.dataofs>SCOPE_DATASIZE-256)
            {
              Scope.dataofs=SCOPE_DATASIZE-256;
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
      Scope.tmradd=1;
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void ScopeHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  uint16_t x;

  switch (event)
  {
    case EVENT_PAINT:
      DefWindowHandler(hwin,event,param,ID);
      if (FrameCount & 1)
      {
        ScopeDrawGrid();
      }
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
    x+=2;
    wdt-=2;
  }
}

void ScopeDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt)
{
  while (hgt>=0)
  {
    SetFBPixel(x,y);
    y+=2;
    hgt-=2;
  }
}

void ScopeDrawGrid(void)
{
  int16_t y=SCOPE_TOP+16;
  int16_t x=SCOPE_LEFT+32;

  while (y<=SCOPE_BOTTOM-30)
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
}

void ScopeDrawInfo(void)
{
  /* Offset */
  DrawWinString(SCOPE_LEFT+4,SCOPE_BOTTOM-30,4,scopestr[0],1);
  /* Mark */
  DrawWinString(SCOPE_LEFT+4,SCOPE_BOTTOM-20,4,scopestr[1],1);
  /* Position */
  DrawWinString(SCOPE_LEFT+4,SCOPE_BOTTOM-10,4,scopestr[2],1);

  /* Frequency */
  DrawWinString(SCOPE_LEFT+4+9*8,SCOPE_BOTTOM-30,4,scopestr[3],1);
  DrawWinDec32(SCOPE_LEFT+4+14*8,SCOPE_BOTTOM-30,frequency,5);
  /* Time */
  DrawWinString(SCOPE_LEFT+4+9*8,SCOPE_BOTTOM-20,4,scopestr[4],1);
  /* Vcurrent */
  DrawWinString(SCOPE_LEFT+4+9*8,SCOPE_BOTTOM-10,4,scopestr[5],1);
}

void ScopeInit(void)
{
  Scope.cur=0;
  Scope.mark=0;
  Scope.dataofs=0;
  Scope.tmrid=0;
  Scope.tmrmax=25;
  Scope.tmrcnt=0;
  Scope.tmrrep=0;
  Scope.tmradd=1;
  Scope.databits=0;
  Scope.sampletime=0;
  Scope.clockdiv=0;
}

void ScopeSetup(void)
{
  uint32_t i;
  WINDOW* hwin;
  uint8_t caps,num;

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
  /* Create scope window */
  Scope.hscope=CreateWindow(Scope.hmain,CLASS_STATIC,1,SCOPE_LEFT,SCOPE_TOP,SCOPE_WIDTH,SCOPE_HEIGHT,0);
  SetStyle(Scope.hscope,STYLE_BLACK);
  SetHandler(Scope.hscope,&ScopeHandler);

  /* Databits left button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,10,SCOPE_MAINRIGHT-100,SCOPE_TOP+10,20,20,"<\0");
  /* Databits right button */
  CreateWindow(Scope.hmain,CLASS_BUTTON,11,SCOPE_MAINRIGHT-25,SCOPE_TOP+10,20,20,">\0");
  CreateWindow(Scope.hmain,CLASS_STATIC,12,SCOPE_MAINRIGHT-80,SCOPE_TOP,55,20,0);

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

  SendEvent(Scope.hmain,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);
  CreateTimer(ScopeTimer);

  while (!Scope.Quit)
  {
    if (Scope.Sample)
    {
      Scope.Sample=0;
      SetStyle(Scope.hmain,STATE_VISIBLE);
      SetStyle(Scope.hmain,STYLE_LEFT);
      // LgaSample();
      SetStyle(Scope.hmain,STYLE_LEFT | STYLE_CANFOCUS);
      SetState(Scope.hmain,STATE_VISIBLE | STATE_FOCUS);
      Scope.dataofs=0;
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
