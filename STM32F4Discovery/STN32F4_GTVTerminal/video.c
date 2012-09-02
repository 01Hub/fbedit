/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "video.h"
#include "Font8x10.h"

/* Private variables ---------------------------------------------------------*/
uint8_t ScreenBuff[SCREEN_HEIGHT][SCREEN_WIDTH];

/* Private function prototypes -----------------------------------------------*/
void Cls(void);
void SetPixel(uint16_t x,uint16_t y,uint8_t c);
uint8_t GetPixel(uint16_t x,uint16_t y);
void DrawChar(uint16_t x, uint16_t y, char chr, uint8_t c);
void DrawString(uint16_t x, uint16_t y, char *str, uint8_t c);
void Rectangle(uint16_t x, uint16_t y, uint16_t b, uint16_t a, uint8_t c);
void Circle(uint16_t cx, uint16_t cy, uint16_t radius, uint8_t c);
void Line(uint16_t X1,uint16_t Y1,uint16_t X2,uint16_t Y2, uint8_t c);
void ScrollUp(void);
void ScrollDown(void);

void * memmove(void *dest, void *source, uint32_t count);
void * memset(void *dest, uint32_t c, uint32_t count); 

/* Private functions ---------------------------------------------------------*/

/**
  * @brief  This function clears the screen.
  * @param  None
  * @retval None
  */
void Cls(void)
{
  memset(&ScreenBuff[0], 0, SCREEN_HEIGHT*SCREEN_WIDTH);
}

/**
  * @brief  This function sets / clears a pixel at x, y.
  * @param  x, y, c
  * @retval None
  */
void SetPixel(uint16_t x,uint16_t y,uint8_t c)
{
  uint8_t bit;
  if (x < (SCREEN_WIDTH-2) * 8 && y < SCREEN_HEIGHT)
  {
    bit = 1 << (x & 0x7);
    if (c)
    {
      ScreenBuff[y][x >> 3] |= bit;
    }
    else
    {
      ScreenBuff[y][x >> 3] &= ~bit;
    }
  }
}

/**
  * @brief  This function gets a pixel at x, y.
  * @param  x, y
  * @retval 1 if set
  */
uint8_t GetPixel(uint16_t x,uint16_t y)
{
  uint8_t bit;
  if (x < (SCREEN_WIDTH-2) * 8 && y < SCREEN_HEIGHT)
  {
    bit = 1 << (x & 0x7);
    return ((ScreenBuff[y][x >> 3]) & bit) > 0;
  }
  return 0;
}

/**
  * @brief  This function draws a character at x, y.
  * @param  x, y, chr, c
  * @retval None
  */
void DrawChar(uint16_t x, uint16_t y, char chr, uint8_t c)
{
  uint8_t cl;
  uint16_t cx, cy;

  cy=0;
  while (cy<TILE_HEIGHT)
  {
    cl=Font8x10[chr][cy];
    cx=0;
    while (cx<TILE_WIDTH)
    {
      SetPixel(x+cx,y+cy,(cl & 0x80));
      cl=cl<<1;
      cx++;
    }
    cy++;
  }
}

/**
  * @brief  This function draws a zero terminated string at x, y.
  * @param  x, y, *str, c
  * @retval None
  */
void DrawString(uint16_t x, uint16_t y, char *str, uint8_t c)
{
  char chr;
  while ((chr = *str++))
  {
    DrawChar(x, y, chr, c);
    x+=8;
  }
}

/**
  * @brief  This function draw a rectangle at x, y with color c.
  * @param  x, y, b, a, c
  * @retval None
  */
void Rectangle(uint16_t x, uint16_t y, uint16_t wdt, uint16_t hgt, uint8_t c)
{
  uint16_t j;
  for (j = 0; j < hgt; j++) {
		SetPixel(x, y + j, c);
		SetPixel(x + wdt - 1, y + j, c);
	}
  for (j = 0; j < wdt; j++)	{
		SetPixel(x + j, y, c);
		SetPixel(x + j, y + hgt - 1, c);
	}
}

/**
  * @brief  This function draw a circle at x0, y0 with color c.
  * @param  x0, y0, radius, c
  * @retval None
  */
void Circle(uint16_t x0, uint16_t y0, uint16_t radius, uint8_t c)
{
  int f = 1 - radius;
  int ddF_x = 1;
  int ddF_y = -2 * radius;
  int x = 0;
  int y = radius;
 
  SetPixel(x0, y0 + radius, c);
  SetPixel(x0, y0 - radius, c);
  SetPixel(x0 + radius, y0, c);
  SetPixel(x0 - radius, y0, c);
 
  while(x < y)
  {
    if(f >= 0) 
    {
      y--;
      ddF_y += 2;
      f += ddF_y;
    }
    x++;
    ddF_x += 2;
    f += ddF_x;    
    SetPixel(x0 + x, y0 + y, c);
    SetPixel(x0 - x, y0 + y, c);
    SetPixel(x0 + x, y0 - y, c);
    SetPixel(x0 - x, y0 - y, c);
    SetPixel(x0 + y, y0 + x, c);
    SetPixel(x0 - y, y0 + x, c);
    SetPixel(x0 + y, y0 - x, c);
    SetPixel(x0 - y, y0 - x, c);
  }
}

/**
  * @brief  This function draw a line from x1, y1 to x2,y2 with color c.
  * @param  x1, y1, x2, y2, c
  * @retval None
  */
void Line(uint16_t X1,uint16_t Y1,uint16_t X2,uint16_t Y2, uint8_t c)
{
uint16_t CurrentX, CurrentY, Xinc, Yinc, 
         Dx, Dy, TwoDx, TwoDy, 
         TwoDxAccumulatedError, TwoDyAccumulatedError;

Dx = (X2-X1);
Dy = (Y2-Y1);

TwoDx = Dx + Dx;
TwoDy = Dy + Dy;

CurrentX = X1;
CurrentY = Y1;

Xinc = 1;
Yinc = 1;

if(Dx < 0)
  {
  Xinc = -1;
  Dx = -Dx;
  TwoDx = -TwoDx;
  }

if (Dy < 0)
  {
  Yinc = -1;
  Dy = -Dy;
  TwoDy = -TwoDy;
  }
SetPixel(X1,Y1, c);

if ((Dx != 0) || (Dy != 0))
  {
  if (Dy <= Dx)
    { 
    TwoDxAccumulatedError = 0;
    do
	  {
      CurrentX += Xinc;
      TwoDxAccumulatedError += TwoDy;
      if(TwoDxAccumulatedError > Dx)
        {
        CurrentY += Yinc;
        TwoDxAccumulatedError -= TwoDx;
        }
       SetPixel(CurrentX,CurrentY, c);
       }while (CurrentX != X2);
     }
   else
      {
      TwoDyAccumulatedError = 0; 
      do 
	    {
        CurrentY += Yinc; 
        TwoDyAccumulatedError += TwoDx;
        if(TwoDyAccumulatedError>Dy) 
          {
          CurrentX += Xinc;
          TwoDyAccumulatedError -= TwoDy;
          }
         SetPixel(CurrentX,CurrentY, c);
         }while (CurrentY != Y2);
    }
  }
}

/**
  * @brief  This function scrolls the screen 1 line up
  * @param  None
  * @retval None
  */
void ScrollUp(void)
{
  memmove(&ScreenBuff[0], &ScreenBuff[1], (SCREEN_HEIGHT-1)*SCREEN_WIDTH);
  memset(&ScreenBuff[SCREEN_HEIGHT-1], 0, SCREEN_WIDTH);
}

/**
  * @brief  This function scrolls the screen 1 line down
  * @param  None
  * @retval None
  */
void ScrollDown(void)
{
  uint16_t y=SCREEN_HEIGHT-1;
  while (y)
  {
    memmove(&ScreenBuff[y], &ScreenBuff[y-1], SCREEN_WIDTH);
    y--;
  }
  memset(&ScreenBuff[0], 0, SCREEN_WIDTH);
}
