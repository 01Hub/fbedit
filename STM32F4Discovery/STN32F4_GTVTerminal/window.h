
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

#ifndef _WINDOW_H_
#define _WINDOW_H_

#include "video.h"

/* Private define ------------------------------------------------------------*/
/* Windows */
#define MAX_WINDOWS         16      // Max number of windows
#define MAX_WINCOLL         256     // Max number of windows and controls

#define CLASS_WINDOW        1
#define CLASS_BUTTON        2
#define CLASS_STATIC        3
#define CLASS_CHKBOX        4
#define CLASS_GROUPBOX      5

#define EVENT_PAINT         1
#define EVENT_SHOW          2
#define EVENT_SETFOCUS      3
#define EVENT_KILLFOCUS     4
#define EVENT_CHAR          5
#define EVENT_ACTIVATE      6
#define EVENT_LDOWN         7
#define EVENT_LUP           8
#define EVENT_LCLICK        9
#define EVENT_MOVE          10

#define STATE_HIDDEN        0
#define STATE_VISIBLE       1
#define STATE_FOCUS         2
#define STATE_CHECKED       4

#define DEF_WINSTATE        STATE_HIDDEN
#define DEF_STCSTATE        STATE_VISIBLE
#define DEF_BTNSTATE        STATE_VISIBLE
#define DEF_CHKSTATE        STATE_VISIBLE
#define DEF_GROUPSTATE      STATE_VISIBLE

#define STYLE_GRAY          1
#define STYLE_BLACK         2
#define STYLE_NOCAPTION     3
#define STYLE_LEFT          0
#define STYLE_CENTER        4
#define STYLE_RIGHT         8
#define STYLE_CANFOCUS      16     // Can have focus

#define DEF_WINSTYLE        STYLE_LEFT | STYLE_CANFOCUS
#define DEF_STCSTYLE        STYLE_CENTER
#define DEF_BTNSTYLE        STYLE_CENTER | STYLE_CANFOCUS
#define DEF_CHKSTYLE        STYLE_LEFT | STYLE_CANFOCUS
#define DEF_GROUPSTYLE      STYLE_LEFT

/* Private typedef -----------------------------------------------------------*/
typedef uint32_t (*handler)(void*,uint8_t,uint32_t,uint8_t);

typedef struct
{
  void* hwin;
  void* owner;
  uint32_t param;
  uint8_t winclass;
  uint8_t ID;
  uint16_t x;
  uint16_t y;
  uint16_t wt;
  uint16_t ht;
  uint8_t state;
  uint8_t style;
  uint8_t caplen;
  uint8_t *caption;
  void *control;
  void (*handler)(void* hwin,uint8_t event,uint32_t param,uint8_t ID);
} WINDOW;

/* Private function prototypes -----------------------------------------------*/
void FocusNext(WINDOW* hpar);
void FocusPrevious(WINDOW* hpar);
//void DrawWinLine(int32_t xl, int32_t yl, int32_t xr, int32_t yr);
void DrawWinLine(int16_t X1,int16_t Y1,int16_t X2,int16_t Y2);
void DrawBlackWinChar(uint16_t x, uint16_t y, uint8_t chr);
void DrawWhiteWinChar(uint16_t x, uint16_t y, uint8_t chr);
void DrawWinChar(uint16_t x, uint16_t y, uint8_t chr);
void DrawWinString(uint16_t x, uint16_t y,uint8_t len, uint8_t *str,uint8_t c);
void DrawWinDec32(uint16_t x, uint16_t y, uint32_t n, uint8_t c);
void DrawWinDec16(uint16_t x, uint16_t y, uint16_t n, uint8_t c);
void DrawWinHex8(uint16_t x, uint16_t y, uint8_t n, uint8_t c);
void DrawWinBin8(uint16_t x, uint16_t y, uint8_t n, uint8_t c);
void DrawWinIcon(uint16_t x,uint16_t y,ICON* icon);
void BlackWinFrame(uint16_t x,uint16_t y,uint16_t wdt,uint16_t hgt);
void BlackWinRect(uint16_t x,uint16_t y,uint16_t xm,uint16_t ym);
void WhiteWinRect(uint16_t x,uint16_t y,uint16_t xm,uint16_t ym);
void DrawWinCaption(WINDOW* hwin,uint16_t x,uint16_t y);
void DrawWindow(WINDOW* hwin);
WINDOW* WindowFromPoint(uint16_t x,uint16_t y);
WINDOW* ControlFromPoint(WINDOW* howner,uint16_t x,uint16_t y);
uint32_t FindWindowPos(WINDOW* hwin);
WINDOW* FindControlFocus(WINDOW* hwin);
WINDOW* FindControlCanFocus(WINDOW* hwin);
uint32_t WindowToFront(WINDOW* hwin);
uint32_t DefWindowHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
uint32_t SendEvent(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);

WINDOW* FindFree(void);
uint8_t StrLen(uint8_t* str);
void AddControl(WINDOW* hwin,WINDOW* hctl);
void AddWindow(WINDOW* hwin);
WINDOW* CreateWindow(WINDOW* howner,uint8_t winclass,uint8_t ID,uint16_t x,uint16_t y,uint16_t wt,uint16_t ht,uint8_t* caption);
void DestroyWindow(WINDOW* hwin);
void SetHandler(WINDOW* hwin,void* hdlr);
WINDOW* GetControlHandle(WINDOW* howner,uint8_t ID);
void SetCaption(WINDOW* hwin,uint8_t *caption);
void SetStyle(WINDOW* hwin,uint8_t style);
void SetState(WINDOW* hwin,uint8_t state);
void SetParam(WINDOW* hwin,uint32_t param);
void CreateTimer(TIMER tmr);
void KillTimer(void);

#endif