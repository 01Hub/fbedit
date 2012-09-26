
/* Includes ------------------------------------------------------------------*/
#include "desktop.h"

/* External variables --------------------------------------------------------*/
extern WINDOW* Focus;                 // The control that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;

/* Private variables ---------------------------------------------------------*/
DESKTOP Desktop;
uint8_t barcap[4][8]={{"Games\0"},{"Tools\0"},{"Options\0"},{"Help\0"}};
uint8_t pop1cap[4][8]={{"Alien\0"},{"Pong\0"},{"Volcano\0"},{"Tetris\0"}};
uint8_t pop2cap[5][17]={{"Terminal\0"},{"Key State\0"},{"Logic Analyser\0"},{"Digital Scope\0"},{"High Speed Clock\0"}};
uint8_t pop3cap[4][8]={{"Option1\0"},{"Option2\0"},{"Option3\0"},{"Option4\0"}};
uint8_t pop4cap[2][6]={{"Help\0"},{"About\0"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void MenuBarHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  WINDOW* hcld;
  switch (event)
  {
    case EVENT_CHAR:
      switch (param & 0xFF)
      {
        case K_DOWN:
        case 0x0D:
          if (Focus->param)
          {
            /* Hide all popup menus */
            hwin=hwin->control;
            while (hwin)
            {
              if (hwin->param)
              {
                hcld=(WINDOW*)hwin->param;
                hcld->state &= ~STATE_VISIBLE;
              }
              hwin=hwin->control;
            }
            /* Activate popup menu */
            hwin=(WINDOW*)Focus->param;
            SendEvent(hwin,EVENT_ACTIVATE,0,hwin->ID);
            break;
          }
          break;
        case K_LEFT:
          FocusPrevious(hwin);
          break;
        case K_RIGHT:
          FocusNext(hwin);
          break;
        default:
          DefWindowHandler(hwin,event,param,ID);
          break;
      }
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void MenuPopupHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      switch (param & 0xFF)
      {
        case 0x0D:
          Desktop.SelectedID=Focus->ID;
          break;
        case 0x1B:
          SendEvent(hwin,EVENT_SHOW,STATE_HIDDEN,0);
          SendEvent(Desktop.hmnubar,EVENT_ACTIVATE,0,0);
          break;
        case K_DOWN:
          FocusNext(hwin);
          break;
        case K_UP:
          FocusPrevious(hwin);
          break;
        case K_LEFT:
          SendEvent(hwin,EVENT_SHOW,STATE_HIDDEN,0);
          SendEvent(Desktop.hmnubar,EVENT_ACTIVATE,0,0);
          FocusPrevious(Desktop.hmnubar);
          SendEvent(Desktop.hmnubar,EVENT_CHAR,0x0D,0);
          break;
        case K_RIGHT:
          SendEvent(hwin,EVENT_SHOW,STATE_HIDDEN,0);
          SendEvent(Desktop.hmnubar,EVENT_ACTIVATE,0,0);
          FocusNext(Desktop.hmnubar);
          SendEvent(Desktop.hmnubar,EVENT_CHAR,0x0D,0);
          break;
        default:
          DefWindowHandler(hwin,event,param,ID);
          break;
      }
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void DeskTopSetup(void)
{
  uint32_t i;
  WINDOW* hwin;
  uint8_t caps,num;

  Cls();
  ShowCursor(1);
  Desktop.SelectedID=0;
  /* Create menu bar window */
  Desktop.hmnubar=CreateWindow(0,CLASS_WINDOW,0,0,0,480,16,0);
  SetStyle(Desktop.hmnubar,STYLE_NOCAPTION | STYLE_CANFOCUS);
  SetHandler(Desktop.hmnubar,&MenuBarHandler);
  /* Create menu bar buttons */
  i=0;
  while (i<4)
  {
    hwin=CreateWindow(Desktop.hmnubar,CLASS_BUTTON,i+1,i*72+2,2,70,12,barcap[i]);
    SetStyle(hwin,STYLE_LEFT | STYLE_CANFOCUS);
    i++;
  }
  /* Create popup1 window (Games) */
  Desktop.hpopup1=CreateWindow(0,CLASS_WINDOW,1,0,16,74,13*4+2,0);
  SetStyle(Desktop.hpopup1,STYLE_NOCAPTION | STYLE_CANFOCUS);
  SetHandler(Desktop.hpopup1,&MenuPopupHandler);
  SetParam(GetControlHandle(Desktop.hmnubar,1),(uint32_t)Desktop.hpopup1);
  /* Create popup1 buttons */
  i=0;
  while (i<4)
  {
    hwin=CreateWindow(Desktop.hpopup1,CLASS_BUTTON,i+11,2,i*13+2,74-4,12,pop1cap[i]);
    SetStyle(hwin,STYLE_LEFT | STYLE_CANFOCUS);
    i++;
  }
  /* Create popup2 window (Tools) */
  Desktop.hpopup2=CreateWindow(0,CLASS_WINDOW,2,72,16,120,13*5+2,0);
  SetStyle(Desktop.hpopup2,STYLE_NOCAPTION | STYLE_CANFOCUS);
  SetHandler(Desktop.hpopup2,&MenuPopupHandler);
  SetParam(GetControlHandle(Desktop.hmnubar,2),(uint32_t)Desktop.hpopup2);
  /* Create popup2 buttons */
  i=0;
  while (i<5)
  {
    hwin=CreateWindow(Desktop.hpopup2,CLASS_BUTTON,i+21,2,i*13+2,120-4,12,pop2cap[i]);
    SetStyle(hwin,STYLE_LEFT | STYLE_CANFOCUS);
    i++;
  }
  /* Create popup3 window (Options) */
  Desktop.hpopup3=CreateWindow(0,CLASS_WINDOW,3,72+72,16,74,13*4+2,0);
  SetStyle(Desktop.hpopup3,STYLE_NOCAPTION | STYLE_CANFOCUS);
  SetHandler(Desktop.hpopup3,&MenuPopupHandler);
  SetParam(GetControlHandle(Desktop.hmnubar,3),(uint32_t)Desktop.hpopup3);
  /* Create popup3 buttons */
  i=0;
  while (i<4)
  {
    hwin=CreateWindow(Desktop.hpopup3,CLASS_BUTTON,i+31,2,i*13+2,74-4,12,pop3cap[i]);
    SetStyle(hwin,STYLE_LEFT | STYLE_CANFOCUS);
    i++;
  }
  /* Create popup4 window (Help) */
  Desktop.hpopup4=CreateWindow(0,CLASS_WINDOW,4,72+72+72,16,74,13*2+2,0);
  SetStyle(Desktop.hpopup4,STYLE_NOCAPTION | STYLE_CANFOCUS);
  SetHandler(Desktop.hpopup4,&MenuPopupHandler);
  SetParam(GetControlHandle(Desktop.hmnubar,4),(uint32_t)Desktop.hpopup4);
  /* Create popup4 buttons */
  i=0;
  while (i<2)
  {
    hwin=CreateWindow(Desktop.hpopup4,CLASS_BUTTON,i+41,2,i*13+2,74-4,12,pop4cap[i]);
    SetStyle(hwin,STYLE_LEFT | STYLE_CANFOCUS);
    i++;
  }
  SendEvent(Desktop.hmnubar,EVENT_ACTIVATE,0,0);
  DrawStatus(0,Caps,Num);

  while (!Desktop.SelectedID)
  {
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus(0,caps,num);
    }
  }
  DestroyWindow(Desktop.hmnubar);
  DestroyWindow(Desktop.hpopup1);
  DestroyWindow(Desktop.hpopup2);
  DestroyWindow(Desktop.hpopup3);
  DestroyWindow(Desktop.hpopup4);
  ShowCursor(0);
  switch (Desktop.SelectedID)
  {
    case 11:
      AlienGameLoop();
      break;
    case 12:
      PongGameLoop();
      break;
    case 21:
      Terminal();
      break;
    case 22:
      KeyState();
      break;
    case 23:
      LogicAnalyserSetup();
      break;
    case 24:
      ScopeSetup();
      break;
    case 25:
      HSClkSetup();
      break;
  }
}
