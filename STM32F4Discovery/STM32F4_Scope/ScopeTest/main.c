/**
  ******************************************************************************
  * @file    ADC_Interleaved_DMAmode2/main.c 
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

/** @addtogroup STM32F4_Discovery_Peripheral_Examples
  * @{
  */

/** @addtogroup ADC_Interleaved_DMAmode2
  * @{
  */ 

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
//#define ADC_CDR_ADDRESS    ((uint32_t)0x40012308)
#define ADC3_DR_ADDRESS     ((uint32_t)0x4001224C)

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
__IO uint16_t ADC3ConvertedValue[1500];

/* Private function prototypes -----------------------------------------------*/
void Clock_Config(void);
void GPIO_Config(void);
void TIM_Config(void);
//void ADC3_CH12_DMA_Config(void);

/* Private functions ---------------------------------------------------------*/

/**
  * @brief   Main program
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

  Clock_Config();
  GPIO_Config();
  TIM_Config;

// /******************************************************************************/
// /*               ADCs interface clock, pin and DMA configuration              */
// /******************************************************************************/
  // ADC3_CH12_DMA_Config();

  // /* Start ADC3 Software Conversion */ 
  // ADC_SoftwareStartConv(ADC3);

  while (1)
  {
  }
}

void Clock_Config(void)
{
  /* Enable GPIOA, GPIOB, GPIOC and GPIOE clocks ****************************************/
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOB | RCC_AHB1Periph_GPIOC | RCC_AHB1Periph_GPIOE, ENABLE);
  /* Enable TIM2, TIM3, TIM4 and TIM5 clocks ****************************************/
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4 | RCC_APB1Periph_TIM5, ENABLE);
  /* Enable TIM10 clocks ****************************************/
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM10, ENABLE);
  // RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC3, ENABLE);
}

void GPIO_Config(void)
{
  GPIO_InitTypeDef        GPIO_InitStructure;

  /* TIM4 chennel 2 and TIM10 channel 1 configuration : PB7, PB8 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_8 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect TIM4 pin to AF2 */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource7, GPIO_AF_TIM4);
  /* Connect TIM10 pin to AF2 */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource8, GPIO_AF_TIM10);

  /* TIM2 chennel 2 and TIM5 channel 3 configuration : PA1, PA2 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM2 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource1, GPIO_AF_TIM2);
  /* Connect TIM5 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource2, GPIO_AF_TIM5);
}

void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  TIM_OCInitTypeDef       TIM_OCInitStructure;

  /* TIM2 Counter configuration */
  TIM_TimeBaseStructure.TIM_Period = 0xffffffff;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  TIM2->CCMR1 = 0x0100;     //CC2S=01
  TIM2->SMCR = 0x0067;      //TS=110, SMS=111

  /* TIM5 Counter configuration */
  TIM_TimeBaseStructure.TIM_Period = 0xffffffff;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM5, &TIM_TimeBaseStructure);
  TIM5->CCMR1 = 0x0100;     //CC2S=01
  TIM5->SMCR = 0x0067;      //TS=110, SMS=111

  /* TIM3 1 second Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 9999;
  TIM_TimeBaseStructure.TIM_Prescaler = 8399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  /* TIM Interrupts enable */
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
}

/**
  * @brief  ADC3 channel12 with DMA configuration
  * @param  None
  * @retval None
  */
// void ADC3_CH12_DMA_Config(void)
// {
  // ADC_InitTypeDef         ADC_InitStructure;
  // ADC_CommonInitTypeDef   ADC_CommonInitStructure;
  // DMA_InitTypeDef         DMA_InitStructure;
  // GPIO_InitTypeDef        GPIO_InitStructure;
  // TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  // TIM_OCInitTypeDef       TIM_OCInitStructure;

  // /* Enable ADC3, DMA2 and GPIO clocks ****************************************/
  // RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA2 | RCC_AHB1Periph_GPIOC, ENABLE);
  // RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC3, ENABLE);

  // /* DMA2 Stream0 channel0 configuration **************************************/
  // DMA_InitStructure.DMA_Channel = DMA_Channel_2;  
  // DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)ADC3_DR_ADDRESS;
  // DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&ADC3ConvertedValue;
  // DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  // DMA_InitStructure.DMA_BufferSize = 1500;
  // DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  // DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  // DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
  // DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
  // DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  // DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  // DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  // DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  // DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  // DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  // DMA_Init(DMA2_Stream0, &DMA_InitStructure);
  // DMA_Cmd(DMA2_Stream0, ENABLE);

  // /* Configure ADC3 Channel12 pin as analog input ******************************/
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_2;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  // GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  // GPIO_Init(GPIOC, &GPIO_InitStructure);

  // /* ADC Common Init **********************************************************/
  // ADC_CommonInitStructure.ADC_Mode = ADC_Mode_Independent;
  // ADC_CommonInitStructure.ADC_Prescaler = ADC_Prescaler_Div2;
  // ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_Disabled;
  // ADC_CommonInitStructure.ADC_TwoSamplingDelay = ADC_TwoSamplingDelay_5Cycles;
  // ADC_CommonInit(&ADC_CommonInitStructure);

  // /* ADC3 Init ****************************************************************/
  // ADC_InitStructure.ADC_Resolution = ADC_Resolution_8b;
  // ADC_InitStructure.ADC_ScanConvMode = DISABLE;
  // ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  // ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  // ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  // ADC_InitStructure.ADC_NbrOfConversion = 1;
  // ADC_Init(ADC3, &ADC_InitStructure);

  // /* ADC3 regular channel12 configuration *************************************/
  // ADC_RegularChannelConfig(ADC3, ADC_Channel_12, 1, ADC_SampleTime_3Cycles);

 // /* Enable DMA request after last transfer (Single-ADC mode) */
  // ADC_DMARequestAfterLastTransferCmd(ADC3, ENABLE);

  // /* Enable ADC3 DMA */
  // ADC_DMACmd(ADC3, ENABLE);

  // /* Enable ADC3 */
  // ADC_Cmd(ADC3, ENABLE);

  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = 83;
  // TIM_TimeBaseStructure.TIM_Prescaler = 0;
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  // TIM_TimeBaseInit(TIM5, &TIM_TimeBaseStructure);
  // /* PWM1 Mode configuration: Channel3 */
  // TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  // TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  // TIM_OCInitStructure.TIM_OutputNState = TIM_OutputState_Disable;
  // TIM_OCInitStructure.TIM_Pulse = 41;
  // TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  // TIM_OCInitStructure.TIM_OCNPolarity = TIM_OCPolarity_Low;
  // TIM_OCInitStructure.TIM_OCIdleState = TIM_OCIdleState_Reset;
  // TIM_OCInitStructure.TIM_OCNIdleState = TIM_OCIdleState_Reset;
  // TIM_OC3Init(TIM5, &TIM_OCInitStructure);

  // TIM_OC1PreloadConfig(TIM5, TIM_OCPreload_Enable);
  // TIM_ARRPreloadConfig(TIM5, ENABLE);
  // /* TIM5 Main Output Enable */
  // TIM_CtrlPWMOutputs(TIM5, ENABLE);
  // /* TIM5 chennel 3 configuration : PA.02 */
  // GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_2;
  // GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  // GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  // GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  // GPIO_Init(GPIOA, &GPIO_InitStructure);
  
  // /* Connect TIM5 pin to AF2 */
  // GPIO_PinAFConfig(GPIOA, GPIO_PinSource2, GPIO_AF_TIM5);

  // /* TIM5 enable counter */
  // TIM_Cmd(TIM5, ENABLE);
// }

// void HSC_Config(void)
// {
// }

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  TIM_ClearITPendingBit(TIM3, TIM_IT_Update);
  STM_EVAL_LEDToggle(LED3);
  Timer=TIM2->CNT;
  Frequency=Timer-PreviousTimer;
  PreviousTimer=Timer;
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
