
/* Private define ------------------------------------------------------------*/
#define SPI_DR              0x4001300C

#define SCREEN_WIDTH        64    // 60*8=480 pixels on each line.
#define TOP_MARGIN          30    // Number of lines before video signal starts
#define SCREEN_HEIGHT       250   // 250 lines.
#define BOTTOM_MARGIN       23    // Number of lines after video signal ends
#define V_SYNC              10    // Number of lines vertical sync timing
#define TILE_WIDTH          8     // Width of a character tile
#define TILE_HEIGHT         10    // Height of a character tile
#define H_SYNC              4700  // Horisontal sync timing (nano seconds)
#define BACK_POCH           7700  // Back poch timing (nano seconds), adjust it to center the screen horizontaly
/* Sprites */
#define MAX_SPRITES         64    // Max number of sprites
#define COLL_LEFT           1     // Left boundary collision
#define COLL_TOP            2     // Top boundary collision
#define COLL_RIGHT          4     // Right boundary collision
#define COLL_BOTTOM         8     // Bottom boundary collision
#define COLL_SPRITE         16    // Collision with another sprite 
#define COLL_BACKGROUND     32    // Collision with background
/* Windows */
#define MAX_WINDOWS         4     // Max number of windows
#define MAX_CONTROLS        4     // Max number of controls on a window

#define CLASS_WINDOW        1
#define CLASS_BUTTON        2
#define CLASS_STATIC        3

#define EVENT_KEYDOWN       1
#define EVENT_KEYUP         2
#define EVENT_CHAR          3
#define EVENT_MOUSMOVE      4
#define EVENT_LBUTTOMDOWN   5
#define EVENT_LBUTTONUP     6
#define EVENT_PAINT         7
#define EVENT_SHOW          8
#define EVENT_BTNCLICK      9
#define EVENT_GOTFOCUS      10
#define EVENT_LOSTFOCUS     11

#define STATE_HIDDEN        0
#define STATE_VISIBLE       1
#define STATE_FOCUS         2

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  int16_t left;
  int16_t top;
  int16_t right;
  int16_t bottom;
} RECT;

typedef struct
{
  uint8_t wt;
  uint8_t ht;
  const uint8_t* icondata;
} ICON;

typedef struct
{
  int16_t x;
  int16_t y;
  uint8_t visible;
  uint8_t collision;
  RECT* boundary;
  ICON icon;
} SPRITE;

typedef void (*handler)(void*,uint8_t,uint16_t,uint8_t);
typedef struct
{
  void* hwin;
  void* owner;
  uint8_t winclass;
  uint8_t ID;
  int16_t x;
  int16_t y;
  int16_t wt;
  int16_t ht;
  uint8_t state;
  uint8_t caplen;
  char *caption;
  void *control[MAX_CONTROLS];
  void (*handler)(void* hwin,uint8_t event,uint16_t param,uint8_t ID);
} WINDOW;

/* Private function prototypes -----------------------------------------------*/
void DefWindowHandler(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID);
void SendEvent(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID);
