
/* Includes ------------------------------------------------------------------*/
#include "window.h"
#include "video.h"

/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;
extern uint8_t FrameBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];
extern const uint8_t Font8x10[256][10];

/* Private variables ---------------------------------------------------------*/
WINDOW* Windows[MAX_WINDOWS+1];
WINDOW* Focus;
uint16_t nevent;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

/**
  * @brief  This function adds a control to a window.
  * @param  hpar,hwin
  * @retval None
  */
void AddControl(WINDOW* hpar,WINDOW* hwin)
{
  WINDOW* hcld;
  hcld=hpar;
  while (hcld->control)
  {
    hcld=hcld->control;
  }
  hcld->control=hwin;
}

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
  * @brief  This function draws transparent an inverted character at x, y.
  * @param  x, y, chr
  * @retval None
  */
void DrawFBChar(uint16_t x, uint16_t y, uint8_t chr)
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
  * @brief  This function draws a string with length len at x, y.
  * @param  x, y, len, *str
  * @retval None
  */
void DrawFBString(uint16_t x, uint16_t y,uint8_t len, uint8_t *str)
{
  uint8_t chr;
  while (len)
  {
    DrawFBChar(x, y, *str);
    x+=TILE_WIDTH;
    str++;
    len--;
  }
}

/**
  * @brief  This function draws a black rectangle.
  * @param  x,y,wdt,hgt)
  * @retval None
  */
void FrameRect(uint16_t x,uint16_t y,uint16_t wdt,uint16_t hgt)
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
  * @brief  This function draws a window caption.
  * @param  hwin
  * @retval None
  */
void DrawCaption(WINDOW* hwin,uint16_t x,uint16_t y)
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
    DrawFBString(x,y,hwin->caplen,hwin->caption);
  }
}

/**
  * @brief  This function draws a window.
  * @param  hwin
  * @retval None
  */
void DrawWindow(WINDOW* hwin)
{
  uint32_t x,y,xm,ym,i,j,k;
  uint8_t cl,cr;
  WINDOW* hpar;

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
      /* Get left fill */
      cl=0xFF<<(x & 7);
      /* Get right fill */
      cr=0xFF>>(8-(xm & 7));
      if ((hwin->style & 3)==STYLE_NOCAPTION)
      {
        /* Fill left & right*/
        j=y+1;
        i=x>>3;
        k=xm>>3;
        while (j<ym-1)
        {
          FrameBuff[j][i] |= cl;
          FrameBuff[j][k] |= cr;
          j++;
        }
        j=y+1;
        while (j<ym-1)
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
      else
      {
        if ((!(hwin->state & STATE_FOCUS)) && (FrameCount & 1))
        {
          /* Fill left & right*/
          j=y+1;
          i=x>>3;
          k=xm>>3;
          while (j<ym-1)
          {
            if (j<y+14)
            {
              FrameBuff[j][i] &= ~cl;
              FrameBuff[j][k] &= ~cr;
            }
            else
            {
              FrameBuff[j][i] |= cl;
              FrameBuff[j][k] |= cr;
            }
            j++;
          }
          j=y+1;
          while (j<ym-1)
          {
            i=(x>>3)+1;
            k=xm>>3;
            while (i<k)
            {
              if (j<y+14)
              {
                FrameBuff[j][i] = 0x0;
              }
              else
              {
                FrameBuff[j][i] = 0xFF;
              }
              i++;
            }
            j++;
          }
        }
        else
        {
          /* Fill left & right*/
          j=y+1;
          i=x>>3;
          k=xm>>3;
          while (j<ym-1)
          {
            if (j==y+14)
            {
              FrameBuff[j][i] &= ~cl;
              FrameBuff[j][k] &= ~cr;
            }
            else
            {
              FrameBuff[j][i] |= cl;
              FrameBuff[j][k] |= cr;
            }
            j++;
          }
          j=y+1;
          while (j<ym-1)
          {
            i=(x>>3)+1;
            k=xm>>3;
            while (i<k)
            {
              if (j==y+14)
              {
                FrameBuff[j][i] = 0x0;
              }
              else
              {
                FrameBuff[j][i] = 0xFF;
              }
              i++;
            }
            j++;
          }
        }
        DrawCaption(hwin,x,y+2);
      }
      FrameRect(x,y,xm-x,ym-y);
      break;
    case CLASS_BUTTON:
      if (hwin->state & STATE_FOCUS)
      {
        FrameRect(x,y,xm-x,ym-y);
      }
      else
      {
        if (FrameCount & 1)
        {
          /* Draw black to make the button appear gray */
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
      }
      y=y+(hwin->ht-TILE_HEIGHT)/2;
      DrawCaption(hwin,x,y);
      break;
    case CLASS_STATIC:
      y=y+(hwin->ht-TILE_HEIGHT)/2;
      DrawCaption(hwin,x,y);
      break;
  }
  if (hwin->control)
  {
    DrawWindow(hwin->control);
  }
}

/**
  * @brief  This function handles default window events.
  * @param  hwin, event, param, ID
  * @retval None
  */
void DefWindowHandler(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID)
{
  WINDOW* howner;
  uint32_t i;

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
      if (hwin->winclass==CLASS_WINDOW)
      {
        hwin->state|=(uint8_t)STATE_FOCUS;
      }
      else if (hwin->style & STYLE_CANFOCUS)
      {
        hwin->state|=(uint8_t)STATE_FOCUS;
        Focus=hwin;
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
        /* Make it visible */
        hwin->state|=STATE_VISIBLE;
        /* Bring window to front */
        i=0;
        while (i<MAX_WINDOWS && hwin!=Windows[i])
        {
          i++;
        }
        if (Windows[i+1])
        {
          while (i<MAX_WINDOWS-1 && Windows[i+1])
          {
            Windows[i]=Windows[i+1];
            i++;
          }
          Windows[i]=hwin;
        }
        if (i)
        {
          Windows[i-1]->state&=(uint8_t)~STATE_FOCUS;
          Focus=0;
        }
        hwin->state|=STATE_FOCUS;
        howner=hwin;
        /* Find control with focus */
        hwin=hwin->control;
        while (hwin)
        {
          if (hwin->state & STATE_FOCUS)
          {
            Focus=hwin;
            break;
          }
          hwin=hwin->control;
        }
        if (!hwin)
        {
          /* No sontrol had focus, find first control that can have focus */
          hwin=howner->control;
          while (hwin)
          {
            if (hwin->style & STYLE_CANFOCUS)
            {
              hwin->state|=STATE_FOCUS;
              Focus=hwin;
              break;
            }
            hwin=hwin->control;
          }
        }
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
        SendEvent(howner,event,param,ID);
      }
      break;
    default:
      howner=hwin->owner;
      if (howner)
      {
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
void SendEvent(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID)
{
  hwin->handler(hwin,event,param,ID);
}

void RemoveWindows(void)
{
  uint32_t i;

  Focus=0;
  i=0;
  while (i<MAX_WINDOWS)
  {
    Windows[i]=0;
    i++;
  }
}
