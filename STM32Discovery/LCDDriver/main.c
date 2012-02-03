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

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"
#include "Font6x8.h"

/* Private variables ---------------------------------------------------------*/
ErrorStatus HSEStartUpStatus;
NVIC_InitTypeDef NVIC_InitStructure;
TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
vu16 LineCount;
vu16 CharTileLineInx;
vu16 ScreenCharLineInx;
vu16 ScreenChars[25*80];

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void TIM2_Configuration(void);
void TIM3_Configuration(void);
void TIM4_Configuration(void);

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
  /* Clear TIM2 Update interrupt pending bit */
  asm("mov    r1,#0x40000000");
  asm("strh   r1,[r1,#0x10]");
  /* Disable TIM2 */
  asm("strh   r0,[r1,#0x0]");
  /* r0 line start index into ScreenChar */
  asm volatile("ldr r0,[%0]" : : "r" (ScreenCharLineInx));
  asm volatile("ldr r1,[%0]" : : "r" (CharTileLineInx));
  asm volatile("add r1,r1,%0" : : "r" (Font6x8));
  asm volatile
  (
    "movw r2,#0x0800\r\n"         // GPIOA
    "movt r2,#0x1000\r\n"
    "mov r7,#0x0\r\n"             // Character index in current line
    "L1:\r\n"
    "ldrb r3,[r0,r7]\r\n"         // Character
    "ldrb r3,[r1,r3,lsl #3]\r\n"  // Character tile pixels

    "lsl r3,r3,#1\r\n"
    "ite cs\r\n"
    "strcs r4,[r2,#0x10]\r\n"
    "strcc r4,[r2,#0x14]\r\n"

    "lsl r3,r3,#1\r\n"
    "ite cs\r\n"
    "strcs r4,[r2,#0x10]\r\n"
    "strcc r4,[r2,#0x14]\r\n"

    "lsl r3,r3,#1\r\n"
    "ite cs\r\n"
    "strcs r4,[r2,#0x10]\r\n"
    "strcc r4,[r2,#0x14]\r\n"

    "lsl r3,r3,#1\r\n"
    "ite cs\r\n"
    "strcs r4,[r2,#0x10]\r\n"
    "strcc r4,[r2,#0x14]\r\n"

    "lsl r3,r3,#1\r\n"
    "ite cs\r\n"
    "strcs r4,[r2,#0x10]\r\n"
    "strcc r4,[r2,#0x14]\r\n"

    "lsl r3,r3,#1\r\n"
    "ite cs\r\n"
    "strcs r4,[r2,#0x10]\r\n"
    "strcc r4,[r2,#0x14]\r\n"

    "add r7,r7,#0x1\r\n"
    "cmp r7,#80\r\n"
    "it ne\r\n"
    "bne L1"
  );
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
  asm("mov    r0,#0x0");
  asm("movw   r1,#0x0400");
  asm("movt   r1,#0x4000");
  asm("strh   r0,[r1,#0x10]");
  /* Reset TIM4 count */
  TIM4->CNT=0;
  /* Enable TIM4 */
  TIM4->CR1=1;
  /* H-Sync low */
  GPIO_ResetBits(GPIOA,GPIO_Pin_1);
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
    if (LineCount>=10 && LineCount<260)
    {
      /* Reset TIM2 count */
      TIM2->CNT=0;
      /* Enable TIM2 */
      TIM2->CR1=1;
      ScreenCharLineInx=(LineCount/10-1)*80;
      CharTileLineInx=LineCount/10;
      CharTileLineInx=ScreenCharLineInx*10;
      CharTileLineInx=LineCount-CharTileLineInx-10;
    }
  }
  else if (LineCount==312)
  {
    /* V-Sync high (9 lines) */
    GPIO_SetBits(GPIOA,GPIO_Pin_1);
    LineCount=0xffff;
    ScreenCharLineInx=0;
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
  /* Enable GPIOA, GPIOB and GPIOC clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC, ENABLE);
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
  /* Configure PA7 to PA0 as outputs */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4 | GPIO_Pin_3 | GPIO_Pin_2 | GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
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
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM4 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM4_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
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

/*****END OF FILE****/
