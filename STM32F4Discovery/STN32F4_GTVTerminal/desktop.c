
/* Includes ------------------------------------------------------------------*/
#include "desktop.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern WINDOW* Windows[];             // Max 16 windows
extern WINDOW* Focus;                 // The windpw that has the keyboard focus
extern volatile uint8_t Caps;
extern volatile uint8_t Num;

/* Private variables ---------------------------------------------------------*/
DESKTOP Desktop;
uint16_t nevent;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void MenuBarHandler(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      switch (param & 0xFF)
      {
        case K_DOWN:
        case 0x0D:
          if (Focus->param)
          {
            /* Activate popup menu */
            SendEvent((WINDOW*)(Focus->param),EVENT_ACTIVATE,0,0);
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

void MenuPopupHandler(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID)
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
          SendEvent(Desktop.MenuBar.hwin,EVENT_ACTIVATE,0,0);
          break;
        case K_DOWN:
          FocusNext(hwin);
          break;
        case K_UP:
          FocusPrevious(hwin);
          break;
        case K_LEFT:
          SendEvent(hwin,EVENT_SHOW,STATE_HIDDEN,0);
          SendEvent(Desktop.MenuBar.hwin,EVENT_ACTIVATE,0,0);
          FocusPrevious(Desktop.MenuBar.hwin);
          SendEvent(Desktop.MenuBar.hwin,EVENT_CHAR,0x0D,0);
          break;
        case K_RIGHT:
          SendEvent(hwin,EVENT_SHOW,STATE_HIDDEN,0);
          SendEvent(Desktop.MenuBar.hwin,EVENT_ACTIVATE,0,0);
          FocusNext(Desktop.MenuBar.hwin);
          SendEvent(Desktop.MenuBar.hwin,EVENT_CHAR,0x0D,0);
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
  uint8_t caps,num;

  RemoveWindows();
  Cls();
  ShowCursor(1);
  Desktop.SelectedID=0;
  /* Create menu bar buttons */
  i=0;
  while (i<4)
  {
    Desktop.MenuBarButtons[i].hwin=&Desktop.MenuBarButtons[i];
    Desktop.MenuBarButtons[i].owner=&Desktop.MenuBar;
    Desktop.MenuBarButtons[i].winclass=CLASS_BUTTON;
    Desktop.MenuBarButtons[i].ID=i+1;
    Desktop.MenuBarButtons[i].x=i*72+2;
    Desktop.MenuBarButtons[i].y=2;
    Desktop.MenuBarButtons[i].wt=70;
    Desktop.MenuBarButtons[i].ht=12;
    Desktop.MenuBarButtons[i].state=STATE_VISIBLE;
    Desktop.MenuBarButtons[i].style=STYLE_LEFT | STYLE_CANFOCUS;
    Desktop.MenuBarButtons[i].control=0;
    Desktop.MenuBarButtons[i].handler=(void*)&DefWindowHandler;
    i++;
  }
  Desktop.MenuBarButtons[0].param=(uint32_t)&Desktop.Menu1Popup;
  Desktop.MenuBarButtons[0].caplen=5;
  Desktop.MenuBarButtons[0].caption="Games";
  Desktop.MenuBarButtons[1].param=(uint32_t)&Desktop.Menu2Popup;
  Desktop.MenuBarButtons[1].caplen=5;
  Desktop.MenuBarButtons[1].caption="Tools";
  Desktop.MenuBarButtons[2].param=(uint32_t)&Desktop.Menu3Popup;
  Desktop.MenuBarButtons[2].caplen=7;
  Desktop.MenuBarButtons[2].caption="Options";
  Desktop.MenuBarButtons[3].param=(uint32_t)&Desktop.Menu4Popup;
  Desktop.MenuBarButtons[3].caplen=4;
  Desktop.MenuBarButtons[3].caption="Help";
  /* Create menu bar */
  Desktop.MenuBar.hwin=&Desktop.MenuBar;
  Desktop.MenuBar.owner=0;
  Desktop.MenuBar.winclass=CLASS_WINDOW;
  Desktop.MenuBar.ID=0;
  Desktop.MenuBar.x=0;
  Desktop.MenuBar.y=0;
  Desktop.MenuBar.wt=480;
  Desktop.MenuBar.ht=16;
  Desktop.MenuBar.state=STATE_HIDDEN | STATE_FOCUS;
  Desktop.MenuBar.style=STYLE_NOCAPTION;
  Desktop.MenuBar.caplen=0;
  Desktop.MenuBar.caption=0;
  Desktop.MenuBar.control=0;
  Desktop.MenuBar.handler=(void*)&MenuBarHandler;
  i=0;
  while (i<4)
  {
    AddControl(Desktop.MenuBar.hwin,Desktop.MenuBarButtons[i]);
    i++;
  }
  Windows[0]=&Desktop.MenuBar;
  /* Create menu items for popup menu 1 (Games) */
  i=0;
  while (i<4)
  {
    Desktop.Menu1ItemButtons[i].hwin=&Desktop.Menu1ItemButtons[i];
    Desktop.Menu1ItemButtons[i].owner=&Desktop.Menu1Popup;
    Desktop.Menu1ItemButtons[i].winclass=CLASS_BUTTON;
    Desktop.Menu1ItemButtons[i].ID=i+11;
    Desktop.Menu1ItemButtons[i].x=2;
    Desktop.Menu1ItemButtons[i].y=i*13+2;
    Desktop.Menu1ItemButtons[i].wt=70;
    Desktop.Menu1ItemButtons[i].ht=12;
    Desktop.Menu1ItemButtons[i].state=STATE_VISIBLE;
    Desktop.Menu1ItemButtons[i].style=STYLE_LEFT | STYLE_CANFOCUS;
    Desktop.Menu1ItemButtons[i].control=0;
    Desktop.Menu1ItemButtons[i].handler=(void*)&DefWindowHandler;
    i++;
  }
  Desktop.Menu1ItemButtons[0].caplen=5;
  Desktop.Menu1ItemButtons[0].caption="Alien";
  Desktop.Menu1ItemButtons[1].caplen=4;
  Desktop.Menu1ItemButtons[1].caption="Pong";
  Desktop.Menu1ItemButtons[2].caplen=7;
  Desktop.Menu1ItemButtons[2].caption="Volcano";
  Desktop.Menu1ItemButtons[3].caplen=6;
  Desktop.Menu1ItemButtons[3].caption="Tetris";
  Desktop.Menu1Popup.hwin=&Desktop.Menu1Popup;
  Desktop.Menu1Popup.owner=0;
  Desktop.Menu1Popup.winclass=CLASS_WINDOW;
  Desktop.Menu1Popup.ID=1;
  Desktop.Menu1Popup.x=0;
  Desktop.Menu1Popup.y=16;
  Desktop.Menu1Popup.wt=74;
  Desktop.Menu1Popup.ht=13*4+2;
  Desktop.Menu1Popup.state=STATE_HIDDEN | STATE_FOCUS;
  Desktop.Menu1Popup.style=STYLE_NOCAPTION;
  Desktop.Menu1Popup.caplen=0;
  Desktop.Menu1Popup.caption=0;
  Desktop.Menu1Popup.control=0;
  Desktop.Menu1Popup.handler=(void*)&MenuPopupHandler;
  i=0;
  while (i<4)
  {
    AddControl(Desktop.Menu1Popup.hwin,Desktop.Menu1ItemButtons[i]);
    i++;
  }
  Windows[1]=&Desktop.Menu1Popup;

  /* Greate menu items for popup menu 2 (Tools) */
  i=0;
  while (i<4)
  {
    Desktop.Menu2ItemButtons[i].hwin=&Desktop.Menu2ItemButtons[i];
    Desktop.Menu2ItemButtons[i].owner=&Desktop.Menu2Popup;
    Desktop.Menu2ItemButtons[i].winclass=CLASS_BUTTON;
    Desktop.Menu2ItemButtons[i].ID=i+21;
    Desktop.Menu2ItemButtons[i].x=2;
    Desktop.Menu2ItemButtons[i].y=i*13+2;
    Desktop.Menu2ItemButtons[i].wt=116;
    Desktop.Menu2ItemButtons[i].ht=12;
    Desktop.Menu2ItemButtons[i].state=STATE_VISIBLE;
    Desktop.Menu2ItemButtons[i].style=STYLE_LEFT | STYLE_CANFOCUS;
    Desktop.Menu2ItemButtons[i].control=0;
    Desktop.Menu2ItemButtons[i].handler=(void*)&DefWindowHandler;
    i++;
  }
  Desktop.Menu2ItemButtons[0].caplen=8;
  Desktop.Menu2ItemButtons[0].caption="Terminal";
  Desktop.Menu2ItemButtons[1].caplen=9;
  Desktop.Menu2ItemButtons[1].caption="Key State";
  Desktop.Menu2ItemButtons[2].caplen=14;
  Desktop.Menu2ItemButtons[2].caption="Logic analyser";
  Desktop.Menu2ItemButtons[3].caplen=14;
  Desktop.Menu2ItemButtons[3].caption="Wave generator";
  Desktop.Menu2Popup.hwin=&Desktop.Menu2Popup;
  Desktop.Menu2Popup.owner=0;
  Desktop.Menu2Popup.winclass=CLASS_WINDOW;
  Desktop.Menu2Popup.ID=2;
  Desktop.Menu2Popup.x=72;
  Desktop.Menu2Popup.y=16;
  Desktop.Menu2Popup.wt=120;
  Desktop.Menu2Popup.ht=13*4+2;
  Desktop.Menu2Popup.state=STATE_HIDDEN | STATE_FOCUS;
  Desktop.Menu2Popup.style=STYLE_NOCAPTION;
  Desktop.Menu2Popup.caplen=0;
  Desktop.Menu2Popup.caption=0;
  Desktop.Menu2Popup.control=0;
  Desktop.Menu2Popup.handler=(void*)&MenuPopupHandler;
  i=0;
  while (i<4)
  {
    AddControl(Desktop.Menu2Popup.hwin,Desktop.Menu2ItemButtons[i]);
    i++;
  }
  Windows[2]=&Desktop.Menu2Popup;

  /* Greate menu items for popup menu 3 (Options) */
  i=0;
  while (i<4)
  {
    Desktop.Menu3ItemButtons[i].hwin=&Desktop.Menu3ItemButtons[i];
    Desktop.Menu3ItemButtons[i].owner=&Desktop.Menu3Popup;
    Desktop.Menu3ItemButtons[i].winclass=CLASS_BUTTON;
    Desktop.Menu3ItemButtons[i].ID=i+31;
    Desktop.Menu3ItemButtons[i].x=2;
    Desktop.Menu3ItemButtons[i].y=i*13+2;
    Desktop.Menu3ItemButtons[i].wt=70;
    Desktop.Menu3ItemButtons[i].ht=12;
    Desktop.Menu3ItemButtons[i].state=STATE_VISIBLE;
    Desktop.Menu3ItemButtons[i].style=STYLE_LEFT | STYLE_CANFOCUS;
    Desktop.Menu3ItemButtons[i].control=0;
    Desktop.Menu3ItemButtons[i].handler=(void*)&DefWindowHandler;
    i++;
  }
  Desktop.Menu3ItemButtons[0].caplen=8;
  Desktop.Menu3ItemButtons[0].caption="Option1";
  Desktop.Menu3ItemButtons[1].caplen=8;
  Desktop.Menu3ItemButtons[1].caption="Option2";
  Desktop.Menu3ItemButtons[2].caplen=8;
  Desktop.Menu3ItemButtons[2].caption="Option3";
  Desktop.Menu3ItemButtons[3].caplen=8;
  Desktop.Menu3ItemButtons[3].caption="Option4";
  Desktop.Menu3Popup.hwin=&Desktop.Menu3Popup;
  Desktop.Menu3Popup.owner=0;
  Desktop.Menu3Popup.winclass=CLASS_WINDOW;
  Desktop.Menu3Popup.ID=3;
  Desktop.Menu3Popup.x=72+72;
  Desktop.Menu3Popup.y=16;
  Desktop.Menu3Popup.wt=74;
  Desktop.Menu3Popup.ht=13*4+2;
  Desktop.Menu3Popup.state=STATE_HIDDEN | STATE_FOCUS;
  Desktop.Menu3Popup.style=STYLE_NOCAPTION;
  Desktop.Menu3Popup.caplen=0;
  Desktop.Menu3Popup.caption=0;
  Desktop.Menu3Popup.control=0;
  Desktop.Menu3Popup.handler=(void*)&MenuPopupHandler;
  i=0;
  while (i<4)
  {
    AddControl(Desktop.Menu3Popup.hwin,Desktop.Menu3ItemButtons[i]);
    i++;
  }
  Windows[3]=&Desktop.Menu3Popup;

  /* Greate menu items for popup menu 4 (Help) */
  i=0;
  while (i<2)
  {
    Desktop.Menu4ItemButtons[i].hwin=&Desktop.Menu4ItemButtons[i];
    Desktop.Menu4ItemButtons[i].owner=&Desktop.Menu4Popup;
    Desktop.Menu4ItemButtons[i].winclass=CLASS_BUTTON;
    Desktop.Menu4ItemButtons[i].ID=i+41;
    Desktop.Menu4ItemButtons[i].x=2;
    Desktop.Menu4ItemButtons[i].y=i*13+2;
    Desktop.Menu4ItemButtons[i].wt=70;
    Desktop.Menu4ItemButtons[i].ht=12;
    Desktop.Menu4ItemButtons[i].state=STATE_VISIBLE;
    Desktop.Menu4ItemButtons[i].style=STYLE_LEFT | STYLE_CANFOCUS;
    Desktop.Menu4ItemButtons[i].control=0;
    Desktop.Menu4ItemButtons[i].handler=(void*)&DefWindowHandler;
    i++;
  }
  Desktop.Menu4ItemButtons[0].caplen=4;
  Desktop.Menu4ItemButtons[0].caption="Help";
  Desktop.Menu4ItemButtons[1].caplen=5;
  Desktop.Menu4ItemButtons[1].caption="About";
  Desktop.Menu4Popup.hwin=&Desktop.Menu4Popup;
  Desktop.Menu4Popup.owner=0;
  Desktop.Menu4Popup.winclass=CLASS_WINDOW;
  Desktop.Menu4Popup.ID=2;
  Desktop.Menu4Popup.x=72+72+72;
  Desktop.Menu4Popup.y=16;
  Desktop.Menu4Popup.wt=74;
  Desktop.Menu4Popup.ht=13*2+2;
  Desktop.Menu4Popup.state=STATE_HIDDEN | STATE_FOCUS;
  Desktop.Menu4Popup.style=STYLE_NOCAPTION;
  Desktop.Menu4Popup.caplen=0;
  Desktop.Menu4Popup.caption=0;
  Desktop.Menu4Popup.control=0;
  Desktop.Menu4Popup.handler=(void*)&MenuPopupHandler;
  i=0;
  while (i<2)
  {
    AddControl(Desktop.Menu4Popup.hwin,Desktop.Menu4ItemButtons[i]);
    i++;
  }
  Windows[4]=&Desktop.Menu4Popup;
  SendEvent(Desktop.MenuBar.hwin,EVENT_ACTIVATE,0,0);
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
  RemoveWindows();
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
  }
}
