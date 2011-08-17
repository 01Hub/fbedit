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
#define ADC1_ICDR_Address ((u32)0x4001243C)

typedef struct
{
  vu8 Start;
  u8 PingPulses;
  u8 PingTimer;
  u8 Gain;
  u8 GainInc;
  u8 Range;
  u8 nSample;
  u8 Dummy8;
  u16 Dummy16;
  vu16 ADCBatt;
  vu16 ADCWaterTemp;
  vu16 ADCAirTemp;
  u8 Echo[MAXECHO];
}STM32_SonarTypeDef;

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
static STM32_SonarTypeDef STM32_Sonar;         // 0x20000000
vu8 BlueLED;
vu8 nSample;
vu16 EchoIndex;
vu16 Ping;

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void ADC_Startup(void);
void ADC_Configuration(void);
void TIM1_Configuration(void);
void TIM2_Configuration(void);
u16 GetADCValue(u8 Channel);

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
  u32* ADC;
  u8 Echo;
  /* System clocks configuration */
  RCC_Configuration();
  /* NVIC configuration */
  NVIC_Configuration();
  /* GPIO configuration */
  GPIO_Configuration();
  /* TIM1 configuration */
  TIM1_Configuration();
  /* TIM2 configuration */
  TIM2_Configuration();
  /* ADC1 configuration */
  ADC_Startup();
  /* ADC1 injected channel configuration */
  ADC_Configuration();
  /* Enable DAC channel1 */
  DAC->CR = 0x1;

  while (1)
  {
    if (STM32_Sonar.Start == 1)
    {
      STM32_Sonar.Start = 2;
      /* Toggle blue led */
      if (BlueLED)
      {
        GPIO_WriteBit(GPIOC, GPIO_Pin_8, Bit_RESET);
        BlueLED = 0;
      }
      else
      {
        GPIO_WriteBit(GPIOC, GPIO_Pin_8, Bit_SET);
        BlueLED = 1;
      }
      /* Read battery */
      STM32_Sonar.ADCBatt = GetADCValue(ADC_Channel_3);
      /* Read water temprature */
      STM32_Sonar.ADCWaterTemp = GetADCValue(ADC_Channel_5);
      /* Read air temprature */
      STM32_Sonar.ADCAirTemp = GetADCValue(ADC_Channel_6);
      /* Clear the echo array */
      i = 0;
      while (i < MAXECHO)
      {
        STM32_Sonar.Echo[i] = 0;
        i++;
      }
      /* Init nSample */
      nSample = STM32_Sonar.nSample;
      /* Reset echo index */
      EchoIndex = 0;
      /* Set the TIM1 Autoreload value */
      TIM1->ARR = STM32_Sonar.PingTimer;
      /* Reset TIM1 count */
      TIM1->CNT = 0;
      /* Set TIM1 repetirion counter */
      TIM1->RCR = 0;
      /* Init Ping */
      Ping = 0x100;
      /* Enable TIM1 */
      TIM_Cmd(TIM1, ENABLE);
      while (STM32_Sonar.Start == 2)
      {
        /* Get echo */
        ADC = ( (u32 *) ADC1_ICDR_Address);
        Echo = (u8) ( (u16) (*(vu32*) (((*(u32*)&ADC)))) >> 4);
        /* Reserve 254 and 255 for fish detect */
        if (Echo > 253)
        {
          Echo = 253;
        }
        /* If echo larger than previous echo, update the echo array */
        if (Echo > STM32_Sonar.Echo[EchoIndex])
        {
          STM32_Sonar.Echo[EchoIndex] = Echo;
        }
        /* Done, Store the current range */
        STM32_Sonar.Echo[0] = STM32_Sonar.Range;
      }
    }
    i = 0;
    while (i < 1000)
    {
      i++;
    }
  }
}

/*******************************************************************************
* Function Name  : GetADCValue
* Description    : This function sums 8 ADC conversions and returns the average.
* Input          : ADC channel
* Output         : None
* Return         : The ADC cannel reading
*******************************************************************************/
u16 GetADCValue(u8 Channel)
{
  vu8 i;
  vu16 ADCValue;
  ADC_InitTypeDef ADC_InitStructure;

  i = 0;
  ADCValue = 0;
  ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfChannel = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* ADC1 regular channel configuration */ 
  ADC_RegularChannelConfig(ADC1, Channel, 1, ADC_SampleTime_239Cycles5);
  /* Start ADC1 Software Conversion */ 
  ADC_SoftwareStartConvCmd(ADC1, ENABLE);
  /* Add 8 conversions to reduce thermal noise */
  while (i<8)
    {
    ADC_ClearFlag(ADC1, ADC_FLAG_EOC);
    while (ADC_GetFlagStatus(ADC1, ADC_FLAG_EOC) == RESET)
    {
    }
    ADCValue = ADCValue + ADC1->DR;
    i++;
  }
  /* Stop ADC1 Software Conversion */ 
  ADC_SoftwareStartConvCmd(ADC1, DISABLE);
  /* Return average of the 8 added conversions */
  return (ADCValue >> 3);
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
  /* Set ping outputs high (FET's off) */
  GPIO_WriteBit(GPIOA, GPIO_Pin_9 | GPIO_Pin_8, Bit_SET);
  /* Clear TIM1 Update interrupt pending bit */
  TIM1->SR = (u16)~TIM_IT_Update;
  if (STM32_Sonar.PingPulses)
  {
    GPIO_Write(GPIOA,Ping);
    if (Ping == 0x100)
    {
      Ping = 0x200;
    }
    else
    {
      Ping = 0x100;
    }
    STM32_Sonar.PingPulses--;
  }
  else
  {
    /* Ping done, Set DAC Gain */
    DAC->DHR12R1 = (u16)STM32_Sonar.Gain << 4;
    /* Disable TIM1 */
    TIM_Cmd(TIM1, DISABLE);
    /* Enable ADC injected channel */
    ADC_AutoInjectedConvCmd(ADC1, ENABLE);
    /* Enable TIM2 */
    TIM_Cmd(TIM2, ENABLE);
  }
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
  u16 Gain;
  /* Clear TIM2 Update interrupt pending bit */
  TIM2->SR = (u16)~TIM_IT_Update;
  nSample--;
  if (nSample == 0)
  {
    /* Set the DAC to output next gain step */
    Gain = (u16)DAC->DHR12R1 + (u16)STM32_Sonar.GainInc;
    if (Gain > 4095)
    {
      Gain = 4095;
    }
    DAC->DHR12R1 = Gain;
    nSample = STM32_Sonar.nSample;
    EchoIndex++;
    if (EchoIndex == MAXECHO)
    {
      EchoIndex = 0;
      /* Disable TIM2 */
      TIM2->CR1 = 0;
      /* Disable ADC injected channel */
      ADC_AutoInjectedConvCmd(ADC1, DISABLE);
      /* Set the DAC to output lowest gain */
      DAC->DHR12R1 = (u16)0x0;
      /* Done sampling echo*/
      STM32_Sonar.Start = 0;
    }
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
*                  on channel 2.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ADC_Configuration(void)
{
  ADC_InitTypeDef ADC_InitStructure;

  /* ADCCLK = PCLK2/2 */
  RCC_ADCCLKConfig(RCC_PCLK2_Div2);
  ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  /* ADC1 single channel configuration */
  ADC_InitStructure.ADC_NbrOfChannel = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* Setup injected channel */
  ADC_InjectedSequencerLengthConfig(ADC1,1);
  /* Sonar echo */
  ADC_InjectedChannelConfig(ADC1,ADC_Channel_2,1,ADC_SampleTime_13Cycles5);
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
    // /* PLLCLK = 8MHz * 6 = 48 MHz */
    // RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_6);
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
    /* Enable TIM1, ADC1, GPIOA and GPIOC peripheral clocks */
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1 | RCC_APB2Periph_ADC1 | RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOC, ENABLE);
    /* Enable DAC and TIM2 peripheral clocks */
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_DAC | RCC_APB1Periph_TIM2, ENABLE);
  }
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
  /* Configure ADC Channel6 (PA.06), ADC Channel5 (PA.05), DAC Channel1 (PA.04), ADC Channel3 (PA.03) and ADC Channel2 (PA.02) as analog input */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4 | GPIO_Pin_3 | GPIO_Pin_2;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* Set ping outputs high (FET's off) */
  GPIO_WriteBit(GPIOA, GPIO_Pin_9 | GPIO_Pin_8, Bit_SET);
  /* Configure PA.09 and PA.08 as outputs */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
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
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_Period = 139;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM1, &TIM_TimeBaseStructure);
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
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  /* Time base configuration 56MHz clock */
  TIM_TimeBaseStructure.TIM_Period = 302;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  /* Enable TIM2 Update interrupt */
  TIM_ClearITPendingBit(TIM2,TIM_IT_Update);
  TIM_ITConfig(TIM2, TIM_IT_Update, ENABLE);
}

/*****END OF FILE****/
