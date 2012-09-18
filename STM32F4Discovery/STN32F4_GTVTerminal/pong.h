
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"



const uint8_t PongPaddleIcon[24][6] = {
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1},
{1,1,1,1,1,1}
};

const uint8_t PongBallIcon[8][8] = {
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1}
};

typedef struct
{
  volatile uint8_t Mode;                  // Mode type
  volatile uint8_t DemoMode;              // Demo mode flag
  volatile uint8_t GameOver;              // Game over flag
  volatile uint8_t Quit;                  // Quit flag
  volatile uint16_t Points[2];            // Points
  volatile int16_t bxdir,bydir,pydir[2];  // Ball / Paddle move
  RECT PongBound;                         // Game bounds
  SPRITE Ball;                            // Ball sprite
  SPRITE Paddle[2];                       // Paddle sprites
  WINDOW* hmsgbox;                        // Handle to message box
} PONG_GAME;
