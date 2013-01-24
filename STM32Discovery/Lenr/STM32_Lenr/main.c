/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 12/28/2012
* Description        : Main program body
*******************************************************************************/

/*******************************************************************************
* Port pins
* PA.08 Heater pvm voltage
* PA.09 Fan pwm voltage
* PC.00 Heater voltage
* PC.01 Heater current
* PC.02 Ambient temprature
* PC.03 Cell temprature
* PC.04 Cell heater temprature
*******************************************************************************/

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  vu32 SecCount;         // @0x20000000
  vu16 Pwm1;             // @0x20000004 Heater
  vu16 Pwm2;             // @0x20000006 Fan
  vu16 Volts;            // @0x20000008 Heater
  vu16 Amps;             // @0x2000000A Heater
  vu16 Temp1;            // @0x2000000C Ambient
  vu16 Temp2;            // @0x2000000E Cell
  vu16 Temp3;            // @0x20000010 Heater
  vu16 Dummy;            // @0x20000012
}LenrTypeDef;

/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
ErrorStatus HSEStartUpStatus;
static LenrTypeDef Lenr;

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void NVIC_Configuration(void);
void GPIO_Configuration(void);
void TIM1_Configuration(void);
void TIM3_Configuration(void);
void ADC_Configuration(void);
u16 GetADCValue(u8 Channel);

/* Private functions ---------------------------------------------------------*/

/*******************************************************************************
* Function Name  : main
* Description    : Main program. It configures the peripherals and then
*                  enters an endles loop.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
int main(void)
{
  Lenr.Pwm1 = 0xFF;
  Lenr.Pwm2 = 0xFF;
  /* System Clocks Configuration */
  RCC_Configuration();
  /* Configure the GPIO ports */
  GPIO_Configuration();
  /* NVIC configuration */
  NVIC_Configuration();
  /* Configure ADC1 */
  ADC_Configuration();
  /* Configure TIM1 */
  TIM1_Configuration();
  /* Configure TIM3 */
  TIM3_Configuration();
  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);
  while (1)
  {
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
  /* Set the Capture Compare Register value */
  TIM1->CCR1 = Lenr.Pwm1;
  TIM1->CCR2 = Lenr.Pwm2;
  /* Clear TIM1 Update interrupt pending bit */
  TIM_ClearITPendingBit(TIM1, TIM_IT_Update);
}

/*******************************************************************************
* Function Name  : TIM3_IRQHandler
* Description    : This function handles TIM3 global interrupt request.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_IRQHandler(void)
{
  GPIO_WriteBit(GPIOC,GPIO_Pin_8,Bit_RESET);
  if ((Lenr.SecCount & 1)!=0)
  {
    GPIO_WriteBit(GPIOC,GPIO_Pin_8,Bit_SET);
  }
  Lenr.Volts = GetADCValue(ADC_Channel_10);
  Lenr.Amps = GetADCValue(ADC_Channel_11);
  Lenr.Temp1 = GetADCValue(ADC_Channel_12);
  Lenr.Temp2 = GetADCValue(ADC_Channel_13);
  Lenr.Temp3 = GetADCValue(ADC_Channel_14);
  /* Clear TIM3 Update interrupt pending bit */
  TIM_ClearITPendingBit(TIM3, TIM_IT_Update);
  Lenr.SecCount++;
}

/*******************************************************************************
* Function Name  : GetADCValue
* Description    : This function sums 16 ADC conversions and returns the average.
* Input          : ADC channel
* Output         : None
* Return         : The ADC cannel reading
*******************************************************************************/
u16 GetADCValue(u8 Channel)
{
  vu8 i;
  vu16 ADCValue;

  ADCValue = 0;
  /* ADC1 regular channel configuration */ 
  ADC_RegularChannelConfig(ADC1, Channel, 1, ADC_SampleTime_7Cycles5);
  /* Start ADC1 Software Conversion */ 
  ADC_SoftwareStartConvCmd(ADC1, ENABLE);
  /* Add 16 conversions to reduce thermal noise */
  i = 16;
  while (i--)
  {
    ADC_ClearFlag(ADC1, ADC_FLAG_EOC);
    while (ADC_GetFlagStatus(ADC1, ADC_FLAG_EOC) == RESET)
    {
    }
    ADCValue += ADC1->DR;
  }
  /* Stop ADC1 Software Conversion */ 
  ADC_SoftwareStartConvCmd(ADC1, DISABLE);
  /* Return average of the 16 added conversions */
  return (ADCValue >> 4);
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
  if (HSEStartUpStatus == SUCCESS)
  {
    /* Enable Prefetch Buffer */
    FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);
    /* Flash 0 wait state */
    FLASH_SetLatency(FLASH_Latency_0);
    /* HCLK = SYSCLK */
    RCC_HCLKConfig(RCC_SYSCLK_Div1);
    /* PCLK2 = HCLK */
    RCC_PCLK2Config(RCC_HCLK_Div1);
    /* PCLK1 = HCLK/2 */
    RCC_PCLK1Config(RCC_HCLK_Div1);
    /* PLLCLK = 8MHz * 3 = 24 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_3);
    /* Enable PLL */
    RCC_PLLCmd(ENABLE);
    /* Wait till PLL is ready */
    while (RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET)
    {}
    /* Select PLL as system clock source */
    RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);
    /* Wait till PLL is used as system clock source */
    while (RCC_GetSYSCLKSource() != 0x08)
    {}
  }
  /* TIM3 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_TIM3, ENABLE);
  /* TIM1, ADC1, GPIOA, GPIOC clock enable */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1 | RCC_APB2Periph_ADC1 | RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOC, ENABLE);
}

/*******************************************************************************
* Function Name  : GPIO_Configuration
* Description    : Configure the GPIO Pins.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void GPIO_Configuration(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  /* TIM1 channel 1 and 2 pin (PA.08 and PA.09) configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* Configure ADC Channel10,11,12,13 and 14 (PC0,PC1,PC2,PC3,PC4) */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4 | GPIO_Pin_3 | GPIO_Pin_2 | GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
}

/*******************************************************************************
* Function Name  : TIM1_Configuration
* Description    : Configures TIM1 to generate PWM output.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_Configuration(void)
{
  /* -----------------------------------------------------------------------
    TIM1 Configuration: generate 4 PWM signals with 4 different duty cycles:
    TIM1CLK = 28 MHz, Prescaler = 0x0, TIM1 counter clock = 28 MHz
    TIM1 ARR Register = 4095 => TIM1 Frequency = TIM1 counter clock/(ARR + 1)
    TIM1 Frequency = 6835.9375 Hz.
    TIM1 Channel1 duty cycle = (TIM1_CCR1 / TIM1_ARR)* 100
  ----------------------------------------------------------------------- */

  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  TIM_OCInitTypeDef  TIM_OCInitStructure;
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 255;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM1, &TIM_TimeBaseStructure);

  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_OutputNState = TIM_OutputState_Disable;
  TIM_OCInitStructure.TIM_Pulse = (u16)0xFF;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_Low;
  TIM_OCInitStructure.TIM_OCNPolarity = TIM_OCPolarity_Low;
  TIM_OCInitStructure.TIM_OCIdleState = TIM_OCIdleState_Reset;
  TIM_OCInitStructure.TIM_OCNIdleState = TIM_OCIdleState_Reset;
  /* PWM1 Mode configuration: Channel1 */
  TIM_OC1Init(TIM1, &TIM_OCInitStructure);
  TIM_OC1PreloadConfig(TIM1, TIM_OCPreload_Enable);
  /* PWM1 Mode configuration: Channel2 */
  TIM_OC2Init(TIM1, &TIM_OCInitStructure);
  TIM_OC2PreloadConfig(TIM1, TIM_OCPreload_Enable);
  /* TIM1 enable counter */
  TIM_Cmd(TIM1, ENABLE);
  /* TIM1 Main Output Enable */
  TIM_CtrlPWMOutputs(TIM1, ENABLE);
  TIM_ITConfig(TIM1, TIM_IT_Update, ENABLE);
}

/*******************************************************************************
* Function Name  : TIM3_Configuration
* Description    : Configures TIM3 to count up and generate interrupt every 500ms.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_Configuration(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  /* Time base configuration */
  TIM_TimeBaseStructure.TIM_Period = 4999;
  TIM_TimeBaseStructure.TIM_Prescaler = 2399;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  TIM_InternalClockConfig(TIM3);
  TIM_ITConfig(TIM3, TIM_IT_Update, ENABLE);
}

/*******************************************************************************
* Function Name  : ADC_Startup
* Description    : This function calibrates ADC1.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ADC_Configuration(void)
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
  ADC_RegularChannelConfig(ADC1, ADC_Channel_10, 1, ADC_SampleTime_7Cycles5);
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
* Function Name  : NVIC_Configuration
* Description    : Configures Vector Table base location and enables
*                  TIM3 global interrupts.
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
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM3 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

