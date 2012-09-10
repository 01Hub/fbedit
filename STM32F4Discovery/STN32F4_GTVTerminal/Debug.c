
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
        DrawHex(0,i*10,keytab[i],1);
        i++;
      }
    }

    // chr=GetKey();
    // if (chr)
    // {
      // DrawHex(x,y,chr,1);
      // x+=TILE_WIDTH*5;
      // if (x>440)
      // {
        // x=0;
        // y+=TILE_HEIGHT;
        // if (y>=SCREEN_HEIGHT)
        // {
          // Cls();
          // y=0;
        // }
      // }
    // }
  }
}
