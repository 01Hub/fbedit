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

#define TOP_MARGIN                  24  // Number of lines before video signal starts
#define SCREEN_WIDTH                64  // 80 characters on each screen line.
#define SCREEN_HEIGHT               32  // 32 screen lines.
#define TILE_WIDTH                  8   // Width of each character tile.
#define TILE_HEIGHT                 8   // Height of each character tile.

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
vu8 ScreenChars[SCREEN_HEIGHT][SCREEN_WIDTH];
vu8 PixelBuff[SCREEN_WIDTH];

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void TIM3_Configuration(void);
void TIM4_Configuration(void);
void SPI_Configuration(void);
void DMA_Configuration(void);
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
  u16 x,y;
  u8 c;
  y=0;
  c=0;
  // while (y<SCREEN_HEIGHT)
  while (y<16)
  {
    x=0;
    while (x<SCREEN_WIDTH)
    {
      ScreenChars[y][x]=c;
      c++;
      x++;
    }
    y++;
  }
  /* System clocks configuration ---------------------------------------------*/
  RCC_Configuration();
  /* NVIC configuration ------------------------------------------------------*/
  NVIC_Configuration();
  SPI_Configuration();
  // DMA_Configuration();
  /* GPIO configuration ------------------------------------------------------*/
  GPIO_Configuration();
  /* TIM3 configuration ------------------------------------------------------*/
  TIM3_Configuration();
  /* TIM4 configuration ------------------------------------------------------*/
  TIM4_Configuration();
  /* Enable TIM2 Update interrupt */
  TIM_ClearITPendingBit(TIM2,TIM_IT_Update);
  TIM_ITConfig(TIM2, TIM_IT_Update, ENABLE);
  /* Enable TIM3 Update interrupt */
  TIM_ClearITPendingBit(TIM3,TIM_IT_Update);
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
  /* Enable TIM4 Update interrupt */
  TIM_ClearITPendingBit(TIM4,TIM_IT_Update);
  TIM_ITConfig(TIM4, TIM_IT_Update, ENABLE);
  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);
  while (1)
  {
    // GPIO_ResetBits(GPIOC,GPIO_Pin_8);
    // GPIO_SetBits(GPIOC,GPIO_Pin_8);
  }
}

/*******************************************************************************
* Function Name  : MakeVideoLine
* Description    : This function makes a video line.
*                  Since the SPI operates in halfword mode
*                  odd first then even character stored in pixel buffer.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void MakeVideoLine(void)
{
  // u16 i,j,k;
  // u8 c;
  // j=LineCount-TOP_MARGIN;
  // k=j && (TILE_HEIGHT-1);
  // j=j/TILE_HEIGHT;
  // i=0;
  // while (i<SCREEN_WIDTH)
  // {
    // c=ScreenChars[j][i+1];
    // c=Font6x8[c][k];
    // PixelBuff[i]=c;
    // c=ScreenChars[j][i];
    // c=Font6x8[c][k];
    // PixelBuff[i+1]=c;
    // i=i+2;
  // }
  asm volatile("push {r4}");
  asm volatile("mov r2,%0" : : "r" (LineCount));
  asm volatile("sub r2,#24");
  asm volatile("mov r4,r2");
  asm volatile("lsr r2,#3");
  asm volatile("lsl r2,#6");      // (LineCount>>3)<<6
  asm volatile("and r4,#7");      // LineCount & 7
  /* r0 current line start index into ScreenChars buffer */
  asm volatile("mov r0,%0" : : "r" (ScreenChars));
  asm volatile("add r0,r2");
  /* r1 current line start pointer into Font6x8 */
  asm volatile("mov r1,%0" : : "r" (Font6x8));
  asm volatile("add r1,r4");
  asm volatile("mov r2,%0" : : "r" (PixelBuff));
  asm volatile
  (
    "mov r4,#0x0\r\n"             // Character index in current line
    "L1:\r\n"
    "add r4,#0x1\r\n"             // Odd character index
    "ldrb r3,[r0,r4]\r\n"         // Get odd character
    "ldrb r3,[r1,r3,lsl #3]\r\n"  // Get character tile pixels from font
    "sub r4,#0x1\r\n"             // Even character index
    "strb r3,[r2,r4]\r\n"         // Store in pixels buffer
    "ldrb r3,[r0,r4]\r\n"         // Get even character
    "ldrb r3,[r1,r3,lsl #3]\r\n"  // Get character tile pixels from font
    "add r4,#0x1\r\n"             // Next byte
    "strb r3,[r2,r4]\r\n"         // Store in pixels buffer
    "add r4,#0x1\r\n"             // Next byte
    "cmp r4,#64\r\n"
    "it ne\r\n"
    "bne L1"
  );
  asm volatile("pop {r4}");
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
  /* Clear the IT pending Bit */
  TIM3->SR=(u16)~TIM_IT_Update;
  /* Reset TIM4 count */
  TIM4->CNT=0;
  /* Enable TIM4 */
  TIM4->CR1=1;
  /* V-Sync */
  GPIOA->BRR=(u16)GPIO_Pin_0;
  // /* Clear TIM3 Update interrupt pending bit */
  // asm("mov r0,#0x0");
  // asm("movw r1,#0x0400");
  // asm("movt r1,#0x4000");
  // asm("strh r0,[r1,#0x10]");
  // /* Reset TIM4 count */
  // asm("movw r1,#0x0800");
  // asm("movt r1,#0x4000");
  // asm("strh r0,[r1,#0x24]");
  // /* Enable TIM4 */
  // asm("mov r0,#0x1");
  // asm("strh r0,[r1,#0x0]");
  // /* H-Sync low */
  // asm("movw r1,#0x0800");         // GPIOA
  // asm("movt r1,#0x1000");
  // asm("mov r0,#0x1");             // GPIO_Pin_0
  // asm("strh r0,[r1,#0x14]");      // GPIO_ResetBits
  if (LineCount>=TOP_MARGIN && LineCount<256+TOP_MARGIN)
  {
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
  // /* Clear TIM4 Update interrupt pending bit */
  // asm("mov    r0,#0x0");
  // asm("movw   r1,#0x0800");
  // asm("movt   r1,#0x4000");
  // asm("strh   r0,[r1,#0x10]");
  // /* Disable TIM4 */
  // asm("strh   r0,[r1,#0x0]");

  /* Disable TIM4 */
  TIM4->CR1=0;
  if (LineCount<303)
  {
    /* H-Sync high */
    GPIOA->BSRR=(u16)GPIO_Pin_0;
    if (LineCount>=TOP_MARGIN && LineCount<256+TOP_MARGIN)
    {
      DMA_Configuration();
      /* Enable DMA1 Channel3 */
      DMA1_Channel3->CCR|=(u32)0x00000001;
    }
  }
  else if (LineCount==312)
  {
    /* V-Sync high after 312-303=9 lines) */
    GPIOA->BSRR=(u16)GPIO_Pin_0;
    LineCount=0xffff;
  }
  LineCount++;
  /* Clear the IT pending Bit */
  TIM4->SR=(u16)~TIM_IT_Update;
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
  /* Enable DMA1 clock */
	RCC_AHBPeriphClockCmd(RCC_AHBPeriph_DMA1 , ENABLE);	
  /* Enable GPIOA, GPIOB, GPIOC and SPI1 clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC | RCC_APB2Periph_SPI1, ENABLE);
  /* Enable TIM3 and TIM4 clock */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4, ENABLE);
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
  /* Configure PA0 as outputs */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
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
  /* Sync signal */
  GPIO_SetBits(GPIOA,GPIO_Pin_0);
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

void SPI_Configuration(void)
{
	//Set up SPI port.  This acts as a pixel buffer.
	SPI_InitStructure.SPI_Direction = SPI_Direction_2Lines_FullDuplex;
	SPI_InitStructure.SPI_Mode = SPI_Mode_Master;
	SPI_InitStructure.SPI_DataSize = SPI_DataSize_16b;
	SPI_InitStructure.SPI_CPOL = SPI_CPOL_Low;
	SPI_InitStructure.SPI_CPHA = SPI_CPHA_2Edge;
	SPI_InitStructure.SPI_NSS = SPI_NSS_Soft;
	SPI_InitStructure.SPI_BaudRatePrescaler = SPI_BaudRatePrescaler_4;
	SPI_InitStructure.SPI_FirstBit = SPI_FirstBit_MSB;
	SPI_Init(SPI1, &SPI_InitStructure);
	SPI_Cmd(SPI1, ENABLE);
	SPI_I2S_DMACmd(SPI1, SPI_I2S_DMAReq_Tx, ENABLE);
}

void DMA_Configuration(void)
{
	//Set up the DMA to keep the SPI port fed from the linebuffer.
	DMA_DeInit(DMA1_Channel3);
	DMA_InitStructure.DMA_PeripheralBaseAddr = (u32)0x4001300C;
	DMA_InitStructure.DMA_MemoryBaseAddr = (u32)PixelBuff;
	DMA_InitStructure.DMA_DIR = DMA_DIR_PeripheralDST;
	DMA_InitStructure.DMA_Priority = DMA_Priority_VeryHigh;
	DMA_InitStructure.DMA_BufferSize = SCREEN_WIDTH/2;
	DMA_InitStructure.DMA_PeripheralInc = DMA_PeripheralInc_Disable;
	DMA_InitStructure.DMA_MemoryInc = DMA_MemoryInc_Enable;
	DMA_InitStructure.DMA_PeripheralDataSize = DMA_PeripheralDataSize_HalfWord;
	DMA_InitStructure.DMA_MemoryDataSize = DMA_MemoryDataSize_HalfWord;
	DMA_InitStructure.DMA_Mode = DMA_Mode_Normal;
	DMA_InitStructure.DMA_M2M = DMA_M2M_Disable;
	DMA_Init(DMA1_Channel3, &DMA_InitStructure);
}

/*****END OF FILE****/
