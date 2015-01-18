/**
  ******************************************************************************
  * @file    LCMeter/main.c 
  * @author  KO
  * @version V1.0.0
  * @date    20-February-2014
  * @brief   Main program body
  ******************************************************************************
  */

/**
  ******************************************************************************
  Port pins
  PA.00           Frequency counter input (TIM5)
  PA.01           Frequency counter input (TIM2)
  PA.04           Scope V-Pos DAC1 Output
  PB.07           High Speed Clock
  PB.13           SPI SCK
  PB.15           SPI MOSI
  PC.01           Scope ADC
  PD.00           Frequency counter select0
  PD.01           Frequency counter select1
  PD.02           Frequency counter select2
  PD.06           LCMeter L/C selection, C = Low L = High
  PD.07           LCMeter calibration
  PD.08           USART3 TX
  PD.09           USART3 RX
  PE.03			      Scope X10 Output OD
  PE.04			      Scope X5 Output OD
  PE.05			      Scope X10 Output OD
  PE.08 to PE.15  LGA Inputs
  ******************************************************************************
  */

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint32_t HSCSet;
  uint32_t HSCDiv;
} STM32_HSCTypeDef;

typedef struct
{
  uint32_t Frequency;
  uint32_t FrequencySCP;
} STM32_FRQTypeDef;

typedef struct
{
  uint32_t FrequencyCal0;
  uint32_t FrequencyCal1;
} STM32_LCMTypeDef;

typedef struct
{
  uint32_t ADC_Prescaler;
  uint32_t ADC_TwoSamplingDelay;
  uint32_t ScopeTrigger;
  uint32_t ScopeTriggerLevel;
  uint32_t ScopeTimeDiv;
  uint16_t ScopeVoltDiv;
  uint16_t ScopeMag;
  uint32_t ScopeVPos;
  uint32_t ADC_TripleMode;
  uint32_t ADC_SampleTime;
  uint32_t ADC_SampleSize;
  uint32_t SubSampling;
} STM32_SCPTypeDef;

typedef struct
{
  uint16_t DDS_Cmd;
  uint16_t DDS_Wave;
  uint32_t DDS__PhaseAdd;
  uint32_t DDS_Amplitude;
  uint32_t DDS_DCOffset;
	uint16_t SWEEP_Mode;
	uint16_t SWEEP_Time;
	uint32_t SWEEP_Step;
	uint32_t SWEEP_Min;
	uint32_t SWEEP_Max;
} STM32_DDSTypeDef;

typedef struct
{
  uint8_t DataBlocks;
  uint8_t TriggerValue;
  uint8_t TriggerMask;
  uint8_t TriggerWait;
  uint16_t LGASampleRateDiv;
  uint16_t LGASampleRate;
} STM32_LGATypeDef;


typedef struct
{
  uint32_t Cmd;
  STM32_HSCTypeDef STM32_HSC;
  STM32_FRQTypeDef STM32_FRQ;
  STM32_LCMTypeDef STM32_LCM;
  STM32_SCPTypeDef STM32_SCP;
  STM32_DDSTypeDef STM32_DDS;
  STM32_LGATypeDef STM32_LGA;
  uint32_t TickCount;
  uint32_t PreviousCountTIM2;
  uint32_t ThisCountTIM2;
  uint32_t PreviousCountTIM5;
  uint32_t ThisCountTIM5;
  char BTBuff[64];
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
#define CMD_DDSSET                              ((uint8_t)9)
#define CMD_LGASET                              ((uint8_t)10)

#define DDS_PHASESET                            ((uint8_t)1)
#define DDS_WAVESET                             ((uint8_t)2)
#define DDS_SWEEPSET                            ((uint8_t)3)

#define SWEEP_ModeOff                           ((uint8_t)0)
#define SWEEP_ModeUp                            ((uint8_t)1)
#define SWEEP_ModeDown                          ((uint8_t)2)
#define SWEEP_ModeUpDown                        ((uint8_t)3)

#define ADC_CDR_ADDRESS                         ((uint32_t)0x40012308)
#define PE_IDR_Address                          ((uint32_t)0x40021011)
#define SCOPE_DATAPTR                           ((uint32_t)0x20008000)
#define LGA_DATAPTR                             ((uint32_t)0x20008000)
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
void DAC_Config(void);
void DMA_SingleConfig(void);
void ADC_SingleConfig(void);
void DMA_TripleConfig(void);
void ADC_TripleConfig(void);
void SPI_Config(void);
void USART_Config(uint32_t Baud);
void ScopeSubSampling(void);
uint32_t GetFrequency(void);
void LCM_Calibrate(void);
void SPISendData32(uint32_t tx);
void SPISendData(uint16_t tx);
void USART3_putdata(uint8_t *dat,uint16_t len);
void USART3_puts(char *str);
void USART3_getdata(uint8_t *dat,uint16_t len);
void DMA_LGAConfig(void);
void SendCompressedBuffer(uint32_t *in,uint16_t len);

/* Private functions ---------------------------------------------------------*/

/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
int main(void)
{
  __IO uint16_t i;
  // __IO float fval;


  /* RCC Configuration */
  RCC_Config();
  /* GPIO Configuration */
  GPIO_Config();
  /* TIM Configuration */
  TIM_Config();
  /* NVIC Configuration */
  NVIC_Config();
  /* DAC Configuration */
  DAC_Config();
  /* SPI Configuration */
  SPI_Config();
  /* USART Configuration */
  USART_Config(115200);
  /* Calibrate LC Meter */
  LCM_Calibrate();

// fval=123.45;
// fval=fval*1.2;
  // /* Update baudrate */
  // STM32_CMD.Cmd = STM32_CMD.TickCount;
  // while (STM32_CMD.Cmd == STM32_CMD.TickCount);
  // STM32_CMD.Cmd = STM32_CMD.TickCount;
  // while (STM32_CMD.Cmd == STM32_CMD.TickCount);
  // USART3_puts("AT\0");
  // STM32_CMD.Cmd = STM32_CMD.TickCount;
  // while (STM32_CMD.Cmd == STM32_CMD.TickCount)
  // {
    // if ((USART3->SR & USART_FLAG_RXNE) != 0)
    // {
      // STM32_CMD.BTBuff[i] = USART3->DR;
      // i++;
    // }
  // }
  // STM32_CMD.Cmd = STM32_CMD.TickCount;
  // while (STM32_CMD.Cmd == STM32_CMD.TickCount);
  // STM32_CMD.Cmd = STM32_CMD.TickCount;
  // while (STM32_CMD.Cmd == STM32_CMD.TickCount);
  // USART3_puts("AT+BAUD8\0");
  // STM32_CMD.Cmd = STM32_CMD.TickCount;
  // while (STM32_CMD.Cmd == STM32_CMD.TickCount)
  // {
    // if ((USART3->SR & USART_FLAG_RXNE) != 0)
    // {
      // STM32_CMD.BTBuff[i] = USART3->DR;
      // i++;
    // }
  // }
  // while (1)
  // {
  // }

  while (1)
  {
    USART3_getdata((uint8_t *)&STM32_CMD.Cmd,4);
    switch (STM32_CMD.Cmd)
    {
      case CMD_LCMCAL:
        LCM_Calibrate();
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_LCM.FrequencyCal0,sizeof(STM32_LCMTypeDef));
        break;
      case CMD_LCMCAP:
        GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_FRQ.Frequency,sizeof(STM32_FRQTypeDef));
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_LCM.FrequencyCal0,sizeof(STM32_LCMTypeDef));
        break;
      case CMD_LCMIND:
        GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_6);
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_FRQ.Frequency,sizeof(STM32_FRQTypeDef));
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_LCM.FrequencyCal0,sizeof(STM32_LCMTypeDef));
        break;
      case CMD_FRQCH1:
        GPIO_ResetBits(GPIOD, GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_0);
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_FRQ.Frequency,sizeof(STM32_FRQTypeDef));
        break;
      case CMD_FRQCH2:
        GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_1);
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_FRQ.Frequency,sizeof(STM32_FRQTypeDef));
        break;
      case CMD_FRQCH3:
        GPIO_ResetBits(GPIOD, GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1);
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_FRQ.Frequency,sizeof(STM32_FRQTypeDef));
        break;
      case CMD_SCPSET:
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_FRQ.Frequency,sizeof(STM32_FRQTypeDef));
        USART3_getdata((uint8_t *)&STM32_CMD.STM32_SCP.ADC_Prescaler,sizeof(STM32_SCPTypeDef));
        /* Scope magnify */
        i = (STM32_CMD.STM32_SCP.ScopeMag & 0x07) << 3;
        GPIO_SetBits(GPIOE,(i ^ 0x38));
        GPIO_ResetBits(GPIOE,i);
        /* Set V-Pos */
        DAC_SetChannel1Data(DAC_Align_12b_R, STM32_CMD.STM32_SCP.ScopeVPos);
        if (STM32_CMD.STM32_SCP.ADC_TripleMode)
        {
          /* DMA Configuration */
          DMA_TripleConfig();
          /* ADC Configuration */
          ADC_TripleConfig();
        }
        else
        {
          /* DMA Configuration */
          DMA_SingleConfig();
          /* ADC Configuration */
          ADC_SingleConfig();
        }
        /* Start ADC1 Software Conversion */
        ADC1->CR2 |= (uint32_t)ADC_CR2_SWSTART;
        /* Since BlueTooth is slower than sampling therev is no need to wait */
        SendCompressedBuffer((uint32_t *)SCOPE_DATAPTR, STM32_CMD.STM32_SCP.ADC_SampleSize / 4);
        /* Done */
        ADC->CCR=0;
        ADC1->CR2=0;
        ADC2->CR2=0;
        ADC3->CR2=0;
        break;
      case CMD_HSCSET:
        GPIO_ResetBits(GPIOD, GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
        GPIO_SetBits(GPIOD, GPIO_Pin_0);
        USART3_getdata((uint8_t *)&STM32_CMD.STM32_HSC.HSCSet,sizeof(STM32_HSCTypeDef));
        TIM4->ARR = STM32_CMD.STM32_HSC.HSCSet;
        TIM4->CCR2 = (STM32_CMD.STM32_HSC.HSCSet+1) / 2;
        TIM4->PSC = STM32_CMD.STM32_HSC.HSCDiv;
        USART3_putdata((uint8_t *)&STM32_CMD.STM32_FRQ.Frequency,sizeof(STM32_FRQTypeDef));
        break;
      case CMD_DDSSET:
        USART3_getdata((uint8_t *)&STM32_CMD.STM32_DDS.DDS_Cmd,sizeof(STM32_DDSTypeDef));
        if (STM32_CMD.STM32_DDS.DDS_Cmd == DDS_PHASESET)
        {
          SPISendData(DDS_PHASESET);
          SPISendData32(STM32_CMD.STM32_DDS.DDS__PhaseAdd);
        }
        else if (STM32_CMD.STM32_DDS.DDS_Cmd == DDS_WAVESET)
        {
          SPISendData(DDS_WAVESET);
          SPISendData(STM32_CMD.STM32_DDS.DDS_Wave);
          SPISendData(STM32_CMD.STM32_DDS.DDS_Amplitude);
          SPISendData(STM32_CMD.STM32_DDS.DDS_DCOffset);
        }
        else if (STM32_CMD.STM32_DDS.DDS_Cmd == DDS_SWEEPSET)
        {
          SPISendData(DDS_SWEEPSET);
          SPISendData(STM32_CMD.STM32_DDS.SWEEP_Mode);
          SPISendData(STM32_CMD.STM32_DDS.SWEEP_Time);
          SPISendData32(STM32_CMD.STM32_DDS.SWEEP_Step);
          SPISendData32(STM32_CMD.STM32_DDS.SWEEP_Min);
          SPISendData32(STM32_CMD.STM32_DDS.SWEEP_Max);
        }
        break;
      case CMD_LGASET:
        USART3_getdata((uint8_t *)&STM32_CMD.STM32_LGA.DataBlocks,sizeof(STM32_LGATypeDef));
        /* Set the Prescaler value */
        TIM8->PSC = STM32_CMD.STM32_LGA.LGASampleRateDiv;
        /* Set the Autoreload value */
        TIM8->ARR = STM32_CMD.STM32_LGA.LGASampleRate;
        TIM8->CNT =  STM32_CMD.STM32_LGA.LGASampleRate-1;
        DMA_LGAConfig();
        TIM_DMACmd(TIM8, TIM_DMA_Update, ENABLE);
        /* DMA2_Stream1 enable */
        DMA_Cmd(DMA2_Stream1, ENABLE);
        /* Enable timer */
        TIM8->CR1 |= TIM_CR1_CEN;
        while (DMA_GetFlagStatus(DMA2_Stream1,DMA_FLAG_HTIF1) == RESET);
        /* Half done */
        USART3_putdata((uint8_t *)LGA_DATAPTR, STM32_CMD.STM32_LGA.DataBlocks * 1024 / 2);
        while (DMA_GetFlagStatus(DMA2_Stream1,DMA_FLAG_TCIF1) == RESET);
        /* Done */
        USART3_putdata((uint8_t *)(LGA_DATAPTR + STM32_CMD.STM32_LGA.DataBlocks * 1024 / 2), STM32_CMD.STM32_LGA.DataBlocks * 1024 / 2);
        TIM_Cmd(TIM8, DISABLE);
        DMA_DeInit(DMA2_Stream1);
        break;
    }
  }
}

/**
  * @brief  ADC data is 12bits so 2halfwords is compressed into 3bytes.
  * @param  Pointer to buffer, buffer size
  * @retval None
  */
void SendCompressedBuffer(uint32_t *in,uint16_t len)
{
  __IO uint32_t dat32;
  __IO uint8_t dat8;
  while  (len--)
  {
    dat32 = *in;
    dat32 = ((dat32 >> 4) & 0x00fff000) | (dat32 & 0xfff);

    /* Wait until transmit register empty */
    while((USART3->SR & USART_FLAG_TXE) == 0);
    /* Transmit Data */
    dat8 = dat32;
    USART3->DR = (uint16_t)dat8;

    /* Wait until transmit register empty */
    while((USART3->SR & USART_FLAG_TXE) == 0);
    /* Transmit Data */
    dat8 = dat32 >> 8;
    USART3->DR = (uint16_t)dat8;

    /* Wait until transmit register empty */
    while((USART3->SR & USART_FLAG_TXE) == 0);
    /* Transmit Data */
    dat8 = dat32 >> 16;
    USART3->DR = (uint16_t)dat8;

    *in++;
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
  * @brief  SPI Send 32 bit data.
  * @param  tx
  * @retval None
  */
void SPISendData32(uint32_t tx)
{
  SPISendData(tx);
  SPISendData(tx >> 16);
}

/**
  * @brief  SPI Send 16 bit data.
  * @param  tx
  * @retval None
  */
void SPISendData(uint16_t tx)
{
	SPI2->DR = tx;                            // write data to be transmitted to the SPI data register
	while (!(SPI2->SR & SPI_I2S_FLAG_TXE));   // wait until transmit complete
  while (SPI2->SR & SPI_I2S_FLAG_BSY);      // wait until SPI is not busy anymore
}

/*******************************************************************************
* Function Name  : USART3_putdata
* Description    : This function transmits data
* Input          : *dat, len
* Output         : None
* Return         : None
*******************************************************************************/
void USART3_putdata(uint8_t *dat,uint16_t len)
{
  /* Data are transmitted one byte at a time. */
  while (len--)
  {
    /* Wait until transmit register empty */
    while((USART3->SR & USART_FLAG_TXE) == 0);          
    /* Transmit Data */
    USART3->DR = (uint16_t)*dat;
    *dat++;
  }
}

/*******************************************************************************
* Function Name  : USART3_puts
* Description    : This function transmits a zero terminated string
* Input          : Zero terminated string
* Output         : None
* Return         : None
*******************************************************************************/
void USART3_puts(char *str)
{
  char c;
  /* Characters are transmitted one at a time. */
  while ((c = *str++))
  {
    /* Wait until transmit register empty */
    while((USART3->SR & USART_FLAG_TXE) == 0);
    /* Transmit Data */
    USART3->DR = (uint16_t)c;
  }
}

/*******************************************************************************
* Function Name  : USART3_getdata
* Description    : This function receives data
* Input          : *dat, len
* Output         : None
* Return         : None
*******************************************************************************/
void USART3_getdata(uint8_t *dat,uint16_t len)
{
  /* Data are recieved one byte at a time. */
  while (len--)
  {
    /* Wait until receive register not empty */
    while((USART3->SR & USART_FLAG_RXNE) == 0);          
    /* Receive Data */
    *dat = (uint8_t)USART3->DR;
    *dat++;
  }
  // STM_EVAL_LEDToggle(LED4);
}

/**
  * @brief  Configure the RCC.
  * @param  None
  * @retval None
  */
void RCC_Config(void)
{
  /* SPI2, DAC, TIM2, TIM3, TIM4 and TIM5 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_SPI2 | RCC_APB1Periph_DAC | RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4 | RCC_APB1Periph_TIM5, ENABLE);
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
  /* GPIOE clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOE, ENABLE);
  /* USART3 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3, ENABLE); 
  /* Enable TIM8, ADC1, ADC2 and ADC3 clocks */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM8 | RCC_APB2Periph_ADC1 | RCC_APB2Periph_ADC2 | RCC_APB2Periph_ADC3, ENABLE);
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
  STM_EVAL_LEDInit(LED4);

  /* TIM2 chennel2 configuration : PA.01 */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM2 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource1, GPIO_AF_TIM2);

  /* TIM5 chennel1 configuration : PA.00 */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM5 pin to AF2 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource0, GPIO_AF_TIM5);

  /* TIM4 chennel 2 configuration : PB7 */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_UP ;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect TIM4 pin to AF2 */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource7, GPIO_AF_TIM4);

  /* Configure ADC123 Channel 11 pin as analog input (Scope) */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOC, &GPIO_InitStructure);

  /* Configure DAC Channel1 pin as analog output (Scope V-Pos) */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);

  /* GPIOD Outputs */
  GPIO_ResetBits(GPIOD, GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7);
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_2 | GPIO_Pin_6 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOD, &GPIO_InitStructure);

  /* GPIOE Outputs */
  GPIO_SetBits(GPIOE, GPIO_Pin_3 | GPIO_Pin_4 | GPIO_Pin_5);
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_3 | GPIO_Pin_4 | GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_OD;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOE, &GPIO_InitStructure);

  /* GPIOE Inputs */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_8 | GPIO_Pin_9 | GPIO_Pin_10 | GPIO_Pin_11 | GPIO_Pin_12 | GPIO_Pin_13 | GPIO_Pin_14 | GPIO_Pin_15;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOE, &GPIO_InitStructure);

/* Configure SPI2 SCK and MOSI pins */
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  /* SPI SCK pin configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect SPI2 pins to AF5 */  
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource13, GPIO_AF_SPI2);
  /* SPI MOSI pin configuration */
  GPIO_InitStructure.GPIO_Pin =  GPIO_Pin_15;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource15, GPIO_AF_SPI2);

  /* USART Tx and Rx pin configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8 | GPIO_Pin_9;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
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
  TIM_TimeBaseStructure.TIM_RepetitionCounter=0;
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
  /* 1.0KHz */
  TIM_TimeBaseStructure.TIM_Period = 1;
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
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 200;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM8, &TIM_TimeBaseStructure);
}

/**
  * @brief  Configure the DAC Channel 1.
  * @param  None
  * @retval None
  */
void DAC_Config(void)
{
  DAC_InitTypeDef  DAC_InitStructure;

  /* DAC channel1 Configuration */
  DAC_StructInit(&DAC_InitStructure);
  DAC_InitStructure.DAC_Trigger = DAC_Trigger_None;
  DAC_InitStructure.DAC_WaveGeneration = DAC_WaveGeneration_None;
  DAC_InitStructure.DAC_OutputBuffer = DAC_OutputBuffer_Enable;
  DAC_Init(DAC_Channel_1, &DAC_InitStructure);
  /* Enable DAC Channel1 */
  DAC_Cmd(DAC_Channel_1, ENABLE);
  DAC_SetChannel1Data(DAC_Align_12b_R, 2048);
  /* Enable DAC Channel1 and output buffer */
  DAC->CR = 0x1;
}

/**
  * @brief  Configure the DMA.
  * @param  None
  * @retval None
  */
void DMA_SingleConfig(void)
{
  DMA_InitTypeDef DMA_InitStructure;
  DMA_StructInit(&DMA_InitStructure);
  DMA_DeInit(DMA2_Stream0);
  /* DMA2 Stream0 channel0 configuration **************************************/
  DMA_InitStructure.DMA_Channel = DMA_Channel_0;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)&ADC1->DR;//ADC1_DR_ADDRESS;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)SCOPE_DATAPTR;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = STM32_CMD.STM32_SCP.ADC_SampleSize/2;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
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
void ADC_SingleConfig(void)
{
  ADC_CommonInitTypeDef ADC_CommonInitStructure;
  ADC_InitTypeDef ADC_InitStructure;
  ADC_StructInit(&ADC_InitStructure);
  ADC_CommonStructInit(&ADC_CommonInitStructure);

  /* ADC Common Init **********************************************************/
  ADC_CommonInitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_CommonInitStructure.ADC_Prescaler = (uint32_t)STM32_CMD.STM32_SCP.ADC_Prescaler<<16;
  ADC_CommonInitStructure.ADC_DMAAccessMode = ADC_DMAAccessMode_Disabled;
  ADC_CommonInitStructure.ADC_TwoSamplingDelay = ADC_TwoSamplingDelay_5Cycles;
  ADC_CommonInit(&ADC_CommonInitStructure);

  /* ADC1 Init ****************************************************************/
  ADC_InitStructure.ADC_Resolution = ADC_Resolution_12b;
  ADC_InitStructure.ADC_ScanConvMode = DISABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConvEdge = ADC_ExternalTrigConvEdge_None;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_T1_CC1;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfConversion = 1;
  ADC_Init(ADC1, &ADC_InitStructure);

  /* ADC1 regular channel11 configuration *************************************/
  ADC_RegularChannelConfig(ADC1, ADC_Channel_11, 1, STM32_CMD.STM32_SCP.ADC_SampleTime);
  /* Enable DMA request after last transfer (Single-ADC mode) */
  ADC_DMARequestAfterLastTransferCmd(ADC1, ENABLE);
  /* Enable ADC1 DMA */
  ADC_DMACmd(ADC1, ENABLE);
  /* Enable ADC1 */
  ADC_Cmd(ADC1, ENABLE);

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
  DMA_InitStructure.DMA_BufferSize = STM32_CMD.STM32_SCP.ADC_SampleSize/4;
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
  * @brief  Configure the DMA.
  * @param  None
  * @retval None
  */
void DMA_LGAConfig(void)
{
  DMA_InitTypeDef DMA_InitStructure;

  DMA_DeInit(DMA2_Stream1);
  DMA_StructInit(&DMA_InitStructure);
  /* DMA2 Stream1 channel7 configuration */
  DMA_InitStructure.DMA_Channel = DMA_Channel_7;  
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)PE_IDR_Address;
  DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)LGA_DATAPTR;
  DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  DMA_InitStructure.DMA_BufferSize = STM32_CMD.STM32_LGA.DataBlocks * 1024;
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
  * @brief  Configure the SPI2.
  * @param  None
  * @retval None
  */
void SPI_Config(void)
{
  SPI_InitTypeDef SPI_InitStructure;

	/* Set up SPI2 port */
	SPI_InitStructure.SPI_Direction = SPI_Direction_1Line_Tx;
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
	SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
	SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
	SPI_InitStructure.SPI_CPHA = SPI_CPHA_1Edge;
	SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
	SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_32;
	SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
  SPI_InitStructure.SPI_CRCPolynomial = 7;
	SPI_Init(SPI2, &SPI_InitStructure);
	SPI_Cmd(SPI2, ENABLE);
}

/**
  * @brief  Configure the USART3.
  * @param  Baud
  * @retval None
  */
void USART_Config(uint32_t Baud)
{
  USART_InitTypeDef USART_InitStructure;
 
  USART_StructInit(&USART_InitStructure);
  //USART_DeInit(USART3);
  USART_InitStructure.USART_BaudRate = Baud;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No ;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART3, &USART_InitStructure);
  /* Connect USART3 pins */  
  GPIO_PinAFConfig(GPIOD, GPIO_PinSource8, GPIO_AF_USART3);
  GPIO_PinAFConfig(GPIOD, GPIO_PinSource9, GPIO_AF_USART3);
  /* Enable the USART3 */
  USART_Cmd(USART3, ENABLE);
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
