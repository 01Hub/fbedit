/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 07/06/2012
* Description        : Main program body
********************************************************************************

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private define ------------------------------------------------------------*/
#define ADC_CDR_ADDRESS           ((uint32_t)0x40012308)
#define PE_IDR_Address            ((uint32_t)0x40021011)

#define STM32_DataSize            ((uint16_t)1024*6/2)
#define STM32_BlockSize           ((uint8_t)64)

/* STM32_Command */
#define STM32_CommandWait         ((uint8_t)0)
#define STM32_CommandInit         ((uint8_t)1)
#define STM32_CommandDone         ((uint8_t)99)

/* STM32_Modes */
#define STM32_ModeNone            ((uint8_t)0)
#define STM32_ModeScopeCHA        ((uint8_t)1)
#define STM32_ModeScopeCHB        ((uint8_t)2)
#define STM32_ModeScopeCHACHB     ((uint8_t)3)
#define STM32_ModeHSClockCHA      ((uint8_t)4)
#define STM32_ModeHSClockCHB      ((uint8_t)5)
#define STM32_ModeHSClockCHACHB   ((uint8_t)6)
#define STM32_ModeLGA             ((uint8_t)7)

/* STM32_Triggers */
#define STM32_TriggerManual       ((uint8_t)0)
#define STM32_TriggerRisingCHA    ((uint8_t)1)
#define STM32_TriggerFallingCHA   ((uint8_t)2)
#define STM32_TriggerRisingCHB    ((uint8_t)3)
#define STM32_TriggerFallingCHB   ((uint8_t)4)
#define STM32_TriggerLGA          ((uint8_t)5)
#define STM32_TriggerLGAEdge      ((uint8_t)6)

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint8_t   Command;
  uint8_t   Mode;
  uint8_t   DataBlocks;
  uint8_t   TriggerMode;
  uint8_t   TriggerValue;
  uint8_t   TriggerMask;
  uint8_t   TriggerWait;
  uint8_t   ScopeDataBits;
  uint8_t   ScopeSampleClocks;
  uint8_t   ScopeClockDiv;
  uint8_t   ScopeAmplifyCHA;
  uint8_t   ScopeAmplifyCHB;
  uint8_t   ScopeDCNullOutCHA;
  uint8_t   ScopeDCNullOutCHB;
  uint16_t  LGASampleRate;
}CommandStructTypeDef;

typedef struct
{
  uint32_t  Frequency;
  uint32_t  PreviousCount;
  uint16_t  HSCEnable;
  uint16_t  HSCClockDiv;
  uint16_t  HSCCount;
  uint16_t  HSCDuty;
}FRQDataStructTypeDef;

typedef struct
{
  FRQDataStructTypeDef FRQDataStructCHA;                // 0x20000014
  FRQDataStructTypeDef FRQDataStructCHB;                // 0x20000024
  CommandStructTypeDef CommandStruct;                   // 0x20000034
  union
  {
    uint16_t STM32_Data[STM32_DataSize];                // 0x20000044
  };
}STM32_DataStructTypeDef;

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
__IO STM32_DataStructTypeDef STM32_DataStruct;          // 0x20000014

/* Private function prototypes -----------------------------------------------*/
void RCC_Config(void);
void NVIC_Config(void);
void GPIO_Config(void);
void TIM_Config(void);
void ADC_DVMConfig(void);
void ADC_SCPConfig(void);
void DMA_SCPConfig(void);
void DMA_LGAConfig(void);
void WaitForTrigger(void);

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
  u32 i;

  asm("add  sp,#0x10000");

  RCC_Config();
  NVIC_Config();
  GPIO_Config();
  TIM_Config();
  ADC_DVMConfig();
  while (1)
  {
    if (STM32_DataStruct.CommandStruct.Command == STM32_CommandInit)
    {
      /* Reset STM32_CommandInit */
      STM32_DataStruct.CommandStruct.Command = STM32_CommandWait;
      switch (STM32_DataStruct.CommandStruct.Mode)
      {
        case STM32_ModeScopeCHA...STM32_ModeScopeCHACHB:
          DMA_SCPConfig();
          ADC_SCPConfig();
          STM32_DataStruct.CommandStruct.TriggerWait = 3;
          WaitForTrigger();
          /* Start ADC1 Software Conversion */
          ADC1->CR2 |= (uint32_t)ADC_CR2_SWSTART;
          while (DMA_GetFlagStatus(DMA2_Stream0,DMA_FLAG_TCIF0)==RESET);
          STM32_DataStruct.CommandStruct.Command = STM32_CommandDone;
          ADC_Cmd(ADC1, DISABLE);
          ADC_Cmd(ADC2, DISABLE);
          DMA_DeInit(DMA2_Stream0);
          break;
        case STM32_ModeHSClockCHA:
          if (STM32_DataStruct.FRQDataStructCHA.HSCEnable)
          {
            /* TIM4 disable counter */
            TIM_Cmd(TIM4, DISABLE);
            /* Reset count */
            TIM4->CNT = 0;
            /* Set the Autoreload value */
            TIM4->ARR = STM32_DataStruct.FRQDataStructCHA.HSCCount;
            /* Set the Prescaler value */
            TIM4->PSC = STM32_DataStruct.FRQDataStructCHA.HSCClockDiv;
            /* Set the Capture Compare Register value */
            TIM4->CCR2 = STM32_DataStruct.FRQDataStructCHA.HSCDuty;
            /* TIM4 enable counter */
            TIM_Cmd(TIM4, ENABLE);
          }
          else
          {
            /* TIM4 disable counter */
            TIM_Cmd(TIM4, DISABLE);
          }
          break;
        case STM32_ModeHSClockCHB:
          if (STM32_DataStruct.FRQDataStructCHB.HSCEnable)
          {
            /* TIM10 disable counter */
            TIM_Cmd(TIM10, DISABLE);
            /* Reset count */
            TIM10->CNT = 0;
            /* Set the Autoreload value */
            TIM10->ARR = STM32_DataStruct.FRQDataStructCHB.HSCCount;
            /* Set the Prescaler value */
            TIM10->PSC = STM32_DataStruct.FRQDataStructCHB.HSCClockDiv;
            /* Set the Capture Compare Register value */
            TIM10->CCR1 = STM32_DataStruct.FRQDataStructCHB.HSCDuty;
            /* TIM10 enable counter */
            TIM_Cmd(TIM10, ENABLE);
          }
          else
          {
            /* TIM10 disable counter */
            TIM_Cmd(TIM10, DISABLE);
          }
          break;
        case STM32_ModeLGA:
          STM_EVAL_LEDToggle(LED4);
          TIM8->CNT=0;
          TIM8->ARR=STM32_DataStruct.CommandStruct.LGASampleRate;
          DMA_LGAConfig();
          STM32_DataStruct.CommandStruct.TriggerWait = 3;
          TIM_DMACmd(TIM8, TIM_DMA_Update, ENABLE);
          /* DMA2_Stream1 enable */
          DMA_Cmd(DMA2_Stream1, ENABLE);
          WaitForTrigger();
          TIM8->CR1 |= TIM_CR1_CEN;
          while (DMA_GetFlagStatus(DMA2_Stream1,DMA_FLAG_TCIF1)==RESET);
          STM32_DataStruct.CommandStruct.Command = STM32_CommandDone;
          DMA_DeInit(DMA2_Stream1);
          TIM_Cmd(TIM8, DISABLE);
          break;
      }
    }
    i=0;
    while (i < 1000000)
    {
      i++;
    }
    ADC_SoftwareStartInjectedConv(ADC3);
  }
}

/*******************************************************************************
* Function Name  : WaitForTrigger
* Description    : This function waits for a trigger on CHA, CHB or
*                  logic analyser .
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void WaitForTrigger(void)
{
  uint32_t tmp;
  /* Syncronize with rising or falling edge or logic analyser */
  switch (STM32_DataStruct.CommandStruct.TriggerMode)
  {
    case (STM32_TriggerRisingCHA):
      /* Count on rising edge */
      TIM2->CCER = 0x0000;
      /* Wait until TIM2 increments */
      tmp = TIM2->CNT;
      while (tmp == TIM2->CNT)
      {
        if (STM32_DataStruct.CommandStruct.TriggerWait == 0)
        {
          break;
        }
      }
      break;
    case (STM32_TriggerFallingCHA):
      /* Count on falling edge */
      TIM2->CCER = 0x0020;
      /* Wait until TIM2 increments */
      tmp = TIM2->CNT;
      while (tmp == TIM2->CNT)
      {
        if (STM32_DataStruct.CommandStruct.TriggerWait == 0)
        {
          break;
        }
      }
      break;
    case (STM32_TriggerRisingCHB):
      /* Count on rising edge */
      TIM5->CCER = 0x0000;
      /* Wait until TIM5 increments */
      tmp = TIM5->CNT;
      while (tmp == TIM5->CNT)
      {
        if (STM32_DataStruct.CommandStruct.TriggerWait == 0)
        {
          break;
        }
      }
      break;
    case (STM32_TriggerFallingCHB):
      /* Count on falling edge */
      TIM5->CCER = 0x0002;
      /* Wait until TIM5 increments */
      tmp = TIM5->CNT;
      while (tmp == TIM5->CNT)
      {
        if (STM32_DataStruct.CommandStruct.TriggerWait == 0)
        {
          break;
        }
      }
      break;
    case (STM32_TriggerLGA):
      tmp = STM32_DataStruct.CommandStruct.TriggerValue & STM32_DataStruct.CommandStruct.TriggerMask;
      /* Wait until conditions are met */
      while ((((GPIOE->IDR>>8) & STM32_DataStruct.CommandStruct.TriggerMask) != tmp) & (STM32_DataStruct.CommandStruct.TriggerWait != 0))
      {
      }
      break;
    case (STM32_TriggerLGAEdge):
      tmp = STM32_DataStruct.CommandStruct.TriggerValue & STM32_DataStruct.CommandStruct.TriggerMask;
      /* Edge sensitive */
      /* Wait while conditions are met */
      while ((((GPIOE->IDR>>8) & STM32_DataStruct.CommandStruct.TriggerMask) == tmp) & (STM32_DataStruct.CommandStruct.TriggerWait != 0))
      {
      }
      /* Wait until conditions are met */
      while ((((GPIOE->IDR>>8) & STM32_DataStruct.CommandStruct.TriggerMask) != tmp) & (STM32_DataStruct.CommandStruct.TriggerWait != 0))
      {
      }
      break;
    default:
      break;
  }
}

void RCC_Config(void)
{
  /* Enable DMA2, GPIOA, GPIOB, GPIOC and GPIOE clocks ****************************************/
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA2 | RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOB | RCC_AHB1Periph_GPIOC | RCC_AHB1Periph_GPIOE, ENABLE);
  /* Enable TIM2, TIM3, TIM4 and TIM5 clocks ****************************************/
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4 | RCC_APB1Periph_TIM5, ENABLE);
  /* Enable TIM10 clocks ****************************************/
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM8 | RCC_APB2Periph_TIM10 | RCC_APB2Periph_ADC1 | RCC_APB2Periph_ADC2 | RCC_APB2Periph_ADC3, ENABLE);
}

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

void GPIO_Config(void)
{
  GPIO_InitTypeDef        GPIO_InitStructure;

  /* TIM4 chennel 2 and TIM10 channel 1 configuration : PB7, PB8 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_8 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_UP ;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect TIM4 pin to AF2 */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource7, GPIO_AF_TIM4);
  /* Connect TIM10 pin to AF2 */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource8, GPIO_AF_TIM10);

  /* TIM2 chennel 2 and TIM5 channel 1 configuration : PA1, PA0 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM2 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource1, GPIO_AF_TIM2);
  /* Connect TIM5 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource0, GPIO_AF_TIM5);

  /* Configure ADC123 Channel1 and ADC123 Channel12 pins as analog inputs (DVM) ******************************/
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_2;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  /* Configure ADC12 Channel8 and ADC12 Channel9 pins as analog inputs (Scope) ******************************/
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0 | GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  STM_EVAL_LEDInit(LED3);
  STM_EVAL_LEDInit(LED4);
}

void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  TIM_OCInitTypeDef       TIM_OCInitStructure;

  //TIM_TimeBaseStructInit(&TIM_TimeBaseInitStruct);
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
  TIM_TimeBaseStructure.TIM_Period = 9999;
  TIM_TimeBaseStructure.TIM_Prescaler = 8399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  /* TIM Interrupts enable */
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);

  TIM_Cmd(TIM2, ENABLE);
  TIM_Cmd(TIM3, ENABLE);
  TIM_Cmd(TIM5, ENABLE);

  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 999;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM4, &TIM_TimeBaseStructure);
  /* PWM1 Mode configuration: Channel2 */

  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_Pulse = 499;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  TIM_OC2Init(TIM4, &TIM_OCInitStructure);

  TIM_OC2PreloadConfig(TIM4, TIM_OCPreload_Enable);
  TIM_ARRPreloadConfig(TIM4, ENABLE);

  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 999;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM10, &TIM_TimeBaseStructure);
  /* PWM1 Mode configuration: Channel3 */
  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_Pulse = 499;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  TIM_OC1Init(TIM10, &TIM_OCInitStructure);

  TIM_OC1PreloadConfig(TIM10, TIM_OCPreload_Enable);
  TIM_ARRPreloadConfig(TIM10, ENABLE);

  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 167;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM8, &TIM_TimeBaseStructure);
}

void ADC_DVMConfig(void)
{
  ADC_CommonInitTypeDef ADC_CommonInitStructure;
  ADC_InitTypeDef       ADC_InitStructure;

  ADC_StructInit(&ADC_InitStructure);
  ADC_CommonStructInit(&ADC_CommonInitStructure);

  /* ADC Common Init **********************************************************/
  ADC_CommonInitStructure.ADC_Mode = ADC_Mode_Independent;//ADC_DualMode_RegSimult;
  ADC_CommonInitStructure.ADC_Prescaler = ADC_Prescaler_Div2;
  ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_Disabled;//ADC_DMAAccessMode_2;
  ADC_CommonInitStructure.ADC_TwoSamplingDelay = ADC_TwoSamplingDelay_5Cycles;
  ADC_CommonInit(&ADC_CommonInitStructure);

  /* ADC3 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = ADC_Resolution_12b;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC3, &ADC_InitStructure);
  ADC_Cmd(ADC3, ENABLE);

  ADC_InjectedSequencerLengthConfig(ADC3,2);
  ADC_InjectedChannelConfig(ADC3,ADC_Channel_11,1,ADC_SampleTime_15Cycles);
  ADC_InjectedChannelConfig(ADC3,ADC_Channel_12,2,ADC_SampleTime_15Cycles);
  ADC_AutoInjectedConvCmd(ADC3, ENABLE);
  ADC_SoftwareStartInjectedConv(ADC3);
}

void ADC_SCPConfig(void)
{
  uint32_t tmp;
  ADC_CommonInitTypeDef ADC_CommonInitStructure;
  ADC_InitTypeDef       ADC_InitStructure;

  ADC_StructInit(&ADC_InitStructure);
  ADC_CommonStructInit(&ADC_CommonInitStructure);

  ADC_MultiModeDMARequestAfterLastTransferCmd(DISABLE);

  /* ADC Common Init **********************************************************/
  ADC_CommonInitStructure.ADC_Mode = ADC_DualMode_RegSimult;
  ADC_CommonInitStructure.ADC_Prescaler = (uint32_t)STM32_DataStruct.CommandStruct.ScopeClockDiv<<16;
  ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_2;
  ADC_CommonInitStructure.ADC_TwoSamplingDelay = ADC_TwoSamplingDelay_5Cycles;
  ADC_CommonInit(&ADC_CommonInitStructure);

  /* ADC1 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = (uint32_t)STM32_DataStruct.CommandStruct.ScopeDataBits<<24;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* ADC1 regular channel11 configuration *************************************/
  ADC_RegularChannelConfig(ADC1, ADC_Channel_8, 1, STM32_DataStruct.CommandStruct.ScopeSampleClocks);
  /* Enable ADC1 DMA */
  ADC_DMACmd(ADC1, ENABLE);

  /* ADC2 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = (uint32_t)STM32_DataStruct.CommandStruct.ScopeDataBits<<24;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC2, &ADC_InitStructure);
  /* ADC2 regular channel12 configuration *************************************/
  ADC_RegularChannelConfig(ADC2, ADC_Channel_9, 1, STM32_DataStruct.CommandStruct.ScopeSampleClocks);

  ADC_MultiModeDMARequestAfterLastTransferCmd(ENABLE);
  ADC_Cmd(ADC1, ENABLE);
  ADC_Cmd(ADC2, ENABLE);
}

void DMA_SCPConfig(void)
{
  DMA_InitTypeDef       DMA_InitStructure;

  DMA_DeInit(DMA2_Stream0);
  /* DMA2 Stream0 channel0 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_0;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)ADC_CDR_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&STM32_DataStruct.STM32_Data;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = STM32_DataStruct.CommandStruct.DataBlocks * STM32_BlockSize * 4;
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

void DMA_LGAConfig(void)
{
  DMA_InitTypeDef       DMA_InitStructure;

  DMA_DeInit(DMA2_Stream1);
  /* DMA2 Stream1 channel7 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_7;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)PE_IDR_Address;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&STM32_DataStruct.STM32_Data;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = STM32_DataStruct.CommandStruct.DataBlocks * STM32_BlockSize;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA2_Stream1, &DMA_InitStructure);
}

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  uint32_t Count;

  TIM_ClearITPendingBit(TIM3, TIM_IT_Update);
  Count=TIM2->CNT;
  STM32_DataStruct.FRQDataStructCHA.Frequency=Count-STM32_DataStruct.FRQDataStructCHA.PreviousCount;
  STM32_DataStruct.FRQDataStructCHA.PreviousCount=Count;
  Count=TIM5->CNT;
  STM32_DataStruct.FRQDataStructCHB.Frequency=Count-STM32_DataStruct.FRQDataStructCHB.PreviousCount;
  STM32_DataStruct.FRQDataStructCHB.PreviousCount=Count;
  STM32_DataStruct.CommandStruct.TriggerWait--;
  STM_EVAL_LEDToggle(LED3);
}

/*****END OF FILE****/
