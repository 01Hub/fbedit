
#include "stm32f4_discovery.h"
#include "video.h"
#include "window.h"
#include "mouse.h"

extern SPRITE Cursor;
extern WINDOW* Focus;

volatile uint8_t mousecode;
volatile uint8_t mbitcount = 11;
volatile uint8_t mbytecount = 0;
volatile uint8_t mb,pmb;
volatile int32_t mx,my;
volatile   uint8_t mclk;

void SendData(uint16_t d)
{
  uint32_t i;

  while (d)
  {
    if (d & 1)
    {
      GPIO_SetBits(GPIOB,GPIO_Pin_1);
    }
    else
    {
      GPIO_ResetBits(GPIOB,GPIO_Pin_1);
    }
    /* Wait until clock high */
    while (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_0)!=Bit_SET)
    {
    }
    /* Wait until clock low */
    while (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_0)==Bit_SET)
    {
    }
    d>>=1;
  }
}

void MouseInit(void)
{
  volatile uint32_t lc;
  GPIO_InitTypeDef GPIO_InitStructure;
  EXTI_InitTypeDef EXTI_InitStructure;
  NVIC_InitTypeDef NVIC_InitStructure;
  /* Configure PB1 and PB0 as open drain outputs */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_OD;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_2MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  GPIO_SetBits(GPIOB,GPIO_Pin_1 | GPIO_Pin_0);
  FrameWait(2);
  LineWait(1);
  /* Clock low */
  GPIO_ResetBits(GPIOB,GPIO_Pin_0);
  LineWait(2);
  TIM_Cmd(TIM3, DISABLE);
  /* Data low */
  GPIO_ResetBits(GPIOB,GPIO_Pin_1);
  /* Clock as input */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
  /* Clock high */
  GPIO_SetBits(GPIOB,GPIO_Pin_0);
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Wait until clock low */
  while (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_0)!=Bit_SET)
  {
  }
  /* Send the F4 command to the mouse */
  SendData(0b10111101000);
  /* GPIOB Pin3, Pin2, Pin1 and Pin0 as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4 | GPIO_Pin_2 | GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect EXTI Line0 to PB0 pin */
  SYSCFG_EXTILineConfig(EXTI_PortSourceGPIOB, EXTI_PinSource0);
  /* Configure EXTI Line0 */
  EXTI_InitStructure.EXTI_Line = EXTI_Line0;
  EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
  EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Falling;  
  EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  EXTI_Init(&EXTI_InitStructure);
  /* Connect EXTI Line2 to PB2 pin */
  SYSCFG_EXTILineConfig(EXTI_PortSourceGPIOB, EXTI_PinSource2);
  /* Configure EXTI Line2 */
  EXTI_InitStructure.EXTI_Line = EXTI_Line2;
  EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
  EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Falling;  
  EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  EXTI_Init(&EXTI_InitStructure);
  /* Enable and set EXTI Line0 Interrupt to low priority */
  NVIC_InitStructure.NVIC_IRQChannel = EXTI0_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable and set EXTI Line2 Interrupt to low priority */
  NVIC_InitStructure.NVIC_IRQChannel = EXTI2_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);
  FrameWait(2);
}

/**
  * @brief  This function handles EXTI2_IRQHandler interrupt request.
            The interrupt is generated on STHL transition
  * @param  None
  * @retval None
  */
void EXTI0_IRQHandler(void)
{
  /* Clear the EXTI line 2 pending bit */
  EXTI_ClearITPendingBit(EXTI_Line0);

	/* figure out what the mouse is sending us */
	--mbitcount;
	if (mbitcount >= 2 && mbitcount <= 9)
	{
		mousecode >>= 1;
		if (GPIOB->IDR & GPIO_Pin_1)
			mousecode |= 0x80;
	}
	else if (mbitcount == 0)
	{
		mbitcount = 11;
    switch (mbytecount)
    {
      case (0):
        mb=mousecode & 7;
        mbytecount++;
        break;
      case (1):
        mx=Cursor.x+(int8_t)mousecode;
        mbytecount++;
        break;
      case (2):
        my=Cursor.y-(int8_t)mousecode;
        mbytecount=0;
        if (mx<0)
        {
          mx=0;
        }
        if (mx>479)
        {
          mx=479;
        }
        if (my<0)
        {
          my=0;
        }
        if (my>249)
        {
          my=249;
        }
        Cursor.x=mx;
        Cursor.y=my;
        break;
    }
	}
}

void GetMouseClick(void)
{
  static volatile WINDOW* hdn;
  static volatile uint16_t px;
  static volatile uint16_t py;
  WINDOW* hwin;
  WINDOW* hctl;
  uint16_t x,y;

  if (Cursor.x!=px || Cursor.y!=py)
  {
    /* Find the window */
    px=Cursor.x;
    py=Cursor.y;
    hwin=WindowFromPoint(px,py);
    if (hwin)
    {
      x=Cursor.x-hwin->x;
      y=Cursor.y-hwin->y;
      /* Find the control */
      hctl=ControlFromPoint(hwin,x,y);
      if (hctl)
      {
        hwin=hctl;
        x=x-hwin->x;
        y=y-hwin->y;
      }
      SendEvent(hwin,EVENT_MOVE,(y<<16) | x,hwin->ID);
    }
  }
  if (mb!=pmb)
  {
    if ((mb & 1)&& !(pmb & 1))
    {
      /* Left button down */
      hwin=WindowFromPoint(Cursor.x,Cursor.y);
      if (hwin)
      {
        /* Activate the window */
        SendEvent(hwin,EVENT_ACTIVATE,0,hwin->ID);
        /* Find the control */
        x=Cursor.x-hwin->x;
        y=Cursor.y-hwin->y;
        hctl=ControlFromPoint(hwin,x,y);
        if (hctl)
        {
          hwin=hctl;
          x=x-hwin->x;
          y=y-hwin->y;
          SendEvent(hwin,EVENT_LDOWN,(y<<16) | x,hwin->ID);
          if (hwin->style & STYLE_CANFOCUS)
          {
            if (Focus)
            {
              Focus->state &= ~STATE_FOCUS;
            }
            hwin->state |= STATE_FOCUS;
            Focus=hwin;
          }
        }
        else
        {
          SendEvent(hwin,EVENT_LDOWN,((y<<16) | x),hwin->ID);
        }
      }
      hdn=hwin;
    }
    else if (!(mb & 1)&& (pmb & 1))
    {
      /* Left button up */
      hwin=WindowFromPoint(Cursor.x,Cursor.y);
      if (hwin)
      {
        x=Cursor.x-hwin->x;
        y=Cursor.y-hwin->y;
        hctl=ControlFromPoint(hwin,x,y);
        if (hctl)
        {
          hwin=hctl;
          x=x-hwin->x;
          y=y-hwin->y;
        }
        if (hdn)
        {
          SendEvent((WINDOW*)hdn,EVENT_LUP,((y<<16) | x),hdn->ID);
          if (hdn==hwin)
          {
            SendEvent(hwin,EVENT_LCLICK,(y<<16) | x,hwin->ID);
          }
        }
      }
      mclk|=1;
    }
    if ((mb & 2)&& !(pmb & 2))
    {
      /* Right button down */
    }
    else if (!(mb & 2)&& (pmb & 2))
    {
      /* Right button up */
      mclk|=2;
    }
    if ((mb & 4)&& !(pmb & 4))
    {
      /* Right button down */
    }
    else if (!(mb & 4)&& (pmb & 4))
    {
      /* Right button up */
      mclk|=4;
    }
    pmb=mb;
  }
}

uint8_t GetClick(void)
{
  uint8_t clk=mclk;

  mclk=0;
  return clk;
}
