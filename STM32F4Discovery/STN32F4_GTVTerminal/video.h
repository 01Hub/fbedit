
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private define ------------------------------------------------------------*/
#define SPI_DR              0x4001300C

#define SCREEN_BUFFWIDTH    64    // Number of bytes on each buffer line.
#define SCREEN_BUFFHEIGHT   250   // Screen buffers are 64*250 bytes.

#define SCREEN_WIDTH        480   // 480 pixels on each line.
#define TOP_MARGIN          30    // Number of lines before video signal starts
#define SCREEN_HEIGHT       250   // 250 lines.
#define BOTTOM_MARGIN       23    // Number of lines after video signal ends
#define V_SYNC              10    // Number of lines vertical sync timing
#define TILE_WIDTH          8     // Width of a character tile
#define TILE_HEIGHT         10    // Height of a character tile
#define H_SYNC              4700  // Horisontal sync timing (nano seconds)
#define BACK_POCH           8000  // Back poch timing (nano seconds), adjust it to center the screen horizontaly
/* Sprites */
#define MAX_SPRITES         64    // Max number of sprites
#define COLL_LEFT           1     // Left boundary collision
#define COLL_TOP            2     // Top boundary collision
#define COLL_RIGHT          4     // Right boundary collision
#define COLL_BOTTOM         8     // Bottom boundary collision
#define COLL_SPRITE         16    // Collision with another sprite 
#define COLL_BACKGROUND     32    // Collision with background

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint16_t left;
  uint16_t top;
  uint16_t right;
  uint16_t bottom;
} RECT;

typedef struct
{
  uint8_t wt;
  uint8_t ht;
  const uint8_t* icondata;
} ICON;

typedef struct
{
  uint16_t x;
  uint16_t y;
  uint8_t visible;
  uint8_t collision;
  RECT* boundary;
  ICON icon;
} SPRITE;

