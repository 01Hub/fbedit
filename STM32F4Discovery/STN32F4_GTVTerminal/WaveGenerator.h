/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

/* Private define ------------------------------------------------------------*/
#define WAVE_MAINLEFT      0
#define WAVE_MAINTOP       0
#define WAVE_MAINWIDTH     480
#define WAVE_MAINHEIGHT    239
#define WAVE_MAINRIGHT     WAVE_MAINLEFT+WAVE_MAINWIDTH
#define WAVE_MAINBOTTOM    WAVE_MAINTOP+WAVE_MAINHEIGHT

#define WAVE_LEFT          4
#define WAVE_TOP           16
#define WAVE_WIDTH         256
#define WAVE_HEIGHT        128+70
#define WAVE_RIGHT         WAVE_LEFT+WAVE_WIDTH
#define WAVE_BOTTOM        WAVE_TOP+WAVE_HEIGHT
/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  WINDOW* hmain;
  WINDOW* hwave;
  // uint16_t mark;
  // uint16_t cur;
  // int32_t dataofs;
  // uint8_t markcnt;
  // uint8_t markshow;
  // uint8_t tmrid;
  // uint8_t tmrmax;
  // uint8_t tmrcnt;
  // uint8_t tmrrep;
  // uint32_t tmradd;
  // uint8_t magnify;
  // uint8_t databits;
  // uint8_t sampletime;
  // uint8_t clockdiv;
  // uint32_t rate;
  // uint8_t autosample;
  // uint8_t trigger;
  // uint8_t Sample;
  uint8_t Quit;
  // uint8_t adcsamplebits;
  // uint32_t adcsamplerate;
  // uint32_t adcsampletime;
  // uint32_t adcfrequency;
  // uint32_t adcperiod;
  // uint8_t scopebuff[256];
} WAVE;

/* Private function prototypes -----------------------------------------------*/
void WaveMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void WaveHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void WaveInit(void);
void WaveSetup(void);
