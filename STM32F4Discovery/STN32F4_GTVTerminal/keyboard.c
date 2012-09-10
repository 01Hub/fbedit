
#include "stm32f4_discovery.h"
#include "keycodes.h"

#define ESC K_ESC
#define CLK K_CAPSLK
#define NLK K_NUMLK
#define SLK K_SCRLK
#define F1  K_F1
#define F2  K_F2
#define F3  K_F3
#define F4  K_F4
#define F5  K_F5
#define F6  K_F6
#define F7  K_F7
#define F8  K_F8
#define F9  K_F9
#define F10 K_F10
#define F11 K_F11
#define F12 K_F12
#define INS K_INS
#define DEL K_DEL
#define HOM K_HOME
#define END K_END
#define PGU K_PGUP
#define PGD K_PGDN
#define ARL K_LEFT
#define ARR K_RIGHT
#define ARU K_UP
#define ARD K_DOWN
#define PRS K_PRTSC
#define BRK K_BREAK
#define _BV(bit) (1 << (bit))  //Useful macro to ease the transition from using avrlibc.

//Keyboard lookup tables
__attribute__((section("FLASH"))) const char codetable[] = {
	//   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	0,   F9,  0,   F5,  F3,  F1,  F2,  F12, 0,   F10, F8,  F6,  F4,  '\t','`', 0,
	0,   0,   0,   0,   0,   'q', '1', 0,   0,   0,   'z', 's', 'a', 'w', '2', 0,
	0,   'c', 'x', 'd', 'e', '4', '3', 0,   0,   ' ', 'v', 'f', 't', 'r', '5', 0,
	0,   'n', 'b', 'h', 'g', 'y', '6', 0,   0,   0,   'm', 'j', 'u', '7', '8', 0,
	0,   ',', 'k', 'i', 'o', '0', '9', 0,   0,   '.', '/', 'l', ';', 'p', '-', 0,
	0,   0,   '\'',0,   '[', '=', 0,   0,   CLK, 0,   '\n',']', 0,   '\\',0,   0,
	0,   0,   0,   0,   0,   0,   '\b',0,   0,   '1', 0,   '4', '7', 0,   0,   0,
	'0', '.', '2', '5', '6', '8', ESC,  NLK, F11, '+', '3', '-', '*', '9', SLK, 0,
	0,   0,   0,   F7
};

__attribute__((section("FLASH"))) const char codetable_shifted[] = {
	//   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	0,   F9,  0,   F5,  F3,  F1,  F2,  F12, 0,   F10, F8,  F6,  F4,  '\t','~', 0,
	0,   0,   0,   0,   0,   'Q', '!', 0,   0,   0,   'Z', 'S', 'A', 'W', '@', 0,
	0,   'C', 'X', 'D', 'E', '$', '#', 0,   0,   ' ', 'V', 'F', 'T', 'R', '%', 0,
	0,   'N', 'B', 'H', 'G', 'Y', '^', 0,   0,   0,   'M', 'J', 'U', '&', '*', 0,
	0,   '<', 'K', 'I', 'O', ')', '(', 0,   0,   '>', '?', 'L', ':', 'P', '_', 0,
	0,   0,   '"', 0,   '{', '+', 0,   0,   CLK, 0,   '\n','}', 0,   '|', 0,   0,
	0,   0,   0,   0,   0,   0,   '\b',0,   0,   '1', 0,   '4', '7', 0,   0,   0,
	'0', '.', '2', '5', '6', '8', ESC, NLK, F11, '+', '3', '-', '*', '9', SLK, 0,
	0,   0,   0,   F7
};

//codes that follow E0 or E1

__attribute__((section("FLASH"))) const char codetable_extended[] = {
	//   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   PRS, 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   '/', 0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   '\n',0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   END, 0,   ARL, HOM, 0,   0,   0,
	INS, DEL, ARD, '5', ARR, ARU, 0,   BRK, 0,   0,   PGD, 0,   PRS, PGU, 0,   0,
	0,   0,   0,   0
};

/* circular buffer for keys */
uint8_t charbuf[256];
volatile uint8_t charbufhead = 0;
volatile uint8_t charbuftail = 0;
/* Key state tables */
volatile uint16_t keytab[16];
volatile uint16_t ext1keytab[16];
volatile uint16_t ext2keytab[16];

/**
  * @brief  This function handles EXTI0_IRQHandler interrupt request.
            The interrupt is generated on STHL transition
  * @param  None
  * @retval None
  */
void EXTI0_IRQHandler(void)
{
  static uint16_t scancode = 0x0800;
  static uint16_t keyflag;

  /* Clear the EXTI line 0 pending bit */
  EXTI->PR = EXTI_Line0;

  scancode >>= 1;
	if (GPIOB->IDR & GPIO_Pin_1)
  {
    scancode |= 0x0400;
  }
  if (scancode & 0x0001)
	{
    scancode=(scancode>>1) & 0xFF;
    if (scancode==0xF0)
    {
      keyflag|=1;
    }
    else if (scancode==0xE0)
    {
      keyflag|=2;
    }
    else if (scancode==0xE1)
    {
      keyflag|=4;
    }
    else if (keyflag & 4)
    {
      if (keyflag & 1)
      {
        ext2keytab[scancode>>4] &= ~(0x01<<(scancode & 0x0F));
        keyflag&=~1;
      }
      else
      {
        ext1keytab[scancode>>4] |= (uint16_t)(0x01<<(scancode & 0x0F));
      }
      keyflag&=~4;
    }
    else if (keyflag & 2)
    {
      if (keyflag & 1)
      {
        ext1keytab[scancode>>4] &= ~(0x01<<(scancode & 0x0F));
        keyflag&=~1;
      }
      else
      {
        ext1keytab[scancode>>4] |= (uint16_t)(0x01<<(scancode & 0x0F));
      }
      keyflag&=~2;
    }
    else
    {
      if (keyflag & 1)
      {
        keytab[scancode>>4] &= ~(0x01<<(scancode & 0x0F));
        keyflag&=~1;
      }
      else
      {
        keytab[scancode>>4] |= (uint16_t)(0x01<<(scancode & 0x0F));
      }
    }
    scancode=0x0800;
	}
}

/**
  * @brief  This function returns the requested keys state
  * @param  SC, one of th SC_??? scan codes
  * @retval TRUE or FALSE
  */
uint8_t GetKeyState(uint16_t SC)
{
  if (SC<0x100)
  {
    return (keytab[SC>>4] & (uint16_t)(0x01<<(SC & 0x0F)))!=0;
  }
  else if (SC<0x200)
  {
    return (ext1keytab[(SC & 0xFF)>>4] & (uint16_t)(0x01<<(SC & 0x0F)))!=0;
  }
  else
  {
    return (ext2keytab[(SC & 0xFF)>>4] & (uint16_t)(0x01<<(SC & 0x0F)))!=0;
  }
}
