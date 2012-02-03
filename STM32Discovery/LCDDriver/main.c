/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 01/30/2012
* Description        : Main program body
*******************************************************************************/

/*******************************************************************************
* Horizontal
* H-sync         4,70uS
* Blank start    1,65uS
* Active video  51,95uS
* Blank end      5,70uS
* Line total    64,0uS
* 
* Vertical
* V-sync        0,576mS (9 lines)
* Frame         20mS (312,5 lines)
* Video signal  288 lines
*******************************************************************************/

#define BUFFER_LINE_LENGTH          64  // 32 halfwords (64characters*8bits/16bits.
#define SCREEN_LINE_LENGHT          64  // 64 characters on each screen line.
#define SCREEN_TILE_WIDTH           8   // Width of each character tile.
#define SCREEN_TILE_HEIGHT          8   // Height of each character tile.

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"
#include "Font6x8.h"

/* Private variables ---------------------------------------------------------*/
ErrorStatus HSEStartUpStatus;
NVIC_InitTypeDef NVIC_InitStructure;
TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
SPI_InitTypeDef SPI_InitStructure;
DMA_InitTypeDef DMA_InitStructure;
vu16 LineCount;
vu16 CharTileLineInx;
vu16 ScreenCharLineInx;
vu8 ScreenChars[32*64];
vu8 LineTileBuff[BUFFER_LINE_LENGTH];
/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void TIM2_Configuration(void);
void TIM3_Configuration(void);
void TIM4_Configuration(void);
void SPI_Config(void);
void DMA_Config(void);
void MakeVideoLine(void);

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
    ScreenChars[0]='A';
    ScreenChars[1]='B';
    ScreenChars[2]='C';
    ScreenChars[3]='D';
    ScreenChars[4]='E';
    ScreenChars[5]='F';
    ScreenChars[6]='G';
    ScreenChars[7]='H';
    // MakeVideoLine();
    // LineCount++;
    // CharTileLineInx++;
    // MakeVideoLine();
    // LineCount++;
    // CharTileLineInx++;
    // MakeVideoLine();
    // LineCount++;
    // CharTileLineInx++;
    // MakeVideoLine();
  /* System clocks configuration ---------------------------------------------*/
  RCC_Configuration();
  /* NVIC configuration ------------------------------------------------------*/
  NVIC_Configuration();
  /* GPIO configuration ------------------------------------------------------*/
  GPIO_Configuration();
  /* TIM2 configuration ------------------------------------------------------*/
  TIM2_Configuration();
  /* TIM3 configuration ------------------------------------------------------*/
  TIM3_Configuration();
  /* TIM4 configuration ------------------------------------------------------*/
  TIM4_Configuration();
  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);
  /* Enable TIM2 Update interrupt */
  TIM_ClearITPendingBit(TIM2,TIM_IT_Update);
  TIM_ITConfig(TIM2, TIM_IT_Update, ENABLE);
  /* Enable TIM3 Update interrupt */
  TIM_ClearITPendingBit(TIM3,TIM_IT_Update);
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
  /* Enable TIM4 Update interrupt */
  TIM_ClearITPendingBit(TIM4,TIM_IT_Update);
  TIM_ITConfig(TIM4, TIM_IT_Update, ENABLE);
  while (1)
  {
  }
}

/*******************************************************************************
* Function Name  : MakeVideoLine
* Description    : This function makes a video line.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void MakeVideoLine(void)
{
  /* r0 current line start index into ScreenChars buffer */
  asm volatile("mov r0,%0" : : "r" (ScreenChars));
  asm volatile("add r0,%0" : : "r" (ScreenCharLineInx));
  /* r1 current line start pointer into Font6x8 */
  asm volatile("mov r1,%0" : : "r" (Font6x8));
  asm volatile("add r1,%0" : : "r" (CharTileLineInx));
  asm volatile("mov r2,%0" : : "r" (LineTileBuff));
  asm volatile
  (
    "mov r7,#0x0\r\n"             // Character index in current line
    "L1:\r\n"
    "ldrb r3,[r0,r7]\r\n"         // Character
    "ldrb r3,[r1,r3,lsl #3]\r\n"  // Character tile pixels
    "strb r3,[r2,r7]\r\n"         // Line tile pixels
    "add r7,r7,#0x1\r\n"
    "cmp r7,#64\r\n"
    "it ne\r\n"
    "bne L1"
  );
}

/*******************************************************************************
* Function Name  : TIM2_IRQHandler
* Description    : This function handles TIM2 global interrupt request.
*                  An interrupt is generated 1,65uS after the end of horizontal sync.
*                  The video signal is generated here.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM2_IRQHandler(void)
{
	DMA_Cmd(DMA1_Channel3, ENABLE);
  /* Clear TIM2 Update interrupt pending bit */
  asm("mov r1,#0x40000000");
  asm("strh r1,[r1,#0x10]");
  /* Disable TIM2 */
  asm("strh r0,[r1,#0x0]");
  // asm("push {r4}");
  // /* r0 line start index into ScreenChar */
  // asm volatile("ldr r0,[%0]" : : "r" (ScreenCharLineInx));
  // asm volatile("ldr r1,[%0]" : : "r" (CharTileLineInx));
  // asm volatile("add r1,r1,%0" : : "r" (Font6x8));
  // asm volatile
  // (
    // "movw r4,#0x0001\r\n"         // Port bit set / reset
    // "movw r2,#0x0800\r\n"         // GPIOA
    // "movt r2,#0x1000\r\n"
    // "mov r7,#0x0\r\n"             // Character index in current line
    // "L2:\r\n"
    // "ldrb r3,[r0,r7]\r\n"         // Character
    // "ldrb r3,[r1,r3,lsl #3]\r\n"  // Character tile pixels

    // "lsls r3,r3,#25\r\n"           // Shift left 25 bits
    // "ite cs\r\n"                   // if else condition
    // "strhcs r4,[r2,#0x10]\r\n"     // if carry Set port bit
    // "strhcc r4,[r2,#0x14]\r\n"     // else Reset port bit

    // "lsls r3,r3,#1\r\n"           // Shift left 1 bit
    // "ite cs\r\n"                  // if else condition
    // "strhcs r4,[r2,#0x10]\r\n"    // if carry Set port bit
    // "strhcc r4,[r2,#0x14]\r\n"    // else Reset port bit

    // "lsls r3,r3,#1\r\n"
    // "ite cs\r\n"
    // "strhcs r4,[r2,#0x10]\r\n"
    // "strhcc r4,[r2,#0x14]\r\n"

    // "lsls r3,r3,#1\r\n"
    // "ite cs\r\n"
    // "strhcs r4,[r2,#0x10]\r\n"
    // "strhcc r4,[r2,#0x14]\r\n"

    // "lsls r3,r3,#1\r\n"
    // "ite cs\r\n"
    // "strhcs r4,[r2,#0x10]\r\n"
    // "strhcc r4,[r2,#0x14]\r\n"

    // "lsls r3,r3,#1\r\n"
    // "ite cs\r\n"
    // "strhcs r4,[r2,#0x10]\r\n"
    // "strhcc r4,[r2,#0x14]\r\n"

    // "add r7,r7,#0x1\r\n"
    // "cmp r7,#80\r\n"
    // "it ne\r\n"
    // "bne L2"
  // );
  // asm("pop {r4}");
}

/*******************************************************************************
* Function Name  : TIM3_IRQHandler
* Description    : This function handles TIM3 global interrupt request.
*                  An interrupt is generated for each horizontal line.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_IRQHandler(void)
{
  /* Clear TIM3 Update interrupt pending bit */
  asm("mov r0,#0x0");
  asm("movw r1,#0x0400");
  asm("movt r1,#0x4000");
  asm("strh r0,[r1,#0x10]");
  /* Reset TIM4 count */
  asm("movw r1,#0x0800");
  asm("movt r1,#0x4000");
  asm("strh r0,[r1,#0x24]");
  /* Enable TIM4 */
  asm("mov r0,#0x1");
  asm("strh r0,[r1,#0x0]");
  /* H-Sync low */
  asm("movw r1,#0x0800");         // GPIOA
  asm("movt r1,#0x1000");
  asm("mov r0,#0x2");             // GPIO_Pin_1
  asm("strh r0,[r1,#0x14]");      // GPIO_ResetBits
  if (LineCount<256)
  {
    ScreenCharLineInx=(LineCount>>3)*64;
    CharTileLineInx=LineCount & 7;
    MakeVideoLine();
  }
}

/*******************************************************************************
* Function Name  : TIM4_IRQHandler
* Description    : This function handles TIM4 global interrupt request.
*                  An interrupt is generated after 4,70uS for each horizontal line.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM4_IRQHandler(void)
{
  /* Clear TIM4 Update interrupt pending bit */
  asm("mov    r0,#0x0");
  asm("movw   r1,#0x0800");
  asm("movt   r1,#0x4000");
  asm("strh   r0,[r1,#0x10]");
  /* Disable TIM4 */
  asm("strh   r0,[r1,#0x0]");

  if (LineCount<303)
  {
    /* H-Sync high */
    GPIO_SetBits(GPIOA,GPIO_Pin_1);
    /* Skip 10 lines befor any video signal */
    if (LineCount<256)
    {
      /* Reset TIM2 count */
      TIM2->CNT=0;
      /* Enable TIM2 */
      TIM2->CR1=1;
    }
  }
  else if (LineCount==312)
  {
    /* V-Sync high after 312-303=9 lines) */
    GPIO_SetBits(GPIOA,GPIO_Pin_1);
    LineCount=0xffff;
  }
  LineCount++;
}

/*******************************************************************************
* Function Name  : RCC_Configuration
* Description    : Configures the different system clocks.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void RCC_Configuration(void)
{
  /* RCC system reset(for debug purpose) */
  RCC_DeInit();
  /* Enable HSE */
  RCC_HSEConfig(RCC_HSE_ON);
  /* Wait till HSE is ready */
  HSEStartUpStatus = RCC_WaitForHSEStartUp();
  if(HSEStartUpStatus == SUCCESS)
  {
    /* Enable Prefetch Buffer */
    FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);
    /* Flash 2 wait state */
    FLASH_SetLatency(FLASH_Latency_0);
    /* HCLK = SYSCLK */
    RCC_HCLKConfig(RCC_SYSCLK_Div1); 
    /* PCLK2 = HCLK */
    RCC_PCLK2Config(RCC_HCLK_Div1); 
    /* PCLK1 = HCLK */
    RCC_PCLK1Config(RCC_HCLK_Div1);
    /* ADCCLK = PCLK2/2 */
    RCC_ADCCLKConfig(RCC_PCLK2_Div2);
    /* PLLCLK = 8MHz * 7 = 56 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_7);
    /* Enable PLL */ 
    RCC_PLLCmd(ENABLE);
    /* Wait till PLL is ready */
    while(RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET)
    {
    }
    /* Select PLL as system clock source */
    RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);
    /* Wait till PLL is used as system clock source */
    while(RCC_GetSYSCLKSource() != 0x08)
    {
    }
  }
  /* Enable peripheral clocks ------------------------------------------------*/
	RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1 , ENABLE);	
  /* Enable GPIOA, GPIOB and GPIOC clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC | RCC_APB2Periph_SPI1, ENABLE);
  /* Enable TIM2, TIM3 and TIM4 clock */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4, ENABLE);
}

/*******************************************************************************
* Function Name  : GPIO_Configuration
* Description    : Configures the different GPIO ports.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void GPIO_Configuration(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  /* Configure PA1 and PA0 as outputs */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
	/* GPIOA Configuration:SPI1_MOSI and SPI1_SCK as alternate function push-pull */
	GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_5 ;
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
	GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
	GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* Video signal */
  GPIO_ResetBits(GPIOA,GPIO_Pin_0);
  /* Sync signal */
  GPIO_SetBits(GPIOA,GPIO_Pin_1);
}

/*******************************************************************************
* Function Name  : NVIC_Configuration
* Description    : Configures Vector Table base location.
*                  Configures interrupts.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void NVIC_Configuration(void)
{
  /* Set the Vector Table base location at 0x08000000 */ 
  NVIC_SetVectorTable(NVIC_VectTab_FLASH, 0x0);   
  /* Enable the TIM2 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM2 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM3 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM4 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM4_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

/*******************************************************************************
* Function Name  : TIM2_Configuration
* Description    : Configures TIM2 to count up
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM2_Configuration(void)
{
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 92;                      // 1.65uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
}

/*******************************************************************************
* Function Name  : TIM3_Configuration
* Description    : Configures TIM3 to count up
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_Configuration(void)
{
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 56*64;                   // 64uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
}

/*******************************************************************************
* Function Name  : TIM4_Configuration
* Description    : Configures TIM4 to count up
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM4_Configuration(void)
{
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 263;                   // 4,70uS
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM4, &TIM_TimeBaseStructure);
}

void SPI_Config(void)
{
	//Set up SPI port.  This acts as a pixel buffer.
	SPI_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
	SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
	SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
	SPI_InitStructure.SPI_CPHA = SPI_CPHA_2Edge;
	SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
	SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_8;
	SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
	SPI_Init(SPI1, &SPI_InitStructure);
	SPI_Cmd(SPI1, ENABLE);
	SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Tx, ENABLE);
}

void DMA_Config(void)
{
	//Set up the DMA to keep the SPI port fed from the framebuffer.
	DMA_DeInit(DMA1_Channel3);
	DMA_InitStructure.DMA_PeripheralBaseAddr = (u32)0x4001300C;
	DMA_InitStructure.DMA_MemoryBaseAddr = (u32)LineTileBuff[0];
	DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralDST;
	DMA_InitStructure.DMA_Priority = DMA_Priority_Low;
	DMA_InitStructure.DMA_BufferSize = BUFFER_LINE_LENGTH;
	DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
	DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
	DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
	DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
	DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
	DMA_InitStructure.DMA_M2M = DMA_M2M_Disable;
	DMA_Init(DMA1_Channel3, &DMA_InitStructure);
}

/*****END OF FILE****/
