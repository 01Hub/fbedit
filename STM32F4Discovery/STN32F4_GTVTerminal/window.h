
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private define ------------------------------------------------------------*/
/* Windows */
#define MAX_WINDOWS         16     // Max number of windows

#define CLASS_WINDOW        1
#define CLASS_BUTTON        2
#define CLASS_STATIC        3

#define EVENT_PAINT         1
#define EVENT_SHOW          2
#define EVENT_SETFOCUS      3
#define EVENT_KILLFOCUS     4
#define EVENT_CHAR          5
#define EVENT_ACTIVATE      6

#define STATE_HIDDEN        0
#define STATE_VISIBLE       1
#define STATE_FOCUS         2

#define STYLE_NORMAL        0
#define STYLE_GRAY          1
#define STYLE_BLACK         2
#define STYLE_NOCAPTION     3
#define STYLE_LEFT          0
#define STYLE_CENTER        4
#define STYLE_RIGHT         8
#define STYLE_CANFOCUS      16     // Can have focus

/* Private typedef -----------------------------------------------------------*/
typedef void (*handler)(void*,uint8_t,uint16_t,uint8_t);
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
  void (*handler)(void* hwin,uint8_t event,uint16_t param,uint8_t ID);
} WINDOW;

/* Private function prototypes -----------------------------------------------*/
void DefWindowHandler(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID);
void SendEvent(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID);
