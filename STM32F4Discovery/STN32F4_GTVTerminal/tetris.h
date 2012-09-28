
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
const uint8_t TetrisShape[7][5] = {
/* Line */
{ 0b00000,
  0b00000,
  0b11111,
  0b00000,
  0b00000},
/* Rev L */
{ 0b00000,
  0b00000,
  0b01110,
  0b00010,
  0b00000},
/* L */
{ 0b00000,
  0b00000,
  0b00010,
  0b01110,
  0b00000},
/* Block */
{ 0b00000,
  0b01110,
  0b01110,
  0b01110,
  0b00000},
/* Shape 1 */
{ 0b00000,
  0b00110,
  0b01100,
  0b00000,
  0b00000},
/* Shape 2 */
{ 0b00000,
  0b01100,
  0b00110,
  0b00000,
  0b00000},
/* Shape 3 */
{ 0b00000,
  0b01110,
  0b00100,
  0b00000,
  0b00000}
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
  volatile uint8_t Shape[5][5];           // Current Shape array
  volatile uint8_t curshape;              // Current Shape
  volatile uint8_t curshapex;             // Current Shape x
  volatile uint8_t curshapey;             // Current Shape y
  volatile uint8_t nxtshape;              // Next Shape
  RECT TetrisBound;                       // Game bounds
  ICON tile;                              // Tile sprite
  WINDOW* hmsgbox;                        // Handle to message box
} TETRIS_GAME;

void TetrisSetup(void);
void TetrisMsgBoxHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void TetrisInit(void);
void TetrisClearBoard(void);
void TetrisDrawBoard(void);
void TetrisRotateShape(void);
void TetrisDrawShape(void);
void TetrisDrawNextShape(void);
void TetrisGetChar(void);
void TetrisPlay(void);
void TetrisGameLoop(void);
