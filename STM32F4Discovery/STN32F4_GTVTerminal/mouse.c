
#include "stm32f4_discovery.h"
#include "video.h"

extern volatile int16_t LineCount;
extern SPRITE Cursor;

/* circular buffer for mouse */
volatile uint8_t mousebuf[256];
volatile uint8_t mousebufhead = 0;
volatile uint8_t mousebuftail = 0;

volatile uint8_t tmpmousecode;
volatile uint8_t mousecode;
volatile uint8_t mbitcount = 11;
volatile int32_t mx,my;

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

  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);

  /* Configure PB1 and PB0 as open drain outputs */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_OD;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_2MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  GPIO_SetBits(GPIOB,GPIO_Pin_1 | GPIO_Pin_0);

  lc=LineCount;;
  while (lc==LineCount)
  {
  }
  /* Clock low */
  GPIO_ResetBits(GPIOB,GPIO_Pin_0);

  lc=LineCount;;
  while (lc==LineCount)
  {
  }
  lc=LineCount;;
  while (lc==LineCount)
  {
  }
  TIM_Cmd(TIM3, DISABLE);
  /* Data low */
  GPIO_ResetBits(GPIOB,GPIO_Pin_1);
  /* Clock as input */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;

  /* Clock high */
  GPIO_SetBits(GPIOB,GPIO_Pin_0);
  // lc=0;
  // while (lc<5)
  // {
    // lc++;
  // }
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Wait until clock low */
  while (GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_0))
  {
  }
  /* Send the F4 command to the mouse */
  SendData(0b10111101000);

  /* GPIOB Pin3, Pin2, Pin1 and Pin0 as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_3 | GPIO_Pin_2 | GPIO_Pin_1 | GPIO_Pin_0;
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
  lc=0;
  while (lc<168000000)
  {
    lc++;
  }
  mousebufhead=0;
  mousebuftail=0;
}

/**
  * @brief  This function handles EXTI2_IRQHandler interrupt request.
            The interrupt is generated on STHL transition
  * @param  None
  * @retval None
  */
void EXTI0_IRQHandler(void)
{
  uint8_t ms;

  /* Clear the EXTI line 2 pending bit */
  EXTI_ClearITPendingBit(EXTI_Line0);

	/* figure out what the mouse is sending us */
	--mbitcount;
	if (mbitcount >= 2 && mbitcount <= 9)
	{
		tmpmousecode >>= 1;
		if (GPIOB->IDR & GPIO_Pin_1)
			tmpmousecode |= 0x80;
	}
	else if (mbitcount == 0)
	{
    mousecode=tmpmousecode;
    mousebuf[mousebufhead]=mousecode;
    mousebufhead++;
//DrawHex(0,200,mousecode,1);
    if (mousebufhead==3)
    {
      ms=mousebuf[0];
      mx=Cursor.x+(int8_t)mousebuf[1];
      if (mx<0)
      {
        mx=0;
      }
      if (mx>479)
      {
        mx=479;
      }
      Cursor.x=mx;
      my=Cursor.y+(int8_t)mousebuf[2];
      if (my<0)
      {
        my=0;
      }
      if (my>249)
      {
        my=249;
      }
      Cursor.y=my;
      mousebufhead=0;
      mousebuftail=0;
    }
		mbitcount = 11;
	}
}

