/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "video.h"

/* Private variables ---------------------------------------------------------*/
uint8_t PixelBuff[SCREEN_WIDTH+2];
uint8_t ScreenChars[SCREEN_HEIGHT][SCREEN_WIDTH];
static uint8_t cx;
static uint8_t cy;
static uint8_t showcursor;

/* Private function prototypes -----------------------------------------------*/
void video_show_cursor();
void video_hide_cursor();
void video_scrollup();
void video_cls();
void video_cfwd();
void video_lfwd();
void video_lf();
void * memmove(void *dest, void *source, uint32_t count);
void * memset(void *dest, uint32_t c, uint32_t count); 

/* Private functions ---------------------------------------------------------*/

static void CURSOR_INVERT()
{
  ScreenChars[cy][cx] ^= showcursor;
}

static void _video_scrollup()
{
  memmove(&ScreenChars[0],&ScreenChars[1], (SCREEN_HEIGHT-1)*SCREEN_WIDTH);
  memset(&ScreenChars[SCREEN_HEIGHT-1], 0, SCREEN_WIDTH);
}

static void _video_lfwd()
{
  cx = 0;
  if (++cy > SCREEN_HEIGHT-1)
  {
    cy = SCREEN_HEIGHT-1;
    _video_scrollup();
  }
}

static inline void _video_cfwd()
{
  if (++cx > SCREEN_WIDTH-1)
    _video_lfwd();
}

static inline void _video_putc(char c)
{
  /* If the last character printed exceeded the right boundary,
   * we have to go to a new line. */
  if (cx >= SCREEN_WIDTH) _video_lfwd();

  if (c == '\r') cx = 0;
  else if (c == '\n') _video_lfwd();
  else
  {
    ScreenChars[cy][cx] = c;
    _video_cfwd();
  }
}

/*******************************************************************************
* Function Name  : video_show_cursor
* Description    : This function shows the cursor
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_show_cursor()
{
  if (!showcursor)
  {
    showcursor = 0x80;
    CURSOR_INVERT();
  }
}

/*******************************************************************************
* Function Name  : video_hide_cursor
* Description    : This function hides the cursor
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_hide_cursor()
{
  if (showcursor)
  {
    CURSOR_INVERT();
    showcursor = 0;
  }
}

/*******************************************************************************
* Function Name  : video_scrollup
* Description    : This function scrolls the screen up
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_scrollup()
{
  CURSOR_INVERT();
  _video_scrollup();
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_cls
* Description    : This function clears the screen and homes the cursor
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_cls()
{
  CURSOR_INVERT();
  memset(&ScreenChars, 0, SCREEN_HEIGHT*SCREEN_WIDTH);
  cx=0;
  cy=0;
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_cfwd
* Description    : This function 
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_cfwd()
{
  CURSOR_INVERT();
  _video_cfwd();
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_lfwd
* Description    : This function handles a crlf
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_lfwd()
{
  CURSOR_INVERT();
  cx = 0;
  if (++cy > SCREEN_HEIGHT-1)
  {
    cy = SCREEN_HEIGHT-1;
    _video_scrollup();
  }
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_lf
* Description    : This function handles a lf
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void video_lf()
{
  CURSOR_INVERT();
  if (++cy > SCREEN_HEIGHT-1)
  {
    cy = SCREEN_HEIGHT-1;
    _video_scrollup();
  }
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_putc
* Description    : This function prints a character
* Input          : Character
* Output         : None
* Return         : None
*******************************************************************************/
void video_putc(char c)
{
  CURSOR_INVERT();
  _video_putc(c);
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_puts
* Description    : This function prints a zero terminated string
* Input          : Zero terminated string
* Output         : None
* Return         : None
*******************************************************************************/
void video_puts(char *str)
{
  /* Characters are interpreted and printed one at a time. */
  char c;
  CURSOR_INVERT();
  while ((c = *str++))
    _video_putc(c);
  CURSOR_INVERT();
}

/*******************************************************************************
* Function Name  : video_puthex
* Description    : This function prints a byte as hex
* Input          : Byte
* Output         : None
* Return         : None
*******************************************************************************/
void video_puthex(u8 n)
{
	static char hexchars[] = "0123456789ABCDEF";
	char hexstr[5];
	hexstr[0] = hexchars[(n >> 4) & 0xF];
	hexstr[1] = hexchars[n & 0xF];
	hexstr[2] = '\r';
	hexstr[3] = '\n';
	hexstr[4] = '\0';
  video_puts(hexstr);
}

