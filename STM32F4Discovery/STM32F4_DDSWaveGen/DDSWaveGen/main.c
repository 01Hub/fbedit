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

/*
  Port pins
  ------------------------------------
  PA1       Frequency counter input
  PA2       High speed clock output
  PA3       DVM input
  PA4       DDS wave output
  PA5       Peak input
  PA6       DDS sweep sync output
  ------------------------------------
*/
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include <stdio.h>
#include "wave.h"

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

/* DDS WaveType */
#define WAVE_Sine                 ((uint8_t)1)
#define WAVE_Triangle             ((uint8_t)2)
#define WAVE_Square               ((uint8_t)3)
#define WAVE_SawTooth             ((uint8_t)4)
#define WAVE_RevSawTooth          ((uint8_t)5)

typedef struct
{
  uint32_t Frequency;
  uint32_t PreviousCount;
  uint32_t Reserved1;
  uint32_t Reserved2;
}STM32_FRQTypeDef;

typedef struct
{
  STM32_FRQTypeDef STM32_Frequency;                   // 0x20000014
  uint8_t  cmnd;                                      // 0x20000024
  uint8_t  HSC_enable;                                // 0x20000025
  uint16_t HSC_div;                                   // 0x20000026
  uint32_t HSC_frq;                                   // 0x20000028
  uint32_t HSC_dutycycle;                             // 0x2000002C
  uint32_t DDS_PhaseFrq;                              // 0x20000030
  uint8_t  DDS_SubMode;                               // 0x20000034
  uint8_t  DDS_DacBuffer;                             // 0x20000035
  uint16_t SWEEP_StepTime;                            // 0x20000036
  uint32_t SWEEP_UpDovn;                              // 0x20000038
  uint32_t SWEEP_Min;                                 // 0x2000003C
  uint32_t SWEEP_Max;                                 // 0x20000040
  uint32_t SWEEP_Add;                                 // 0x20000044
  uint32_t WaveType;                                  // 0x00000048
  uint32_t Amplitude;                                 // 0x0000004C
  int32_t DCOffset;                                   // 0x00000050
  uint16_t Wave[2048];                                // 0x20000054
  uint16_t Peak[1536];                                // 0x20001054
}STM32_CMNDTypeDef;
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
static STM32_CMNDTypeDef STM32_Command;               // 0x20000014
/* Private function prototypes -----------------------------------------------*/
void FRQ_Config(void);
void HSC_Config(void);
void DAC_Config(void);
void ADC_Config(void);
void DDSWaveGenerator(void);
void DDSSweepWaveGenerator(void);
void DDSSweepWaveGeneratorPeak(void);
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
  int32_t tmp;

  /* Initialize Leds mounted on STM32F4-Discovery board */
  STM_EVAL_LEDInit(LED3);
  STM_EVAL_LEDInit(LED4);
  STM_EVAL_LEDInit(LED5);
  STM_EVAL_LEDInit(LED6);
  STM_EVAL_LEDOff(LED3);
  STM_EVAL_LEDOff(LED4);
  STM_EVAL_LEDOff(LED5);
  STM_EVAL_LEDOff(LED6);
  /* Setup frequency counter */
  FRQ_Config();
  /* Setup DVM */
  ADC_Config();
  /* Setup DDS */
  DAC_Config();

  while (1)
  {
    if (STM32_Command.cmnd == STM32_CMNDStart)
    {
      /* Reset STM32_CMNDStart */
      STM32_Command.cmnd = STM32_CMNDWait;
      /* Setup high speed clock */
      HSC_Config();
      i=0;
      switch (STM32_Command.WaveType)
      {
        case WAVE_Sine:
          while (i<2048)
          {
            STM32_Command.Wave[i] = SineWave[i];
            i++;
          }
          break;
        case WAVE_Triangle:
          while (i<2048)
          {
            STM32_Command.Wave[i] = TriangleWave[i];
            i++;
          }
          break;
        case WAVE_Square:
          while (i<2048)
          {
            STM32_Command.Wave[i] = SquareWave[i];
            i++;
          }
          break;
        case WAVE_SawTooth:
          while (i<2048)
          {
            STM32_Command.Wave[i] = SawToothWave[i];
            i++;
          }
          break;
        case WAVE_RevSawTooth:
          while (i<2048)
          {
            STM32_Command.Wave[i] = RevSawToothWave[i];
            i++;
          }
          break;
      }
      // i=0;
      // while (i<2048)
      // {
        // tmp = (STM32_Command.Wave[i] * STM32_Command.Amplitude) / 4095;
        // tmp = tmp + STM32_Command.DCOffset;
        // if (tmp<0)
        // {
          // tmp = 0;
        // }
        // if (tmp>4095)
        // {
          // tmp = 4095;
        // }
        // STM32_Command.Wave[i] = tmp;
        // i++;
      // }
      switch (STM32_Command.DDS_SubMode)
      {
        case SWEEP_SubModeOff:
          STM_EVAL_LEDOn(LED5);
          DDSWaveGenerator();
          break;
        case SWEEP_SubModeUp:
          STM_EVAL_LEDOn(LED6);
          DDSSweepWaveGenerator();
          break;
        case SWEEP_SubModeDown:
          STM_EVAL_LEDOn(LED6);
          DDSSweepWaveGenerator();
          break;
        case SWEEP_SubModeUpDown:
          STM_EVAL_LEDOn(LED6);
          DDSSweepWaveGenerator();
          break;
        case SWEEP_SubModePeak:
          STM_EVAL_LEDOn(LED6);
          DDSSweepWaveGeneratorPeak();
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
      STM_EVAL_LEDOn(LED3);
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
  /* TIM2, TIM3, TIM5 and DAC clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM5 | RCC_APB1Periph_TIM6 | RCC_APB1Periph_TIM7 | RCC_APB1Periph_DAC, ENABLE);
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

void DAC_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  DAC_InitTypeDef  DAC_InitStructure;

  /* DAC channel 1 (DAC_OUT1 = PA.4) configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* DAC channel1 Configuration */
  DAC_InitStructure.DAC_Trigger = DAC_Trigger_None;
  DAC_InitStructure.DAC_WaveGeneration = DAC_WaveGeneration_None;
  if (STM32_Command.DDS_DacBuffer)
  {
    DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Enable;
  }
  else
  {
    DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Disable;
  }
  DAC_Init(DAC_Channel_1, &DAC_InitStructure);
  /* Enable DAC Channel1 */
  DAC_Cmd(DAC_Channel_1, ENABLE);
}

void ADC_Config(void)
{
  ADC_InitTypeDef       ADC_InitStructure;
  ADC_CommonInitTypeDef ADC_CommonInitStructure;
  GPIO_InitTypeDef      GPIO_InitStructure;

  ADC_CommonStructInit(&ADC_CommonInitStructure);
  ADC_StructInit(&ADC_InitStructure);
  /* Enable ADC1 and ADC2 clocks */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC1 | RCC_APB2Periph_ADC2, ENABLE);
  /* Configure ADC1 Channel3 and and ADC2 Channel5 pins as analog inputs ******************************/
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_3 | GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  /* ADC Common Init **********************************************************/
  ADC_CommonInitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_CommonInitStructure.ADC_Prescaler = ADC_Prescaler_Div2;
  ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_Disabled;
  ADC_CommonInitStructure.ADC_TwoSamplingDelay = ADC_TwoSamplingDelay_5Cycles;
  ADC_CommonInit(&ADC_CommonInitStructure);

  /* ADC1 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = ADC_Resolution_12b;
  ADC_InitStructure.ADC_ScanConvMode = DISABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* ADC1 regular channel3 configuration *************************************/
  ADC_RegularChannelConfig(ADC1, ADC_Channel_3, 1, ADC_SampleTime_480Cycles);
  /* Enable ADC1 */
  ADC_Cmd(ADC1, ENABLE);
  /* Start ADC1 Software Conversion */ 
  ADC_SoftwareStartConv(ADC1);

  /* ADC2 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = ADC_Resolution_12b;
  ADC_InitStructure.ADC_ScanConvMode = DISABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC2, &ADC_InitStructure);
  /* ADC2 regular channel5 configuration *************************************/
  ADC_RegularChannelConfig(ADC2, ADC_Channel_5, 1, ADC_SampleTime_3Cycles);
  /* Enable ADC2 */
  ADC_Cmd(ADC2, ENABLE);
  /* Start ADC2 Software Conversion */ 
  ADC_SoftwareStartConv(ADC2);
}

/*******************************************************************************
* Function Name  : DDSWaveLoop
* Description    : This function generates the DDS waveform
*                  It updates the DAC every 8 cycles.
*                  With a 168MHz system clock the update
*                  frequency is 21MHz.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void DDS_WaveLoop(void)
{
  while (1)
  {
    asm("mov    r5,r3,lsr #21");
    asm("ldrh   r5,[r1,r5,lsl #1]");
    asm("strh   r5,[r2,#0x0]");
    asm("add    r3,r3,r4");
  }
}

/*******************************************************************************
* Function Name  : DDSWaveGenerator
* Description    : This function generates a waveform using DDS
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void DDSWaveGenerator(void)
{
  asm("movw   r1,#0x0054");
  asm("movt   r1,#0x2000");       /* STM32_Command.Wave[0] = 0x20000054 */
  asm("movw   r2,#0x7408");
  asm("movt   r2,#0x4000");       /* DAC_DHR12R1 */
  asm("mov    r3,#0x0");          /* DDSPhase pointer value */
  asm("movw   r4,#0x0030");
  asm("movt   r4,#0x2000");       /* STM32_Command.DDSPhaseFrq = 0x20000030 */
  asm("ldr    r4,[r4,#0x0]");     /* DDSPhaseFrq value */

  DDS_WaveLoop();
}

/*******************************************************************************
* Function Name  : DDSSweepWaveGenerator
* Description    : This function generates a sweep waveform using DDS
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void DDSSweepWaveGenerator(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_6;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  /* TIM6 configuration */
  TIM_TimeBaseStructure.TIM_Period = STM32_Command.SWEEP_StepTime;
  TIM_TimeBaseStructure.TIM_Prescaler = 8399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM6, &TIM_TimeBaseStructure);
  TIM_InternalClockConfig(TIM6);

  /* Enable the TIM6 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM6_DAC_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);

  TIM_Cmd(TIM6, ENABLE);
  TIM_ClearITPendingBit(TIM6,TIM_IT_Update);
  TIM_ITConfig(TIM6, TIM_IT_Update, ENABLE);

  /* Used by Clear TIM6 Update interrupt pending bit */
  asm("mov    r10,#0x1000");
  asm("movt   r10,#0x4000");

  asm("movw   r9,#0x0000");
  asm("movt    r9,#0x4002");      /* GPIOA */
  asm("movw   r1,#0x0054");
  asm("movt   r1,#0x2000");       /* STM32_Command.Wave[0] = 0x20000054 */
  asm("movw   r2,#0x7408");
  asm("movt   r2,#0x4000");       /* DAC_DHR12R1 */
  asm("mov    r3,#0x0");          /* DDSPhase pointer value */

  asm("movw   r8,#0x0");          /* STM32_Command.SWEEP_UpDown = 0x20000038 */
  asm("movt   r8,#0x2000");
  asm("ldr    r0,[r8,#0x38]");    /* SWEEP up or down=0 / up and down=1 */
  asm("ldr    r6,[r8,#0x3C]");    /* STM32_Command.SWEEP_Min = 0x2000003C */
  asm("ldr    r7,[r8,#0x40]");    /* STM32_Command.SWEEP_Max = 0x20000040 */
  asm("ldr    r8,[r8,#0x44]");    /* STM32_Command.SWEEP_Add = 0x20000044 */
  asm("mov    r4,r6");            /* STM32_Command.SWEEP_Min */

  DDS_WaveLoop();
}

/*******************************************************************************
* Function Name  : TIM6_DAC_IRQHandler
* Description    : This function handles TIM6 global interrupt request.
*                  It is used by dds sweep
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM6_DAC_IRQHandler(void)
{
  /* Clear TIM6 Update interrupt pending bit */
  asm("mov    r12,#0x0");
  asm("strh   r12,[r10,#0x8 *2]");
  /* Clear sweep sync */
  asm("mov    r12,#0x4000");
  asm("str    r12,[r9,#0x18]");
  /* Prepare set sweep sync */
  asm("mov    r12,#0x0040");

  asm("cbnz   r0,lblupdown");
  /* Up or Down*/
  asm("add    r4,r8");            /* SWEEP_Add */
  asm("cmp    r4,r7");            /* SWEEP_Max */
  asm("itt     eq");              /* Make the next two instructions conditional */
  asm("moveq  r4,r6");            /* Conditional load SWEEP_Min */
  asm("streq  r12,[r9,#0x18]");   /* Conditional set sweep sync */
  asm("bx     lr");               /* Return */

  /* Up & Down */
  asm("lblupdown:");
  asm("add    r4,r8");            /* SWEEP_Add */
  asm("cmp    r4,r7");            /* SWEEP_Max */
  asm("it     ne");               /* Make the next instruction conditional */
  asm("bxne   lr");               /*  Conditional return */
  /* Change direction */
  asm("mov    r11,r6");           /* tmp = SWEEP_Min */
  asm("mov    r6,r7");            /* SWEEP_Min = SWEEP_Max */
  asm("mov    r7,r11");           /* SWEEP_Max = tmp */
  asm("sub    r8,r9,r8");         /* Negate SWEEP_Add */
}

/*******************************************************************************
* Function Name  : DDSSweepWaveGeneratorPeak
* Description    : This function generates a sweep waveform using DDS
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void DDSSweepWaveGeneratorPeak(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  TIM_TimeBaseStructure.TIM_Period = STM32_Command.SWEEP_StepTime;
  TIM_TimeBaseStructure.TIM_Prescaler = 8399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM7, &TIM_TimeBaseStructure);
  TIM_InternalClockConfig(TIM7);
  /* Enable the TIM7 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM7_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* TIM7 enable counter */
  TIM_Cmd(TIM7, ENABLE);
  TIM_ClearITPendingBit(TIM7,TIM_IT_Update);
  TIM_ITConfig(TIM7, TIM_IT_Update, ENABLE);

  /* Used by Clear TIM7 Update interrupt pending bit */
  asm("mov    r9,#0x0");
  asm("mov    r10,#0x1400");
  asm("movt   r10,#0x4000");

  asm("movw   r1,#0x0054");
  asm("movt   r1,#0x2000");       /* STM32_Command.Wave[0] = 0x20000054 */
  asm("movw   r2,#0x7408");
  asm("movt   r2,#0x4000");       /* DAC_DHR12R1 */
  asm("mov    r3,#0x0");          /* DDSPhase pointer value */

  asm("movw   r8,#0x0");
  asm("movt   r8,#0x2000");       /* Pointer to sweep init data */
  asm("ldr    r11,[r8,#0x3C]");   /* SWEEP_Min */
  asm("ldr    r12,[r8,#0x40]");   /* SWEEP_Max */
  asm("ldr    r8,[r8,#0x44]");    /* SWEEP_Add */
  asm("mov    r4,r11");           /* SWEEP_Min */
  asm("mov    r6,#0x54");         /* Peak index */

  DDS_WaveLoop();
}

/*******************************************************************************
* Function Name  : TIM7_IRQHandler
* Description    : This function handles TIM7 global interrupt request.
*                  It is used by dds sweep
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM7_IRQHandler(void)
{
  /* Clear TIM7 Update interrupt pending bit */
  asm("strh   r9,[r10,#0x8 *2]");

  /* Read ADC2 channel 5 */
  asm("mov    r0,#0x2100");
  asm("movt   r0,#0x4001");
  asm("ldrh   r7,[r0,#0x4C]");    /* Get ADC2 value */
  asm("mov    r0,#0x1000");
  asm("movt   r0,#0x2000");       /* ADC value start address */
  asm("strh   r7,[r0,r6]");       /* Store value in ram */
  asm("add    r6,r6,#0x2");       /* Increment index */

  /* Up */
  asm("add    r4,r8");            /* SWEEP add */
  asm("cmp    r4,r12");           /* SWEEP max */
  asm("itt    eq");               /* Make the next 2 instructions conditional */
  asm("moveq  r4,r11");           /* Conditional load SWEEP min */
  asm("moveq  r6,#0x54");         /* Conditional reset index */
}

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  /* Clear TIM3 Update interrupt pending bit */
  asm("mov    r0,#0x40000000");     // TIM2
  asm("strh   r0,[r0,#0x410]");     // TIM3->SR
  /* Calculate frequency TIM2 */
  asm("ldr    r2,[r0,#0x24]");      // TIM2->CNT
  asm("mov    r1,#0x20000000");
  asm("ldr    r3,[r1,#0x18]");      // STM32_Frequency.PreviousCount
  asm("str    r2,[r1,#0x18]");      // STM32_Frequency.PreviousCount
  asm("sub    r2,r2,r3");
  asm("str    r2,[r1,#0x14]");      // STM32_Frequency.Frequency
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
