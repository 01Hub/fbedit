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
#define PE_IDR_Address            ((uint32_t)0x40001011)

#define PC_IDR_Address            ((uint32_t)0x40011008)
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
#define STM32_ModeWriteData       ((uint8_t)8)
#define STM32_ModeReadData        ((uint8_t)9)

/* STM32_Triggers */
#define STM32_TriggerManual       ((uint8_t)0)
#define STM32_TriggerRisingCHA    ((uint8_t)1)
#define STM32_TriggerFallingCHA   ((uint8_t)2)
#define STM32_TriggerRisingCHB    ((uint8_t)3)
#define STM32_TriggerFallingCHB   ((uint8_t)4)
#define STM32_TriggerLGA          ((uint8_t)5)

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint8_t   Command;
  uint8_t   Mode;
  uint8_t   ScopeDataBits;
  uint8_t   ScopeSampleClocks;
  uint8_t   ScopeClockDiv;
  uint8_t   ScopeDataBlocks;
  uint8_t   ScopeTriggerMode;
  uint8_t   ScopeTriggerValue;
  uint8_t   ScopeAmplifyCHA;
  uint8_t   ScopeAmplifyCHB;
  uint8_t   ScopeDCNullOutCHA;
  uint8_t   ScopeDCNullOutCHB;
  uint8_t   LGATriggerValue;
  uint8_t   LGATriggerMask;
  uint8_t   LGATriggerEdge;
  uint8_t   TriggerWait;
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
  uint32_t  DataSize;
  uint32_t  Adress;
  uint32_t  Data;
}DataStructTypeDef;

typedef struct
{
  FRQDataStructTypeDef FRQDataStructCHA;                // 0x20000014
  FRQDataStructTypeDef FRQDataStructCHB;                // 0x20000024
  CommandStructTypeDef CommandStruct;                   // 0x20000034
  union
  {
    uint16_t STM32_Data[STM32_DataSize];                // 0x20000044
    DataStructTypeDef DataStruct[100];                  // 0x20000044
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
  u32 *adr;

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
          DMA_LGAConfig();
          WaitForTrigger();
          TIM_Cmd(TIM8, ENABLE);
          TIM_DMACmd(TIM8, TIM_DMA_Update, ENABLE);
          while (DMA_GetFlagStatus(DMA2_Stream1,DMA_FLAG_TCIF0)==RESET);
          STM32_DataStruct.CommandStruct.Command = STM32_CommandDone;
          DMA_DeInit(DMA2_Stream1);
          TIM_Cmd(TIM8, DISABLE);
          break;
        case STM32_ModeWriteData:
          // adr = (u32 *)STM32_DataStruct.STM32_CommandStruct.Address;
          // *adr = STM32_DataStruct.STM32_CommandStruct.dByte;
          break;
        case STM32_ModeReadData:
          // adr = (u32 *)STM32_DataStruct.STM32_CommandStruct.Address;
          // STM32_DataStruct.STM32_CommandStruct.dByte = *adr;
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
  switch (STM32_DataStruct.CommandStruct.ScopeTriggerMode)
  {
    case (STM32_TriggerRisingCHA):
      /* Count on rising edge */
      TIM2->CCER = 0x0000;
      // tmp=0;
      // while (tmp < 1000)
      // {
        // tmp++;
      // }
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
      tmp = STM32_DataStruct.CommandStruct.LGATriggerValue & STM32_DataStruct.CommandStruct.LGATriggerMask;
      if ((STM32_DataStruct.CommandStruct.LGATriggerEdge != 0) & (STM32_DataStruct.CommandStruct.LGATriggerMask != 0))
      {
        /* Edge sensitive */
        /* Wait while conditions are met */
        while (((GPIOE->IDR & STM32_DataStruct.CommandStruct.LGATriggerMask) == tmp) & (STM32_DataStruct.CommandStruct.TriggerWait != 0))
        {
        }
        /* Wait until conditions are met */
        while (((GPIOE->IDR & STM32_DataStruct.CommandStruct.LGATriggerMask) != tmp) & (STM32_DataStruct.CommandStruct.TriggerWait != 0))
        {
        }
      }
      else
      {
        /* Wait until conditions are met */
        while (((GPIOE->IDR & STM32_DataStruct.CommandStruct.LGATriggerMask) != tmp) & (STM32_DataStruct.CommandStruct.TriggerWait != 0))
        {
        }
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
  /* TIM8 TRGO selection */
  TIM_SelectOutputTrigger(TIM8, TIM_TRGOSource_Update);
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

  /* DMA2 Stream0 channel0 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_0;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)ADC_CDR_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&STM32_DataStruct.STM32_Data;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = STM32_DataSize/2;
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

  /* DMA2 Stream0 channel0 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_7;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)PE_IDR_Address;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&STM32_DataStruct.STM32_Data;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = STM32_DataSize;
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
  /* DMA2_Stream1 enable */
  DMA_Cmd(DMA2_Stream1, ENABLE);
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

/*******************************************************************************
* Function Name  : TIM2_IRQHandler
* Description    : This function handles TIM2 global interrupt request.
*                  It increments the TIM2H 16 bit variable on each rollover
*                  of the counter.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM2_IRQHandler(void)
// {
  // /* Clear TIM2 Update interrupt pending bit */
  // asm("mov    r1,#0x40000000");
  // asm("strh   r1,[r1,#0x10]");
  // /* Increment STM32_DataStruct.STM32_FRQDataStructCHA.TIMxH */
  // asm("mov    r1,#0x20000000");
  // asm("ldrh   r2,[r1,0xe]");
  // asm("add    r2,r2,0x1");
  // asm("strh   r2,[r1,0xe]");
// }

/*******************************************************************************
* Function Name  : TIM3_IRQHandler
* Description    : This function handles TIM3 global interrupt request.
*                  It calculates the frequency every 1000ms.
*                  Since it calculate the difference between this reading
*                  and the previous reading there is no need to take into
*                  account interrupt overhead.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM3_IRQHandler(void)
// {
  // /* Clear TIM3 Update interrupt pending bit */
  // asm("mov    r0,#0x0");
  // asm("movw   r1,#0x0400");
  // asm("movt   r1,#0x4000");
  // asm("strh   r0,[r1,#0x10]");
  // /* Decrement STM32_DataStruct.STM32_CommandStruct.TIM3_TimeOut */
  // asm("mov    r1,#0x20000000");
  // asm("ldrb   r0,[r1,0x2f]");
  // asm("cmp    r0,0x0");
  // asm("itt    ne");
  // asm("subne  r0,r0,0x1");
  // asm("strbne r0,[r1,0x2f]");
  // /* Calculate frequency TIM2 */
  // asm("mov    r0,#0x40000000");
  // asm("mov    r1,#0x20000000");
  // asm("ldrh   r2,[r1,0xe]");        // STM32_DataStruct.STM32_FRQDataStructCHA.TIMxH
  // asm("ldrh   r3,[r0,#0x24]");      // TIM2->CNT
  // asm("orr    r2,r3,r2,lsl #16");   // (STM32_DataStruct.STM32_FRQDataStructCHA.TIMxH << 16) | TIM2->CNT
  // asm("ldr    r3,[r1,0x4]");        // STM32_DataStruct.STM32_FRQDataStructCHA.PreviousCount
  // asm("str    r2,[r1,0x4]");        // STM32_DataStruct.STM32_FRQDataStructCHA.PreviousCount
  // asm("sub    r2,r2,r3");
  // asm("str    r2,[r1,0x0]");        // STM32_DataStruct.STM32_FRQDataStructCHA.Frequency
  // /* Calculate frequency TIM4 */
  // asm("movw   r0,#0x0800");
  // asm("movt   r0,#0x4000");
  // asm("ldrh   r2,[r1,0x1e]");       // STM32_DataStruct.STM32_FRQDataStructCHB.TIMxH
  // asm("ldrh   r3,[r0,#0x24]");      // TIM4->CNT
  // asm("orr    r2,r3,r2,lsl #16");   // (STM32_DataStruct.STM32_FRQDataStructCHB.TIMxH << 16) | TIM4->CNT
  // asm("ldr    r3,[r1,0x14]");       // STM32_DataStruct.STM32_FRQDataStructCHB.PreviousCount
  // asm("str    r2,[r1,0x14]");       // STM32_DataStruct.STM32_FRQDataStructCHB.PreviousCount
  // asm("sub    r2,r2,r3");
  // asm("str    r2,[r1,0x10]");       // STM32_DataStruct.STM32_FRQDataStructCHB.Frequency
// }

/*******************************************************************************
* Function Name  : TIM4_IRQHandler
* Description    : This function handles TIM4 global interrupt request.
*                  It increments the TIM4H 16 bit variable on each rollover
*                  of the counter.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM4_IRQHandler(void)
// {
  // /* Clear TIM4 Update interrupt pending bit */
  // asm("mov    r2,#0x0");
  // asm("movw   r1,#0x0800");
  // asm("movt   r1,#0x4000");
  // asm("strh   r2,[r1,#0x10]");
  // /* Increment STM32_DataStruct.STM32_FRQDataStructCHB.TIMxH */
  // asm("mov    r1,#0x20000000");
  // asm("ldrh   r2,[r1,0x1e]");
  // asm("add    r2,r2,0x1");
  // asm("strh   r2,[r1,0x1e]");
// }

/*******************************************************************************
* Function Name  : ADC_Startup
* Description    : This function calibrates ADC1.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void ADC_Startup(void)
// {
  // ADC_InitTypeDef ADC_InitStructure;
  // /* ADCCLK = PCLK2/2 */
  // RCC_ADCCLKConfig(RCC_PCLK2_Div2);
  // /* ADC1 configuration ------------------------------------------------------*/
  // ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  // ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  // ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  // ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  // ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  // ADC_InitStructure.ADC_NbrOfChannel = 1;
  // ADC_Init(ADC1, &ADC_InitStructure);
  // /* ADC1 regular channel2 configuration */ 
  // ADC_RegularChannelConfig(ADC1, ADC_Channel_2, 1, ADC_SampleTime_55Cycles5);
  // /* Enable ADC1 */
  // ADC_Cmd(ADC1, ENABLE);
  // /* Enable ADC1 reset calibaration register */   
  // ADC_ResetCalibration(ADC1);
  // /* Check the end of ADC1 reset calibration register */
  // while(ADC_GetResetCalibrationStatus(ADC1));
  // /* Start ADC1 calibaration */
  // ADC_StartCalibration(ADC1);
  // /* Check the end of ADC1 calibration */
  // while(ADC_GetCalibrationStatus(ADC1));
// }

/*******************************************************************************
* Function Name  : ADC_DVNConfiguration
* Description    : This function prepares ADC1 for Injected conversion
*                  on channel 2 and channel 3.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void ADC_DVMConfiguration(void)
// {
  // ADC_InitTypeDef ADC_InitStructure;

  // /* ADCCLK = PCLK2/8 */
  // RCC_ADCCLKConfig(RCC_PCLK2_Div8);
  // ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  // ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  // ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  // ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  // ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  // /* ADC1 single channel configuration -----------------------------*/
  // ADC_InitStructure.ADC_NbrOfChannel = 1;
  // ADC_Init(ADC1, &ADC_InitStructure);

  // ADC_InjectedSequencerLengthConfig(ADC1,2);
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_2,1,ADC_SampleTime_239Cycles5);
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_3,2,ADC_SampleTime_239Cycles5);
  // ADC_AutoInjectedConvCmd(ADC1, ENABLE);
// }

/*******************************************************************************
* Function Name  : ADC_Configuration
* Description    : This function prepares ADC1
*                  for DMA transfer on channel 8 and / or channel 9.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void ADC_Configuration(void)
// {
  // ADC_InitTypeDef ADC_InitStructure;
  // ADC_AutoInjectedConvCmd(ADC1, DISABLE);
  // /* Setup ADC Clock divisor */
  // switch (STM32_DataStruct.STM32_CommandStruct.STM32_SampleRateH)
  // {
    // case (0):
      // /* ADCCLK = PCLK2/2 */
      // RCC_ADCCLKConfig(RCC_PCLK2_Div2);
      // break;
    // case (1):
      // /* ADCCLK = PCLK2/4 */
      // RCC_ADCCLKConfig(RCC_PCLK2_Div4);
      // break;
    // case (2):
      // /* ADCCLK = PCLK2/6 */
      // RCC_ADCCLKConfig(RCC_PCLK2_Div6);
      // break;
    // case (3):
      // /* ADCCLK = PCLK2/8 */
      // RCC_ADCCLKConfig(RCC_PCLK2_Div8);
      // break;
  // }
  // ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  // ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  // ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  // ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  // ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Left;
  // switch (STM32_DataStruct.STM32_CommandStruct.STM32_Mode)
  // {
    // case STM32_ModeScopeCHA:
      // /* ADC1 single channel (CHA) configuration -----------------------------*/
      // ADC_InitStructure.ADC_NbrOfChannel = 1;
      // break;
    // case STM32_ModeScopeCHB:
      // /* ADC1 single channel (CHB) configuration -----------------------------*/
      // ADC_InitStructure.ADC_NbrOfChannel = 1;
      // break;
    // case STM32_ModeScopeCHACHB:
      // /* ADC1 dual channel configuration -------------------------------------*/
      // ADC_InitStructure.ADC_NbrOfChannel = 2;
      // break;
  // }
  // ADC_Init(ADC1, &ADC_InitStructure);
// }

/*******************************************************************************
* Function Name  : DMA_ADC_Configuration
* Description    : Configures the DMA1 channel 1 to transfer ADC data to memory.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void DMA_ADC_Configuration(void)
// {
  // DMA_InitTypeDef DMA_InitStructure;
  // DMA_DeInit(DMA1_Channel1);
  // DMA_DeInit(DMA1_Channel5);
  // DMA_InitStructure.DMA_PeripheralBaseAddr = ADC1_DR_Address+1;
  // DMA_InitStructure.DMA_MemoryBaseAddr = (u32)&STM32_DataStruct.STM32_Data;
  // DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralSRC;
  // DMA_InitStructure.DMA_BufferSize = (u32)(STM32_DataStruct.STM32_CommandStruct.STM32_DataBlocks * STM32_BlockSize * 2) - 2;
  // DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  // DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  // DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
  // DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
  // DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  // DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  // DMA_InitStructure.DMA_M2M = DMA_M2M_Disable;
  // DMA_Init(DMA1_Channel1, &DMA_InitStructure);
  // /* Clear all interrupt pending bits */
  // DMA1->IFCR =0x0FFFFFFF;
// }

/*******************************************************************************
* Function Name  : DMA_LGA_Configuration
* Description    : Configures the DMA1 channel 5 to transfer PC.00 to PC.07
*                  data to memory on each rollover of TIM15.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void DMA_LGA_Configuration(void)
// {
  // DMA_InitTypeDef DMA_InitStructure;
  // DMA_DeInit(DMA1_Channel1);
  // DMA_DeInit(DMA1_Channel5);
  // DMA_InitStructure.DMA_PeripheralBaseAddr = PC_IDR_Address;
  // DMA_InitStructure.DMA_MemoryBaseAddr = (u32)&STM32_DataStruct.STM32_Data;
  // DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralSRC;
  // DMA_InitStructure.DMA_BufferSize = (u32)(STM32_DataStruct.STM32_CommandStruct.STM32_DataBlocks * STM32_BlockSize * 2) - 2;
  // DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  // DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  // DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Byte;
  // DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Byte;
  // DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  // DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  // DMA_InitStructure.DMA_M2M = DMA_M2M_Disable;
  // DMA_Init(DMA1_Channel5, &DMA_InitStructure);
  // /* Clear all interrupt pending bits */
  // DMA1->IFCR =0x0FFFFFFF;
// }

/*******************************************************************************
* Function Name  : RCC_Configuration
* Description    : Configures the different system clocks.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void RCC_Configuration(void)
// {
  // /* RCC system reset(for debug purpose) */
  // RCC_DeInit();
  // /* Enable HSE */
  // RCC_HSEConfig(RCC_HSE_ON);
  // /* Wait till HSE is ready */
  // HSEStartUpStatus = RCC_WaitForHSEStartUp();
  // if(HSEStartUpStatus == SUCCESS)
  // {
    // /* Enable Prefetch Buffer */
    // FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);
    // /* Flash 2 wait state */
    // FLASH_SetLatency(FLASH_Latency_0);
    // /* HCLK = SYSCLK */
    // RCC_HCLKConfig(RCC_SYSCLK_Div1); 
    // /* PCLK2 = HCLK */
    // RCC_PCLK2Config(RCC_HCLK_Div1); 
    // /* PCLK1 = HCLK */
    // RCC_PCLK1Config(RCC_HCLK_Div1);
    // /* ADCCLK = PCLK2/2 */
    // RCC_ADCCLKConfig(RCC_PCLK2_Div2);
// #ifdef STM32Clock24MHz
    // /* PLLCLK = 8MHz * 3 = 24 MHz */
    // RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_3);
// #endif
// #ifdef STM32Clock28MHz
    // /* PLLCLK = 8MHz / 2 * 7 = 28 MHz */
    // RCC_PLLConfig(RCC_PLLSource_HSE_Div2, RCC_PLLMul_7);
// #endif
// #ifdef STM32Clock32MHz
    // /* PLLCLK = 8MHz * 4 = 32 MHz */
    // RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_4);
// #endif
// #ifdef STM32Clock40MHz
    // /* PLLCLK = 8MHz * 5 = 40 MHz */
    // RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_5);
// #endif
// #ifdef STM32Clock48MHz
    // /* PLLCLK = 8MHz * 6 = 48 MHz */
    // RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_6);
// #endif
// #ifdef STM32Clock56MHz
    // /* PLLCLK = 8MHz * 7 = 56 MHz */
    // RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_7);
// #endif
    // /* Enable PLL */ 
    // RCC_PLLCmd(ENABLE);
    // /* Wait till PLL is ready */
    // while(RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET)
    // {
    // }
    // /* Select PLL as system clock source */
    // RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);
    // /* Wait till PLL is used as system clock source */
    // while(RCC_GetSYSCLKSource() != 0x08)
    // {
    // }
  // }
  // /* Enable peripheral clocks ------------------------------------------------*/
  // /* Enable DMA1 clock */
  // RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1, ENABLE);
  // /* Enable TIM1, ADC1, GPIOA, GPIOB and GPIOC clock */
  // RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1 | RCC_APB2Periph_TIM15 | RCC_APB2Periph_TIM16 | RCC_APB2Periph_TIM17 | RCC_APB2Periph_ADC1 | RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC, ENABLE);
  // /* Enable DAC, TIM2, TIM3, TIM4, TIM6 and TIM7 clock */
  // RCC_APB1PeriphClockCmd(RCC_APB1Periph_DAC | RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4 | RCC_APB1Periph_TIM6 | RCC_APB1Periph_TIM7, ENABLE);
// }

/*******************************************************************************
* Function Name  : GPIO_Configuration
* Description    : Configures the different GPIO ports.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void GPIO_Configuration(void)
// {
  // GPIO_InitTypeDef GPIO_InitStructure;
  // /* Configure ADC Channel9 (PB.01) and ADC Channel8 (PB.00) as analog input */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_0;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AIN;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOB, &GPIO_InitStructure);
  // /* Configure DAC Channel1 (PA.04), DAC Channel2 (PA.05), ADC Channel2 (PA.02) and ADC Channel3 (PA.03) as analog input */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4 | GPIO_Pin_3 | GPIO_Pin_2;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AIN;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOA, &GPIO_InitStructure);
  // /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOC, &GPIO_InitStructure);
  // /* TIM2 channel 2 pin (PA.01) configuration */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOA, &GPIO_InitStructure);
  // /* TIM4 channel 2 pin (PB.07) configuration */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOB, &GPIO_InitStructure);
  // /* TIM16 Channel 1 pin (PB.08, TIM17 Channel 1 pin (PB.09) configuration */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOB, &GPIO_InitStructure);
  // /* TIM1 channel 1 pin (PA.08), channel 2 pin (PA.09), channel 3 pin (PA.10) and channel 4 pin (PA.11) configuration */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11 | GPIO_Pin_10 | GPIO_Pin_9 | GPIO_Pin_8;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOA, &GPIO_InitStructure);
  // /* LGA PC.07 to PC.00 configuration */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4 | GPIO_Pin_3 | GPIO_Pin_2 | GPIO_Pin_1 | GPIO_Pin_0;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOC, &GPIO_InitStructure);
  // /* Scope CHA / CHB amplification selector (Open Drain Output) */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_15 | GPIO_Pin_14 | GPIO_Pin_13 | GPIO_Pin_12 | GPIO_Pin_11 | GPIO_Pin_10;
  // GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_OD;
  // GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  // GPIO_Init(GPIOB, &GPIO_InitStructure);
// }

/*******************************************************************************
* Function Name  : NVIC_Configuration
* Description    : Configures Vector Table base location.
*                  Configures interrupts.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void NVIC_Configuration(void)
// {
  // NVIC_InitTypeDef NVIC_InitStructure;

  // /* Set the Vector Table base location at 0x08000000 */ 
  // NVIC_SetVectorTable(NVIC_VectTab_FLASH, 0x0);   
  // /* Enable the TIM2 global Interrupt */
  // NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQChannel;
  // NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  // NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  // NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  // NVIC_Init(&NVIC_InitStructure);
  // /* Enable the TIM3 global Interrupt */
  // NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQChannel;
  // NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  // NVIC_InitStructure.NVIC_IRQChannelSubPriority = 3;
  // NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  // NVIC_Init(&NVIC_InitStructure);
  // /* Enable the TIM4 global Interrupt */
  // NVIC_InitStructure.NVIC_IRQChannel = TIM4_IRQChannel;
  // NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  // NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;
  // NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  // NVIC_Init(&NVIC_InitStructure);
// }

/*******************************************************************************
* Function Name  : TIM1_Configuration
* Description    : Configures TIM1 to generate PWM output.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM1_Configuration(void)
// {
  /* -----------------------------------------------------------------------
    TIM1 Configuration: generate 4 PWM signals with 4 different duty cycles:
    TIM1CLK = 28 MHz, Prescaler = 0x0, TIM1 counter clock = 28 MHz
    TIM1 ARR Register = 255 => TIM1 Frequency = TIM1 counter clock/(ARR + 1)
    TIM1 Frequency = 109.375 KHz.
    TIM1 Channel1 duty cycle = (TIM1_CCR1 / TIM1_ARR)* 100
    TIM1 Channel2 duty cycle = (TIM1_CCR2 / TIM1_ARR)* 100
    TIM1 Channel3 duty cycle = (TIM1_CCR3 / TIM1_ARR)* 100
    TIM1 Channel4 duty cycle = (TIM1_CCR4 / TIM1_ARR)* 100
  ----------------------------------------------------------------------- */

  // TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  // TIM_OCInitTypeDef  TIM_OCInitStructure;
  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = 255;
  // TIM_TimeBaseStructure.TIM_Prescaler = 0;
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseInit(TIM1, &TIM_TimeBaseStructure);

  // TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  // TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  // TIM_OCInitStructure.TIM_OutputNState = TIM_OutputState_Disable;
  // TIM_OCInitStructure.TIM_Pulse = (u16)0x7F;
  // TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  // TIM_OCInitStructure.TIM_OCNPolarity = TIM_OCPolarity_Low;
  // TIM_OCInitStructure.TIM_OCIdleState = TIM_OCIdleState_Reset;
  // TIM_OCInitStructure.TIM_OCNIdleState = TIM_OCIdleState_Reset;
  // /* PWM1 Mode configuration: Channel1 */
  // TIM_OC1Init(TIM1, &TIM_OCInitStructure);
  // TIM_OC1PreloadConfig(TIM1, TIM_OCPreload_Enable);
  // /* PWM1 Mode configuration: Channel2 */
  // TIM_OC2Init(TIM1, &TIM_OCInitStructure);
  // TIM_OC2PreloadConfig(TIM1, TIM_OCPreload_Enable);
  // /* PWM1 Mode configuration: Channel3 */
  // TIM_OC3Init(TIM1, &TIM_OCInitStructure);
  // TIM_OC3PreloadConfig(TIM1, TIM_OCPreload_Enable);
  // /* PWM1 Mode configuration: Channel4 */
  // TIM_OC4Init(TIM1, &TIM_OCInitStructure);
  // TIM_OC4PreloadConfig(TIM1, TIM_OCPreload_Enable);
  // /* TIM1 enable counter */
  // TIM_Cmd(TIM1, ENABLE);
  // /* TIM1 Main Output Enable */
  // TIM_CtrlPWMOutputs(TIM1, ENABLE);
// }

/*******************************************************************************
* Function Name  : TIM2_Configuration
* Description    : Configures TIM2 to count up on rising edges on CH2 PA.01
*                  An interrupt is generated on each rollover.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM2_Configuration(void)
// {
  // TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = 0xffff;
  // TIM_TimeBaseStructure.TIM_Prescaler = 0;
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  // TIM2->CCMR1 = 0x0100;     //CC2S=01
  // TIM2->SMCR = 0x0067;      //TS=110, SMS=111
// }

/*******************************************************************************
* Function Name  : TIM3_Configuration
* Description    : Configures TIM3 to count up and generate interrupt every 1000ms.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM3_Configuration(void)
// {
  // TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = 9999;
// #ifdef STM32Clock24MHz
  // TIM_TimeBaseStructure.TIM_Prescaler = 2399;
// #endif
// #ifdef STM32Clock28MHz
  // TIM_TimeBaseStructure.TIM_Prescaler = 2799;
// #endif
// #ifdef STM32Clock32MHz
  // TIM_TimeBaseStructure.TIM_Prescaler = 3199;
// #endif
// #ifdef STM32Clock40MHz
  // TIM_TimeBaseStructure.TIM_Prescaler = 3999;
// #endif
// #ifdef STM32Clock48MHz
  // TIM_TimeBaseStructure.TIM_Prescaler = 4799;
// #endif
// #ifdef STM32Clock56MHz
  // TIM_TimeBaseStructure.TIM_Prescaler = 5599;
// #endif
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  // TIM_InternalClockConfig(TIM3);
// }

/*******************************************************************************
* Function Name  : TIM4_Configuration
* Description    : Configures TIM4 to count up on rising edges on CH2 PB.07
*                  An interrupt is generated on each rollover.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM4_Configuration(void)
// {
  // TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = 0xffff;
  // TIM_TimeBaseStructure.TIM_Prescaler = 0;
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseInit(TIM4, &TIM_TimeBaseStructure);
  // TIM4->CCMR1 = 0x0001;     //CC2S=01
  // TIM4->SMCR = 0x0067;      //TS=110, SMS=111
// }

/*******************************************************************************
* Function Name  : TIM6_Configuration
* Description    : Configures TIM6 to count up.
*                  A TRG0 signal is generated on each rollover.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM6_Configuration(void)
// {
  // /* TIM6 TRGO selection */
  // TIM_SelectOutputTrigger(TIM6, TIM_TRGOSource_Update);
  // /* TIM6 enable counter */
  // TIM_Cmd(TIM6, ENABLE);
// }

/*******************************************************************************
* Function Name  : TIM7_Configuration
* Description    : Configures TIM7 to count up.
*                  A TRG0 signal is generated on each rollover.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM7_Configuration(void)
// {
  // /* TIM6 TRGO selection */
  // TIM_SelectOutputTrigger(TIM7, TIM_TRGOSource_Update);
  // /* TIM7 enable counter */
  // TIM_Cmd(TIM7, ENABLE);
// }

/*******************************************************************************
* Function Name  : TIM15_Configuration
* Description    : Configures TIM115 to count up.
*                  A DMA request is generated on each rollover.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM15_Configuration()
// {
  // TIM_DeInit(TIM15);
  // TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = (STM32_DataStruct.STM32_CommandStruct.STM32_SampleRateH << 8) + STM32_DataStruct.STM32_CommandStruct.STM32_SampleRateL;
  // TIM_TimeBaseStructure.TIM_Prescaler = 0;
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseInit(TIM15, &TIM_TimeBaseStructure);
  // TIM_DMACmd(TIM15,TIM_DMA_Update,ENABLE);
// }

/*******************************************************************************
* Function Name  : TIM16_Configuration
* Description    : Configures TIM16 to generate PWM output.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM16_Configuration(void)
// {
  // TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  // TIM_OCInitTypeDef  TIM_OCInitStructure;
  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = 255;
  // TIM_TimeBaseStructure.TIM_Prescaler = 0;
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseInit(TIM16, &TIM_TimeBaseStructure);
  // /* PWM1 Mode configuration: Channel1 */
  // TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  // TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  // TIM_OCInitStructure.TIM_Pulse = (u16)0x0000;
  // TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  // TIM_OC1Init(TIM16, &TIM_OCInitStructure);
  // TIM_OC1PreloadConfig(TIM16, TIM_OCPreload_Enable);
  // TIM16->CCR1 = (u16)0x7F;
  // /* TIM16 Main Output Enable */
  // TIM_CtrlPWMOutputs(TIM16, ENABLE);
// }

/*******************************************************************************
* Function Name  : TIM17_Configuration
* Description    : Configures TIM17 to generate PWM output.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
// void TIM17_Configuration(void)
// {
  // TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  // TIM_OCInitTypeDef  TIM_OCInitStructure;
  // /* Time base configuration */
  // TIM_TimeBaseStructure.TIM_Period = 255;
  // TIM_TimeBaseStructure.TIM_Prescaler = 0;
  // TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  // TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  // TIM_TimeBaseInit(TIM17, &TIM_TimeBaseStructure);
  // /* PWM1 Mode configuration: Channel1 */
  // TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  // TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  // TIM_OCInitStructure.TIM_Pulse = (u16)0x0000;
  // TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  // TIM_OC1Init(TIM17, &TIM_OCInitStructure);
  // TIM_OC1PreloadConfig(TIM17, TIM_OCPreload_Enable);
  // TIM17->CCR1 = (u16)0x7F;
  // /* TIM17 Main Output Enable */
  // TIM_CtrlPWMOutputs(TIM17, ENABLE);
// }

/*****END OF FILE****/
