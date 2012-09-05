
/* Private define ------------------------------------------------------------*/
#define SCREEN_WIDTH        64    // 60*8=480 pixels on each line.
#define TOP_MARGIN          30    // Number of lines before video signal starts
#define SCREEN_HEIGHT       250   // 250 lines.
#define BOTTOM_MARGIN       23    // Number of lines after video signal ends
#define V_SYNC              10    // Number of lines vertical sync timing
#define TILE_WIDTH          8     // Width of a character tile
#define TILE_HEIGHT         10    // Height of a character tile
#define H_SYNC              4700  // Horisontal sync timing (nano seconds)
#define BACK_POCH           7700  // Back poch timing (nano seconds), adjust it to center the screen horizontaly
#define SPI_DR              0x4001300C

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint16_t id;
  uint16_t count;
  uint16_t x;
  uint16_t y;
  uint16_t z;
} TIME;

typedef struct
{
  uint8_t wt;
  uint8_t ht;
  uint8_t* icondata;
} ICON;

typedef struct
{
  uint16_t x;
  uint16_t y;
  uint8_t z;
  ICON icon;
} SPRITE;

