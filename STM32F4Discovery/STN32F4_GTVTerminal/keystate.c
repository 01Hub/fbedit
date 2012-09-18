
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "keycodes.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern volatile uint16_t keytab[16];
extern volatile uint16_t extkeytab[16];
extern volatile uint16_t keyscan;
extern volatile uint8_t Pause;
extern volatile uint8_t Caps;
extern volatile uint8_t Num;

/* Private variables ---------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void KeyState(void)
{
  int16_t y;
  uint8_t caps,num,chr;

  RemoveSprites();
  Cls();
  ShowCursor(0);
  DrawString(76,20,"Key States      \0",3);
  DrawString(277,20,"Extended States \0",3);
  DrawString(75,200,"Scancode :\0",1);
  DrawString(75,210,"Character:\0",1);
  while (!(GetKeyState(SC_ESC) && (GetKeyState(SC_L_CTRL) | GetKeyState(SC_R_CTRL))))
  {
    FrameWait(1);
    y=0;
    while (y<16)
    {
      DrawBin16(75,y*10+30,keytab[y],1);
      DrawBin16(277,y*10+30,extkeytab[y],1);
      y++;
    }
    if (keyscan)
    {
      DrawHex16(75+88,200,keyscan,1);
      chr=GetChar();
      DrawHex16(75+88,210,chr,1);
    }
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      DrawStatus("Ctrl+Esc to quit\0",Caps,Num);
    }
  }
}
