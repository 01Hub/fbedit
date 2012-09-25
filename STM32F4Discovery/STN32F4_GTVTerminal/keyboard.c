
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
__attribute__((section("FLASH"))) const uint8_t codetable[] = {
	//   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	0,   F9,  0,   F5,  F3,  F1,  F2,  F12, 0,   F10, F8,  F6,  F4,  '\t','`', 0,
	0,   0,   0,   0,   0,   'q', '1', 0,   0,   0,   'z', 's', 'a', 'w', '2', 0,
	0,   'c', 'x', 'd', 'e', '4', '3', 0,   0,   ' ', 'v', 'f', 't', 'r', '5', 0,
	0,   'n', 'b', 'h', 'g', 'y', '6', 0,   0,   0,   'm', 'j', 'u', '7', '8', 0,
	0,   ',', 'k', 'i', 'o', '0', '9', 0,   0,   '.', '/', 'l', ';', 'p', '-', 0,
	0,   0,   '\'',0,   '[', '=', 0,   0,   CLK, 0,   '\r',']', 0,   '\\',0,   0,
	0,   0,   0,   0,   0,   0,   '\b',0,   0,   '1', 0,   '4', '7', 0,   0,   0,
	'0', '.', '2', '5', '6', '8', ESC,  NLK, F11, '+', '3', '-', '*', '9', SLK, 0,
	0,   0,   0,   F7
};

__attribute__((section("FLASH"))) const uint8_t codetable_shifted[] = {
	//   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	0,   F9,  0,   F5,  F3,  F1,  F2,  F12, 0,   F10, F8,  F6,  F4,  '\t','~', 0,
	0,   0,   0,   0,   0,   'Q', '!', 0,   0,   0,   'Z', 'S', 'A', 'W', '@', 0,
	0,   'C', 'X', 'D', 'E', '$', '#', 0,   0,   ' ', 'V', 'F', 'T', 'R', '%', 0,
	0,   'N', 'B', 'H', 'G', 'Y', '^', 0,   0,   0,   'M', 'J', 'U', '&', '*', 0,
	0,   '<', 'K', 'I', 'O', ')', '(', 0,   0,   '>', '?', 'L', ':', 'P', '_', 0,
	0,   0,   '"', 0,   '{', '+', 0,   0,   CLK, 0,   '\r','}', 0,   '|', 0,   0,
	0,   0,   0,   0,   0,   0,   '\b',0,   0,   '1', 0,   '4', '7', 0,   0,   0,
	'0', '.', '2', '5', '6', '8', ESC, NLK, F11, '+', '3', '-', '*', '9', SLK, 0,
	0,   0,   0,   F7
};

//codes that follow E0

__attribute__((section("FLASH"))) const uint8_t codetable_extended[] = {
	//   1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   PRS, 0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   '/', 0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   '\r',0,   0,   0,   0,   0,
	0,   0,   0,   0,   0,   0,   0,   0,   0,   END, 0,   ARL, HOM, 0,   0,   0,
	INS, DEL, ARD, '5', ARR, ARU, 0,   0,   0,   0,   PGD, 0,   PRS, PGU, 0,   0,
	0,   0,   0,   0
};

/* Key state tables */
volatile uint16_t keytab[16];
volatile uint16_t extkeytab[16];
/* Pause flag */
volatile uint8_t Pause;
volatile uint8_t Caps;
volatile uint8_t Num;
volatile uint16_t scancode = 0x0800;
volatile uint8_t nStuck;
volatile uint16_t keyscan;

/* Returns parity of byte in x. */
uint32_t parity1(uint32_t x)
{
 x ^= (x >> 1);
 x ^= (x >> 2);
 x ^= (x >> 4);
 return (x & 0x1);
}

/**
  * @brief  This function handles EXTI0_IRQHandler interrupt request.
            The interrupt is generated on STHL transition
  * @param  None
  * @retval None
  */
void EXTI2_IRQHandler(void)
{
  static uint16_t keyflag;
  uint16_t tmp;

  /* Clear the EXTI line 0 pending bit */
  EXTI->PR = EXTI_Line2;

  scancode >>= 1;
	if (GPIOB->IDR & GPIO_Pin_1)
  {
    scancode |= 0x0400;
  }
  if (scancode & 0x0001)
	{
    /* A scancode is ready */
    scancode = (scancode >> 1) & 0xFF;
    if (scancode == 0xF0)
    {
      /* Key up */
      keyflag |= 1;
    }
    else if (scancode == 0xE0)
    {
      /* Extended */
      keyflag |= 2;
    }
    else if (scancode == 0xE1)
    {
      /* Extended2 */
      keyflag |= 4;
    }
    else
    {
      if (keyflag & 4)
      {
        if (keyflag==5 && scancode == 0x77)
        {
          keyflag = 0;
          Pause ^=1;
        }
      }
      else if (keyflag & 2)
      {
        tmp = extkeytab[scancode>>4];
        if (keyflag & 1)
        {
          tmp ^= (0x01<<(scancode & 0x0F));
        }
        else
        {
          keyscan=0x100 | scancode;
          tmp |= (uint16_t)(0x01<<(scancode & 0x0F));
        }
        extkeytab[scancode>>4] = tmp;
        keyflag = 0;
      }
      else
      {
        tmp = keytab[scancode>>4];
        if (keyflag & 1)
        {
          tmp ^= (0x01<<(scancode & 0x0F));
        }
        else
        {
          keyscan=scancode;
          tmp |= (uint16_t)(0x01<<(scancode & 0x0F));
        }
        keytab[scancode>>4] = tmp;
        keyflag = 0;
      }
    }
    /* Prepare for a new scancode */
    scancode = 0x0800;
	}
}

void KeyboardReset(void)
{
  if (scancode!=0x0800)
  {
    nStuck++;
    if (nStuck>10)
    {
      /* Relese all keys */
      nStuck=0;
      while (nStuck<16)
      {
        keytab[nStuck]=0;
        extkeytab[nStuck]=0;
        nStuck++;
      }
      nStuck=0;
      DrawHex16(200,0,scancode,1);
      scancode=0x0800;
    }
  }
  else
  {
    nStuck=0;
  }
}

/**
  * @brief  This function returns the requested key state
  * @param  SC, one of th SC_??? scan codes
  * @retval TRUE or FALSE
  */
uint8_t GetKeyState(uint16_t SC)
{
  if (SC < 0x100)
  {
    return (keytab[SC >> 4] & (uint16_t)(0x01 << (SC & 0x0F))) != 0;
  }
  else
  {
    return (extkeytab[(SC & 0xFF) >> 4] & (uint16_t)(0x01 << (SC & 0x0F))) != 0;
  }
}

uint8_t Shifted(void)
{
  return (GetKeyState(SC_L_SHFT) | GetKeyState(SC_R_SHFT));
}

uint8_t Ctrled(void)
{
  return (GetKeyState(SC_L_CTRL) | GetKeyState(SC_R_CTRL));
}

uint8_t GetChar(void)
{
  uint8_t chr=0;
  uint16_t ks;

  ks=keyscan;
  keyscan=0;
  if (ks>0 && ks<=0x83)
  {
    chr=codetable[ks];
    if (chr>='a' && chr<='z')
    {
      if (Ctrled())
      {
        chr^=0x60;
      }
      else if (Shifted()^Caps)
      {
        chr=codetable_shifted[ks];
      }
    }
    else if (Shifted())
    {
      chr=codetable_shifted[ks];
    }
  }
  else if (ks>0x100 && ks<=0x183)
  {
    chr=codetable_extended[ks & 0xFF];
  }
  if (chr==CLK)
  {
    Caps^=1;
    chr=0;
  }
  else if(chr==NLK)
  {
    Num^=1;
    chr=0;
  }
  return chr;
}
