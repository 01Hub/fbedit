/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V1.0.0
* Date               : 11/16/2013
* Description        : Main program body
********************************************************************************

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"

/* Private define ------------------------------------------------------------*/
// Uncomment the clock speed you will be using
#define STM32Clock24MHz
//#define STM32Clock28MHz
//#define STM32Clock32MHz
//#define STM32Clock40MHz
//#define STM32Clock48MHz
//#define STM32Clock56MHz

#define MAXBLUETOOTH            ((u16)512)

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void USART3_Configuration(u32 Baud);
void SendData(vu16 Data);

typedef struct
{
  vu16 BLUETOOTHData;
  vu16 BLUETOOTHFlag;
  vu32 BLUETOOTHBytesSendt;
  vu32 BLUETOOTHBytesRecived;
  vu32 BLUETOOTHTail;                           // BLUETOOTHArray tail, index into BLUETOOTHArray
  vu32 BLUETOOTHHead;                           // BLUETOOTHArray head, index into BLUETOOTHArray
  u8 BLUETOOTHArray[MAXBLUETOOTH];              // Bluetooth array, received bluetooth data
}STM32_BlueToothTypeDef;


/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
STM32_BlueToothTypeDef BlueTooth;
vu32 BlueLED;
vu32 GreenLED;
vu32 Baud;

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
  RCC_Configuration();
  /* NVIC configuration */
  NVIC_Configuration();
  /* GPIO configuration */
  GPIO_Configuration();
  /* Setup USART3 9600 baud */
  USART3_Configuration(9600);
  while (1)
  {
    if (BlueTooth.BLUETOOTHFlag)
    {
      BlueTooth.BLUETOOTHFlag = 0;
      if (BlueTooth.BLUETOOTHData == 0x0004)
      {
        SendData(0x0041);
        SendData(0x002B);
        SendData(0x002B);
        SendData(0x002B);
      }
      else if (BlueTooth.BLUETOOTHData == 0x005E)
      {
        if (Baud)
        {
          USART3_Configuration(9600);
          Baud = 0;
        }
        else
        {
          USART3_Configuration(115200);
          Baud = 1;
        }
      }
      else
      {
        SendData(BlueTooth.BLUETOOTHData);
      }
      /* Toggle blue led */
      GPIO_WriteBit(GPIOC, GPIO_Pin_8, BlueLED);
      BlueLED ^=1;
    }
  }
}

void SendData(vu16 Data)
{
  /* Wait until transmit register empty */
  while((USART3->SR & USART_FLAG_TXE) == 0);          
  /* Transmit Data */
  USART3->DR = Data;
  BlueTooth.BLUETOOTHBytesSendt++;
}

/*******************************************************************************
* Function Name  : USART3_IRQHandler
* Description    : This function handles USART3 global interrupt request.
*                  An interrupt is generated when a character is recieved.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USART3_IRQHandler(void)
{
  BlueTooth.BLUETOOTHArray[BlueTooth.BLUETOOTHHead++] = USART3->DR;
  /* Limit BLUETOOTHHead to 512 bytes array*/
  BlueTooth.BLUETOOTHHead &= MAXBLUETOOTH-1;
  BlueTooth.BLUETOOTHBytesRecived++;
  /* Toggle green led */
  GPIO_WriteBit(GPIOC, GPIO_Pin_9, GreenLED);
  GreenLED ^=1;
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
#ifdef STM32Clock24MHz
    /* PLLCLK = 8MHz * 3 = 24 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_3);
#endif
#ifdef STM32Clock28MHz
    /* PLLCLK = 8MHz / 2 * 7 = 28 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div2, RCC_PLLMul_7);
#endif
#ifdef STM32Clock32MHz
    /* PLLCLK = 8MHz * 4 = 32 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_4);
#endif
#ifdef STM32Clock40MHz
    /* PLLCLK = 8MHz * 5 = 40 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_5);
#endif
#ifdef STM32Clock48MHz
    /* PLLCLK = 8MHz * 6 = 48 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_6);
#endif
#ifdef STM32Clock56MHz
    /* PLLCLK = 8MHz * 7 = 56 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_7);
#endif
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
    /* Enable GPIOA, GPIOB and GPIOC peripheral clocks */
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC, ENABLE);
    /* Enable USART3 peripheral clock */
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART3, ENABLE);
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
  /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* Configure PB10 USART3 Tx as alternate function push-pull */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB11 USART3 Rx as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB14 USART3 RTS as alternate function push-pull */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_14;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB13 USART3 CTS as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
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
  /* Enable USART3 interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = USART3_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

/*******************************************************************************
* Function Name  : USART3_Configuration
* Description    : Configures USART3 Rx and Tx for communication with Bluetooth module.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USART3_Configuration(u32 BaudRate)
{
  /* USART3 configured as follow:
        - BaudRate = 1200,2400,4800,9600,19200 or 38400 baud  
        - Word Length = 8 Bits
        - One Stop Bit
        - No parity
        - Hardware flow control enabled
        - Receive and transmit enabled
  */
  USART_InitTypeDef USART_InitStructure;

  USART_DeInit(USART3);
  USART_InitStructure.USART_BaudRate = BaudRate;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No ;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_RTS_CTS;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART3, &USART_InitStructure);
  /* Enable the USART Receive interrupt: this interrupt is generated when the 
     USART3 receive data register is not empty */
  USART_ITConfig(USART3, USART_IT_RXNE, ENABLE);
  /* Enable the USART3 */
  USART_Cmd(USART3, ENABLE);
}

/*****END OF FILE****/
