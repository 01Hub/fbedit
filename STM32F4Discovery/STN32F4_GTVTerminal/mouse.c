
#include "stm32f4_discovery.h"

/* circular buffer for mouse */
__IO uint8_t mousebuf[256];
__IO uint8_t mousebufhead = 0;
__IO uint8_t mousebuftail = 0;

__IO uint8_t tmpmousecode;
__IO uint8_t mousecode;
__IO uint8_t mbitcount = 11;

/**
  * @brief  This function handles EXTI2_IRQHandler interrupt request.
            The interrupt is generated on STHL transition
  * @param  None
  * @retval None
  */
void EXTI2_IRQHandler(void)
{
  /* Clear the EXTI line 2 pending bit */
  EXTI_ClearITPendingBit(EXTI_Line2);

	/* figure out what the keyboard is sending us */
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
		mbitcount = 11;
	}
}

