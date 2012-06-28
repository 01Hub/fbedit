/**
  ******************************************************************************
  * @file    ADC3_DMA/main.c 
  * @author  MCD Application Team
  * @version V1.0.0
  * @date    19-September-2011
  * @brief   Main program body
  ******************************************************************************
  * @attention
  *
  * THE PRESENT FIRMWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
  * WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE
  * TIME. AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY
  * DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING
  * FROM THE CONTENT OF SUCH FIRMWARE AND/OR THE USE MADE BY CUSTOMERS OF THE
  * CODING INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
  *
  * <h2><center>&copy; COPYRIGHT 2011 STMicroelectronics</center></h2>
  ******************************************************************************
  */

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include <stdio.h>

/** @addtogroup STM32F4_Discovery_Peripheral_Examples
  * @{
  */

/** @addtogroup ADC_ADC3_DMA
  * @{
  */ 

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* STM32_Command */
#define STM32_CMNDWait            ((uint8_t)0)
#define STM32_CMNDStart           ((uint8_t)1)
#define STM32_CMNDFrqEnable       ((uint8_t)2)

/* DDS SWEEP SubModes */
#define SWEEP_SubModeOff          ((uint8_t)1)
#define SWEEP_SubModeUp           ((uint8_t)2)
#define SWEEP_SubModeDown         ((uint8_t)3)
#define SWEEP_SubModeUpDown       ((uint8_t)4)
#define SWEEP_SubModePeak         ((uint8_t)5)

typedef struct
{
  uint32_t Frequency;
  uint32_t PreviousCount;
  uint32_t Reserved1;
  uint32_t Reserved2;
}STM32_FRQTypeDef;

typedef struct
{
  STM32_FRQTypeDef STM32_Frequency;                   // 0x20000000
  uint8_t  cmnd;
  uint8_t  HSC_enable;
  uint16_t HSC_div;
  uint32_t HSC_frq;
  uint32_t HSC_dutycycle;
  uint32_t DDS_PhaseFrq;                              // 0x20000018
  uint8_t  DDS_SubMode;
  uint8_t  DDS_DacBuffer;
  uint16_t SWEEP_StepTime;
  uint32_t SWEEP_UpDovn;                              // 0x20000020
  uint32_t SWEEP_Min;                                 // 0x20000024
  uint32_t SWEEP_Max;                                 // 0x20000028
  uint32_t SWEEP_Add;                                 // 0x2000002C
  uint16_t Wave[2048];                                // 0x20000030
  uint16_t Peak[1536];                                // 0x20001030
}STM32_CMNDTypeDef;
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
static STM32_CMNDTypeDef STM32_Command;               // 0x20000000
/* Private function prototypes -----------------------------------------------*/
void FRQ_Config(void);
void HSC_Config(void);
/* Private functions ---------------------------------------------------------*/
/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
int main(void)
{
  /*!< At this stage the microcontroller clock setting is already configured, 
       this is done through SystemInit() function which is called from startup
       file (startup_stm32f4xx.s) before to branch to application main.
       To reconfigure the default setting of SystemInit() function, refer to
       system_stm32f4xx.c file
     */

  uint32_t i;

  /* Initialize Leds mounted on STM32F4-Discovery board */
  STM_EVAL_LEDInit(LED3);
  STM_EVAL_LEDInit(LED4);
  STM_EVAL_LEDOff(LED3);
  STM_EVAL_LEDOff(LED4);
  /* Setup frequency */
  FRQ_Config();

  while (1)
  {
    if (STM32_Command.cmnd == STM32_CMNDStart)
    {
      /* Reset STM32_CMNDStart */
      STM32_Command.cmnd = STM32_CMNDWait;
      /* Setup high speed clock */
      HSC_Config();
      /* DAC configuration */
      //DAC_DDS_Configuration();
      switch (STM32_Command.DDS_SubMode)
      {
        case SWEEP_SubModeOff:
          //DDSWaveGenerator();
          break;
        case SWEEP_SubModeUp:
          //DDSSweepWaveGenerator();
          break;
        case SWEEP_SubModeDown:
          //DDSSweepWaveGenerator();
          break;
        case SWEEP_SubModeUpDown:
          //DDSSweepWaveGenerator();
          break;
        case SWEEP_SubModePeak:
          //DDSSweepWaveGeneratorPeak();
          break;
      }
    }
    else if (STM32_Command.cmnd == STM32_CMNDFrqEnable)
    {
      /* Reset STM32_CMNDFrqEnable */
      STM32_Command.cmnd = STM32_CMNDWait;
      /* Enable TIM3 Update interrupt */
      TIM_ClearITPendingBit(TIM3,TIM_IT_Update);
      TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
      /* Enable TIM2 */
      TIM_Cmd(TIM2, ENABLE);
      /* Enable TIM3 */
      TIM_Cmd(TIM3, ENABLE);
    }
    i=0;
    while (i < 100000)
    {
      i++;
    }
  }
}

void FRQ_Config(void)
{
  NVIC_InitTypeDef NVIC_InitStructure;
  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  GPIO_InitTypeDef GPIO_InitStructure;
  /* TIM2, TIM3 and TIM5 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM5, ENABLE);
  /* GPIOA clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA, ENABLE);
  /* Enable the TIM3 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);

  /* TIM2 Counter configuration */
  TIM_TimeBaseStructure.TIM_Period = 0xffffffff;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  TIM2->CCMR1 = 0x0100;     //CC2S=01
  TIM2->SMCR = 0x0067;      //TS=110, SMS=111

  /* TIM2 chennel2 configuration : PA.01 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  
  /* Connect TIM2 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource1, GPIO_AF_TIM2);

  /* TIM3 1 second Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 9999;
  TIM_TimeBaseStructure.TIM_Prescaler = 8399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
}

void HSC_Config(void)
{
  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  TIM_OCInitTypeDef  TIM_OCInitStructure;
  GPIO_InitTypeDef GPIO_InitStructure;
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = STM32_Command.HSC_frq;
  TIM_TimeBaseStructure.TIM_Prescaler = STM32_Command.HSC_div;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM5, &TIM_TimeBaseStructure);
  /* PWM1 Mode configuration: Channel3 */
  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_OutputNState = TIM_OutputState_Disable;
  TIM_OCInitStructure.TIM_Pulse = STM32_Command.HSC_dutycycle;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  TIM_OCInitStructure.TIM_OCNPolarity = TIM_OCPolarity_Low;
  TIM_OCInitStructure.TIM_OCIdleState = TIM_OCIdleState_Reset;
  TIM_OCInitStructure.TIM_OCNIdleState = TIM_OCIdleState_Reset;
  TIM_OC3Init(TIM5, &TIM_OCInitStructure);

  TIM_OC1PreloadConfig(TIM5, TIM_OCPreload_Enable);
  TIM_ARRPreloadConfig(TIM5, ENABLE);
  /* TIM5 Main Output Enable */
  TIM_CtrlPWMOutputs(TIM5, ENABLE);
  /* TIM5 chennel 3 configuration : PA.02 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_2;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  
  /* Connect TIM5 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource2, GPIO_AF_TIM5);

  if (STM32_Command.HSC_enable)
  {
    STM_EVAL_LEDOn(LED4);
    /* TIM5 enable counter */
    TIM_Cmd(TIM5, ENABLE);
  }
}

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  uint32_t Timer;
  TIM_ClearITPendingBit(TIM3, TIM_IT_Update);
  STM_EVAL_LEDToggle(LED3);
  Timer=TIM2->CNT;
  STM32_Command.STM32_Frequency.Frequency=Timer-STM32_Command.STM32_Frequency.PreviousCount;
  STM32_Command.STM32_Frequency.PreviousCount=Timer;
}

#ifdef  USE_FULL_ASSERT

/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t* file, uint32_t line)
{ 
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */

  /* Infinite loop */
  while (1)
  {
  }
}
#endif

/**
  * @}
  */ 

/**
  * @}
  */ 

/******************* (C) COPYRIGHT 2011 STMicroelectronics *****END OF FILE****/
