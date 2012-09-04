
/*******************************************************************************
* Keyboard connector 5 pin female DIN
*        2
*        o
*   4 o    o 5
*   1 o    o 3
* 
* Pin 1   CLK     Clock signal
* Pin 2   DATA    Data
* Pin 3   N/C     Not connected. Reset on older keyboards
* Pin 4   GND     Ground
* Pin 5   VCC     +5V DC
*******************************************************************************/

/*******************************************************************************
* Keyboard connector 6 pin female mini DIN
*
*   5 o    o 6
*   3 o    o 4
*    1 o o 2 
*
* Pin 1   DATA    Data
* Pin 2   N/C     Not connected.
* Pin 3   GND     Ground
* Pin 4   VCC     +5V DC
* Pin 5   CLK     Clock signal
* Pin 6   N/C     Not connected.
*******************************************************************************/

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

/* Private function prototypes -----------------------------------------------*/
void decode(uint8_t scancode);

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

/* keyboard init */
static uint8_t keyup = 0;
static uint8_t extended = 0;
static uint8_t mods = 0;
/* circular buffer for keys */
__IO uint8_t charbuf[256];
__IO uint8_t charbufhead = 0;
__IO uint8_t charbuftail = 0;

__IO uint8_t tmpscancode;
__IO uint8_t scancode;
__IO uint8_t kbitcount = 11;

//Decode PS/2 keycodes
void decode(uint8_t scancode)
{
	if (scancode == 0xF0)
		keyup = 1;
	else if (scancode == 0xE0 || scancode == 0xE1)
		extended = 1;
	else
	{
		if (keyup) // handling a key release; don't do anything
		{
			if (scancode == 0x12) // left shift
				mods &= ~_BV(0);
			else if (scancode == 0x59) // right shift
				mods &= ~_BV(1);
			else if (scancode == 0x14) // left/right ctrl
				mods &= (extended) ? ~_BV(3) : ~_BV(2);
		}
		else // handling a key press; store character
		{
			if (scancode == 0x12) // left shift
				mods |= _BV(0);
			else if (scancode == 0x59) // right shift
				mods |= _BV(1);
			else if (scancode == 0x14) // left/right ctrl
				mods |= (extended) ? _BV(3) : _BV(2);
			else if (scancode <= 0x83)
			{
				u8 chr;
				if (extended)
					chr = codetable_extended[scancode];
				else if (mods & 0b1100) // ctrl
					chr = codetable[scancode] & 31;
				else if (mods & 0b0011) // shift
					chr = codetable_shifted[scancode];
				else
					chr = codetable[scancode];
				
				if (!chr) chr = '?';
				
				/* add to buffer */
				charbuf[charbufhead++] = chr;
			}
		}
		extended = 0;
		keyup = 0;
	}
}

/**
  * @brief  This function handles EXTI0_IRQHandler interrupt request.
            The interrupt is generated on STHL transition
  * @param  None
  * @retval None
  */
void EXTI0_IRQHandler(void)
{
  /* Clear the EXTI line 0 pending bit */
  EXTI_ClearITPendingBit(EXTI_Line0);

	/* figure out what the keyboard is sending us */
	--kbitcount;
	if (kbitcount >= 2 && kbitcount <= 9)
	{
		tmpscancode >>= 1;
		if (GPIOB->IDR & GPIO_Pin_1)
			tmpscancode |= 0x80;
	}
	else if (kbitcount == 0)
	{
    scancode=tmpscancode;
		kbitcount = 11;
    decode(scancode);
	}
}

