
/* Includes ------------------------------------------------------------------*/
#include "wavegenerator.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern volatile uint32_t SecCount;
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;

/* Private variables ---------------------------------------------------------*/
WAVE Wave;
// uint8_t scopestr[10][6]={{"Ofs:"},{"Mrk:"},{"Pos:"},{"Frq:"},{"Per:"},{"Tme:"},{"Vcu:"},{"Vpp:"},{"Vmn:"},{"Vmx:"}};
// uint8_t scopedbstr[4][3]={{"6\0"},{"8\0"},{"10\0"},{"12\0"}};
// uint8_t scopeststr[8][4]={{"3\0"},{"15\0"},{"28\0"},{"56\0"},{"84\0"},{"112\0"},{"144\0"},{"480\0"}};
// uint8_t scopecdstr[4][2]={{"2\0"},{"4\0"},{"6\0"},{"8\0"}};
// uint8_t scopemagstr[18][5]={{"/9\0"},{"/8\0"},{"/7\0"},{"/6\0"},{"/5\0"},{"/4\0"},{"/3\0"},{"/2\0"},{"*1\0"},{"*2\0"},{"*3\0"},{"*4\0"},{"*5\0"},{"*6\0"},{"*7\0"},{"*8\0"},{"*9\0"},{"Auto\0"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void WaveMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D)
      {
        switch (ID)
        {
          case 1:
            break;
          case 2:
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
      }
      break;
    case EVENT_LUP:
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
      // ScopeDrawGrid();
      // ScopeDrawMark();
      // ScopeDrawData();
      // ScopeDrawInfo();
      break;
    case EVENT_LDOWN:
      // x=param & 0xFFFF;
      // Scope.mark=x+Scope.dataofs;
      break;
    case EVENT_MOVE:
      // x=param & 0xFFFF;
      // Scope.cur=x+Scope.dataofs;
      break;
    case EVENT_CHAR:
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void WaveInit(void)
{
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
  Wave.hmain=CreateWindow(0,CLASS_WINDOW,0,WAVE_MAINLEFT,WAVE_MAINTOP,WAVE_MAINWIDTH,WAVE_MAINHEIGHT,"Digital Scope\0");
  SetHandler(Wave.hmain,&WaveMainHandler);
  /* Quit button */
  CreateWindow(Wave.hmain,CLASS_BUTTON,99,WAVE_MAINRIGHT-75,WAVE_MAINBOTTOM-25,70,20,"Quit\0");
  // /* Left button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,1,WAVE_LEFT,WAVE_BOTTOM,20,20,"<\0");
  // /* Right button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,2,WAVE_LEFT+80,WAVE_BOTTOM,20,20,">\0");
  // /* Left magnify button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,3,WAVE_RIGHT-100,WAVE_BOTTOM,20,20,"<\0");
  // /* Magnify static */
  // CreateWindow(Scope.hmain,CLASS_STATIC,71,WAVE_RIGHT-100+20,WAVE_BOTTOM,60,10,"\0");
  // /* Right magnify button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,4,WAVE_RIGHT-20,WAVE_BOTTOM,20,20,">\0");
  // /* Auto sample checkbox */
  // CreateWindow(Scope.hmain,CLASS_CHKBOX,70,WAVE_RIGHT+8,WAVE_TOP+15,90,10,"Auto sample\0");
  // if (Scope.autosample)
  // {
    // SetState(GetControlHandle(Scope.hmain,70),STATE_VISIBLE | STATE_CHECKED);
  // }
  // /* Trigger none checkbox */
  // CreateWindow(Scope.hmain,CLASS_CHKBOX,80,WAVE_RIGHT+16,WAVE_TOP+45,45,10,"None\0");
  // /* Trigger rising checkbox */
  // CreateWindow(Scope.hmain,CLASS_CHKBOX,81,WAVE_RIGHT+16,WAVE_TOP+60,45,10,"Rising\0");
  // /* Trigger falling checkbox */
  // CreateWindow(Scope.hmain,CLASS_CHKBOX,82,WAVE_RIGHT+16,WAVE_TOP+75,45,10,"Falling\0");
  // switch (Scope.trigger)
  // {
    // case 0:
      // SetState(GetControlHandle(Scope.hmain,80),STATE_VISIBLE | STATE_CHECKED);
      // break;
    // case 1:
      // SetState(GetControlHandle(Scope.hmain,81),STATE_VISIBLE | STATE_CHECKED);
      // break;
    // case 2:
      // SetState(GetControlHandle(Scope.hmain,82),STATE_VISIBLE | STATE_CHECKED);
      // break;
  // }
  // /* Trigger Groupbox */
  // CreateWindow(Scope.hmain,CLASS_GROUPBOX,83,WAVE_RIGHT+8,WAVE_TOP+30,90,65,"Trigger\0");

  /* Create wave window */
  Wave.hwave=CreateWindow(Wave.hmain,CLASS_STATIC,1,WAVE_LEFT,WAVE_TOP,WAVE_WIDTH,WAVE_HEIGHT,0);
  SetStyle(Wave.hwave,STYLE_BLACK);
  SetHandler(Wave.hwave,&WaveHandler);

  // /* Databits left button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,10,WAVE_MAINRIGHT-100,WAVE_TOP+10,20,20,"<\0");
  // /* Databits right button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,11,WAVE_MAINRIGHT-25,WAVE_TOP+10,20,20,">\0");
  // CreateWindow(Scope.hmain,CLASS_STATIC,12,WAVE_MAINRIGHT-80,WAVE_TOP+10,55,20,0);

  // /* Sample time left button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,20,WAVE_MAINRIGHT-100,WAVE_TOP+50,20,20,"<\0");
  // /* Sample time right button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,21,WAVE_MAINRIGHT-25,WAVE_TOP+50,20,20,">\0");
  // CreateWindow(Scope.hmain,CLASS_STATIC,22,WAVE_MAINRIGHT-80,WAVE_TOP+50,55,20,0);

  // /* Clock division left button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,30,WAVE_MAINRIGHT-100,WAVE_TOP+90,20,20,"<\0");
  // /* Clock division right button */
  // CreateWindow(Scope.hmain,CLASS_BUTTON,31,WAVE_MAINRIGHT-25,WAVE_TOP+90,20,20,">\0");
  // CreateWindow(Scope.hmain,CLASS_STATIC,32,WAVE_MAINRIGHT-80,WAVE_TOP+90,55,20,0);

  // CreateWindow(Scope.hmain,CLASS_STATIC,90,WAVE_MAINRIGHT-100,WAVE_TOP,95,10,"Data bits\0");
  // CreateWindow(Scope.hmain,CLASS_STATIC,91,WAVE_MAINRIGHT-100,WAVE_TOP+40,95,10,"Sample time\0");
  // CreateWindow(Scope.hmain,CLASS_STATIC,92,WAVE_MAINRIGHT-100,WAVE_TOP+80,95,10,"Clock div\0");

  // CreateWindow(Scope.hmain,CLASS_STATIC,93,WAVE_MAINRIGHT-100,WAVE_TOP+120,95,10,"Sample rate\0");
  // CreateWindow(Scope.hmain,CLASS_STATIC,94,WAVE_MAINRIGHT-100,WAVE_TOP+130,95,20,0);

  // ScopeSetStrings();
  // SendEvent(Scope.hmain,EVENT_ACTIVATE,0,0);
  // DrawStatus(0,Caps,Num);
  // CreateTimer(ScopeTimer);

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

