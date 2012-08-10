/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 08/08/2012
* Description        : Main program body
********************************************************************************

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private define ------------------------------------------------------------*/
/* Private typedef -----------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
void RCC_Config(void);
void NVIC_Config(void);
void GPIO_Config(void);
/* Private functions ---------------------------------------------------------*/

/*******************************************************************************
* Function Name  : main
* Description    : Main program
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
int main(void)
{
  asm("add  sp,#0x10000");

  RCC_Config();
  GPIO_Config();
  NVIC_Config();
  while (1)
  {
  }
}

void RCC_Config(void)
{
  /* Enable GPIOA, GPIOB, GPIOC and GPIOE clocks ****************************************/
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOB | RCC_AHB1Periph_GPIOC | RCC_AHB1Periph_GPIOE, ENABLE);
  /* Enable SYSCFG clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_SYSCFG, ENABLE);
}

void NVIC_Config(void)
{
  NVIC_InitTypeDef NVIC_InitStructure;

  /* Enable and set EXTI Line9_5 Interrupt to the lowest priority */
  NVIC_InitStructure.NVIC_IRQChannel = EXTI9_5_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x01;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x01;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

void GPIO_Config(void)
{
  GPIO_InitTypeDef        GPIO_InitStructure;
  EXTI_InitTypeDef        EXTI_InitStructure;

  /* GPIOE Pin15 to Pin7 as outputs */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_15 | GPIO_Pin_14 | GPIO_Pin_13 | GPIO_Pin_12 | GPIO_Pin_11 | GPIO_Pin_10 | GPIO_Pin_9 | GPIO_Pin_8 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOE, &GPIO_InitStructure);
  /* GPIOE Pin6 and Pin5 as input floating */
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_5;
  GPIO_Init(GPIOE, &GPIO_InitStructure);

  /* Connect EXTI Line5 to PE5 pin */
  SYSCFG_EXTILineConfig(EXTI_PortSourceGPIOE, EXTI_PinSource5);

  /* Configure EXTI Line5 */
  EXTI_InitStructure.EXTI_Line = EXTI_Line5;
  EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
  EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising;  
  EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  EXTI_Init(&EXTI_InitStructure);
}

void EXTI9_5_IRQHandler(void)
{
  /* Clear the EXTI line 5 pending bit */
  EXTI_ClearITPendingBit(EXTI_Line5);
}
