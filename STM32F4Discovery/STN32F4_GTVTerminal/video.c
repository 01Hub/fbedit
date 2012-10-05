
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
#include "video.h"
#include "Font8x10.h"

/* External variables --------------------------------------------------------*/
extern WINDOW* Windows[];
extern WINDOW* Focus;
extern volatile uint16_t scancode;


/* Private variables ---------------------------------------------------------*/
uint8_t BackBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];
uint8_t FrameBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];
volatile int16_t LineCount;
volatile uint16_t FrameCount;
volatile uint16_t FrameSkip;
volatile int8_t BackPochFlag;
SPRITE Cursor;
SPRITE* Sprites[MAX_SPRITES];
volatile uint8_t FrameDraw;
volatile uint32_t RNDSeed;          // Random seed
TIMER timer;
volatile uint32_t pcount, frequency;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

/**
  * @brief  This function generates a random number
  * @param  None
  * @retval None
  */
uint32_t Random(uint32_t Range)
{
  uint32_t rnd;
  RNDSeed=(((RNDSeed*23+7) & 0xFFFFFFFF)>>1)^RNDSeed;
  rnd=RNDSeed-(RNDSeed/Range)*Range;
  return rnd;
}

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
  memset(&BackBuff, 0, SCREEN_BUFFHEIGHT*SCREEN_BUFFWIDTH);
}

/**
  * @brief  This function sets / clears a pixel at x, y.
  * @param  x, y, c
  * @retval None
  */
void SetPixel(uint16_t x,uint16_t y,uint8_t c)
{
  uint8_t bit;
  if (x < SCREEN_WIDTH && y < SCREEN_HEIGHT)
  {
    bit = 1 << (x & 0x7);
    if (c)
    {
      BackBuff[y][x >> 3] |= bit;
    }
    else
    {
      BackBuff[y][x >> 3] &= ~bit;
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
  if (x < SCREEN_WIDTH && y < SCREEN_HEIGHT)
  {
    bit = 1 << (x & 0x7);
    return ((BackBuff[y][x >> 3]) & bit) > 0;
  }
  return 0;
}

/**
  * @brief  This function draws a character at x, y.
  * @param  x, y, chr, c
  * @retval None
  */
void DrawChar(uint16_t x, uint16_t y, uint8_t chr, uint8_t c)
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
void DrawLargeChar(uint16_t x, uint16_t y, uint8_t chr, uint8_t c)
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
void DrawString(uint16_t x, uint16_t y, uint8_t *str, uint8_t c)
{
  uint8_t chr;
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
void DrawLargeString(uint16_t x, uint16_t y, uint8_t *str, uint8_t c)
{
  uint8_t chr;
  while ((chr = *str++))
  {
    DrawLargeChar(x, y, chr, c);
    x+=TILE_WIDTH*2;
  }
}

/**
  * @brief  This function draws a 16bit decimal value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawDec16(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
	uint8_t decstr[6];
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
  while (i<4 && decstr[i]==0x30)
  {
    decstr[i]=0x20;
    i++;
  }
  DrawString(x,y,decstr,c);
}

/**
  * @brief  This function draws a 16 bit decimal value using large font at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawLargeDec16(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
	uint8_t decstr[6];
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
  while (i<4 && decstr[i]==0x30)
  {
    decstr[i]=0x20;
    i++;
  }
  DrawLargeString(x,y,decstr,c);
}

/**
  * @brief  This function draws a 16 bit hex value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawHex16(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
	static uint8_t hexchars[] = "0123456789ABCDEF";
	uint8_t hexstr[5];
	hexstr[0] = hexchars[(n >> 12) & 0xF];
	hexstr[1] = hexchars[(n >> 8) & 0xF];
	hexstr[2] = hexchars[(n >> 4) & 0xF];
	hexstr[3] = hexchars[n & 0xF];
	hexstr[4] = '\0';
  DrawString(x,y,hexstr,c);
}

/**
  * @brief  This function draws a 16 bit binary value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawBin16(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
  uint8_t i;
  i=0;
  while (i<16)
  {
    if (n & 0x8000)
    {
      DrawChar(x,y,0x31,1);
    }
    else
    {
      DrawChar(x,y,0x30,1);
    }
    x+=8;
    n<<=1;
    i++;
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
void Line(int16_t X1,int16_t Y1,int16_t X2,int16_t Y2, uint8_t c)
{
  int16_t CurrentX, CurrentY, Xinc, Yinc, 
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
  * @brief  This function draws an icon
  * @param  x, y, icon, c
  * @retval None
  */
void DrawIcon(uint16_t x,uint16_t y,ICON* icon,uint8_t c)
{
  uint32_t xm,ym,i;
  uint8_t cb;
  const uint8_t *picon;

  /* Draw the icon */
  ym=y+icon->ht;
  xm=x+icon->wt;
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
  memmove(&BackBuff[0], &BackBuff[1], (SCREEN_BUFFHEIGHT-1)*SCREEN_BUFFWIDTH);
  memset(&BackBuff[SCREEN_BUFFHEIGHT-1], 0, SCREEN_BUFFWIDTH);
}

/**
  * @brief  This function scrolls the screen 1 line down
  * @param  None
  * @retval None
  */
void ScrollDown(void)
{
  uint16_t y=SCREEN_BUFFHEIGHT-1;
  while (y)
  {
    memmove(&BackBuff[y], &BackBuff[y-1], SCREEN_BUFFWIDTH);
    y--;
  }
  memset(&BackBuff[0], 0, SCREEN_BUFFWIDTH);
}

/**
  * @brief  This function draws the status bar
  * @param  *str,caps,num
  * @retval None
  */
void DrawStatus(uint8_t *str,uint8_t caps,uint8_t num)
{
  uint32_t i;
  uint8_t chr;
  static uint8_t ccaps[]="|CAPS\0";
  static uint8_t cnocaps[]="|    \0";
  static uint8_t cnum[]="|NUM|\0";
  static uint8_t cnonum[]="|   |\0";

  i=0;
  if (str)
  {
    while ((chr = *str++))
    {
      DrawChar(i, 240, chr, 3);
      i+=TILE_WIDTH;
    }
  }
  while (i<SCREEN_WIDTH-10*TILE_WIDTH)
  {
    DrawChar(i,240,0x80,1);
    i+=TILE_WIDTH;
  }
  if (caps)
  {
    DrawString(SCREEN_WIDTH-10*TILE_WIDTH,240,ccaps,3);
  }
  else
  {
    DrawString(SCREEN_WIDTH-10*TILE_WIDTH,240,cnocaps,3);
  }
  if (num)
  {
    DrawString(SCREEN_WIDTH-5*TILE_WIDTH,240,cnum,3);
  }
  else
  {
    DrawString(SCREEN_WIDTH-5*TILE_WIDTH,240,cnonum,3);
  }
}

/*********** Draw onto FrameBuff ***********/

/**
  * @brief  This function clears a pixel at x, y.
  * @param  x, y
  * @retval None
  */
void ClearFBPixel(uint16_t x,uint16_t y)
{
  uint8_t bit;
  if (x < SCREEN_WIDTH && y < SCREEN_HEIGHT)
  {
    bit = 1 << (x & 0x7);
    FrameBuff[y][x >> 3] &= ~bit;
  }
}

/**
  * @brief  This function sets a pixel at x, y.
  * @param  x, y
  * @retval None
  */
void SetFBPixel(uint16_t x,uint16_t y)
{
  uint8_t bit;
  if (x < SCREEN_WIDTH && y < SCREEN_HEIGHT)
  {
    bit = 1 << (x & 0x7);
    FrameBuff[y][x >> 3] |= bit;
  }
}

/**
  * @brief  This function draws a sprite
  * @param  None
  * @retval None
  */
uint32_t DrawSprite(const SPRITE* ps)
{
  uint32_t x,y,xm,ym;
  uint8_t bt,coll,cb;
  const uint8_t *picon;

  coll=0;
  /* Draw the sprite */
  ym=ps->y+ps->icon.ht;
  if (ym>SCREEN_HEIGHT)
  {
    ym=SCREEN_HEIGHT;
  }
  xm=ps->x+ps->icon.wt;
  if (xm>SCREEN_WIDTH)
  {
    xm=SCREEN_WIDTH;
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
        if (BackBuff[y][x >> 3] & bt)
        {
          coll |= COLL_BACKGROUND;
        }
        /* Test collision with another sprite */
        else if (FrameBuff[y][x >> 3] & bt)
        {
          coll |= COLL_SPRITE;
        }
        /* Set / Clear bit */
        if (cb)
        {
          FrameBuff[y][x >> 3] |= bt;
        }
        else
        {
          FrameBuff[y][x >> 3] &= ~bt;
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
  * @brief  This function removes all sprites
  * @param  None
  * @retval None
  */
void RemoveSprites(void)
{
  uint32_t i;

  while (i<MAX_SPRITES)
  {
    Sprites[i]=0;
    i++;
  }
}

/**
  * @brief  This function waits n lines
  * @param  n
  * @retval None
  */
void LineWait(uint32_t n)
{
  uint16_t lc;

  while (n)
  {
    lc=LineCount;
    while (lc==LineCount);
    n--;
  }
}

/**
  * @brief  This function waits n frames
  * @param  n
  * @retval None
  */
void FrameWait(uint32_t n)
{
  uint16_t fc;

  while (n)
  {
    fc=FrameCount;
    while (fc==FrameCount);
    n--;
  }
}

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  uint32_t i;
  static volatile uint32_t lcnt;

  /* Clear the IT pending Bit */
  TIM3->SR=(u16)~TIM_IT_Update;
  /* This loop eliminate differences in interrupt latency */
  i=32-(TIM3->CNT);
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
  lcnt++;
  if (lcnt==625*25)
  {
    i=TIM2->CNT;
    frequency=i-pcount;
    pcount=i;
    lcnt=0;
  }
  if (LineCount<SCREEN_HEIGHT)
  {
    /* Disable DMA1 Stream4 */
    DMA1_Stream4->CR &= ~((uint32_t)DMA_SxCR_EN);
    /* Reset interrupt pending bits for DMA1 Stream4 */
    DMA1->HIFCR = (uint32_t)(DMA_LISR_FEIF0 | DMA_LISR_DMEIF0 | DMA_LISR_TEIF0 | DMA_LISR_HTIF0 | DMA_LISR_TCIF0 | (uint32_t)0x20000000);
    DMA1_Stream4->NDTR = (uint16_t)SCREEN_BUFFWIDTH/2-1;
    DMA1_Stream4->PAR = (uint32_t) & (SPI2->DR);
    DMA1_Stream4->M0AR = (uint32_t) & (FrameBuff[LineCount]);
  }
}

/**
  * @brief  This function handles TIM4 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM4_IRQHandler(void)
{
  uint32_t i;

  /* Clear the IT pending Bit */
  TIM4->SR=(u16)~TIM_IT_Update;
  /* This loop eliminate differences in interrupt latency */
  i=32-(TIM4->CNT);
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
      if (FrameCount==(FrameCount/50)*50)
      {
        STM_EVAL_LEDToggle(LED3);
      }
      LineCount=-TOP_MARGIN;
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
      /* If frame drawing busy, skip a frame */
      if (!FrameDraw)
      {
        /* Enable TIM7 */
        TIM7->CR1=1;
      }
      else
      {
        FrameSkip++;
      }
    }
    LineCount++;
  }
}

void FrameBuffDraw(void)
{
  uint32_t i,pos,coll;

  /* Draw sprites onto WorkBuff */
  i=0;
  while (Sprites[i] && i<MAX_SPRITES)
  {
    coll=0;
    if (Sprites[i]->visible)
    {
      coll=DrawSprite(Sprites[i]);
      /* Boundary check */
      if (Sprites[i]->boundary)
      {
        pos=Sprites[i]->x;
        if ((int16_t)pos<=Sprites[i]->boundary->left)
        {
          coll|=COLL_LEFT;
        }
        pos+=Sprites[i]->icon.wt;
        if ((int16_t)pos>=Sprites[i]->boundary->right)
        {
          coll|=COLL_RIGHT;
        }
        pos=Sprites[i]->y;
        if ((int16_t)pos<=Sprites[i]->boundary->top)
        {
          coll|=COLL_TOP;
        }
        pos+=Sprites[i]->icon.ht;
        if ((int16_t)pos>=Sprites[i]->boundary->bottom)
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
  while (Windows[i] && i<MAX_WINDOWS)
  {
    if (Windows[i]->state & STATE_VISIBLE)
    {
      Windows[i]->handler(Windows[i],EVENT_PAINT,0,0);
    }
    i++;
  }
  /* Draw cursor */
  if (Cursor.visible)
  {
    DrawSprite(&Cursor);
  }
}

/**
  * @brief  This function handles TIM7 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM7_IRQHandler(void)
{
  uint32_t *pd,*ps,i;
  uint8_t chr;

  /* Disable TIM7 */
  TIM7->CR1=0;
  /* Clear the IT pending Bit */
  TIM7->SR=(u16)~TIM_IT_Update;
  FrameDraw=1;
  /* Copy ScreenBuff to WorkBuff */
  pd=(uint32_t *)&FrameBuff;
  ps=(uint32_t *)&BackBuff;
  i=0;
  while (i<SCREEN_BUFFHEIGHT*SCREEN_BUFFWIDTH/4)
  {
    pd[i]=ps[i];
    i++;
  }
  FrameBuffDraw();
  KeyboardReset();
  if (Focus)  {
    chr=GetChar();
    if (chr)
    {
      Focus->handler(Focus,EVENT_CHAR,chr,Focus->ID);
    }
  }
  if (timer)
  {
    timer();
  }
  GetMouseClick();
  FrameCount++;
  FrameDraw=0;
}

