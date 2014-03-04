/**
  ******************************************************************************
  * @file    LCMeter/main.c 
  * @author  MCD Application Team / KO
  * @version V1.0.0
  * @date    20-February-2014
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

/**
  ******************************************************************************
  Port pins
  PA.00         Frequency counter input (TIM5)
  PA.01         Frequency counter input (TIM2)
  PB.07         High Speed Clock
  PC.01         Scope ADC
  PD.00         Frequency counter select0
  PD.01         Frequency counter select1
  PD.02         Frequency counter select2
  PD.06         LCMeter L/C selection, C = Low L = High
  PD.07         LCMeter calibration
  ******************************************************************************
  */

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint32_t HSCSet;                              // 0x20000018
} STM32_HSCTypeDef;

typedef struct
{
  uint32_t Frequency;                           // 0x2000001C
  uint32_t FrequencySCP;                        // 0x20000020
} STM32_FRQTypeDef;

typedef struct
{
  uint32_t FrequencyCal0;                       // 0x20000024
  uint32_t FrequencyCal1;                       // 0x20000028
} STM32_LCMTypeDef;

typedef struct
{
  uint32_t ADC_Prescaler;                       // 0x2000002C
  uint32_t ADC_TwoSamplingDelay;                // 0x20000030
  uint32_t ScopeTrigger;                        // 0x20000034
  uint32_t ScopeTriggerLevel;                   // 0x20000038
  uint32_t ScopeTimeDiv;                        // 0x2000003c
  uint32_t ScopeVoltDiv;                        // 0x20000040
} STM32_SCPTypeDef;

typedef struct
{
  uint32_t Cmd;                                 // 0x20000014
  STM32_HSCTypeDef STM32_HSC;                   // 0x20000018
  STM32_FRQTypeDef STM32_FRQ;                   // 0x2000001C
  STM32_LCMTypeDef STM32_LCM;                   // 0x20000024
  STM32_SCPTypeDef STM32_SCP;                   // 0x2000002C
  uint32_t TickCount;                           // 0x20000034
  uint32_t PreviousCountTIM2;                   // 0x20000038
  uint32_t ThisCountTIM2;                       // 0x2000003C
  uint32_t PreviousCountTIM5;                   // 0x20000040
  uint32_t ThisCountTIM5;                       // 0x20000044
} STM32_CMDTypeDef;

/* Private define ------------------------------------------------------------*/
/* DDS WaveType */
#define CMD_DONE                                ((uint8_t)0)
#define CMD_LCMCAL                              ((uint8_t)1)
#define CMD_LCMCAP                              ((uint8_t)2)
#define CMD_LCMIND                              ((uint8_t)3)
#define CMD_FRQCH1                              ((uint8_t)4)
#define CMD_FRQCH2                              ((uint8_t)5)
#define CMD_FRQCH3                              ((uint8_t)6)
#define CMD_SCPSET                              ((uint8_t)7)
#define CMD_HSCSET                              ((uint8_t)8)

#define ADC_CDR_ADDRESS                         ((uint32_t)0x40012308)
#define SCOPE_DATAPTR                           ((uint32_t)0x20008000)
#define SCOPE_DATASIZE                          ((uint32_t)0x10000)
#define STM32_CLOCK                             ((uint32_t)200000000)
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
__IO STM32_CMDTypeDef STM32_CMD;                // 0x20000014

/* Private function prototypes -----------------------------------------------*/
void RCC_Config(void);
void NVIC_Config(void);
void GPIO_Config(void);
void TIM_Config(void);
void DMA_TripleConfig(void);
void ADC_TripleConfig(void);
void ScopeSubSampling(void);
uint32_t GetFrequency(void);
void LCM_Calibrate(void);

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
  __IO uint32_t tmp;
  __IO uint32_t ticks;

  /* RCC Configuration */
  RCC_Config();
  /* GPIO Configuration */
  GPIO_Config();
  /* TIM Configuration */
  TIM_Config();
  /* NVIC Configuration */
  NVIC_Config();
  /* Calibrate LC Meter */
  LCM_Calibrate();
  while (1)
  {
    switch (STM32_CMD.Cmd)
    {
      case CMD_LCMCAL:
        LCM_Calibrate();
        STM32_CMD.Cmd = CMD_DONE;
        break;
      case CMD_LCMCAP:
        GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        STM32_CMD.Cmd = CMD_DONE;
        break;
      case CMD_LCMIND:
        GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_6);
        STM32_CMD.Cmd = CMD_DONE;
        break;
      case CMD_FRQCH1:
        GPIO_ResetBits(GPIOD, GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_0);
        STM32_CMD.Cmd = CMD_DONE;
        break;
      case CMD_FRQCH2:
        GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_1);
        STM32_CMD.Cmd = CMD_DONE;
        break;
      case CMD_FRQCH3:
        GPIO_ResetBits(GPIOD, GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1);
        STM32_CMD.Cmd = CMD_DONE;
        break;
      case CMD_SCPSET:
        GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_1);
        /* DMA Configuration */
        DMA_TripleConfig();
        /* ADC Configuration */
        ADC_TripleConfig();
        ticks = STM32_CMD.TickCount + 3;
        switch (STM32_CMD.STM32_SCP.ScopeTrigger)
        {
          case 0:
            break;
          case 1:
            /* Count on rising edge */
            TIM5->CCER = 0x0000;
            /* Wait until TIM5 increments */
            tmp = TIM5->CNT;
            while (tmp == TIM5->CNT)
            {
              if (ticks == STM32_CMD.TickCount)
              {
                break;
              }
            }
            break;
          case 2:
            /* Count on falling edge */
            TIM5->CCER = 0x0002;
            /* Wait until TIM5 increments */
            tmp = TIM5->CNT;
            while (tmp == TIM5->CNT)
            {
              if (ticks == STM32_CMD.TickCount)
              {
                break;
              }
            }
            break;
        }
        /* Start ADC1 Software Conversion */
        ADC1->CR2 |= (uint32_t)ADC_CR2_SWSTART;
        while (DMA_GetFlagStatus(DMA2_Stream0,DMA_FLAG_TCIF0)==RESET);
        ADC->CCR=0;
        ADC1->CR2=0;
        ADC2->CR2=0;
        ADC3->CR2=0;
        STM32_CMD.Cmd = CMD_DONE;
        break;
      case CMD_HSCSET:
        GPIO_ResetBits(GPIOD, GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_0);
        TIM4->PSC = STM32_CMD.STM32_HSC.HSCSet;
        STM32_CMD.Cmd = CMD_DONE;
        break;
    }
  }
}

/**
  * @brief  Get frequency reading.
  * @param  None
  * @retval None
  */
uint32_t GetFrequency(void)
{
  uint32_t i;
  i = STM32_CMD.TickCount;
  while (i == STM32_CMD.TickCount);
  return STM32_CMD.STM32_FRQ.Frequency;
}

/**
  * @brief  Calibrate LC Meter.
  * @param  None
  * @retval None
  */
void LCM_Calibrate(void)
{
  uint32_t i;
  GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
  STM32_CMD.STM32_LCM.FrequencyCal0 = 0;
  STM32_CMD.STM32_LCM.FrequencyCal1 = 0;
  i = GetFrequency();
  i = 0;
  while (i < 4)
  {
    STM32_CMD.STM32_LCM.FrequencyCal0 += GetFrequency();
    i++;
  }
  STM32_CMD.STM32_LCM.FrequencyCal0 /= 4;
  GPIO_SetBits(GPIOD, GPIO_Pin_7);
  i = GetFrequency();
  i = 0;
  while (i < 4)
  {
    STM32_CMD.STM32_LCM.FrequencyCal1 += GetFrequency();
    i++;
  }
  STM32_CMD.STM32_LCM.FrequencyCal1 /= 4;
  GPIO_ResetBits(GPIOD, GPIO_Pin_7);
}

/**
  * @brief  Configure the RCC.
  * @param  None
  * @retval None
  */
void RCC_Config(void)
{
  /* TIM2, TIM3, TIM4 and TIM5 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4 | RCC_APB1Periph_TIM5, ENABLE);
  /* DMA2 clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA2, ENABLE);
  /* GPIOA clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOA, ENABLE);
  /* GPIOB clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOB, ENABLE);
  /* GPIOC clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOC, ENABLE);
  /* GPIOD clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOD, ENABLE);
  /* Enable ADC1, ADC2, ADC3 clocks */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC1 | RCC_APB2Periph_ADC2 | RCC_APB2Periph_ADC3, ENABLE);
}

/**
  * @brief  Configure the NVIC.
  * @param  None
  * @retval None
  */
void NVIC_Config(void)
{
  NVIC_InitTypeDef NVIC_InitStructure;
  /* Enable the TIM3 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

/**
  * @brief  Configure the GPIO.
  * @param  None
  * @retval None
  */
void GPIO_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  /* Initialize Leds mounted on STM32F4-Discovery board */
  STM_EVAL_LEDInit(LED3);

  /* TIM2 chennel2 configuration : PA.01 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM2 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource1, GPIO_AF_TIM2);

  /* TIM5 chennel1 configuration : PA.00 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM5 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource0, GPIO_AF_TIM5);

  /* TIM4 chennel 2 configuration : PB7 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_UP ;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect TIM4 pin to AF2 */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource7, GPIO_AF_TIM4);

  /* Configure ADC123 Channel 11 pin as analog input (Scope) */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

/* GPIOD Outputs */
  GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOD, &GPIO_InitStructure);
}

/**
  * @brief  Configure the TIM.
  * @param  None
  * @retval None
  */
void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  TIM_OCInitTypeDef       TIM_OCInitStructure;
  TIM_OCStructInit(&TIM_OCInitStructure);
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
  TIM5->CCMR1 = 0x01;       //CC1S=01
  TIM5->SMCR = 0x0057;      //TS=101, SMS=111
  /* TIM3 1 second Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 10000-1;
  TIM_TimeBaseStructure.TIM_Prescaler = (STM32_CLOCK/2/10000)-1;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  /* TIM Interrupts enable */
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
  /* TIM2 enable counter */
  TIM_Cmd(TIM2, ENABLE);
  /* TIM5 enable counter */
  TIM_Cmd(TIM5, ENABLE);
  /* TIM3 enable counter */
  TIM_Cmd(TIM3, ENABLE);
  /* TIM4 HSC Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 1;
  /* 1.0KHz */
  TIM_TimeBaseStructure.TIM_Prescaler = 50000-1;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM4, &TIM_TimeBaseStructure);
  /* PWM1 Mode configuration: Channel2 */
  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_Pulse = 1;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  TIM_OC2Init(TIM4, &TIM_OCInitStructure);
  TIM_OC2PreloadConfig(TIM4, TIM_OCPreload_Enable);
  TIM_ARRPreloadConfig(TIM4, ENABLE);
  /* TIM4 enable counter */
  TIM_Cmd(TIM4, ENABLE);

}

/**
  * @brief  Configure the DMA.
  * @param  None
  * @retval None
  */
void DMA_TripleConfig(void)
{
  DMA_InitTypeDef DMA_InitStructure;
  DMA_StructInit(&DMA_InitStructure);
  DMA_DeInit(DMA2_Stream0);
  /* DMA2 Stream0 channel0 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_0;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)ADC_CDR_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)SCOPE_DATAPTR;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = SCOPE_DATASIZE/4;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Word;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Word;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA2_Stream0, &DMA_InitStructure);
  /* DMA2_Stream0 enable */
  DMA_Cmd(DMA2_Stream0, ENABLE);
}

/**
  * @brief  Configure the ADC.
  * @param  None
  * @retval None
  */
void ADC_TripleConfig(void)
{
  ADC_CommonInitTypeDef ADC_CommonInitStructure;
  ADC_InitTypeDef ADC_InitStructure;
  ADC_StructInit(&ADC_InitStructure);
  ADC_CommonStructInit(&ADC_CommonInitStructure);

  /* ADC Common configuration *************************************************/
  ADC_CommonInitStructure.ADC_Mode = ADC_TripleMode_Interl;
  ADC_CommonInitStructure.ADC_TwoSamplingDelay = STM32_CMD.STM32_SCP.ADC_TwoSamplingDelay<<8;
  ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_2;  
  ADC_CommonInitStructure.ADC_Prescaler = (uint32_t)STM32_CMD.STM32_SCP.ADC_Prescaler<<16; 
  ADC_CommonInit(&ADC_CommonInitStructure);

  ADC_InitStructure.ADC_Resolution = ADC_Resolution_12b;
  ADC_InitStructure.ADC_ScanConvMode = DISABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_T1_CC1;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;

  /* ADC1 regular channel 11 configuration ************************************/
  ADC_Init(ADC1, &ADC_InitStructure);
  ADC_RegularChannelConfig(ADC1, ADC_Channel_11, 1, ADC_SampleTime_3Cycles);

  /* ADC2 regular channel 11 configuration ************************************/
  ADC_Init(ADC2, &ADC_InitStructure);
  ADC_RegularChannelConfig(ADC2, ADC_Channel_11, 1, ADC_SampleTime_3Cycles);

  /* ADC3 regular channel 11 configuration ************************************/
  ADC_Init(ADC3, &ADC_InitStructure); 
  ADC_RegularChannelConfig(ADC3, ADC_Channel_11, 1, ADC_SampleTime_3Cycles);

  /* Enable ADC1 **************************************************************/
  ADC_Cmd(ADC1, ENABLE);
  /* Enable ADC2 **************************************************************/
  ADC_Cmd(ADC2, ENABLE);
  /* Enable ADC3 **************************************************************/
  ADC_Cmd(ADC3, ENABLE);
  /* Enable DMA request after last transfer (multi-ADC mode) ******************/
  ADC_MultiModeDMARequestAfterLastTransferCmd(ENABLE);
}

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  STM32_CMD.ThisCountTIM2 = TIM2->CNT;
  STM32_CMD.ThisCountTIM5 = TIM5->CNT;
  STM32_CMD.STM32_FRQ.Frequency = STM32_CMD.ThisCountTIM2 - STM32_CMD.PreviousCountTIM2;
  STM32_CMD.PreviousCountTIM2 = STM32_CMD.ThisCountTIM2;
  STM32_CMD.STM32_FRQ.FrequencySCP = STM32_CMD.ThisCountTIM5 - STM32_CMD.PreviousCountTIM5;
  STM32_CMD.PreviousCountTIM5 = STM32_CMD.ThisCountTIM5;
  STM32_CMD.TickCount++;
  TIM_ClearITPendingBit(TIM3, TIM_IT_Update);
  STM_EVAL_LEDToggle(LED3);
}

/*****END OF FILE****/
