/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

/* Private define ------------------------------------------------------------*/
#define SCOPE_MAINLEFT      0
#define SCOPE_MAINTOP       0
#define SCOPE_MAINWIDTH     480
#define SCOPE_MAINHEIGHT    239
#define SCOPE_MAINRIGHT     SCOPE_MAINLEFT+SCOPE_MAINWIDTH
#define SCOPE_MAINBOTTOM    SCOPE_MAINTOP+SCOPE_MAINHEIGHT

#define SCOPE_LEFT          4
#define SCOPE_TOP           16
#define SCOPE_WIDTH         256
#define SCOPE_HEIGHT        128+70
#define SCOPE_RIGHT         SCOPE_LEFT+SCOPE_WIDTH
#define SCOPE_BOTTOM        SCOPE_TOP+SCOPE_HEIGHT

#define SCOPE_BYTES         256

#define ADC1_DR_ADDRESS     ((uint32_t)0x4001024C)
#define ADC_CDR_ADDRESS     ((uint32_t)0x40012308)
#define SCOPE_DATAPTR       ((uint32_t)0x20010000)
#define SCOPE_DATASIZE      ((uint32_t)0x8000)

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  WINDOW* hmain;
  WINDOW* hscope;
  uint16_t mark;
  uint16_t cur;
  int32_t dataofs;
  uint8_t markcnt;
  uint8_t markshow;
  uint8_t tmrid;
  uint8_t tmrmax;
  uint8_t tmrcnt;
  uint8_t tmrrep;
  uint32_t tmradd;
  uint8_t magnify;
  uint8_t databits;
  uint8_t sampletime;
  uint8_t clockdiv;
  uint32_t rate;
  uint8_t autosample;
  uint8_t trigger;
  uint16_t triggerlevel;
  uint8_t Sample;
  uint8_t Quit;
  uint8_t adcsamplebits;
  uint32_t adcsamplerate;
  uint32_t adcsampletime;
  uint32_t adcfrequency;
  uint32_t adcperiod;
  uint8_t scopebuff[256];
} SCOPE;

/* Private function prototypes -----------------------------------------------*/
void ScopeSetStrings(void);
void ScopeMainHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void ScopeHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void ScopeDrawDotHLine(uint16_t x,uint16_t y,int16_t wdt);
void ScopeDrawDotVLine(uint16_t x,uint16_t y,int16_t hgt);
void ScopeDrawGrid(void);
void ScopeDrawMark(void);
void ScopeDrawData(void);
uint8_t ScopeConvert(uint16_t val);
void ScopeGetData(void);
void ScopeDrawInfo(void);
void ScopeInit(void);
void ScopeSetup(void);
void ScopeTimer(void);
void ScopeSample(void);
void DMA_SCPConfig(void);
void ADC_SCPConfig(void);
void DAC_SPCConfig(void);
