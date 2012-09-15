
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "video.h"
#include "keycodes.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;// Frame counter
extern volatile uint16_t keytab[16];
extern volatile uint16_t extkeytab[16];
extern volatile uint8_t Pause;

/* Private variables ---------------------------------------------------------*/
volatile int16_t i,x,y;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void KeyState(void)
{
  RemoveWindows();
  while (!GetKeyState(SC_ESC))
  {
    if (x!=FrameCount)
    {
      x=FrameCount;
      DrawHex(0,0,Pause,1);
      i=0;
      while (i<16)
      {
        DrawBin(0,i*10+10,keytab[i],1);
        DrawBin(30*8,i*10+10,extkeytab[i],1);
        i++;
      }
    }
  }
}
