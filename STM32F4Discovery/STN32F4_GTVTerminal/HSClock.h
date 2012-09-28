/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"

/* Private define ------------------------------------------------------------*/
#define HSCLK_MAINLEFT      0
#define HSCLK_MAINTOP       0
#define HSCLK_MAINWIDTH     480
#define HSCLK_MAINHEIGHT    239
#define HSCLK_MAINRIGHT     HSCLK_MAINLEFT+HSCLK_MAINWIDTH
#define HSCLK_MAINBOTTOM    HSCLK_MAINTOP+HSCLK_MAINHEIGHT

#define HSCLK_LEFT          4
#define HSCLK_TOP           16
#define HSCLK_WIDTH         256
#define HSCLK_HEIGHT        128+38
#define HSCLK_RIGHT         HSCLK_LEFT+HSCLK_WIDTH
#define HSCLK_BOTTOM        HSCLK_TOP+HSCLK_HEIGHT

#define HSCLK_BYTES         256

#define ADC_ADDRESS         ((uint32_t)0x40021011)
#define HSCLK_DATAPTR       ((uint32_t)0x20010000)
#define HSCLK_DATASIZE      ((uint32_t)0x8000)

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  WINDOW* hmain;
  WINDOW* hhsclk;
  uint8_t tmrid;
  uint8_t tmrmax;
  uint8_t tmrcnt;
  uint8_t tmrrep;
  uint32_t tmradd;
  int32_t frq;
  int32_t clk;
  int32_t clkdiv;
  int16_t duty;
  uint8_t Quit;
} HSCLK;

/* Private function prototypes -----------------------------------------------*/
void FrequencyToClock(void);
void ClockToFrequency(void);
void HSClkSetTimer(void);
void HSClkMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void HSClkHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void HSClkDrawDotHLine(uint16_t x,uint16_t y,int16_t wdt);
void HSClkDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt);
void HSClkDrawHLine(uint16_t x,uint16_t y,int16_t wdt);
void HSClkDrawVLine(uint16_t x,uint16_t y,int16_t hgt);
void HSClkDrawGrid(void);
void HSClkDrawData(void);
void HSClkDrawInfo(void);
void HSClkInit(void);
void HSClkSetup(void);
void HSClkTimer(void);
