/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 05/13/2011
* Description        : Main program body
********************************************************************************

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"

/* Private define ------------------------------------------------------------*/
#define MAXECHO           ((u16)512)

typedef struct
{
  u8 Start;
  u8 PingPulses;
  u16 Gain;
  u16 Timer;
  u16 Skip;
  u16 EchoIndex;
  u16 ADCBatt;
  u16 ADCWaterTemp;
  u16 ADCAirTemp;
  u8 Echo[MAXECHO];
}STM32_SonarTypeDef;

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
static STM32_SonarTypeDef STM32_Sonar;         // 0x20000000
vu8 BlueLED;
vu8 GreenLED;
GPIO_InitTypeDef GPIO_InitStructure;

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void ADC_Startup(void);
void ADC_Configuration(void);
void TIM1_Configuration(void);
void TIM2_Configuration(void);

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
  u32 i;

  /* System clocks configuration ---------------------------------------------*/
  RCC_Configuration();
  /* NVIC configuration ------------------------------------------------------*/
  NVIC_Configuration();
  /* GPIO configuration ------------------------------------------------------*/
  GPIO_Configuration();
  /* TIM1 configuration */
  TIM1_Configuration();
  /* TIM2 configuration ------------------------------------------------------*/
  TIM2_Configuration();
  /* ADC1 configuration ------------------------------------------------------*/
  ADC_Startup();
  /* ADC1 injected channels configuration ------------------------------------*/
  ADC_Configuration();
  STM32_Sonar.PingPulses = 127;
  STM32_Sonar.Gain = 7;
  STM32_Sonar.Timer = 551;

  while (1)
  {
    if (STM32_Sonar.Start == 1)
    {
      STM32_Sonar.Start = 2;
      /* Set the lowest gain */
      GPIO_Write(GPIOC, (u16)0x0);
      /* Toggle blue led */
      if (BlueLED)
      {
        BlueLED = 0;
      }
      else
      {
        GPIO_WriteBit(GPIOC, GPIO_Pin_8, Bit_SET);
        BlueLED = 1;
      }
      /* Read battery */
      STM32_Sonar.ADCBatt = ADC_GetInjectedConversionValue(ADC1, ADC_InjectedChannel_2);
      /* Read water temprature */
      STM32_Sonar.ADCWaterTemp = ADC_GetInjectedConversionValue(ADC1, ADC_InjectedChannel_3);
      /* Read air temprature */
      STM32_Sonar.ADCAirTemp = ADC_GetInjectedConversionValue(ADC1, ADC_InjectedChannel_4);
      /* TIM2 configuration */
      TIM2_Configuration();
      /* Reset echo index */
      STM32_Sonar.EchoIndex = 0;
      /* Reset TIM1 count */
      TIM1->CNT = 0;
      /* Set repetirion counter */
      TIM1->RCR = STM32_Sonar.PingPulses;
      /* TIM1 channel 1 pin (PA.08) and TIM1 channel 2 pin (PA.09) configuration */
      GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8 | GPIO_Pin_9;
      GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
      GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
      GPIO_Init(GPIOA, &GPIO_InitStructure);
      /* Enable TIM1 */
      TIM_Cmd(TIM1, ENABLE);
    }
    i = 0;
    while (i < 1000)
    {
      i++;
    }
  }
}

/*******************************************************************************
* Function Name  : TIM1_UP_IRQHandler
* Description    : This function handles TIM1 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_UP_IRQHandler(void)
{
  u16 tmp;
  /*  Configure pin (PA.08) and pin (PA.09) */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_8 | GPIO_Pin_9;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Clear TIM1 Update interrupt pending bit */
  TIM1->SR = (u16)~TIM_IT_Update;
  /* Disable TIM1 */
  TIM_Cmd(TIM1, DISABLE);
  /* Set the gain */
  tmp = GPIO_ReadInputData(GPIOC);
  tmp = tmp & (u16)0xFF00;
  tmp = tmp | (u16)STM32_Sonar.Gain;
  tmp = tmp | (u16)0x80;
  GPIO_Write(GPIOC, (u16)tmp);
  /* Setup injected channels */
  ADC_InjectedSequencerLengthConfig(ADC1,1);
  /* Sonar echo */
  ADC_InjectedChannelConfig(ADC1,ADC_Channel_2,1,ADC_SampleTime_1Cycles5);
  // /* Battery */
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_3,2,ADC_SampleTime_1Cycles5);
  // /* Water temprature */
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_4,3,ADC_SampleTime_1Cycles5);
  // /* Air temprature */
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_16,4,ADC_SampleTime_1Cycles5);
  ADC_AutoInjectedConvCmd(ADC1, ENABLE);
  /* Enable TIM2 */
  TIM_Cmd(TIM2, ENABLE);
}

/*******************************************************************************
* Function Name  : TIM2_IRQHandler
* Description    : This function handles TIM2 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM2_IRQHandler(void)
{
  // /* Clear TIM2 Update interrupt pending bit */
  // asm("mov    r0,#0x40000000");       // TIM2
  // asm("movw   r2,#0xFFFE");
  // asm("strh   r2,[r0,#0x10]");
  // asm("mov    r1,#0x20000000");       // STM32_Sonar
  // asm("ldrh   r2,[r1,#0x6]");         // STM32_Sonar.Skip
  // asm("cbz    r2,TIM2_IRQHandler1");
  // asm("add    r2,#0xFFFFFFFF");
  // asm("strh   r2,[r1,#0x6]");         // STM32_Sonar.Skip
  // asm("movw   r2,#0x0");
  // asm("b      TIM2_IRQHandler2");
  // asm("TIM2_IRQHandler1:");
  // asm("movw   r2,#0x243C");
  // asm("movt   r2,#0x4100");           // ADC1->ADC_InjectedChannel_1
  // asm("ldr    r2,[r2]");
  // asm("uxth   r2,r2");
  // asm("lsr    r2,#0x4");
  // asm("TIM2_IRQHandler2:");
  // asm("ldrh   r3,[r1,#0x8]");         // STM32_Sonar.EchoIndex
  // asm("add    r3,r3,r1");
  // asm("strb   r2,[r3,#0x10]");        // STM32_Sonar.Echo[STM32_Sonar.EchoIndex]
  // asm("ldrh   r3,[r1,#0x8]");         // STM32_Sonar.EchoIndex
  // asm("add    r3,#0x1");
  // asm("strh   r3,[r1,#0x8]");
  // asm("sub    r3,#0x200");            // MAXECHO
  // asm("cbnz   r3,TIM2_IRQHandler3");
  // asm("strh   r3,[r0]");              // TIM2->CR1
  // asm("strb   r3,[r1]");              // STM32_Sonar.Start
  // asm("TIM2_IRQHandler3:");
  /* Clear TIM2 Update interrupt pending bit */
  TIM2->SR = (u16)~TIM_IT_Update;
  if (STM32_Sonar.Skip)
  {
    STM32_Sonar.Skip--;
    STM32_Sonar.Echo[STM32_Sonar.EchoIndex] = 0;
  }
  else
  {
    STM32_Sonar.Echo[STM32_Sonar.EchoIndex] = (ADC_GetInjectedConversionValue(ADC1, ADC_InjectedChannel_1) >> 4);
  }
  STM32_Sonar.EchoIndex++;
  if (STM32_Sonar.EchoIndex == MAXECHO)
  {
    /* Disable TIM2 */
    TIM2->CR1 = 0;
    ADC_AutoInjectedConvCmd(ADC1, DISABLE);
    /* Done */
    STM32_Sonar.Start = 0;
  }
}

/*******************************************************************************
* Function Name  : ADC_Startup
* Description    : This function calibrates ADC1.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ADC_Startup(void)
{
  ADC_InitTypeDef ADC_InitStructure;
  /* ADCCLK = PCLK2/2 */
  RCC_ADCCLKConfig(RCC_PCLK2_Div2);
  /* ADC1 configuration ------------------------------------------------------*/
  ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfChannel = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* ADC1 regular channel2 configuration */ 
  ADC_RegularChannelConfig(ADC1, ADC_Channel_2, 1, ADC_SampleTime_55Cycles5);
  /* Enable ADC1 */
  ADC_Cmd(ADC1, ENABLE);
  /* Enable ADC1 reset calibaration register */   
  ADC_ResetCalibration(ADC1);
  /* Check the end of ADC1 reset calibration register */
  while(ADC_GetResetCalibrationStatus(ADC1));
  /* Start ADC1 calibaration */
  ADC_StartCalibration(ADC1);
  /* Check the end of ADC1 calibration */
  while(ADC_GetCalibrationStatus(ADC1));
}

/*******************************************************************************
* Function Name  : ADC_Configuration
* Description    : This function prepares ADC1 for Injected conversion
*                  on channel 2, 3, 4 and channel 16.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ADC_Configuration(void)
{
  ADC_InitTypeDef ADC_InitStructure;

  /* Enable temprature sensor */
  ADC_TempSensorVrefintCmd(ENABLE);
  /* ADCCLK = PCLK2/8 */
  RCC_ADCCLKConfig(RCC_PCLK2_Div2);
  ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  /* ADC1 single channel configuration -----------------------------*/
  ADC_InitStructure.ADC_NbrOfChannel = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  // /* Setup injected channels */
  // ADC_InjectedSequencerLengthConfig(ADC1,4);
  // /* Sonar echo */
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_2,1,ADC_SampleTime_1Cycles5);
  // /* Battery */
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_3,2,ADC_SampleTime_1Cycles5);
  // /* Water temprature */
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_4,3,ADC_SampleTime_1Cycles5);
  // /* Air temprature */
  // ADC_InjectedChannelConfig(ADC1,ADC_Channel_16,4,ADC_SampleTime_1Cycles5);
  // ADC_AutoInjectedConvCmd(ADC1, ENABLE);
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
  ErrorStatus HSEStartUpStatus;
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
    /* PLLCLK = 8MHz * 6 = 48 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_6);
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
  /* Enable TIM1, ADC1, GPIOA, GPIOB and GPIOC clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1 | RCC_APB2Periph_ADC1 | RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC, ENABLE);
  /* Enable TIM2 clock */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM2, ENABLE);
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
  /* Configure  ADC Channel4 (PA.04), ADC Channel3 (PA.03) and ADC Channel2 (PA.02) as analog input */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4 | GPIO_Pin_3 | GPIO_Pin_2;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* Configure PC07, PC06, PC05, PC04, PC03, PC02, PC01 amd PC00 as open drain output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4 | GPIO_Pin_3 | GPIO_Pin_2 | GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_OD;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  GPIO_WriteBit(GPIOA, GPIO_Pin_8 | GPIO_Pin_9, Bit_SET);
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
  NVIC_InitTypeDef NVIC_InitStructure;
  /* Set the Vector Table base location at 0x08000000 */ 
  NVIC_SetVectorTable(NVIC_VectTab_FLASH, 0x0);   
  /* Enable the TIM1 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM1_UP_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM2 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

/*******************************************************************************
* Function Name  : TIM1_Configuration
* Description    : Configures TIM1 to generate PWM output on PA.08.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_Configuration(void)
{
  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  TIM_OCInitTypeDef  TIM_OCInitStructure;
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 9;
  TIM_TimeBaseStructure.TIM_Prescaler = 23;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = STM32_Sonar.PingPulses;
  TIM_TimeBaseInit(TIM1, &TIM_TimeBaseStructure);
  /* PWM1 Mode configuration: Channel1 */
  TIM_OCStructInit(&TIM_OCInitStructure);
  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_OutputNState = TIM_OutputNState_Disable;
  TIM_OCInitStructure.TIM_Pulse = 5;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  TIM_OC1Init(TIM1, &TIM_OCInitStructure);
  TIM_OC1PreloadConfig(TIM1, TIM_OCPreload_Enable);
  /* PWM1 Mode configuration: Channel2 */
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_Low;
  TIM_OC2Init(TIM1, &TIM_OCInitStructure);
  TIM_OC2PreloadConfig(TIM1, TIM_OCPreload_Enable);
  TIM_ARRPreloadConfig(TIM1, ENABLE);
  /* TIM1 Main Output Enable */
  TIM_CtrlPWMOutputs(TIM1, ENABLE);
  /* Enable TIM1 Update interrupt */
  TIM_ClearITPendingBit(TIM1,TIM_IT_Update);
  TIM_ITConfig(TIM1, TIM_IT_Update, ENABLE);
}

/*******************************************************************************
* Function Name  : TIM2_Configuration
* Description    : Configures TIM2 to count up and generate interrupt on overflow
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM2_Configuration(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = STM32_Sonar.Timer;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  /* Enable TIM2 Update interrupt */
  TIM_ClearITPendingBit(TIM2,TIM_IT_Update);
  TIM_ITConfig(TIM2, TIM_IT_Update, ENABLE);
}

/*****END OF FILE****/
