
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "video.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
volatile int16_t i,x,y;
extern volatile uint16_t FrameCount;// Frame counter
extern volatile uint16_t keytab[16];
extern volatile uint16_t ext1keytab[16];


/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void DebugKeyboard(void)
{
  char chr;

  while (1)
  {
    if (x!=FrameCount)
    {
      x=FrameCount;
      i=0;
      while (i<16)
      {
        DrawBin(0,i*10,keytab[i],1);
        DrawBin(18*8,i*10,ext1keytab[i],1);
        i++;
      }
    }
  }
}
