
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

/* Private define ------------------------------------------------------------*/
#define LGA_MAINLEFT      0
#define LGA_MAINTOP       0
#define LGA_MAINWIDTH     480
#define LGA_MAINHEIGHT    239
#define LGA_MAINRIGHT     LGA_MAINLEFT+LGA_MAINWIDTH
#define LGA_MAINBOTTOM    LGA_MAINTOP+LGA_MAINHEIGHT

#define LGA_BITWIDTH      4
#define LGA_BITHEIGHT     20
#define LGA_BYTES         64

#define LGA_LEFT          4
#define LGA_TOP           16
#define LGA_WIDTH         LGA_BITWIDTH*LGA_BYTES+30
#define LGA_HEIGHT        LGA_BITHEIGHT*8+38
#define LGA_RIGHT         LGA_LEFT+LGA_WIDTH
#define LGA_BOTTOM        LGA_TOP+LGA_HEIGHT

#define PE_IDR_ADDRESS    ((uint32_t)0x40021011)
#define LGA_DATAPTR       ((uint32_t)0x20010000)
#define LGA_DATASIZE      ((uint32_t)0x8000)
#define LGA_RATEMAX       9

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint32_t picosec;
  uint16_t cnt;
  uint8_t str[16];
} SAMPLE;

typedef struct
{
  WINDOW* hmain;
  WINDOW* hlga;
  uint16_t mark;
  uint16_t cur;
  int32_t dataofs;
  uint8_t markcnt;
  uint8_t markshow;
  uint8_t tmrid;
  uint8_t tmrmax;
  uint8_t tmrcnt;
  uint8_t rate;
  uint8_t Sample;
  uint8_t Quit;
} LGA;

/* Private function prototypes -----------------------------------------------*/
void LgaMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void LgaHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void LgaDrawHLine(uint16_t x,uint16_t y,uint16_t wdt);
void LgaDrawVLine(uint16_t x,uint16_t y,uint16_t hgt);
void LgaDrawGrid(void);
void LgaDrawMark(void);
void LgaDrawInfo(void);
void LgaDrawByte(uint32_t x,uint8_t byte,uint8_t pbyte);
void LgaDrawData();
void LgaSample(void);
void LogicAnalyserSetup(void);
void WaitForTrigger(void);
void DMA_LGAConfig(void);
void LgaTimer(void);
