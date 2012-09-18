
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

/* Private define ------------------------------------------------------------*/
#define LGA_LEFT          4
#define LGA_TOP           16
#define LGA_WIDTH         256+30
#define LGA_HEIGHT        128+30

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  WINDOW* hmain;
  WINDOW* hlga;
  uint8_t Quit;
} LGA;

/* Private function prototypes -----------------------------------------------*/
void LgaMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void LgaHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void DrawLgaLine(uint16_t X1,uint16_t Y1,uint16_t X2,uint16_t Y2);
void DrawLgaGrid(void);
void DrawLgaByte(uint16_t x,uint8_t byte,uint8_t pbyte);
void DrawLgaData();
void LogicAnalyserSetup(void);
