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
  PA0					TIM5_CH1	Input for frequency counter scope CHB
  PA1					TIM2_CH2	Input for frequency counter scope CHA
  PA4         DDS wave output
  PA6         DDS sweep sync output

  PB13				SPI2_SCK
  PB15				SPI2_MOSI
  ------------------------------------
*/
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "wave.h"

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint32_t FrequencyCHA;                                  // 0x20000002
  uint32_t PreviousCountCHA;
  uint32_t FrequencyCHB;                                  // 0x2000000A
  uint32_t PreviousCountCHB;
}STM32_FRQTypeDef;

typedef struct
{
  STM32_FRQTypeDef STM32_Frequency;                       // 0x20000002
  uint8_t   DDS_WaveType;                                 // 0x20000012
  uint8_t   DDS_SweepMode;                                // 0x20000013
  uint32_t  DDS_PhaseAdd;                                 // 0x20000014
  uint16_t  DDS_Amplitude;                                // 0x20000018
  uint16_t  DDS_DCOffset;                                 // 0x2000001A
  uint32_t  SWEEP_Add;                                    // 0x2000001C
  uint16_t  SWEEP_StepTime;                               // 0x20000020
  uint16_t  SWEEP_StepCount;                              // 0x20000022
  uint32_t  SWEEP_Min;                                    // 0x20000024
  uint32_t  SWEEP_Max;                                    // 0x20000028
  uint16_t Wave[2048];                                    // 0x2000002C
}STM32_CMNDTypeDef;

/* Private define ------------------------------------------------------------*/
#define STM32_CMNDWait            ((uint8_t)0)
#define STM32_CMNDStart           ((uint8_t)1)
#define STM32_CMNDFrqEnable       ((uint8_t)2)

/* DDS SWEEP SubModes */
#define SWEEP_ModeOff             ((uint8_t)0)
#define SWEEP_ModeUp              ((uint8_t)1)
#define SWEEP_ModeDown            ((uint8_t)2)
#define SWEEP_ModeUpDown          ((uint8_t)3)

/* DDS WaveType */
#define WAVE_Sine                 ((uint8_t)0)
#define WAVE_Triangle             ((uint8_t)1)
#define WAVE_Square               ((uint8_t)2)
#define WAVE_SawTooth             ((uint8_t)3)
#define WAVE_RevSawTooth          ((uint8_t)4)

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
static STM32_CMNDTypeDef STM32_Command;                   // 0x20000002
uint16_t *Adr;                                            // 0x2000102C

/* Private function prototypes -----------------------------------------------*/
void DDS_Config(void);
void WaveSetup(void);
void DDS_WaveLoop(void);
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

  STM32_Command.DDS_WaveType = WAVE_Sine;
  STM32_Command.DDS_SweepMode = SWEEP_ModeOff;
  STM32_Command.DDS_PhaseAdd = 204522;
  STM32_Command.DDS_Amplitude = 0xFFF;
  STM32_Command.DDS_DCOffset = 0xFFF;
  STM32_Command.SWEEP_Add = 2045;
  STM32_Command.SWEEP_StepTime = 100;
  STM32_Command.SWEEP_StepCount = 10;
  STM32_Command.SWEEP_Min = 194297;
  STM32_Command.SWEEP_Max = 214747;
  Adr = 0;
  /* Setup GPIO, TIM's, DAC and SPI */
  DDS_Config();
  /* Setup wave data */
  WaveSetup();
  asm("movw   r1,#0x002C");
  asm("movt   r1,#0x2000");           /* STM32_Command.Wave[0] = 0x2000002C */
  asm("movw   r2,#0x7408");
  asm("movt   r2,#0x4000");           /* DAC_DHR12R1 */
  asm("mov    r3,#0x0");              /* DDSPhase pointer value */
  asm("movw   r4,#0x0014");
  asm("movt   r4,#0x2000");           /* STM32_Command.DDS_PhaseAdd = 0x20000014 */
  asm("ldr    r4,[r4,#0x0]");         /* DDSPhaseFrq value */
  /* Start wave generation */
  DDS_WaveLoop();
}

void WaveSetup(void)
{
  uint32_t i;
  int32_t tmp;

  i=0;
  switch (STM32_Command.DDS_WaveType)
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
  i=0;
  while (i<2048)
  {
    tmp = (STM32_Command.Wave[i] * STM32_Command.DDS_Amplitude) / 4096;
    tmp = (tmp - STM32_Command.DDS_Amplitude/2)+STM32_Command.DDS_DCOffset-2048;
    if (tmp<0)
    {
      tmp = 0;
    }
    if (tmp>4095)
    {
      tmp = 4095;
    }
    STM32_Command.Wave[i] = tmp;
    i++;
  }
}

void DDS_Config(void)
{
  NVIC_InitTypeDef          NVIC_InitStructure;
  TIM_TimeBaseInitTypeDef   TIM_TimeBaseStructure;
  GPIO_InitTypeDef          GPIO_InitStructure;
  DAC_InitTypeDef           DAC_InitStructure;
  SPI_InitTypeDef           SPI_InitStructure;

  /* GPIOA, GPIOB, SPI2, TIM2, TIM3, TIM5, TIM6 and DAC clock enable */
  RCC_APB1PeriphClockCmd(RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOB | RCC_APB1Periph_SPI2 | RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM5 | RCC_APB1Periph_TIM6 | RCC_APB1Periph_DAC, ENABLE);

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

  /* TIM3 1 second Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 9999;
  TIM_TimeBaseStructure.TIM_Prescaler = 8399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);

  /* Enable the TIM3 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  TIM_ClearITPendingBit(TIM3,TIM_IT_Update);
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);

  /* TIM6 configuration */
  TIM_TimeBaseStructure.TIM_Period = STM32_Command.SWEEP_StepTime-1;
  TIM_TimeBaseStructure.TIM_Prescaler = 8399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM6, &TIM_TimeBaseStructure);
  TIM_InternalClockConfig(TIM6);
  TIM_ARRPreloadConfig(TIM6, ENABLE);

  /* Enable the TIM6 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM6_DAC_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  TIM_ClearITPendingBit(TIM6,TIM_IT_Update);
  TIM_ITConfig(TIM6, TIM_IT_Update, ENABLE);

  /* Sweep sync output */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_6;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  /* DAC channel 1 (DAC_OUT1 = PA.4) configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* DAC channel1 Configuration */
  DAC_InitStructure.DAC_Trigger = DAC_Trigger_None;
  DAC_InitStructure.DAC_WaveGeneration = DAC_WaveGeneration_None;
  DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Enable;
  DAC_Init(DAC_Channel_1, &DAC_InitStructure);
  /* Enable DAC Channel1 and output buffer */
  DAC->CR = 0x1;

  /* Configure SPI2 SCK and MOSI pins */
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_UP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_25MHz;
  /* SPI SCK pin configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect SPI2 pins to AF5 */  
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource13, GPIO_AF_SPI2);
  /* SPI MOSI pin configuration */
  GPIO_InitStructure.GPIO_Pin =  GPIO_Pin_15;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource15, GPIO_AF_SPI2);

	/* Set up SPI2 port */
	SPI_InitStructure.SPI_Direction = SPI_Direction_1Line_Rx;
	SPI_InitStructure.SPI_Mode = SPI_Mode_Slave;
	SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
	SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
	SPI_InitStructure.SPI_CPHA = SPI_CPHA_2Edge;
	SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
	SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_8;
	SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
  SPI_InitStructure.SPI_CRCPolynomial = 7;
	SPI_Init(SPI2, &SPI_InitStructure);

  /* Enable the SPI2 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = SPI2_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  SPI_ClearITPendingBit(SPI2,SPI_IT_RXNE);
  SPI_ITConfig(SPI2, SPI_IT_RXNE, ENABLE);

	SPI_Cmd(SPI2, ENABLE);

  /* Enable TIM2, TIM3 and TIM5 */
  TIM_Cmd(TIM2, ENABLE);
  TIM_Cmd(TIM5, ENABLE);
  TIM_Cmd(TIM3, ENABLE);
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
  asm("str    r12,[r9,#0x14]");
  /* Prepare set sweep sync */
  asm("mov    r12,#0x0040");

  asm("cmp    r11,#0x3");             /* SWEEP_ModeUpDown */
  asm("it     ne");                   /* Make the next instruction conditional */
  asm("bne    lblupdown");            /*  Conditional jump */
  /* Up or Down*/
  asm("add    r4,r8");                /* SWEEP_Add */
  asm("cmp    r4,r7");                /* SWEEP_Max */
  asm("itt    eq");                   /* Make the next two instructions conditional */
  asm("moveq  r4,r6");                /* Conditional load SWEEP_Min */
  asm("streq  r12,[r9,#0x14]");       /* Conditional set sweep sync */
  asm("bx     lr");                   /* Return */

  /* Up & Down */
  asm("lblupdown:");
  asm("add    r4,r8");                /* SWEEP_Add */
  asm("cmp    r4,r7");                /* SWEEP_Max */
  asm("it     ne");                   /* Make the next instruction conditional */
  asm("bxne   lr");                   /*  Conditional return */
  /* Change direction */
  asm("mov    r0,r6");                /* tmp = SWEEP_Min */
  asm("mov    r6,r7");                /* SWEEP_Min = SWEEP_Max */
  asm("mov    r7,r0");                /* SWEEP_Max = tmp */
  asm("neg    r8,r8");                /* Negate SWEEP_Add */
}

/**
  * @brief  This function handles TIM3 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM3_IRQHandler(void)
{
  asm("mov    r1,#0x20000000");       // Ram start
  /* Clear TIM3 Update interrupt pending bit */
  asm("mov    r0,#0x40000000");       // TIM2
  asm("strh   r0,[r0,#0x410]");       // TIM3->SR
  /* Calculate frequency TIM2 */
  asm("ldr    r2,[r0,#0x24]");        // TIM2->CNT
  asm("ldr    r3,[r1,#0x06]");        // STM32_Frequency.PreviousCountCHA
  asm("str    r2,[r1,#0x06]");        // STM32_Frequency.PreviousCountCHA
  asm("sub    r2,r2,r3");
  asm("str    r2,[r1,#0x02]");        // STM32_Frequency.FrequencyCHA
  /* Calculate frequency TIM5 */
  asm("ldr    r2,[r0,#0xC24]");       // TIM5->CNT
  asm("ldr    r3,[r1,#0x0E]");        // STM32_Frequency.PreviousCountCHB
  asm("str    r2,[r1,#0x0E]");        // STM32_Frequency.PreviousCountCHB
  asm("sub    r2,r2,r3");
  asm("str    r2,[r1,#0x0A]");        // STM32_Frequency.FrequencyCHB
}

void SPI2_IRQHandler(void)
{
  SPI_I2S_ClearITPendingBit(SPI2,SPI_IT_RXNE);

  asm("movw   r0,#0x102C");
  asm("movt   r0,#0x2000");           /* Pointer to Adr */
  asm("ldr    r3,[r0,#0x0]");
  asm("cbnz   r3,adrset");            /* if Adr == 0 */
  asm("movw   r3,#0x0010");
  asm("movt   r3,#0x2000");           /* Pointer to DDS_WaveType-2 */
  asm("adrset:");
  asm("add    r3,r3,#0x2");
  asm("str    r3,[r0,#0x0]");
  asm("movw   r1,#0x3800");
  asm("movt   r1,#0x4000");
  asm("ldrh   r2,[r1,#0x0C]");
  asm("strh   r2,[r3,#0x0]");
  if ((uint32_t)Adr == 0x20000028)
  {
    Adr = 0;
    /* Disable the TIM6 Counter */
    TIM6->CR1 &= (uint16_t)~TIM_CR1_CEN;
    WaveSetup();
    if (STM32_Command.DDS_SweepMode == SWEEP_ModeOff)
    {
      asm("movw   r4,#0x0014");
      asm("movt   r4,#0x2000");       /* STM32_Command.DDS_PhaseAdd = 0x20000014 */
      asm("ldr    r4,[r4,#0x0]");     /* DDSPhaseFrq value */
    }
    else
    {
      TIM6->CNT = 0;
      TIM6->ARR = STM32_Command.SWEEP_StepTime-1;
      /* Enable the TIM6 Counter */
      TIM6->CR1 |= TIM_CR1_CEN;

      /* Used by Clear TIM6 Update interrupt pending bit */
      asm("mov    r10,#0x1000");
      asm("movt   r10,#0x4000");

      asm("movw   r9,#0x0000");
      asm("movt   r9,#0x4002");       /* GPIOA */

      asm("movw   r8,#0x0");
      asm("movt   r8,#0x2000");
      asm("mov    r11,#0x0");
      asm("ldrb   r11,[r8,#0x13]");   /* STM32_Command.DDS_SweepMode = 0x20000013 */

      asm("ldr    r6,[r8,#0x24]");    /* STM32_Command.SWEEP_Min = 0x20000024 */
      asm("ldr    r7,[r8,#0x28]");    /* STM32_Command.SWEEP_Max = 0x20000028 */
      asm("ldr    r8,[r8,#0x1C]");    /* STM32_Command.SWEEP_Add = 0x2000001C */
      asm("mov    r4,r6");            /* STM32_Command.SWEEP_Min */
    }
    asm("movw   r1,#0x002C");
    asm("movt   r1,#0x2000");         /* STM32_Command.Wave[0] = 0x2000002C */
    asm("movw   r2,#0x7408");
    asm("movt   r2,#0x4000");         /* DAC_DHR12R1 */
    asm("mov    r3,#0x0");            /* DDSPhase pointer value */
  }
}

/******************* (C) COPYRIGHT 2011 STMicroelectronics *****END OF FILE****/
