
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

#define TERM_SCREEN_WIDTH      60
#define TERM_SCREEN_HEIGHT     24

/* Private function prototypes -----------------------------------------------*/
void rs232_putc(uint8_t c);
void rs232_puts(uint8_t *str);
void * memmove(void *dest, void *source, uint32_t count);
void * memset(void *dest, uint32_t c, uint32_t count); 

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;  // Frame counter
extern volatile uint8_t Caps;
extern volatile uint8_t Num;

/* Private variables ---------------------------------------------------------*/
uint8_t rs232buf[256];
volatile uint8_t rs232buftail;
volatile uint8_t rs232bufhead;
volatile uint32_t cx,cy;
volatile uint8_t showcursor;
volatile uint8_t ScreenChars[TERM_SCREEN_HEIGHT][TERM_SCREEN_WIDTH];

/**
  * @brief  This function transmits a character
  * @param  Character
  * @retval None
  */
void rs232_putc(uint8_t c)
{
  /* Wait until transmit register empty*/
  while((USART2->SR & USART_FLAG_TXE) == 0);          
  /* Transmit Data */
  USART2->DR = (u16)c;
}

/**
  * @brief  This function transmits a zero terminated string
  * @param  Zero terminated string
  * @retval None
  */
void rs232_puts(uint8_t *str)
{
  uint8_t c;
  /* Characters are transmitted one at a time. */
  while ((c = *str++))
    rs232_putc(c);
}

/**
  * @brief  This function handles USART2_IRQHandler interrupt request.
            An interrupt is generated when a character is recieved
  * @param  None
  * @retval None
  */
void USART2_IRQHandler(void)
{
  rs232buf[rs232bufhead++]=USART2->DR;
  USART2->SR = (u16)~USART_FLAG_RXNE;
}

static void CURSOR_INVERT()
{
  ScreenChars[cy][cx] ^= showcursor;
}

static void _video_scrollup()
{
  memmove(&ScreenChars[0],&ScreenChars[1], (TERM_SCREEN_HEIGHT-1)*TERM_SCREEN_WIDTH);
  memset(&ScreenChars[TERM_SCREEN_HEIGHT-1], 0, TERM_SCREEN_WIDTH);
}

static void _video_lfwd()
{
  cx = 0;
  if (++cy > TERM_SCREEN_HEIGHT-1)
  {
    cy = TERM_SCREEN_HEIGHT-1;
    _video_scrollup();
  }
}

static inline void _video_cfwd()
{
  if (++cx > TERM_SCREEN_WIDTH-1)
    _video_lfwd();
}

static inline void _video_putc(uint8_t c)
{
  /* If the last character printed exceeded the right boundary,
   * we have to go to a new line. */
  if (cx >= TERM_SCREEN_WIDTH) _video_lfwd();

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
  memset(&ScreenChars, 0, TERM_SCREEN_HEIGHT*TERM_SCREEN_WIDTH);
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
  if (++cy > TERM_SCREEN_HEIGHT-1)
  {
    cy = TERM_SCREEN_HEIGHT-1;
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
  if (++cy > TERM_SCREEN_HEIGHT-1)
  {
    cy = TERM_SCREEN_HEIGHT-1;
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
void video_putc(uint8_t c)
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
void video_puts(uint8_t *str)
{
  /* Characters are interpreted and printed one at a time. */
  uint8_t c;
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
	static uint8_t hexchars[] = "0123456789ABCDEF";
	uint8_t hexstr[5];
	hexstr[0] = hexchars[(n >> 4) & 0xF];
	hexstr[1] = hexchars[n & 0xF];
	hexstr[2] = '\r';
	hexstr[3] = '\n';
	hexstr[4] = '\0';
  video_puts(hexstr);
}

void RefreshScreen(void)
{
  uint32_t scx,scy,gx,gy;
  uint8_t chr;

  scy=0;
  gy=0;
  while (scy<TERM_SCREEN_HEIGHT)
  {
    scx=0;
    gx=0;
    while (scx<TERM_SCREEN_WIDTH)
    {
      chr=ScreenChars[scy][scx];
      DrawChar(gx,gy,chr,1);
      scx++;
      gx+=8;
    }
    scy++;
    gy+=10;
  }
}

void CapsNum(uint8_t caps,uint8_t num)
{
  uint32_t i,x;
  static uint8_t ccaps[]="|CAPS";
  static uint8_t cnocaps[]="|    ";
  static uint8_t cnum[]="|NUM|";
  static uint8_t cnonum[]="|   |";

  i=0;
  while (i<SCREEN_WIDTH-10*TILE_WIDTH)
  {
    DrawChar(i,240,0x80,1);
    i+=TILE_WIDTH;
  }
  x=0;
  if (caps)
  {
    while (x<5)
    {
      DrawChar(i,240,ccaps[x]|0x80,1);
      x++;
      i+=TILE_WIDTH;
    }
  }
  else
  {
    while (x<5)
    {
      DrawChar(i,240,cnocaps[x]|0x80,1);
      x++;
      i+=TILE_WIDTH;
    }
  }
  x=0;
  if (num)
  {
    while (x<5)
    {
      DrawChar(i,240,cnum[x]|0x80,1);
      x++;
      i+=TILE_WIDTH;
    }
  }
  else
  {
    while (x<5)
    {
      DrawChar(i,240,cnonum[x]|0x80,1);
      x++;
      i+=TILE_WIDTH;
    }
  }
}

void Terminal(void)
{
  uint8_t chr,caps,num;
  uint32_t i,Quit;

  RemoveWindows();
  video_show_cursor();
  video_cls();
  RefreshScreen();
  Quit=0;
  while (!Quit)
  {
    if (i!=FrameCount)
    {
      i=FrameCount;
      chr=GetChar();
      switch (chr)
      {
        case 0x00:
          break;
        case 0x1B:
          if (GetKeyState(SC_L_CTRL) | GetKeyState(SC_R_CTRL))
          {
            Quit=1;
          }
          else
          {
            rs232_putc(chr);
          }
          break;
        case 0x0D:
          rs232_putc(chr);
          rs232_putc(0x0A);
        default:
          rs232_putc(chr);
      }
    }
    if (caps!=Caps || num!=Num)
    {
      caps=Caps;
      num=Num;
      CapsNum(caps,num);
    }
    if (rs232buftail!=rs232bufhead)
    {
      chr=rs232buf[rs232buftail++];
      video_putc(chr);
      RefreshScreen();
    }
  }
}
