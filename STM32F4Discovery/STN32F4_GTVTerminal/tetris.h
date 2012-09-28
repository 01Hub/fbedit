
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

const uint8_t TetrisIcon[12][12] = {
{0,0,0,0,0,0,0,0,0,0,0,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,1,1,0},
{0,0,0,0,0,0,0,0,0,0,0,0}
};

/* [Shape][Orientation][Byte] */
const uint8_t TetrisShape[7][4][4] = {
{
/* Line */
{
0b1111,
0b0000,
0b0000,
0b0000
},
{
0b0100,
0b0100,
0b0100,
0b0100
},
{
0b1111,
0b0000,
0b0000,
0b0000
},
{
0b0100,
0b0100,
0b0100,
0b0100
}
},
{
/* Rev L */
{
0b1000,
0b1110,
0b0000,
0b0000
},
{
0b0110,
0b0100,
0b0100,
0b0000
},
{
0b1110,
0b0010,
0b0000,
0b0000
},
{
0b0010,
0b0010,
0b0110,
0b0000
}
},
{
/* L */
{
0b0010,
0b1110,
0b0000,
0b0000
},
{
0b0100,
0b0100,
0b0110,
0b0000
},
{
0b1110,
0b1000,
0b0000,
0b0000
},
{
0b0110,
0b0100,
0b0100,
0b0000
}
},
{
/* Block */
{
0b1110,
0b1110,
0b1110,
0b0000
},
{
0b1110,
0b1110,
0b1110,
0b0000
},
{
0b1110,
0b1110,
0b1110,
0b0000
},
{
0b1110,
0b1110,
0b1110,
0b0000
}
},
{
/* Shape 1 */
{
0b0110,
0b1100,
0b0000,
0b0000
},
{
0b1000,
0b1100,
0b0100,
0b0000
},
{
0b0110,
0b1100,
0b0000,
0b0000
},
{
0b1000,
0b1100,
0b0100,
0b0000
}
},
{
/* Shape 2 */
{
0b1100,
0b0110,
0b0000,
0b0000
},
{
0b0100,
0b1100,
0b1000,
0b0000
},
{
0b1100,
0b0110,
0b0000,
0b0000
},
{
0b0100,
0b1100,
0b1000,
0b0000
}
},
{
/* Shape 3 */
{
0b1110,
0b0100,
0b0000,
0b0000
},
{
0b0100,
0b1100,
0b0100,
0b0000
},
{
0b0100,
0b1110,
0b0000,
0b0000
},
{
0b1000,
0b1100,
0b1000,
0b0000
}
}
};

typedef struct
{
  volatile uint8_t Mode;                  // Mode type
  volatile uint8_t DemoMode;              // Demo mode flag
  volatile uint8_t GameOver;              // Game over flag
  volatile uint8_t Quit;                  // Quit flag
  volatile uint8_t Speed;                 // Game speed
  volatile uint16_t Points;               // Points
  volatile uint8_t Board[20][10];         // Board
  volatile uint8_t Shape[20][10];         // Current Shape
  volatile uint8_t curshape;              // Current Shape
  volatile uint8_t curshapeo;             // Current Shape orientation
  volatile uint8_t curshapex;             // Current Shape x
  volatile uint8_t curshapey;             // Current Shape y
  volatile uint8_t nxtshape;              // Next Shape
  RECT TetrisBound;                       // Game bounds
  ICON tile;                              // Tile sprite
  WINDOW* hmsgbox;                        // Handle to message box
} TETRIS_GAME;

void TetrisGameSetup(void);
void TetrisMsgBoxHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void TetrisGameInit(void);
void TetrisGamePlay(void);
void TetrisGameLoop(void);
