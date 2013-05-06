/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

/* Private define ------------------------------------------------------------*/
#define DAC_DHR12R1_ADDRESS 0x40007408
#define DAC_DHR8R1_ADDRESS  0x40007410
#define WAVE_MAXFRQ         250000
#define WAVE_MAINLEFT       0
#define WAVE_MAINTOP        0
#define WAVE_MAINWIDTH      480
#define WAVE_MAINHEIGHT     239
#define WAVE_MAINRIGHT      WAVE_MAINLEFT+WAVE_MAINWIDTH
#define WAVE_MAINBOTTOM     WAVE_MAINTOP+WAVE_MAINHEIGHT

#define WAVE_LEFT           4
#define WAVE_TOP            16
#define WAVE_WIDTH          256+1
#define WAVE_HEIGHT         128+70
#define WAVE_RIGHT          WAVE_LEFT+WAVE_WIDTH
#define WAVE_BOTTOM         WAVE_TOP+WAVE_HEIGHT

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  WINDOW* hmain;
  WINDOW* hwave;
  uint8_t tmrid;
  uint8_t tmrmax;
  uint8_t tmrcnt;
  uint8_t tmrrep;
  uint32_t tmradd;
  uint8_t enable;
  uint8_t waveform;
  uint8_t amplitude;
  uint8_t dcoffset;
  uint8_t magnify;
  int32_t timerdiv;
  int32_t timer;
  int32_t frequency;
  uint8_t Quit;
  uint8_t wavebuff[256];
  uint16_t wave[256];
} WAVE;

/* Private function prototypes -----------------------------------------------*/
void WaveFrequencyToClock(void);
void WaveClockToFrequency(void);
void WaveSetStrings();
void WaveMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void WaveHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void WaveDrawDotHLine(uint16_t x,uint16_t y,int16_t wdt);
void WaveDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt);
void WaveDrawGrid(void);
void WaveDrawData(void);
void WaveGetData();
void WaveInit(void);
void WaveSetup(void);
void WaveTimer(void);
void WaveConfig();
