/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 14/08/2012
* Description        : Main program body
*******************************************************************************/

/*******************************************************************************
* Port pins used
*
* Video out
* PA1   H-Sync and V-Sync
* PB15  Video out SPI2_MOSI
*
* RS232
* PA2   USART2 Tx
* PA3   USART2 Rx
*
* Logic analyser
* PE8 to PE15
*
* Frequency counter
* PA15  TIM2_CH1
*
* High speed clock
* PB8   TIM10_CH1
*
* Scope
* PB0   ADC12 channel 8

* Keyboard
* PB0   Keyboard clock in
* PB1   Keyboard data in
*
* Mouse
* PB2   Mouse clock in
* PB3   Mouse data in
*
* Leds
* PA9   Green
* PD5   Red
* PD12  Green
* PD13  Orange
* PD14  Red
* PD15  Blue
*
* User button
* PA0   User button
*
*******************************************************************************/

/*******************************************************************************
* Video output
*                  330
* PB15    O-------[  ]---o---------O  Video output
*                  1k0   |
* PA1     O-------[  ]---o
*                        |
*                       ---
*                       | |  82
*                       ---
*                        |
* GND     O--------------o---------O  GND
* 
*******************************************************************************/

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "video.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern volatile uint8_t nStuck;
extern volatile uint8_t mbytecount;

/* Private variables ---------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
void RCC_Config(void);
void NVIC_Config(void);
void GPIO_Config(void);
void TIM_Config(void);
void SPI_Config(void);
void DMA_Config(void);
void USART_Config(uint32_t Baud);

/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
void main(void)
{
  RCC_Config();
  NVIC_Config();
  GPIO_Config();
  TIM_Config();
  SPI_Config();
  DMA_Config();
  USART_Config(9600);
  STM_EVAL_LEDInit(LED3);
  STM_EVAL_LEDInit(LED4);
  STM_EVAL_PBInit(BUTTON_USER,BUTTON_MODE_GPIO);
  LgaInit();
  ScopeInit();
  HSClkInit();

  /* Enable TIM10 */
  TIM_Cmd(TIM10, ENABLE);
  /* Enable TIM2 */
  TIM_Cmd(TIM2, ENABLE);
  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);
  MouseInit();
  SetCursor(0);
  MoveCursor(SCREEN_WIDTH/2,SCREEN_HEIGHT/2);
  /* Wait 25 frames */
  FrameWait(25);
  mbytecount=0;
  nStuck=10;
  KeyboardReset();
  while (1)
  {
    DeskTopSetup();
  }
}

/**
  * @brief  Configure peripheral clocks
  * @param  None
  * @retval None
  */
void RCC_Config(void)
{
  /* Enable DMA1, DMA2, GPIOA, GPIOB and GPIOE clocks */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA1 | RCC_AHB1Periph_DMA2 | RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOB | RCC_AHB1Periph_GPIOE, ENABLE);
  /* Enable USART2, TIM2, TIM3, TIM4, TIM7 and SPI2 clocks */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2 | RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4 | RCC_APB1Periph_TIM7 | RCC_APB1Periph_SPI2, ENABLE);
  /* Enable ADC1, TIM8, TIM10 and SYSCFG clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC1 | RCC_APB2Periph_TIM8 | RCC_APB2Periph_TIM10 | RCC_APB2Periph_SYSCFG, ENABLE);
}

/**
  * @brief  Configure interrupts
  * @param  None
  * @retval None
  */
void NVIC_Config(void)
{
  NVIC_InitTypeDef NVIC_InitStructure;

  NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2);
  /* Enable and set TIM3 interrupt to high priority */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable and set TIM4 interrupt to the highest priority */
  NVIC_InitStructure.NVIC_IRQChannel = TIM4_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable and set TIM7 interrupt to low priority */
  NVIC_InitStructure.NVIC_IRQChannel = TIM7_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 3;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
	/* Enable and set USART interrupt to the lowest priority */
	NVIC_InitStructure.NVIC_IRQChannel = USART2_IRQn;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 3;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_InitStructure);
}

/**
  * @brief  Configure GPIO
  * @param  None
  * @retval None
  */
void GPIO_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  EXTI_InitTypeDef EXTI_InitStructure;

  /* Configure PA1 as output, H-Sync and V-Sync*/
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_OUT;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* H-Sync and V-Sync signal High */
  GPIO_SetBits(GPIOA,GPIO_Pin_1);

  /* SPI MOSI and SPI SCK pin configuration */
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_UP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_15 | GPIO_Pin_13;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect SPI2 pins */  
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource13, GPIO_AF_SPI2);
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource15, GPIO_AF_SPI2);

  /* USART Tx and Rx pin configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_2 | GPIO_Pin_3;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect USART2 pins */  
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource2, GPIO_AF_USART2);
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource3, GPIO_AF_USART2);

  /* TIM10 chennel 1 configuration : PB8 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Connect TIM10 pin to AF1 */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource8, GPIO_AF_TIM10);

  /* TIM2 chennel 1 configuration : PA.15 */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_15;
  GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_100MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd  = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Connect TIM2 pin to AF1 */
  GPIO_PinAFConfig(GPIOA, GPIO_PinSource15, GPIO_AF_TIM2);
  /* Configure ADC12 Channel 8 pin as analog input (Scope) ******************************/
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AN;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL ;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
}

/**
  * @brief  Configure timers
  * @param  None
  * @retval None
  */
void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  TIM_OCInitTypeDef       TIM_OCInitStructure;

  /* TIM10 Counter configuration */
  TIM_TimeBaseStructure.TIM_Period = 167;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter=0;
  TIM_TimeBaseInit(TIM10, &TIM_TimeBaseStructure);
  /* PWM1 Mode configuration: Channel 1 */
  TIM_OCStructInit(&TIM_OCInitStructure);
  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_Pulse = 83;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  TIM_OC1Init(TIM10, &TIM_OCInitStructure);
  TIM_OC1PreloadConfig(TIM10, TIM_OCPreload_Enable);
  TIM_ARRPreloadConfig(TIM10, ENABLE);
  /* TIM2 Counter configuration */
  TIM_TimeBaseStructure.TIM_Period = 0xffffffff;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  TIM2->CCMR1 = 0x0001;     //CC1S=01
  TIM2->SMCR = 0x0057;      //TS=101, SMS=111
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 84*64-1;                     // 64uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  /* Enable TIM3 Update interrupt */
  TIM_ClearITPendingBit(TIM4,TIM_IT_Update);
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = (84*H_SYNC)/1000;            // 4,70uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM4, &TIM_TimeBaseStructure);
  /* Enable TIM4 Update interrupt */
  TIM_ClearITPendingBit(TIM4,TIM_IT_Update);
  TIM_ITConfig(TIM4, TIM_IT_Update, ENABLE);
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 32;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM7, &TIM_TimeBaseStructure);
  /* Enable TIM7 Update interrupt */
  TIM_ClearITPendingBit(TIM7,TIM_IT_Update);
  TIM_ITConfig(TIM7, TIM_IT_Update, ENABLE);
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 167;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM8, &TIM_TimeBaseStructure);
}

/**
  * @brief  Configures SPI2 to output pixel data
  * @param  None
  * @retval None
  */
void SPI_Config(void)
{
  SPI_InitTypeDef SPI_InitStructure;

	/* Set up SPI2 port */
  SPI_I2S_DeInit(SPI2);
  SPI_StructInit(&SPI_InitStructure);
  SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
  SPI_InitStructure.SPI_Direction = SPI_Direction_1Line_Tx;
  SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
  SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_LSB;
  SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
  /* 168/4/4=10,5 */
  SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_4;
  SPI_Init(SPI2, &SPI_InitStructure);
  SPI_I2S_DMACmd(SPI2, SPI_I2S_DMAReq_Tx, ENABLE);
  /* Enable the SPI port */
  SPI_Cmd(SPI2, ENABLE);
}

/**
  * @brief  Configures DMA1_Stream4, DMA_Channel_0
  * @param  None
  * @retval None
  */
void DMA_Config(void)
{
  DMA_InitTypeDef DMA_InitStructure;

  DMA_DeInit(DMA1_Stream4);
  DMA_InitStructure.DMA_Channel = DMA_Channel_0;
  DMA_InitStructure.DMA_PeripheralBaseAddr = (uint32_t) & (SPI2->DR);
  DMA_InitStructure.DMA_Memory0BaseAddr = 0;
  DMA_InitStructure.DMA_DIR = DMA_DIR_MemoryToPeripheral;
  DMA_InitStructure.DMA_BufferSize = (uint16_t)SCREEN_BUFFWIDTH/2;
  DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
  DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
  DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
  DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
  DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
  DMA_InitStructure.DMA_Priority = DMA_Priority_High;
  DMA_InitStructure.DMA_FIFOMode = DMA_FIFOMode_Disable;
  DMA_InitStructure.DMA_FIFOThreshold = DMA_FIFOThreshold_1QuarterFull;
  DMA_InitStructure.DMA_MemoryBurst = DMA_MemoryBurst_Single;
  DMA_InitStructure.DMA_PeripheralBurst = DMA_PeripheralBurst_Single;
  DMA_Init(DMA1_Stream4, &DMA_InitStructure);
}

/**
  * @brief  Configures USART2 Rx and Tx
  * @param  Baudrate
  * @retval None
  */
void USART_Config(uint32_t Baud)
{
  /* USART1 configured as follow:
        - BaudRate = 4800 baud  
        - Word Length = 8 Bits
        - One Stop Bit
        - No parity
        - Hardware flow control disabled
        - Receive and transmit enabled
  */
  USART_InitTypeDef USART_InitStructure;
 
  USART_InitStructure.USART_BaudRate = Baud;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No ;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART2, &USART_InitStructure);
  /* Enable the USART Receive interrupt: this interrupt is generated when the 
     USART2 receive data register is not empty */
  USART_ITConfig(USART2, USART_IT_RXNE, ENABLE);
  /* Enable the USART2 */
  USART_Cmd(USART2, ENABLE);
}

/*****END OF FILE****/
