
/* Includes ------------------------------------------------------------------*/
#include "window.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern uint8_t FrameBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];
extern const uint8_t Font8x10[256][10];
extern TIMER timer;

/* Private variables ---------------------------------------------------------*/
WINDOW WinColl[MAX_WINCOLL];      // Holds windows and controls data
WINDOW* Windows[MAX_WINDOWS+1];   // Pointers to WinColl, windows only
WINDOW* Focus;
uint16_t FocusBlink;

const uint8_t UncheckedIcon[10][10] = {
{0,0,0,0,0,0,0,0,0,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,0,0,0,0,0,0,0,0,0}
};

const uint8_t CheckedIcon[10][10] = {
{0,0,0,0,0,0,0,0,0,0},
{0,1,1,1,1,1,1,1,1,0},
{0,1,0,1,1,1,1,1,1,0},
{0,1,1,0,1,1,1,0,1,0},
{0,1,1,0,1,1,0,1,1,0},
{0,1,1,0,1,0,1,1,1,0},
{0,1,1,0,0,1,1,1,1,0},
{0,1,1,0,1,1,1,1,1,0},
{0,1,1,1,1,1,1,1,1,0},
{0,0,0,0,0,0,0,0,0,0}
};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

/**
  * @brief  This function sets focus to next control
  * @param  hpar
  * @retval None
  */
void FocusNext(WINDOW* hpar)
{
  WINDOW* hnext;
  WINDOW* hfocus;

  /* Find control with focus */
  hfocus=hpar->control;
  hnext=0;
  while (hfocus)
  {
    if ((hfocus->state & STATE_FOCUS))
    {
      hnext=hfocus->control;
      break;
    }
    hfocus=hfocus->control;
  }
  /* Find control to set focus to */
  while (hnext)
  {
    if (hnext->style & STYLE_CANFOCUS)
    {
      break;
    }
    hnext=hnext->control;
  }
  if (!hnext)
  {
    hnext=hpar->control;
    while (hnext)
    {
      if (hnext->style & STYLE_CANFOCUS)
      {
        break;
      }
      hnext=hnext->control;
    }
  }
  if (hnext)
  {
    if (hfocus)
    {
      SendEvent(hfocus,EVENT_KILLFOCUS,0,hfocus->ID);
    }
    SendEvent(hnext,EVENT_SETFOCUS,0,hnext->ID);
  }
}

/**
  * @brief  This function sets focus to previous control
  * @param  hpar
  * @retval None
  */
void FocusPrevious(WINDOW* hpar)
{
  WINDOW* hnext;
  WINDOW* hprevious;
  WINDOW* hfocus;

  /* Find control with focus */
  hfocus=hpar->control;
  hnext=0;
  hprevious=0;

  while (hfocus)
  {
    if ((hfocus->state & STATE_FOCUS))
    {
      hnext=hfocus->control;
      break;
    }
    hfocus=hfocus->control;
  }
  if (!hfocus)
  {
    /* Find first control that can focus */
    hnext=hpar->control;
    while (hnext)
    {
      if (hnext->style & STYLE_CANFOCUS)
      {
        break;
      }
      hnext=hnext->control;
    }
  }
  else
  {
    while (hnext!=hfocus)
    {
      if (!hnext)
      {
        hnext=hpar;
      }
      if (hnext->style & STYLE_CANFOCUS)
      {
        hprevious=hnext;
      }
      hnext=hnext->control;
    }
  }
  if (hprevious)
  {
    if (hfocus)
    {
      SendEvent(hfocus,EVENT_KILLFOCUS,0,hfocus->ID);
    }
    SendEvent(hprevious,EVENT_SETFOCUS,0,hnext->ID);
  }
}

/**
  * @brief  This function draw a line from x1, y1 to x2,y2.
  * @param  x1, y1, x2, y2
  * @retval None
  */
void DrawWinLine(int16_t X1,int16_t Y1,int16_t X2,int16_t Y2)
{
  int16_t CurrentX, CurrentY, Xinc, Yinc, 
           Dx, Dy, TwoDx, TwoDy, 
           TwoDxAccumulatedError, TwoDyAccumulatedError;
  uint8_t bit;

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
  // SetFBPixel(X1,Y1);
  if (X1 < SCREEN_WIDTH && Y1 < SCREEN_HEIGHT)
  {
    bit = 1 << (X1 & 0x7);
    FrameBuff[Y1][X1 >> 3] |= bit;
  }

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
        // SetFBPixel(CurrentX,CurrentY);
        if (CurrentX < SCREEN_WIDTH && CurrentY < SCREEN_HEIGHT)
        {
          bit = 1 << (CurrentX & 0x7);
          FrameBuff[CurrentY][CurrentX >> 3] |= bit;
        }
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
        // SetFBPixel(CurrentX,CurrentY);
        if (CurrentX < SCREEN_WIDTH && CurrentY < SCREEN_HEIGHT)
        {
          bit = 1 << (CurrentX & 0x7);
          FrameBuff[CurrentY][CurrentX >> 3] |= bit;
        }
      }while (CurrentY != Y2);
    }
  }
}

/**
  * @brief  This function draws transparent a black character at x, y.
  * @param  x, y, chr
  * @retval None
  */
void DrawBlackWinChar(uint16_t x, uint16_t y, uint8_t chr)
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
        if (cx < SCREEN_WIDTH && cy < SCREEN_HEIGHT)
        {
          bit = 1 << ((x+cx) & 0x7);
          FrameBuff[y+cy][(x+cx >> 3)] &= ~bit;
        }
      }
      cl=cl<<1;
      cx++;
    }
    cy++;
  }
}

/**
  * @brief  This function draws transparent a white character at x, y.
  * @param  x, y, chr
  * @retval None
  */
void DrawWhiteWinChar(uint16_t x, uint16_t y, uint8_t chr)
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
        if (cx < SCREEN_WIDTH && cy < SCREEN_HEIGHT)
        {
          bit = 1 << ((x+cx) & 0x7);
          FrameBuff[y+cy][(x+cx >> 3)] |= bit;
        }
      }
      cl=cl<<1;
      cx++;
    }
    cy++;
  }
}

/**
  * @brief  This function draws opaque a character at x, y.
  * @param  x, y, chr
  * @retval None
  */
void DrawWinChar(uint16_t x, uint16_t y, uint8_t chr)
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
      bit = 1 << ((x+cx) & 0x7);
      if (cl & 0x80)
      {
        if (cx < SCREEN_WIDTH && cy < SCREEN_HEIGHT)
        {
          FrameBuff[y+cy][(x+cx >> 3)] |= bit;
        }
      }
      else
      {
        if (cx < SCREEN_WIDTH && cy < SCREEN_HEIGHT)
        {
          FrameBuff[y+cy][(x+cx >> 3)] &= ~bit;
        }
      }
      cl=cl<<1;
      cx++;
    }
    cy++;
  }
}

/**
  * @brief  This function draws a string with length len at x, y with color c (0=black, 1=white).
  * @param  x, y, len, *str, c
  * @retval None
  */
void DrawWinString(uint16_t x, uint16_t y,uint8_t len, uint8_t *str,uint8_t c)
{
  switch (c)
  {
    case 0:
      while (len)
      {
        DrawBlackWinChar(x, y, *str);
        x+=TILE_WIDTH;
        str++;
        len--;
      }
      break;
    case 1:
      while (len)
      {
        DrawWhiteWinChar(x, y, *str);
        x+=TILE_WIDTH;
        str++;
        len--;
      }
      break;
    case 2:
      while (len)
      {
        DrawWhiteWinChar(x, y, *str | 0x80);
        x+=TILE_WIDTH;
        str++;
        len--;
      }
      break;
    case 3:
      while (len)
      {
        DrawWinChar(x, y, *str);
        x+=TILE_WIDTH;
        str++;
        len--;
      }
      break;
    case 4:
      while (len)
      {
        DrawWinChar(x, y, *str | 0x80);
        x+=TILE_WIDTH;
        str++;
        len--;
      }
      break;
  }
}

/**
  * @brief  This function draws a 32bit decimal value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawWinDec32(uint16_t x, uint16_t y, uint32_t n, uint8_t c)
{
	uint8_t decstr[10];
  uint8_t i,d;
  uint32_t dm;

  i=0;
  dm=1000000000;
  while (i<10)
  {
    d=n/dm;
    n-=d*dm;
    decstr[i]=d | 0x30;
    i++;
    dm /=10;
  }
  i=0;
  while (i<9 && decstr[i]==0x30)
  {
    decstr[i]=0x20;
    i++;
  }
  if (c & 4)
  {
    /* Right aligned */
    x+=i*TILE_WIDTH;
  }
  DrawWinString(x,y,10-i,&decstr[i],c & 3);
}

/**
  * @brief  This function draws a 16bit decimal value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawWinDec16(uint16_t x, uint16_t y, uint16_t n, uint8_t c)
{
	uint8_t decstr[5];
  uint8_t i,d;
  uint16_t dm;

  i=0;
  dm=10000;
  while (i<5)
  {
    d=n/dm;
    n-=d*dm;
    decstr[i]=d | 0x30;
    i++;
    dm /=10;
  }
  i=0;
  while (i<4 && decstr[i]==0x30)
  {
    decstr[i]=0x20;
    i++;
  }
  if (c & 4)
  {
    /* Right aligned */
    x+=i*TILE_WIDTH;
  }
  DrawWinString(x,y,5-i,&decstr[i],c & 3);
}

/**
  * @brief  This function draws a 8 bit hex value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawWinHex8(uint16_t x, uint16_t y, uint8_t n, uint8_t c)
{
	static uint8_t hexchars[] = "0123456789ABCDEF";
	uint8_t hexstr[2];

	hexstr[0] = hexchars[(n >> 4) & 0xF];
	hexstr[1] = hexchars[n & 0xF];
  DrawWinString(x,y,2,hexstr,c);
}

/**
  * @brief  This function draws a 8 bit binary value at x, y.
  * @param  x, y, n, c
  * @retval None
  */
void DrawWinBin8(uint16_t x, uint16_t y, uint8_t n, uint8_t c)
{
  uint8_t i=0;

  while (i<8)
  {
    if (n & 0x80)
    {
      if (c)
      {
        DrawWhiteWinChar(x,y,0x31);
      }
      else
      {
        DrawBlackWinChar(x,y,0x31);
      }
    }
    else
    {
      if (c)
      {
        DrawWhiteWinChar(x,y,0x30);
      }
      else
      {
        DrawBlackWinChar(x,y,0x30);
      }
    }
    x+=8;
    n<<=1;
    i++;
  }
}

/**
  * @brief  This function draws an icon
  * @param  x, y, icon
  * @retval None
  */
void DrawWinIcon(uint16_t x,uint16_t y,ICON* icon)
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
      /* Set / Clear bit */
      if (cb)
      {
        SetFBPixel(i,y);
      }
      else
      {
        ClearFBPixel(i,y);
      }
      }
      i++;
      picon++;
    }
    y++;
  }
}

/**
  * @brief  This function draws a black rectangle.
  * @param  x,y,wdt,hgt)
  * @retval None
  */
void BlackWinFrame(uint16_t x,uint16_t y,uint16_t wdt,uint16_t hgt)
{
  uint16_t j;

  for (j = 0; j < hgt; j++) {
		ClearFBPixel(x, y + j);
		ClearFBPixel(x + wdt - 1, y + j);
	}
  for (j = 0; j < wdt; j++)	{
		ClearFBPixel(x + j, y);
		ClearFBPixel(x + j, y + hgt - 1);
	}
}

/**
  * @brief  This function draws a white rectangle.
  * @param  x,y,wdt,hgt)
  * @retval None
  */
void WhiteWinFrame(uint16_t x,uint16_t y,uint16_t wdt,uint16_t hgt)
{
  uint16_t j;

  for (j = 0; j < hgt; j++) {
		SetFBPixel(x, y + j);
		SetFBPixel(x + wdt - 1, y + j);
	}
  for (j = 0; j < wdt; j++)	{
		SetFBPixel(x + j, y);
		SetFBPixel(x + j, y + hgt - 1);
	}
}

/**
  * @brief  This function draws a white filled rectangle.
  * @param  x,y,xm,ym
  * @retval None
  */
void WhiteWinRect(uint16_t x,uint16_t y,uint16_t xm,uint16_t ym)
{
  uint32_t i,j,k;
  uint8_t cl,cr;

  /* Draw black */
  /* Get left fill */
  cl=0xFF<<(x & 7);
  /* Get right fill */
  cr=0xFF>>(8-(xm & 7));
  /* Fill left & right*/
  j=y;
  i=x>>3;
  k=xm>>3;
  while (j<ym)
  {
    FrameBuff[j][i] |= cl;
    FrameBuff[j][k] |= cr;
    j++;
  }
  j=y;
  while (j<ym)
  {
    i=(x>>3)+1;
    k=xm>>3;
    while (i<k)
    {
      FrameBuff[j][i] = 0xFF;
      i++;
    }
    j++;
  }
}

/**
  * @brief  This function draws a black filled rectangle.
  * @param  x,y,xm,ym
  * @retval None
  */
void BlackWinRect(uint16_t x,uint16_t y,uint16_t xm,uint16_t ym)
{
  uint32_t i,j,k;
  uint8_t cl,cr;

  /* Draw black */
  /* Get left fill */
  cl=0xFF<<(x & 7);
  /* Get right fill */
  cr=0xFF>>(8-(xm & 7));
  /* Fill left & right*/
  j=y;
  i=x>>3;
  k=xm>>3;
  while (j<ym)
  {
    FrameBuff[j][i] &= ~cl;
    FrameBuff[j][k] &= ~cr;
    j++;
  }
  j=y;
  while (j<ym)
  {
    i=(x>>3)+1;
    k=xm>>3;
    while (i<k)
    {
      FrameBuff[j][i] = 0;
      i++;
    }
    j++;
  }
}

/**
  * @brief  This function draws a window caption (Black).
  * @param  hwin
  * @retval None
  */
void DrawWinCaption(WINDOW* hwin,uint16_t x,uint16_t y)
{
  if (hwin->caplen)
  {
    switch (hwin->style & 0x0C)
    {
      case STYLE_LEFT:
        x+=2;
        break;
      case STYLE_CENTER:
        x+=(hwin->wt-hwin->caplen*TILE_WIDTH)/2;
        break;
      case STYLE_RIGHT:
        x+=(hwin->wt-hwin->caplen*TILE_WIDTH)-2;
        break;
    }
    DrawWinString(x,y,hwin->caplen,hwin->caption,0);
  }
}

/**
  * @brief  This function draws a window caption (Black).
  * @param  hwin
  * @retval None
  */
void DrawWhiteWinCaption(WINDOW* hwin,uint16_t x,uint16_t y)
{
  if (hwin->caplen)
  {
    switch (hwin->style & 0x0C)
    {
      case STYLE_LEFT:
        x+=2;
        break;
      case STYLE_CENTER:
        x+=(hwin->wt-hwin->caplen*TILE_WIDTH)/2;
        break;
      case STYLE_RIGHT:
        x+=(hwin->wt-hwin->caplen*TILE_WIDTH)-2;
        break;
    }
    DrawWinString(x,y,hwin->caplen,hwin->caption,1);
  }
}

/**
  * @brief  This function draws a window.
  * @param  hwin
  * @retval None
  */
void DrawWindow(WINDOW* hwin)
{
  uint32_t x,y,xm,ym;
  WINDOW* hpar;
  ICON icon;

  x=hwin->x;
  y=hwin->y;
  if (hwin->owner)
  {
    hpar=hwin->owner;
    x+=hpar->x;
    y+=hpar->y;
  }
  xm=x+hwin->wt;
  ym=y+hwin->ht;
  switch (hwin->winclass)
  {
    case CLASS_WINDOW:
      if ((hwin->style & 3)==STYLE_NOCAPTION)
      {
        WhiteWinRect(x,y,xm,ym);
      }
      else
      {
        if ((!(hwin->state & STATE_FOCUS)) && (FrameCount & 1))
        {
          BlackWinRect(x,y,xm,y+13);
        }
        else
        {
          WhiteWinRect(x,y,xm,y+13);
          DrawWinCaption(hwin,x,y+2);
        }
        WhiteWinRect(x,y+14,xm,ym);
      }
      BlackWinFrame(x,y,xm-x,ym-y);
      break;
    case CLASS_BUTTON:
      if (hwin->state & STATE_FOCUS)
      {
        if ((FrameCount & 7)==0)
        {
          FocusBlink ^=1;
        }
        if (FocusBlink)
        {
          BlackWinFrame(x,y,xm-x,ym-y);
        }
        y=y+(hwin->ht-TILE_HEIGHT)/2;
        DrawWinCaption(hwin,x,y);
      }
      else
      {
        BlackWinFrame(x,y,xm-x,ym-y);
        y=y+(hwin->ht-TILE_HEIGHT)/2;
        DrawWinCaption(hwin,x,y);
      }
      break;
    case CLASS_STATIC:
      if ((hwin->style & 3)==STYLE_BLACK)
      {
        BlackWinRect(x,y,xm,ym);
      }
      else if ((hwin->style & 3)==STYLE_GRAY)
      {
        if (FrameCount & 1)
        {
          BlackWinRect(x,y,xm,ym);
        }
        else
        {
          y=y+(hwin->ht-TILE_HEIGHT)/2;
          DrawWinCaption(hwin,x,y);
        }
      }
      else
      {
        y=y+(hwin->ht-TILE_HEIGHT)/2;
        DrawWinCaption(hwin,x,y);
      }
      break;
    case CLASS_CHKBOX:
      icon.wt=10;
      icon.ht=10;
      if (hwin->state & STATE_CHECKED)
      {
        icon.icondata=*CheckedIcon;
      }
      else
      {
        icon.icondata=*UncheckedIcon;
      }
      y=y+(hwin->ht-TILE_HEIGHT)/2;
      if (hwin->style & STYLE_RIGHT)
      {
        DrawWinIcon(x+hwin->wt-10,y,&icon);
        DrawWinString(x,y,hwin->caplen,hwin->caption,0);
      }
      else
      {
        DrawWinIcon(x,y,&icon);
        DrawWinString(x+12,y,hwin->caplen,hwin->caption,0);
      }
      break;
    case CLASS_GROUPBOX:
      BlackWinFrame(x,y+5,xm-x,ym-y-5);
      DrawWinString(x+5,y,hwin->caplen,hwin->caption,4);
      break;
  }
  if (hwin->control)
  {
    hwin=hwin->control;
    SendEvent(hwin,EVENT_PAINT,0,hwin->ID);
  }
}

/**
  * @brief  This function finds a window from a point.
  * @param  x,y
  * @retval hwin
  */
WINDOW* WindowFromPoint(uint16_t x,uint16_t y)
{
  uint32_t i;
  WINDOW* hwin;

  i=MAX_WINDOWS;

  while (i)
  {
    i--;
    if (Windows[i])
    {
      hwin=Windows[i];
      if ((hwin->state & STATE_VISIBLE) && (hwin->style & STYLE_CANFOCUS))
      {
        if ((x>=hwin->x) && (x<hwin->x+hwin->wt))
        {
          if ((y>=hwin->y) && (y<hwin->y+hwin->ht))
          {
            /* Found the window */
            return hwin;
          }
        }
      }
    }
  }
  /* No window found */
  return 0;
}

/**
  * @brief  This function finds a control from a point.
  * @param  howner,x,y
  * @retval hwin
  */
WINDOW* ControlFromPoint(WINDOW* howner,uint16_t x,uint16_t y)
{
  uint32_t i;
  WINDOW* hwin;

  hwin=howner->control;
  while (hwin)
  {
    if (hwin->state & STATE_VISIBLE)
    {
      if (x>=hwin->x && x<hwin->x+hwin->wt)
      {
        if (y>=hwin->y && y<hwin->y+hwin->ht)
        {
          /* Found the control */
          return hwin;
        }
      }
    }
    hwin=hwin->control;
  }
  /* No control found */
  return 0;
}

/**
  * @brief  This function finds a windpws position.
  * @param  hwin
  * @retval Windows Index
  */
uint32_t FindWindowPos(WINDOW* hwin)
{
  uint32_t i=0;

  while (i<MAX_WINDOWS)
  {
    if (hwin==Windows[i])
    {
      break;
    }
    i++;
  }
  return i;
}

/**
  * @brief  This function finds a control with focus.
  * @param  hwin
  * @retval hwin
  */
WINDOW* FindControlFocus(WINDOW* hwin)
{
  hwin=hwin->control;
  while (hwin)
  {
    if (hwin->state & STATE_FOCUS)
    {
      break;
    }
    hwin=hwin->control;
  }
  return hwin;
}

/**
  * @brief  This function finds first control that can focus.
  * @param  hwin
  * @retval hwin
  */
WINDOW* FindControlCanFocus(WINDOW* hwin)
{
  hwin=hwin->control;
  while (hwin)
  {
    if (hwin->style & STYLE_CANFOCUS)
    {
      break;
    }
    hwin=hwin->control;
  }
  return hwin;
}

/**
  * @brief  This function brigs a windpw to front.
  * @param  hwin
  * @retval Windows Index
  */
uint32_t WindowToFront(WINDOW* hwin)
{
  uint32_t i;
  WINDOW* hctl;

  /* Find the windows position */
  i=FindWindowPos(hwin);
  /* Bring window to front */
  while (i<MAX_WINDOWS-1 && Windows[i+1])
  {
    Windows[i]=Windows[i+1];
    i++;
  }
  Windows[i]=hwin;
  if (i)
  {
    /* Remove focus from previous window */
    Windows[i-1]->state&=(uint8_t)~STATE_FOCUS;
  }
  /* Make the window visible and give it focus */
  hwin->state|=(STATE_VISIBLE | STATE_FOCUS);
  /* Find control with focus */
  hctl=FindControlFocus(hwin);
  if (!hctl)
  {
    /* Find control that can have focus */
    hctl=FindControlCanFocus(hwin);
    if (hctl)
    {
      hctl->state |= STATE_FOCUS;
    }
  }
  Focus=hctl;
  return i;
}

/**
  * @brief  This function handles default window events.
  * @param  hwin, event, param, ID
  * @retval None
  */
uint32_t DefWindowHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  WINDOW* howner;
  WINDOW* hctl;
  uint32_t i,x,y;

  switch (event)
  {
    case EVENT_PAINT:
      DrawWindow(hwin);
      break;
    case EVENT_SHOW:
      if (param & STATE_VISIBLE)
      {
        hwin->state|=STATE_VISIBLE;
      }
      else
      {
        hwin->state&=~STATE_VISIBLE;
      }
      break;
    case EVENT_SETFOCUS:
      if (hwin->style & STYLE_CANFOCUS)
      {
        hwin->state|=(uint8_t)STATE_FOCUS;
        if (hwin->winclass!=CLASS_WINDOW)
        {
          Focus=hwin;
        }
      }
      break;
    case EVENT_KILLFOCUS:
      hwin->state&=(uint8_t)~STATE_FOCUS;
      if (hwin==Focus)
      {
        Focus=0;
      }
      break;
    case EVENT_ACTIVATE:
      if (hwin->winclass==CLASS_WINDOW)
      {
        i=WindowToFront(hwin);
      }
      break;
    case EVENT_CHAR:
      howner=hwin->owner;
      if (howner)
      {
        if (param==0x09)    // Tab
        {
          FocusNext(howner);
          break;
        }
        if (hwin->winclass==CLASS_CHKBOX && param==0x0D)
        {
          hwin->state^=STATE_CHECKED;
        }
        SendEvent(howner,event,param,ID);
      }
      break;
    case EVENT_LCLICK:
      SendEvent(hwin,EVENT_CHAR,0x0D,hwin->ID);
      break;
    default:
      howner=hwin->owner;
      if (howner)
      {
        /* Send the event to the owner */
        SendEvent(howner,event,param,ID);
      }
      break;
  }
}

/**
  * @brief  This function sends an event to a window
  * @param  hwin, event, param, ID
  * @retval None
  */
uint32_t SendEvent(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  hwin->handler(hwin,event,param,ID);
}

/**
  * @brief  This function returns a free WinColl pointer.
  * @param  None
  * @retval Window handle
  */
WINDOW* FindFree(void)
{
  uint32_t i=0;

  while (i<MAX_WINCOLL)
  {
    if (!WinColl[i].hwin)
    {
      return &WinColl[i];
    }
    i++;
  }
  return 0;
}

/**
  * @brief  This function returns the lenght of a zero terminated string.
  * @param  str
  * @retval lenght of string
  */
uint8_t StrLen(uint8_t *str)
{
  uint32_t len=0;
  uint8_t chr;
  while ((*str++))
  {
    len++;
  }
  return len;
}

/**
  * @brief  This function adds a control to a window.
  * @param  hpar,hwin
  * @retval None
  */
void AddControl(WINDOW* hwin,WINDOW* hctl)
{
  while (hwin->control)
  {
    hwin=hwin->control;
  }
  hwin->control=hctl;
}

/**
  * @brief  This function adds a window to Windows collection.
  * @param  hwin
  * @retval None
  */
void AddWindow(WINDOW* hwin)
{
  uint32_t i=0;

  while (i<MAX_WINDOWS)
  {
    if (!Windows[i])
    {
      Windows[i]=hwin;
      break;
    }
    i++;
  }
}

/**
  * @brief  This function creates a window.
  * @param  howner,winclass,ID,x,y,wt,ht,caption
  * @retval window handle
  */
WINDOW* CreateWindow(WINDOW* howner,uint8_t winclass,uint8_t ID,uint16_t x,uint16_t y,uint16_t wt,uint16_t ht,uint8_t *caption)
{
  WINDOW* hwin;

  hwin=FindFree();
  if (hwin)
  {
    hwin->hwin=hwin;
    hwin->owner=howner;
    hwin->param=0;
    hwin->winclass=winclass;
    hwin->ID=ID;
    hwin->x=x;
    hwin->y=y;
    hwin->wt=wt;
    hwin->ht=ht;
    hwin->caplen=0;
    hwin->caption=caption;
    if (caption)
    {
      hwin->caplen=StrLen(caption);
    }
    hwin->control=0;
    switch (winclass)
    {
      case CLASS_WINDOW:
        hwin->state=DEF_WINSTATE;
        hwin->style=DEF_WINSTYLE;
        break;
      case CLASS_BUTTON:
        hwin->state=DEF_BTNSTATE;
        hwin->style=DEF_BTNSTYLE;
        break;
      case CLASS_STATIC:
        hwin->state=DEF_STCSTATE;
        hwin->style=DEF_STCSTYLE;
        break;
      case CLASS_CHKBOX:
        hwin->state=DEF_CHKSTATE;
        hwin->style=DEF_CHKSTYLE;
        break;
      case CLASS_GROUPBOX:
        hwin->state=DEF_GROUPSTATE;
        hwin->style=DEF_GROUPSTYLE;
        break;
    }
    hwin->handler=(void*)&DefWindowHandler;
    if (howner)
    {
      AddControl(howner,hwin);
    }
    else
    {
      AddWindow(hwin);
    }
  }
  return hwin;
}

/**
  * @brief  This function destroys a window.
  * @param  hwin
  * @retval None
  */
void DestroyWindow(WINDOW* hwin)
{
  WINDOW* hctl;
  uint32_t i=0;

  if (!hwin->owner)
  {
    while (i<MAX_WINDOWS)
    {
      if (hwin=Windows[i])
      {
        break;
      }
    }
    while (i<MAX_WINDOWS)
    {
      Windows[i]=Windows[i+1];
      i++;
    }
    /* Destroy controls */
    hctl=hwin->control;
    while (hctl)
    {
      hctl=hctl->control;
      hctl->hwin=0;
    }
    hwin->hwin=0;
  }
}

/**
  * @brief  This function sets the window handler function.
  * @param  hwin,hdlr
  * @retval None
  */
void SetHandler(WINDOW* hwin,void* hdlr)
{
  hwin->handler=hdlr;
}

/**
  * @brief  This function gets a controls window handle.
  * @param  howner,ID
  * @retval wwindow handle
  */
WINDOW* GetControlHandle(WINDOW* howner,uint8_t ID)
{
  WINDOW* hctl;

  hctl=howner->control;
  while (hctl)
  {
    if (ID==hctl->ID)
    {
      return hctl;
    }
    hctl=hctl->control;
  }
  return hctl;
}

/**
  * @brief  This function sets a controls caption.
  * @param  hwin,*caption
  * @retval none
  */
void SetCaption(WINDOW* hwin,uint8_t *caption)
{
  hwin->caplen=0;
  hwin->caption=caption;
  if (caption)
  {
    hwin->caplen=StrLen(caption);
  }
}

/**
  * @brief  This function sets a controls style.
  * @param  hwin,style
  * @retval none
  */
void SetStyle(WINDOW* hwin,uint8_t style)
{
  hwin->style=style;
}

/**
  * @brief  This function sets a controls state.
  * @param  hwin,state
  * @retval none
  */
void SetState(WINDOW* hwin,uint8_t state)
{
  hwin->state=state;
}

/**
  * @brief  This function clears a controls state.
  * @param  hwin,state
  * @retval none
  */
void ClearState(WINDOW* hwin,uint8_t state)
{
  hwin->state&=~state;
}

/**
  * @brief  This function sets a controls param.
  * @param  hwin,param
  * @retval none
  */
void SetParam(WINDOW* hwin,uint32_t param)
{
  hwin->param=param;
}

/**
  * @brief  This function creates the timer.
  * @param  tmr
  * @retval none
  */
void CreateTimer(TIMER tmr)
{
  timer=tmr;
}

/**
  * @brief  This function destroyes the timer.
  * @param  none
  * @retval none
  */
void KillTimer(void)
{
  timer=0;
}

