/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 01/30/2012
* Description        : Main program body
*******************************************************************************/

/*******************************************************************************
* PAL timing Horizontal
* H-sync         4,70uS
* Front porch    1,65uS
* Active video  51,95uS
* Back porch     5,70uS
* Line total     64,0uS
*
* |                64.00uS                   |
* |4,70|1,65|          51,95uS          |5,70|
*
*            ---------------------------
*           |                           |
*           |                           |
*           |                           |
*       ----                             ----
* |    |                                     |
* -----                                      ----
*
* Vertical
* V-sync        0,576mS (9 lines)
* Frame         20mS (312,5 lines)
* Video signal  288 lines
*******************************************************************************/

/*******************************************************************************
* Port pins used
*
* Video out
* PA1   H-Sync and V-Sync
* PB15  Video out SPI2_MOSI
* RS232
* PA9   USART1 Tx
* PA10  USART1 Rx
* Keyboard
* PA8   Keyboard clock in
* PA11  Keyboard data in
* Leds
* PC08  Led
* PC09  Led
* User button
* PA1   User button
*******************************************************************************/

/*******************************************************************************
* Video output
*                  330
* PA1     O-------[  ]---o---------O  Video output
*                  1k0   |
* PA7     O-------[  ]---o
*                        |
*                       ---
*                       | |  82
*                       ---
*                        |
* GND     O--------------o---------O  GND
* 
*******************************************************************************/

/*******************************************************************************
* Keyboard connector 5 pin female DIN
*        2
*        o
*   4 o    o 5
*   1 o    o 3
* 
* Pin 1   CLK     Clock signal
* Pin 2   DATA    Data
* Pin 3   N/C     Not connected. Reset on older keyboards
* Pin 4   GND     Ground
* Pin 5   VCC     +5V DC
*******************************************************************************/

/*******************************************************************************
* Keyboard connector 6 pin female mini DIN
*
*   5 o    o 6
*   3 o    o 4
*    1 o o 2 
*
* Pin 1   DATA    Data
* Pin 2   N/C     Not connected.
* Pin 3   GND     Ground
* Pin 4   VCC     +5V DC
* Pin 5   CLK     Clock signal
* Pin 6   N/C     Not connected.
*******************************************************************************/

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include <stdio.h>
#include "Font8x10.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
#define TOP_MARGIN          30  // Number of lines before video signal starts
#define SCREEN_WIDTH        40  // 40 characters on each line.
#define SCREEN_HEIGHT       25  // 25 lines.
#define TILE_WIDTH          8   // Width of a character tile.
#define TILE_HEIGHT         10  // Height of a character tile.

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
uint16_t LineCount;
uint16_t FrameCount;
uint8_t ScreenChars[SCREEN_HEIGHT][SCREEN_WIDTH];
uint8_t PixelBuff[SCREEN_WIDTH+2];

/* Private function prototypes -----------------------------------------------*/
void RCC_Config(void);
void NVIC_Config(void);
void GPIO_Config(void);
void TIM_Config(void);
void DMA_Config(void);
void SPI_Config(void);

/* Private functions ---------------------------------------------------------*/

/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
int main(void)
{
  RCC_Config();
  NVIC_Config();
  GPIO_Config();
  TIM_Config();
  DMA_Config();
  SPI_Config();

  while (1)
  {
  }
}

void RCC_Config(void)
{
  /* Enable DMA2, GPIOA, GPIOB clocks */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA2 | RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOB, ENABLE);
  /* Enable SPI2 clock */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_SPI2, ENABLE);
  /* Enable TIM10 and TIM11 clocks */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM10 | RCC_APB2Periph_TIM11, ENABLE);
}

void NVIC_Config(void)
{
  NVIC_InitTypeDef NVIC_InitStructure;

  /* Enable the TIM10 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM1_UP_TIM10_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM11 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM1_TRG_COM_TIM11_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

void GPIO_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  /* Configure PA1 as output, H-Sync and V-Sync*/
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* H-Sync and V-Sync signal High */
  GPIO_SetBits(GPIOA,GPIO_Pin_1);

  /* Configure SPI2 SCK and MOSI pins */
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_UP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  // /* SPI SCK pin configuration */
  // GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13;
  // GPIO_Init(GPIOB, &GPIO_InitStructure);
  // /* Connect SPI2 pins to AF5 */  
  // GPIO_PinAFConfig(GPIOB, GPIO_PinSource13, GPIO_AF_SPI2);
  /* SPI MOSI pin configuration */
  GPIO_InitStructure.GPIO_Pin =  GPIO_Pin_15;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource15, GPIO_AF_SPI2);
}

void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;

  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 168*64-1;                // 64uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM10, &TIM_TimeBaseStructure);
  /* Enable TIM10 Update interrupt */
  TIM_ClearITPendingBit(TIM10,TIM_IT_Update);
  TIM_ITConfig(TIM10, TIM_IT_Update, ENABLE);
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 789;                     // 4,70uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM11, &TIM_TimeBaseStructure);
  /* Enable TIM11 Update interrupt */
  TIM_ClearITPendingBit(TIM11,TIM_IT_Update);
  TIM_ITConfig(TIM11, TIM_IT_Update, ENABLE);
}

void DMA_Config(void)
{
  // DMA_InitTypeDef       DMA_InitStructure;

  // DMA_DeInit(DMA2_Stream0);
  // /* DMA2 Stream0 channel0 configuration */
  // DMA_InitStructure.DMA_Channel = DMA_Channel_0;  
  // DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t)ADC_CDR_ADDRESS;
  // DMA_InitStructure.DMA_Memory0BaseAddr = (uint32_t)&STM32_DataStruct.STM32_Data;
  // DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralToMemory;
  // DMA_InitStructure.DMA_BufferSize = STM32_DataStruct.CommandStruct.DataBlocks * STM32_BlockSize;
  // DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  // DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  // DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_Word;
  // DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_Word;
  // DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  // DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  // DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;         
  // DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_HalfFull;
  // DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  // DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  // DMA_Init(DMA2_Stream0, &DMA_InitStructure);
  // /* DMA2_Stream0 enable */
  // DMA_Cmd(DMA2_Stream0, ENABLE);
}

/*******************************************************************************
* Function Name  : SPI_Configuration
* Description    : Configures SPI2 to output DDS configuration
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void SPI_Config(void)
{
  SPI_InitTypeDef SPI_InitStructure;

	/* Set up SPI2 port */
	SPI_InitStructure.SPI_Direction = SPI_Direction_1Line_Tx;
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
	SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
	SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
	SPI_InitStructure.SPI_CPHA = SPI_CPHA_2Edge;
	SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
	SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_8;
	SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
  SPI_InitStructure.SPI_CRCPolynomial = 7;
	SPI_Init(SPI2, &SPI_InitStructure);
	SPI_Cmd(SPI2, ENABLE);
}

/**
  * @brief  This function handles TIM10 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM1_UP_TIM10_IRQHandler(void)
{
  uint16_t i,j,k;
  /* Clear the IT pending Bit */
  TIM10->SR=(u16)~TIM_IT_Update;
  /* TIM11 is used to time the H-Sync (4,70uS) */
  /* Reset TIM11 count */
  TIM11->CNT=0;
  /* Enable TIM11 */
  TIM11->CR1=1;
  /* H-Sync or V-Sync low */
  GPIOA->BSRRH = (uint16_t)GPIO_Pin_1;
  if (LineCount>=TOP_MARGIN && LineCount<SCREEN_HEIGHT*TILE_HEIGHT+TOP_MARGIN)
  {
    /* Make a video line. Since the SPI operates in halfword mode
       odd character first then even character stored in pixel buffer. */
    j=k=LineCount-TOP_MARGIN;
    j=j/TILE_HEIGHT;
    k=k-j*TILE_HEIGHT;
    i=0;
    while (i<SCREEN_WIDTH)
    {
      PixelBuff[i]=Font8x10[ScreenChars[j][i+1]][k];
      PixelBuff[i+1]=Font8x10[ScreenChars[j][i]][k];
      i+=2;
    }
  }
}

/**
  * @brief  This function handles TIM11 global interrupt request.
  * @param  None
  * @retval None
  */
void TIM1_TRG_COM_TIM11_IRQHandler(void)
{
  u32 tmp;
  /* Disable TIM11 */
  TIM11->CR1=0;
  /* Clear the IT pending Bit */
  TIM11->SR=(u16)~TIM_IT_Update;
  if (LineCount<303)
  {
    /* H-Sync high */
    GPIOA->BSRRL=(u16)GPIO_Pin_1;
    if (LineCount>=TOP_MARGIN && LineCount<SCREEN_HEIGHT*TILE_HEIGHT+TOP_MARGIN)
    {
      /* The time it takes to init the DMA and run the loop is the Front porch */
      tmp=0;
      while (tmp<20)
      {
        tmp++;
      }
      /* Set up the DMA to keep the SPI port fed from the pixelbuffer. */
      /* Disable the selected DMA1 Channel3 */
      DMA1_Stream0->CR &= (u32)0xFFFFFFFE;
      /* Reset DMA1 Channel3 control register */
      DMA1_Stream0->CR  = 0;
      // /* Reset interrupt pending bits for DMA1 Channel3 */
      // DMA1->IFCR |= (u32)0x00000F00;

      // DMA1_Stream0->CR = (u32)DMA_DIR_PeripheralDST | DMA_Mode_Normal |
                              // DMA_PeripheralInc_Disable | DMA_MemoryInc_Enable |
                              // DMA_PeripheralDataSize_HalfWord | DMA_MemoryDataSize_HalfWord |
                              // DMA_Priority_VeryHigh | DMA_M2M_Disable;
      // /* Write to DMA1 Channel3 CNDTR */
      // /* Add 1 halfword to ensure MOSI is low when transfer is done. */
      // DMA1_Channel3->CNDTR = (u32)SCREEN_WIDTH/2+1;
      // /* Write to DMA1 Channel3 CPAR */
      // DMA1_Channel3->CPAR = (u32)0x4001300C;
      // /* Write to DMA1 Channel3 CMAR */
      // DMA1_Channel3->CMAR = (u32)PixelBuff;
      // /* Enable DMA1 Channel3 */
      // DMA1_Channel3->CCR |= (u32)0x00000001;
    }
  }
  else if (LineCount==313)
  {
    /* V-Sync high after 313-303=10 lines) */
    GPIOA->BSRRL=(u16)GPIO_Pin_1;
    FrameCount++;
    LineCount=0xffff;
  }
  LineCount++;
}

/*****END OF FILE****/
