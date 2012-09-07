
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
uint8_t WorkBuff[SCREEN_HEIGHT][SCREEN_WIDTH];
__IO int16_t LineCount;
__IO uint16_t FrameCount;
__IO int8_t BackPochFlag;
SPRITE Cursor;
// __IO TIME time;
SPRITE* Sprites[MAX_SPRITES];
WINDOW* Windows[MAX_WINDOWS];

/* Private function prototypes -----------------------------------------------*/
void SetCursor(uint8_t cur);
void MoveCursor(uint16_t x,uint16_t y);
void ShowCursor(uint8_t z);
void Cls(void);
void SetPixel(uint16_t x,uint16_t y,uint8_t c);
uint8_t GetPixel(uint16_t x,uint16_t y);
void DrawChar(uint16_t x, uint16_t y, char chr, uint8_t c);
void DrawLargeChar(uint16_t x, uint16_t y, char chr, uint8_t c);
void DrawString(uint16_t x, uint16_t y, char *str, uint8_t c);
void DrawLargeString(uint16_t x, uint16_t y, char *str, uint8_t c);
void DrawDec(uint16_t x, uint16_t y, uint16_t n, uint8_t c);
void DrawLargeDec(uint16_t x, uint16_t y, uint16_t n, uint8_t c);
void DrawHex(uint16_t x, uint16_t y, uint16_t n, uint8_t c);
void Rectangle(uint16_t x, uint16_t y, uint16_t b, uint16_t a, uint8_t c);
void Circle(uint16_t cx, uint16_t cy, uint16_t radius, uint8_t c);
void Line(uint16_t X1,uint16_t Y1,uint16_t X2,uint16_t Y2, uint8_t c);
void DrawIcon(uint16_t x,uint16_t y,ICON* icon,uint8_t c);
void ScrollUp(void);
void ScrollDown(void);
uint32_t DrawSprite(const SPRITE* ps);

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
    Cursor.visible=1;     // Show
  }
  else
  {
    Cursor.visible=0;     // Hide
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
  * @brief  This function draws a character using large font at x, y.
  * @param  x, y, chr, c
  * @retval None
  */
void DrawLargeChar(uint16_t x, uint16_t y, char chr, uint8_t c)
{
  uint8_t cl;
  uint16_t cx, cy;

  cy=0;
  switch (c)
  {
    case 0:
    case 2:
      /* Clear opaque and inverted opaque */
      while (cy<TILE_HEIGHT*2)
      {
        cx=0;
        while (cx<TILE_WIDTH*2)
        {
          SetPixel(x+cx,y+cy,0);
          SetPixel(x+cx+1,y+cy,0);
          SetPixel(x+cx,y+cy+1,0);
          SetPixel(x+cx+1,y+cy+1,0);
          cx+=2;
        }
        cy+=2;
      }
      break;
    case 3:
      chr ^= 0x80;
    case 1:
      /* Draw opaque and inverted opaque */
      while (cy<TILE_HEIGHT*2)
      {
        cl=Font8x10[chr][cy/2];
        cx=0;
        while (cx<TILE_WIDTH*2)
        {
          SetPixel(x+cx,y+cy,(cl & 0x80));
          SetPixel(x+cx+1,y+cy,(cl & 0x80));
          SetPixel(x+cx,y+cy+1,(cl & 0x80));
          SetPixel(x+cx+1,y+cy+1,(cl & 0x80));
          cl=cl<<1;
          cx+=2;
        }
        cy+=2;
      }
      break;
    case 6:
      chr ^= 0x80;
    case 4:
      /* Clear transparent and inverted transparent */
      while (cy<TILE_HEIGHT*2)
      {
        cl=Font8x10[chr][cy];
        cx=0;
        while (cx<TILE_WIDTH*2)
        {
          if (cl & 0x80)
          {
            SetPixel(x+cx,y+cy,0);
            SetPixel(x+cx+1,y+cy,0);
            SetPixel(x+cx,y+cy+1,0);
            SetPixel(x+cx+1,y+cy+1,0);
          }
          cl=cl<<1;
          cx+=2;
        }
        cy+=2;
      }
      break;
    case 7:
      chr ^= 0x80;
    case 5:
      /* Draw transparent and inverted transparent */
      while (cy<TILE_HEIGHT*2)
      {
        cl=Font8x10[chr][cy];
        cx=0;
        while (cx<TILE_WIDTH*2)
        {
          if (cl & 0x80)
          {
            SetPixel(x+cx,y+cy,1);
            SetPixel(x+cx+1,y+cy,1);
            SetPixel(x+cx,y+cy+1,1);
            SetPixel(x+cx+1,y+cy+1,1);
          }
          cl=cl<<1;
          cx+=2;
        }
        cy+=2;
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
  * @brief  This function draws a zero terminated string using large font at x, y.
  * @param  x, y, *str, c
  * @retval None
  */
void DrawLargeString(uint16_t x, uint16_t y, char *str, uint8_t c)
{
  char chr;
  while ((chr = *str++))
  {
    DrawLargeChar(x, y, chr, c);
    x+=TILE_WIDTH*2;
  }
}

/**
  * @brief  This function draws a decimal value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawDec(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
	char decstr[6];
  int8_t i,d;

  d=n/10000;
  n-=d*10000;
  decstr[0]=d | 0x30;
  d=n/1000;
  n-=d*1000;
  decstr[1]=d | 0x30;
  d=n/100;
  n-=d*100;
  decstr[2]=d | 0x30;
  d=n/10;
  n-=d*10;
  decstr[3]=d | 0x30;
  decstr[4]=n | 0x30;
  decstr[5]='\0';
  i=0;
  while (i<4)
  {
    if (decstr[i]='0')
    {
      decstr[i]=' ';
    }
    i++;
  }
  DrawString(x,y,decstr,c);
}

/**
  * @brief  This function draws a decimal value using large font at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawLargeDec(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
	char decstr[6];
  int8_t i,d;

  d=n/10000;
  n-=d*10000;
  decstr[0]=d | 0x30;
  d=n/1000;
  n-=d*1000;
  decstr[1]=d | 0x30;
  d=n/100;
  n-=d*100;
  decstr[2]=d | 0x30;
  d=n/10;
  n-=d*10;
  decstr[3]=d | 0x30;
  decstr[4]=n | 0x30;
  decstr[5]='\0';
  i=0;
  while (i<4)
  {
    if (decstr[i]='0')
    {
      decstr[i]=' ';
    }
    i++;
  }
  DrawLargeString(x,y,decstr,c);
}

/**
  * @brief  This function draws a hex value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawHex(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
	static char hexchars[] = "0123456789ABCDEF";
	char hexstr[5];
	hexstr[0] = hexchars[(n >> 12) & 0xF];
	hexstr[1] = hexchars[(n >> 8) & 0xF];
	hexstr[2] = hexchars[(n >> 4) & 0xF];
	hexstr[3] = hexchars[n & 0xF];
	hexstr[4] = '\0';
  DrawString(x,y,hexstr,c);
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

void DrawIcon(uint16_t x,uint16_t y,ICON* icon,uint8_t c)
{
  uint32_t xm,ym,i;
  uint8_t cb,*picon;

  /* Draw the icon */
  ym=y+icon->ht;
  xm=x+icon->wt;
  // DrawHex(x,y,xm,1);
  // DrawHex(x,y+8,ym,1);
  picon=icon->icondata;
  while (y<ym)
  {
    i=x;
    while (i<xm)
    {
      cb=picon[0];
      if (cb!=2)
      {
        if (c)
        {
          /* Set / Clear bit */
          if (cb)
          {
            SetPixel(i,y, 1);
          }
          else
          {
            SetPixel(i,y, 0);
          }
        }
        else if (cb)
        {
          SetPixel(i,y, 0);
        }
      }
      i++;
      picon++;
    }
    y++;
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

uint32_t DrawSprite(const SPRITE* ps)
{
  uint32_t x,y,xm,ym;
  uint8_t bt,coll,cb,*picon;

  coll=0;
  /* Draw the sprite */
  ym=ps->y+ps->icon.ht;
  if (ym>SCREEN_HEIGHT)
  {
    ym=SCREEN_HEIGHT;
  }
  xm=ps->x+ps->icon.wt;
  if (xm>(SCREEN_WIDTH-4)*8)
  {
    xm=(SCREEN_WIDTH-4)*8;
  }
  y=ps->y;
  picon=ps->icon.icondata;
  while (y<ym)
  {
    x=ps->x;
    while (x<xm)
    {
      cb=picon[0];
      if (cb!=2)
      {
        bt = 1 << (x & 0x7);
        
        /* Test collision with background */
        if (ScreenBuff[y][x >> 3] & bt)
        {
          coll |= COLL_BACKGROUND;
        }
        /* Test collision with another sprite */
        else if (WorkBuff[y][x >> 3] & bt)
        {
          coll |= COLL_SPRITE;
        }
        /* Set / Clear bit */
        if (cb)
        {
          WorkBuff[y][x >> 3] |= bt;
        }
        else
        {
          WorkBuff[y][x >> 3] &= ~bt;
        }
      }
      x++;
      picon++;
    }
    y++;
  }
  return coll;
}

/**
  * @brief  This function draws transparent an inverted character at x, y.
  * @param  x, y, chr
  * @retval None
  */
void DrawWBChar(uint16_t x, uint16_t y, char chr)
{
  uint8_t cl,bit;
  uint16_t cx, cy;

  cy=0;
  while (cy<TILE_HEIGHT)
  {
    cl=Font8x10[chr][cy];
    cx=0;
    while (cx<TILE_WIDTH)
    {
      if (cl & 0x80)
      {
        if (cx < (SCREEN_WIDTH-4) * 8 && cy < SCREEN_HEIGHT)
        {
          bit = 1 << (cx & 0x7);
          WorkBuff[cy][cx >> 3] &= ~bit;
        }
      }
      cl=cl<<1;
      cx++;
    }
    cy++;
  }
}

/**
  * @brief  This function draws a zero terminated string at x, y.
  * @param  x, y, *str
  * @retval None
  */
void DrawWBString(uint16_t x, uint16_t y, char *str)
{
  char chr;
  while ((chr = *str++))
  {
    DrawWBChar(x, y, chr);
    x+=TILE_WIDTH;
  }
}

void DrawWindow(const WINDOW* win)
{
  int32_t x,y,xm,ym,i,j;
  uint8_t cl,cr;
  x=win->x;
  xm=x+win->wt;
  y=win->y;
  ym=y+win->ht;
  /* Get left fill */
  cl=0xFF>>((8-(x & 7)) & 7);
  /* Get right fill */
  cr=0xFF<<((8-(xm & 7)) & 7);
  /* Fill left & right*/
  j=y;
  while (j<ym)
  {
    WorkBuff[j][x >> 3] |= cl;
    WorkBuff[j][xm >> 3] |= cr;
    j++;
  }
  j=y;
  while (j<ym)
  {
    i=(x >> 3)+1;
    while (i<(xm >> 3)-1)
    {
      WorkBuff[j][i] = 0xFF;
      i++;
    }
    j++;
  }
  if (win->caption)
  {
    DrawWBString(x,y,win->caption);
  }
}

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  uint16_t i;

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
  BackPochFlag = 0;
  /* H-Sync or V-Sync low */
  GPIOA->BSRRH = (uint16_t)GPIO_Pin_1;
  if (LineCount<SCREEN_HEIGHT)
  {
    /* Disable DMA1 Stream4 */
    DMA1_Stream4->CR &= ~((uint32_t)DMA_SxCR_EN);
    /* Reset interrupt pending bits for DMA1 Stream4 */
    DMA1->HIFCR = (uint32_t)(DMA_LISR_FEIF0 | DMA_LISR_DMEIF0 | DMA_LISR_TEIF0 | DMA_LISR_HTIF0 | DMA_LISR_TCIF0 | (uint32_t)0x20000000);
    DMA1_Stream4->NDTR = (uint16_t)SCREEN_WIDTH/2;
    DMA1_Stream4->PAR = (uint32_t) & (SPI2->DR);
    DMA1_Stream4->M0AR = (uint32_t) & (WorkBuff[LineCount]);
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
  if (!BackPochFlag)
  {
    if (LineCount<SCREEN_HEIGHT+BOTTOM_MARGIN)
    {
      /* H-Sync high */
      GPIOA->BSRRL=(u16)GPIO_Pin_1;
    }
    else if (LineCount==SCREEN_HEIGHT+BOTTOM_MARGIN+V_SYNC)
    {
      /* V-Sync high */
      GPIOA->BSRRL=(u16)GPIO_Pin_1;
      LineCount=-(TOP_MARGIN+1);
    }
    /* Set TIM4 auto reload */
    TIM4->ARR=(84*BACK_POCH)/1000;                // 5,70uS
    BackPochFlag = 1;
  }
  else
  {
    /* Disable TIM4 */
    TIM4->CR1=0;
    if (LineCount>=0 && LineCount<SCREEN_HEIGHT)
    {
      /* Enable DMA1 Stream4 to keep the SPI port fed from the pixelbuffer. */
      DMA1_Stream4->CR |= (uint32_t)DMA_SxCR_EN;
    }
    else if (LineCount==SCREEN_HEIGHT)
    {
      /* Enable TIM5 */
      TIM5->CR1=1;
    }
    LineCount++;
  }
}

/**
  * @brief  This function handles TIM5 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM5_IRQHandler(void)
{
  uint32_t *pd,*ps,i,pos,coll;

  /* Disable TIM5 */
  TIM5->CR1=0;
  /* Clear the IT pending Bit */
  TIM5->SR=(u16)~TIM_IT_Update;
  /* Copy ScreenBuff to WorkBuff */
  pd=(uint32_t *)&WorkBuff;
  ps=(uint32_t *)&ScreenBuff;
  i=0;
  while (i<SCREEN_HEIGHT*SCREEN_WIDTH/4)
  {
    pd[i]=ps[i];
    i++;
  }
  /* Draw sprites onto WorkBuff */
  i=0;
  while (Sprites[i])
  {
    coll=0;
    if (Sprites[i]->visible)
    {
      coll=DrawSprite(Sprites[i]);
      /* Boundary check */
      if (Sprites[i]->boundary)
      {
        pos=Sprites[i]->x;
        if (pos<=Sprites[i]->boundary->left)
        {
          coll|=COLL_LEFT;
        }
        pos+=Sprites[i]->icon.wt;
        if (pos>=Sprites[i]->boundary->right)
        {
          coll|=COLL_RIGHT;
        }
        pos=Sprites[i]->y;
        if (pos<=Sprites[i]->boundary->top)
        {
          coll|=COLL_TOP;
        }
        pos+=Sprites[i]->icon.ht;
        if (pos>=Sprites[i]->boundary->bottom)
        {
          coll|=COLL_BOTTOM;
        }
      }
    }
    Sprites[i]->collision=coll;
    i++;
  }
  /* Draw windows onto WorkBuff */
  i=0;
  while (Windows[i])
  {
    if (Windows[i]->visible)
    {
      DrawWindow(Windows[i]);
    }
    i++;
  }
  /* Draw cursor */
  if (Cursor.visible)
  {
    DrawSprite(&Cursor);
  }

  //DrawHex(0,0,LineCount,1);
  FrameCount++;
}

