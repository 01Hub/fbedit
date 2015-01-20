/*
  Port pins
  ------------------------------------
  PE15-PE4  DDS wave output
  PB13      SPI SCK
  PB15      SPI MOSI
  ------------------------------------
*/
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include <stdio.h>
#include "wave.h"

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint32_t DDS_PhaseFrq;                              // 0x20000000
  uint16_t WaveType;                                  // 0x00000004
  uint16_t Amplitude;                                 // 0x00000006
  int16_t DCOffset;                                   // 0x00000008
  uint16_t SPI_Cmnd;                                  // 0x0000000A
  uint16_t SPI_Cnt;                                   // 0x0000000C
  uint16_t rx;                                        // 0x0000000E
  uint16_t Wave[2048];                                // 0x20000010
  uint16_t SweepMode;                                 // 0x00001010
  uint16_t SweepTime;                                 // 0x00001012
  int32_t SweepStep;                                  // 0x20001014
  uint32_t SweepMin;                                  // 0x20001018
  uint32_t SweepMax;                                  // 0x2000101C
  uint32_t tmp;                                       // 0x20001020
  uint16_t WaveUpload[2048];                          // 0x20001024
}STM32_CMNDTypeDef;

/* Private define ------------------------------------------------------------*/
/* DDS WaveType */
#define WAVE_Sine                 ((uint8_t)0)
#define WAVE_Triangle             ((uint8_t)1)
#define WAVE_Square               ((uint8_t)2)
#define WAVE_SawTooth             ((uint8_t)3)
#define WAVE_RevSawTooth          ((uint8_t)4)
#define WAVE_Upload               ((uint8_t)5)

#define Sweep_Off                 ((uint8_t)0)
#define Sweep_Up                  ((uint8_t)1)
#define Sweep_Down                ((uint8_t)2)
#define Sweep_UpDown              ((uint8_t)3)

#define SPI_PhaseSet              ((uint16_t)1)
#define SPI_WaveSet               ((uint16_t)2)
#define SPI_SweepSet              ((uint16_t)3)
#define SPI_WaveUpload            ((uint16_t)4)


/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
__IO STM32_CMNDTypeDef STM32_Command;               // 0x20000014

void DDS_Config(void);
void SPI_Config(void);
void TIM_Config(void);
void DDS_MakeWave(void);
void DDS_WaveGenerator(void);
void DDS_WaveLoop(void);

/* Private functions ---------------------------------------------------------*/
/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
int main(void)
{
  STM32_Command.WaveType = WAVE_Sine;
  STM32_Command.Amplitude = 4095;
  STM32_Command.DCOffset = 4095;
  STM32_Command.DDS_PhaseFrq = 858993;
  STM32_Command.SweepMode = Sweep_Off;
  STM32_Command.SweepTime = 9;
  STM32_Command.SweepStep = 1718;
  STM32_Command.SweepMin = 687193;
  STM32_Command.SweepMax = 1030793;

  DDS_Config();
  SPI_Config();
  TIM_Config();
  DDS_MakeWave();
  DDS_WaveGenerator();
}

void DDS_MakeWave(void)
{
  uint32_t i;
  int32_t tmp;

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
    case WAVE_Upload:
      while (i<2048)
      {
        STM32_Command.Wave[i] = STM32_Command.WaveUpload[i] + 2048;
        i++;
      }
      break;
  }
  i=0;
  while (i<2048)
  {
    tmp = (STM32_Command.Wave[i] * STM32_Command.Amplitude) / 4096;
    tmp = (tmp - STM32_Command.Amplitude/2)+STM32_Command.DCOffset-2048;
    if (tmp<0)
    {
      tmp = 0;
    }
    if (tmp>4095)
    {
      tmp = 4095;
    }
    STM32_Command.Wave[i] = tmp << 4;
    i++;
  }
}

/*******************************************************************************
* Function Name  : DDS_WaveLoop
* Description    : This function generates the DDS waveform
*                  It updates the DAC every 8 cycles.
*                  With a 200MHz system clock the update
*                  frequency is 25MHz.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void DDS_WaveLoop(void)
{
  while (1)
  {
    asm("mov    r4,r3,lsr #21");      /* Get offset into wave */
    asm("ldrh   r4,[r1,r4,lsl #1]");  /* Get wave data */
    asm("strh   r4,[r2,#0x0]");       /* Output wave data to dac */
    asm("add    r3,r3,r5");           /* Update phase */
  }
}

/*******************************************************************************
* Function Name  : DDSWaveGenerator
* Description    : This function generates a waveform using DDS
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void DDS_WaveGenerator(void)
{
  asm("movw   r1,#0x0010");
  asm("movt   r1,#0x2000");       /* STM32_Command.Wave[0] = 0x20000010 */
  asm("movw   r2,#0x1014");
  asm("movt   r2,#0x4002");       /* GPIOE ODR */
  asm("mov    r3,#0x0");          /* DDSPhase pointer value */
  asm("movw   r5,#0x0000");
  asm("movt   r5,#0x2000");       /* STM32_Command.DDSPhaseFrq = 0x20000000 */
  asm("ldr    r5,[r5,#0x0]");     /* DDSPhaseFrq value */
  DDS_WaveLoop();
}

void DDS_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;

  /* GPIOE clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOD | RCC_AHB1Periph_GPIOE, ENABLE);
  /* DAC port configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_15 | GPIO_Pin_14 | GPIO_Pin_13 | GPIO_Pin_12 | GPIO_Pin_11 | GPIO_Pin_10 | GPIO_Pin_9 | GPIO_Pin_8 | GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOE, &GPIO_InitStructure);

  // STM_EVAL_LEDInit(LED4);
  /* Configure the GPIOD_LED4 pin */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_12;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_UP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOD, &GPIO_InitStructure);
}

void SPI_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  SPI_InitTypeDef SPI_InitStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  /* GPIOB clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOB, ENABLE);
  /* SPI2 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_SPI2, ENABLE);

  /* Configure SPI2 SCK and MOSI pins */
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
	GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
	GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_15 | GPIO_Pin_13;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect SPI2 pins to AF5 */  
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource13, GPIO_AF_SPI2);
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource15, GPIO_AF_SPI2);

  /* Enable the SPI2 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = SPI2_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);

  /* SPI2 configuration */
  SPI_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
  SPI_InitStructure.SPI_Mode = SPI_Mode_Slave;
	SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
	SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
	SPI_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;
	SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
	SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_32;
	SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
  SPI_InitStructure.SPI_CRCPolynomial = 7;
	SPI_Init(SPI2, &SPI_InitStructure);
  SPI_I2S_ITConfig(SPI2, SPI_I2S_IT_RXNE, ENABLE);
  SPI_Cmd(SPI2, ENABLE);
}

void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  NVIC_InitTypeDef NVIC_InitStructure;

  /* TIM6 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM6, ENABLE);

  /* TIM6 Counter configuration */
  TIM_TimeBaseStructure.TIM_Period = 9;
  TIM_TimeBaseStructure.TIM_Prescaler = 9999;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_RepetitionCounter=0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM6, &TIM_TimeBaseStructure);
  /* Clear the IT pending Bit */
  TIM6->SR = (uint16_t)~TIM_IT_Update;
  /* Enable TIM6 Update interrupt */
  TIM_ITConfig(TIM6, TIM_IT_Update, ENABLE);
  /* Enable the TIM6 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM6_DAC_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

void SPI2_IRQHandler(void)
{
  /* Get the SPI received data */
  STM32_Command.rx = SPI2->DR;
  STM32_Command.SPI_Cnt++;
  if (STM32_Command.SPI_Cnt == 1)
  {
    STM32_Command.SPI_Cmnd = STM32_Command.rx;
  }
  else if (STM32_Command.SPI_Cmnd == SPI_PhaseSet)
  {
    switch (STM32_Command.SPI_Cnt)
    {
      case 2:
        STM32_Command.DDS_PhaseFrq = STM32_Command.rx;
        break;
      case 3:
        STM32_Command.DDS_PhaseFrq |= ((uint32_t)STM32_Command.rx)<<16;
        STM32_Command.SPI_Cnt = 0;
        asm("movw   r5,#0x0000");
        asm("movt   r5,#0x2000");       /* STM32_Command.DDSPhaseFrq = 0x20000000 */
        asm("ldr    r5,[r5,#0x0]");     /* DDSPhaseFrq value */
        break;
    }
  }
  else if (STM32_Command.SPI_Cmnd == SPI_WaveSet)
  {
    switch (STM32_Command.SPI_Cnt)
    {
      case 2:
        STM32_Command.WaveType = STM32_Command.rx;
        break;
      case 3:
        STM32_Command.Amplitude = STM32_Command.rx;
        break;
      case 4:
        STM32_Command.DCOffset = STM32_Command.rx;
        STM32_Command.SPI_Cnt = 0;
        DDS_MakeWave();
        break;
    }
  }
  else if (STM32_Command.SPI_Cmnd == SPI_WaveUpload)
  {
    if (STM32_Command.SPI_Cnt == 2048 + 1)
    {
      STM32_Command.SPI_Cnt = 0;
      STM32_Command.WaveType = WAVE_Upload;
      DDS_MakeWave();
      //STM_EVAL_LEDToggle(LED4);
      GPIOD->ODR ^= GPIO_Pin_12;
    }
    else
    {
      STM32_Command.WaveUpload[STM32_Command.SPI_Cnt - 2] = STM32_Command.rx;;
    }
  }
  else if (STM32_Command.SPI_Cmnd == SPI_SweepSet)
  {
    switch (STM32_Command.SPI_Cnt)
    {
      case 2:
        STM32_Command.SweepMode = STM32_Command.rx;
        /* Disable the TIM Counter */
        TIM6->CR1 &= (uint16_t)~TIM_CR1_CEN;
        /* Reset the TIM6 Counter */
        TIM6->CNT = 0;
        break;
      case 3:
        STM32_Command.SweepTime = STM32_Command.rx;
        break;
      case 4:
        STM32_Command.SweepStep = STM32_Command.rx;
        break;
      case 5:
        STM32_Command.SweepStep |= ((uint32_t)STM32_Command.rx)<<16;
        break;
      case 6:
        STM32_Command.SweepMin = STM32_Command.rx;
        break;
      case 7:
        STM32_Command.SweepMin |= ((uint32_t)STM32_Command.rx)<<16;
        break;
      case 8:
        STM32_Command.SweepMax = STM32_Command.rx;
        break;
      case 9:
        STM32_Command.SweepMax |= ((uint32_t)STM32_Command.rx)<<16;
        STM32_Command.SPI_Cnt = 0;
        if (STM32_Command.SweepMode != Sweep_Off)
        {
          /* Set the TIM6 Autoreload value */
          TIM6->ARR = STM32_Command.SweepTime;
          asm("mov    r9,#0x0");                    /* Up or Down */
          if (STM32_Command.SweepMode == Sweep_UpDown)
          {
            asm("mov    r9,#0x1");                  /* Up and Down */
          }
          /* Used by Clear TIM6 Update interrupt pending bit */
          asm("movw   r10,#0x1000");
          asm("movt   r10,#0x4000");
          /* Get SweepStep, SweepMin and SweepMax */
          asm("movw   r8,#0x1014");
          asm("movt   r8,#0x2000");                 /* STM32_Command.SweepStep = 0x20001014 */
          asm("ldr    r6,[r8,#0x4]");               /* STM32_Command.SweepMin = 0x20001018 */
          asm("ldr    r7,[r8,#0x8]");               /* STM32_Command.SweepMax = 0x2000101C */
          asm("ldr    r8,[r8,#0x0]");               /* STM32_Command.SweepStep = 0x20001014 */
          if (STM32_Command.SweepMode == Sweep_Down)
          {
            /* Change direction by changing SweepStep sign and swapping SweepMin / SweepMax */
            asm("neg    r8,r8");            /* Negate SweepStep */
            asm("mov    r11,r6");           /* tmp = SweepMin */
            asm("mov    r6,r7");            /* SweepMin = SweepMax */
            asm("mov    r7,r11");           /* SweepMax = tmp */
          }
          /* Enable the TIM Counter */
          TIM6->CR1 |= TIM_CR1_CEN;
        }
        asm("movw   r5,#0x0000");
        asm("movt   r5,#0x2000");                 /* STM32_Command.DDS_PhaseFrq = 0x20000000 */
        asm("ldr    r5,[r5,#0x0]");               /* DDSPhaseFrq value */
        break;
    }
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

  asm("mov    r0,r9");
  asm("cbnz   r0,lblupdown");
  /* Up or Down */
  asm("add    r5,r8");            /* SWEEP_Add */
  asm("cmp    r5,r7");            /* SWEEP_Max */
  asm("it     eq");               /* Make the next instruction conditional */
  asm("moveq  r5,r6");            /* Conditional load SWEEP_Min */
  asm("bx     lr");               /* Return */

  /* Up & Down */
  asm("lblupdown:");
  asm("add    r5,r8");            /* SWEEP_Add */
  asm("cmp    r5,r7");            /* SWEEP_Max */
  asm("it     ne");               /* Make the next instruction conditional */
  asm("bxne   lr");               /* Conditional return */
  /* Change direction by changing SweepStep sign and swapping SweepMin / SweepMax */
  asm("neg    r8,r8");            /* Negate SweepStep */
  asm("mov    r11,r6");           /* tmp = SweepMin */
  asm("mov    r6,r7");            /* SweepMin = SweepMax */
  asm("mov    r7,r11");           /* SweepMax = tmp */
}
