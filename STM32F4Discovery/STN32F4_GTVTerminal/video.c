
/*******************************************************************************
* PAL timing Horizontal
* H-sync         4,70uS
* Back porch     5,70uS
* Active video  51,95uS
* Front porch    1,65uS
* Line total     64,0uS
*
* |                 64.00uS                      |
* |4,70|  5,70  |          51,95uS          |1,65|
*
*                ---------------------------
*               |                           |
*               |                           |
*               |                           |
*       --------                             ----
* |    |                                         |
* -----                                          ----
*
* PAL timing Vertical
* V-sync        0,576mS (9 lines)
* Frame         20mS (312,5 lines)
* Video signal  288 lines
*******************************************************************************/

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "video.h"
#include "Font8x10.h"

/* Private variables ---------------------------------------------------------*/
uint8_t ScreenBuff[SCREEN_HEIGHT][SCREEN_WIDTH];
uint8_t ScreenLine[SCREEN_WIDTH];
__IO uint16_t LineCount;
__IO uint16_t FrameCount;
__IO uint16_t BackPochFlag;
SPRITE Cursor;
__IO TIME time;

/* Private function prototypes -----------------------------------------------*/
void SetCursor(uint8_t cur);
void MoveCursor(uint16_t x,uint16_t y);
void ShowCursor(uint8_t z);
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
  * @brief  This function sets the cursor (mouse icon) type.
  * @param  cur
  * @retval None
  */
void SetCursor(uint8_t cur)
{
  switch (cur)
  {
    case 0:
      Cursor.icon.wt=8;
      Cursor.icon.ht=10;
      Cursor.icon.icondata=*SelectCur;
      break;
  }
}

/**
  * @brief  This function sets the cursor (mouse icon) position.
  * @param  x, y
  * @retval None
  */
void MoveCursor(uint16_t x,uint16_t y)
{
  Cursor.x=x;
  Cursor.y=y;
}

/**
  * @brief  This function show / hide the cursor (mouse icon).
  * @param  x, y
  * @retval None
  */
void ShowCursor(uint8_t z)
{
  if (z)
  {
    Cursor.z=0xFF;   // Show
  }
  {
    Cursor.z=0x0;  // Hide
  }
}

/**
  * @brief  This function clears the screen.
  * @param  None
  * @retval None
  */
void Cls(void)
{
  memset(&ScreenBuff, 0, SCREEN_HEIGHT*SCREEN_WIDTH);
}

/**
  * @brief  This function sets / clears a pixel at x, y.
  * @param  x, y, c
  * @retval None
  */
void SetPixel(uint16_t x,uint16_t y,uint8_t c)
{
  uint8_t bit;
  if (x < (SCREEN_WIDTH-4) * 8 && y < SCREEN_HEIGHT)
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
  switch (c)
  {
    case 0:
    case 2:
      /* Clear opaque and inverted opaque */
      while (cy<TILE_HEIGHT)
      {
        cx=0;
        while (cx<TILE_WIDTH)
        {
          SetPixel(x+cx,y+cy,0);
          cx++;
        }
        cy++;
      }
      break;
    case 3:
      chr ^= 0x80;
    case 1:
      /* Draw opaque and inverted opaque */
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
      break;
    case 6:
      chr ^= 0x80;
    case 4:
      /* Clear transparent and inverted transparent */
      while (cy<TILE_HEIGHT)
      {
        cl=Font8x10[chr][cy];
        cx=0;
        while (cx<TILE_WIDTH)
        {
          if (cl & 0x80)
          {
            SetPixel(x+cx,y+cy,0);
          }
          cl=cl<<1;
          cx++;
        }
        cy++;
      }
      break;
    case 7:
      chr ^= 0x80;
    case 5:
      /* Draw transparent and inverted transparent */
      while (cy<TILE_HEIGHT)
      {
        cl=Font8x10[chr][cy];
        cx=0;
        while (cx<TILE_WIDTH)
        {
          if (cl & 0x80)
          {
            SetPixel(x+cx,y+cy,1);
          }
          cl=cl<<1;
          cx++;
        }
        cy++;
      }
      break;
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
    x+=TILE_WIDTH;
  }
}

/**
  * @brief  This function draw a rectangle at x, y with color c.
  * @param  x, y, wdt, hgt, c
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

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  uint16_t i,x,ts,tt;
  uint8_t cx,cy,cb,bit;
  uint32_t *pd,*ps;

  /* Clear the IT pending Bit */
  TIM3->SR=(u16)~TIM_IT_Update;
  /* This loop eliminate differences in interrupt latency */
  i=32-((TIM3->CNT)>>1);
  while (i)
  {
    i--;
  }
  /* TIM4 is used to time the H-Sync (4,70uS) and the Back poch (5,70uS) */
  /* Set TIM4 auto reload */
  TIM4->ARR=(84*H_SYNC)/1000;                // 4,70uS
  /* Reset TIM4 count */
  TIM4->CNT=0;
  /* Enable TIM4 */
  TIM4->CR1=1;
  /* H-Sync or V-Sync low */
  GPIOA->BSRRH = (uint16_t)GPIO_Pin_1;
  if (LineCount<SCREEN_HEIGHT)
  {
    ts=TIM3->CNT;
    BackPochFlag = 0;
    /* Disable DMA1 Stream4 */
    DMA1_Stream4->CR &= ~((uint32_t)DMA_SxCR_EN);
    /* Reset interrupt pending bits for DMA1 Stream4 */
    DMA1->HIFCR = (uint32_t)(DMA_LISR_FEIF0 | DMA_LISR_DMEIF0 | DMA_LISR_TEIF0 | DMA_LISR_HTIF0 | DMA_LISR_TCIF0 | (uint32_t)0x20000000);
    DMA1_Stream4->NDTR = (uint16_t)SCREEN_WIDTH/2;
    DMA1_Stream4->PAR = (uint32_t) & (SPI2->DR);
    DMA1_Stream4->M0AR = (uint32_t) & (ScreenLine);
    /* Copy ScreenBuff[LineCount] to ScreenLine */
    pd=(uint32_t *)&ScreenLine;
    ps=(uint32_t *)&ScreenBuff[LineCount];
    x=0;
    while (x<15)
    {
      pd[x]=ps[x];
      x++;
    }
    /* Draw cursor icon */
    if (LineCount>=Cursor.y && LineCount<Cursor.y+Cursor.icon.ht && Cursor.z!=0)
    {
      x=Cursor.x;
      /* Get icon line */
      cy=LineCount-Cursor.y;
      cx=0;
      while (cx<8)
      {
        cb=Cursor.icon.icondata[cy*Cursor.icon.wt+cx];
        if (cb!=2)
        {
          /* Set / Clear bit */
          if (x < (SCREEN_WIDTH-4) * 8)
          {
            bit = 1 << (x & 0x7);
            if (cb)
            {
              ScreenLine[x >> 3] |= bit;
            }
            else
            {
              ScreenLine[x >> 3] &= ~bit;
            }
          }
        }
        x++;
        cx++;
      }
    }
    tt=(TIM3->CNT)-ts;
    if (tt>time.count)
    {
      time.count=tt;
    }
  }
}

/**
  * @brief  This function handles TIM4 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM4_IRQHandler(void)
{
  uint16_t i;

  /* Clear the IT pending Bit */
  TIM4->SR=(u16)~TIM_IT_Update;
  /* This loop eliminate differences in interrupt latency */
  i=32-((TIM4->CNT)>>1);
  while (i)
  {
    i--;
  }
  /* Set TIM4 auto reload */
  TIM4->ARR=(84*BACK_POCH)/1000;                // 5,70uS
  if (BackPochFlag)
  {
    /* Disable TIM4 */
    TIM4->CR1=0;
    if (LineCount<SCREEN_HEIGHT+BOTTOM_MARGIN)
    {
      /* H-Sync high */
      GPIOA->BSRRL=(u16)GPIO_Pin_1;
      if (LineCount<SCREEN_HEIGHT)
      {
        /* Enable DMA1 Stream4 to keep the SPI port fed from the pixelbuffer. */
        DMA1_Stream4->CR |= (uint32_t)DMA_SxCR_EN;
      }
    }
    else if (LineCount==SCREEN_HEIGHT+BOTTOM_MARGIN+V_SYNC)
    {
      /* V-Sync high after 313 lines) */
      GPIOA->BSRRL=(u16)GPIO_Pin_1;
      FrameCount++;
      LineCount=-(TOP_MARGIN+1);
    }
    LineCount++;
  }
  BackPochFlag = 1;
}

