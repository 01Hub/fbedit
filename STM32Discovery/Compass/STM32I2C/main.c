/******************** (C) COPYRIGHT 2008 STMicroelectronics ********************
* File Name          : main.c
* Author             : MCD Application Team
* Version            : V2.0.3
* Date               : 09/22/2008
* Description        : Main program body
********************************************************************************
* THE PRESENT FIRMWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
* WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE TIME.
* AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY DIRECT,
* INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING FROM THE
* CONTENT OF SUCH FIRMWARE AND/OR THE USE MADE BY CUSTOMERS OF THE CODING
* INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
*******************************************************************************/

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  u16 flag;
  u16 x;
  u16 y;
  u16 z;
  u32 Count;
} STM32_COMPASSTypeDef;

/* Private define ------------------------------------------------------------*/
#define I2C1_SLAVE_ADDRESS        0x3C              // Address for HMC5883L magnetometer
#define I2C_SPEED                 100000            //100Khz speed for I2C
#define I2C_NACKPosition_Current  ((u16)0xF7FF)

#define MODE_DONE                 0                 // Done
#define MODE_NORMAL               1                 // Normal operation
#define MODE_COMPENSATE           2                 // Get temprature compensation
#define MODE_CALIBRATE            3                 // Get calibration

/* Private macro -------------------------------------------------------------*/
ErrorStatus HSEStartUpStatus;
volatile STM32_COMPASSTypeDef STM32_Compass;

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void NVIC_Configuration(void);
void GPIO_Configuration(void);
void I2C_Configuration(void);
void Init_Compass(u8 First, u8 Second);
u16 GetCompassAxis(u8 NACK);
void Get_Compass();
void ClockWait(void);

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
  vu32 i;
  /* System clocks configuration ---------------------------------------------*/
  RCC_Configuration();
  /* NVIC configuration ------------------------------------------------------*/
  NVIC_Configuration();
  /* GPIO configuration ------------------------------------------------------*/
  GPIO_Configuration();
  /* I2C configuration -------------------------------------------------------*/
  I2C_Configuration();
  i = 100000;
  while (i--)
  {
    ClockWait();
  }
  /* Normal measurement configuration. Average 8 samples */
  Init_Compass(0x00, 0x60);
  /* Set the device gain */
  Init_Compass(0x01, 0x00);
  i = 130000;
  while (i--)
  {
    ClockWait();
  }
  while (1)
  {
    if (STM32_Compass.flag)
    {
      switch (STM32_Compass.flag)
      {
        case MODE_NORMAL:
          /* Get x, y and z */
          Get_Compass();
          break;
        case MODE_COMPENSATE:
          /* Positive bias configuration. Average 8 samples */
          Init_Compass(0x00, 0x61);
          /* Set the device gain */
          Init_Compass(0x01, 0x60);
          /* Get x, y and z */
          Get_Compass();
          /* Normal measurement configuration. Average 8 samples */
          Init_Compass(0x00, 0x60);
          /* Set the device gain */
          Init_Compass(0x01, 0x00);
          break;
        case MODE_CALIBRATE:
          /* Get x, y and z */
          Get_Compass();
          break;
      }
      STM32_Compass.flag = MODE_DONE;
    }
  }
}

/*******************************************************************************
* Function Name  : Init_Compass
* Description    : Initialization for continuous-measurement mode
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void Init_Compass(u8 First, u8 Second)
{
  /* initiate start sequence */
  I2C_GenerateSTART(I2C1, ENABLE);
  /* check start bit flag */
  while(!I2C_GetFlagStatus(I2C1, I2C_FLAG_SB));
  /*send write command to chip*/
  I2C_Send7bitAddress(I2C1, I2C1_SLAVE_ADDRESS, I2C_Direction_Transmitter);
  /*check master is now in Tx mode*/
  while(!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_TRANSMITTER_MODE_SELECTED));
  /*mode register address*/
  I2C_SendData(I2C1, First);
  /*wait for byte send to complete*/
  while(!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));
  /*clear bits*/
  I2C_SendData(I2C1, Second);
  /* Wait for byte send to complete */
  while(!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));
  /* Send STOP Condition */
  I2C_GenerateSTOP(I2C1, ENABLE);
  while(I2C_GetFlagStatus(I2C1, I2C_FLAG_STOPF));
}

/*******************************************************************************
* Function Name  : GetCompassAxis
* Description    : Reads axis
* Input          : NACK
* Output         : None
* Return         : Axis
*******************************************************************************/
u16 GetCompassAxis(u8 NACK)
{
  u8 MSB, LSB;

  /* Get MSB */
  while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_RECEIVED));
  MSB = I2C_ReceiveData(I2C1);
  /* Get LSB */
  while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_RECEIVED));
  LSB = I2C_ReceiveData(I2C1);
  if (NACK)
  {
    /* Enable NACK bit */
    I2C1->CR1 &= I2C_NACKPosition_Current;
    /* Disable ACK */
    I2C_AcknowledgeConfig(I2C1, DISABLE);
    /* Send STOP Condition */
    I2C_GenerateSTOP(I2C1, ENABLE);
    while(I2C_GetFlagStatus(I2C1, I2C_FLAG_STOPF));
  }
  return ((MSB<<8) | LSB);
}

void Get_Compass()
{
  /* Re-enable ACK bit incase it was disabled last call */
  I2C_AcknowledgeConfig(I2C1, ENABLE);
  /* Test on BUSY Flag */
  while (I2C_GetFlagStatus(I2C1,I2C_FLAG_BUSY));
  /* Single-Measurement Mode */
  Init_Compass(0x02, 0x01);
  /* Wait for DRDY to go high */
  while ((((u16)GPIOB->IDR) & GPIO_Pin_5) == 0);
  /* Enable the I2C peripheral */
/*======================================================*/
  I2C_GenerateSTART(I2C1, ENABLE);
  /* Test on start flag */
  while (!I2C_GetFlagStatus(I2C1,I2C_FLAG_SB));
  /* Send device address for write */
  I2C_Send7bitAddress(I2C1, I2C1_SLAVE_ADDRESS, I2C_Direction_Transmitter);
  /* Test on master Flag */
  while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_TRANSMITTER_MODE_SELECTED));
  /* Send the device's internal address to read from */
  I2C_SendData(I2C1,0x03);
  /* Test on TXE FLag (data sent) */
  while (!I2C_GetFlagStatus(I2C1,I2C_FLAG_TXE));
/*=====================================================*/
   /* Send START condition a second time (Re-Start) */
  I2C_GenerateSTART(I2C1, ENABLE);
  /* Test start flag */
  while (!I2C_GetFlagStatus(I2C1,I2C_FLAG_SB));
  /* Send address for read */
  I2C_Send7bitAddress(I2C1, I2C1_SLAVE_ADDRESS, I2C_Direction_Receiver);
  /* Test Receive mode Flag */
  while (!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_RECEIVER_MODE_SELECTED));
  /* Get all 3 axis (x, z and y) */
  STM32_Compass.x = GetCompassAxis(0);
  STM32_Compass.z = GetCompassAxis(0);
  STM32_Compass.y = GetCompassAxis(1);
  STM32_Compass.Count++;
}

void ClockWait(void)
{
  vu32 wait = 20;
  while (wait--);
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
    /* Flash 0 wait state */
    FLASH_SetLatency(FLASH_Latency_0);
    /* HCLK = SYSCLK */
    RCC_HCLKConfig(RCC_SYSCLK_Div1); 
    /* PCLK2 = HCLK */
    RCC_PCLK2Config(RCC_HCLK_Div1); 
    /* PCLK1 = HCLK */
    RCC_PCLK1Config(RCC_HCLK_Div1);
    /* ADCCLK = PCLK2/4 */
    RCC_ADCCLKConfig(RCC_PCLK2_Div2); 
    /* PLLCLK = 8MHz * 3 = 24 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_3);
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
  /* Enable peripheral clocks --------------------------------------------------*/
  /* Enable GPIOB clock */
  RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);
  /* Enable I2C1 Periph clock */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_I2C1, ENABLE);
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

  /* Configure I2C1 pins: SCL and SDA ----------------------------------------*/
  GPIO_InitStructure.GPIO_Pin =  GPIO_Pin_6 | GPIO_Pin_7;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_OD;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB5 as input for DRDY */
  GPIO_InitStructure.GPIO_Pin =  GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
}

/*******************************************************************************
* Function Name  : I2C_Configuration
* Description    : Configures the I2C.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void I2C_Configuration(void)
{
  I2C_InitTypeDef  I2C_InitStructure;

  I2C_Cmd(I2C1,ENABLE);
  /* I2C1 configuration */
  I2C_InitStructure.I2C_Mode = I2C_Mode_I2C;
  I2C_InitStructure.I2C_DutyCycle = I2C_DutyCycle_2;
  I2C_InitStructure.I2C_OwnAddress1 = 0x00;
  I2C_InitStructure.I2C_Ack = I2C_Ack_Enable;
  I2C_InitStructure.I2C_AcknowledgedAddress = I2C_AcknowledgedAddress_7bit;
  I2C_InitStructure.I2C_ClockSpeed = I2C_SPEED;
  I2C_Init(I2C1, &I2C_InitStructure);
}

/*******************************************************************************
* Function Name  : NVIC_Configuration
* Description    : Configures Vector Table base location.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void NVIC_Configuration(void)
{
  /* Set the Vector Table base location at 0x08000000 */ 
  NVIC_SetVectorTable(NVIC_VectTab_FLASH, 0x0);   
}

