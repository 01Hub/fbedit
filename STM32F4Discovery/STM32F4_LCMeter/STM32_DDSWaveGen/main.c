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
  uint32_t DDS_PhaseFrq;                              // 0x20000014
  uint16_t WaveType;                                  // 0x00000018
  uint16_t Amplitude;                                 // 0x0000001A
  int16_t DCOffset;                                   // 0x0000001C
  uint16_t SPI_Cmnd;                                  // 0x0000001E
  uint16_t SPI_Cnt;                                   // 0x00000020
  uint16_t rx;                                        // 0x00000022
  uint16_t Wave[2048];                                // 0x20000024
}STM32_CMNDTypeDef;

/* Private define ------------------------------------------------------------*/
/* DDS WaveType */
#define WAVE_Sine                 ((uint8_t)0)
#define WAVE_Triangle             ((uint8_t)1)
#define WAVE_Square               ((uint8_t)2)
#define WAVE_SawTooth             ((uint8_t)3)
#define WAVE_RevSawTooth          ((uint8_t)4)

#define SPI_PhaseSet              ((uint16_t)1)
#define SPI_WaveSet               ((uint16_t)2)

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
__IO STM32_CMNDTypeDef STM32_Command;               // 0x20000014

void DDS_Config(void);
void SPI_Config(void);
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
  STM32_Command.DDS_PhaseFrq = 858994;

  DDS_Config();
  SPI_Config();
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
void DDS_WaveGenerator(void)
{
  asm("movw   r1,#0x0024");
  asm("movt   r1,#0x2000");       /* STM32_Command.Wave[0] = 0x20000024 */
  asm("movw   r2,#0x1014");
  asm("movt   r2,#0x4002");       /* GPIOE ODR */
  asm("mov    r3,#0x0");          /* DDSPhase pointer value */
  asm("movw   r4,#0x0014");
  asm("movt   r4,#0x2000");       /* STM32_Command.DDSPhaseFrq = 0x20000020 */
  asm("ldr    r4,[r4,#0x0]");     /* DDSPhaseFrq value */
  DDS_WaveLoop();
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
    if (STM32_Command.SPI_Cnt == 2)
    {
      STM32_Command.DDS_PhaseFrq = STM32_Command.rx;
    }
    else if (STM32_Command.SPI_Cnt == 3)
    {
      STM32_Command.DDS_PhaseFrq |= ((uint32_t)STM32_Command.rx)<<16;
      STM32_Command.SPI_Cnt = 0;
      asm("movw   r4,#0x0014");
      asm("movt   r4,#0x2000");       /* STM32_Command.DDSPhaseFrq = 0x20000020 */
      asm("ldr    r4,[r4,#0x0]");     /* DDSPhaseFrq value */
    }
  }
  else if (STM32_Command.SPI_Cmnd == SPI_WaveSet)
  {
    if (STM32_Command.SPI_Cnt == 2)
    {
      STM32_Command.WaveType = STM32_Command.rx;
    }
    else if (STM32_Command.SPI_Cnt == 3)
    {
      STM32_Command.Amplitude = STM32_Command.rx;
    }
    else if (STM32_Command.SPI_Cnt == 4)
    {
      STM32_Command.DCOffset = STM32_Command.rx;
      STM32_Command.SPI_Cnt = 0;
      DDS_MakeWave();
    }
  }
}

void DDS_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;

  /* GPIOE clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOE, ENABLE);

  /* DAC port configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_15 | GPIO_Pin_14 | GPIO_Pin_13 | GPIO_Pin_12 | GPIO_Pin_11 | GPIO_Pin_10 | GPIO_Pin_9 | GPIO_Pin_8 | GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOE, &GPIO_InitStructure);
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
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
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
