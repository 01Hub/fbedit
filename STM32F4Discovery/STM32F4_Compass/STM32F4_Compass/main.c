/**
  ******************************************************************************
  * @file    ADC3_DMA/main.c 
  * @author  MCD Application Team
  * @version V1.0.0
  * @date    19-September-2011
  * @brief   Main program body
  ******************************************************************************
  * @attention
  *
  * THE PRESENT FIRMWARE WHICH IS FOR GUIDANCE ONLY AIMS AT PROVIDING CUSTOMERS
  * WITH CODING INFORMATION REGARDING THEIR PRODUCTS IN ORDER FOR THEM TO SAVE
  * TIME. AS A RESULT, STMICROELECTRONICS SHALL NOT BE HELD LIABLE FOR ANY
  * DIRECT, INDIRECT OR CONSEQUENTIAL DAMAGES WITH RESPECT TO ANY CLAIMS ARISING
  * FROM THE CONTENT OF SUCH FIRMWARE AND/OR THE USE MADE BY CUSTOMERS OF THE
  * CODING INFORMATION CONTAINED HEREIN IN CONNECTION WITH THEIR PRODUCTS.
  *
  * <h2><center>&copy; COPYRIGHT 2011 STMicroelectronics</center></h2>
  ******************************************************************************
  */

/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "stm32f4_discovery_lis302dl.h"

/** @addtogroup STM32F4_Discovery_Peripheral_Examples
  * @{
  */

/** @addtogroup ADC_ADC3_DMA
  * @{
  */ 

/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  uint16_t flag;
  uint16_t x;
  uint16_t y;
  uint16_t z;
  uint8_t Buffer[6];
  uint16_t TimingDelay;
} COMPASSTypeDef;

/* Private define ------------------------------------------------------------*/
#define I2C1_SLAVE_ADDRESS        0x3C              // Address for HMC5883L magnetometer
#define MODE_DONE                 0                 // Done
#define MODE_NORMAL               1                 // Normal operation
#define MODE_COMPENSATE           2                 // Get temprature compensation
#define MODE_CALIBRATE            3                 // Get calibration
#define MODE_COMPENSATEOFF        4                 // End temprature compensation

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
__IO COMPASSTypeDef Compass;
/* Private function prototypes -----------------------------------------------*/
void RCC_Config(void);
void GPIO_Config(void);
void I2C_Config(void);
void LIS302DL_Config(void);
void Init_Compass(uint8_t Reg, uint8_t Param);
uint16_t GetCompassAxis(uint8_t NACK);
void Get_Compass(void);
void Delay(__IO uint32_t nTime);
void TimingDelay_Decrement(void);

/* Private functions ---------------------------------------------------------*/

/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
int main(void)
{
  __IO uint32_t i;

  Compass.flag = 0;
  RCC_Config();
  I2C_Config();
  GPIO_Config();
  /* SysTick 1ms */
  SysTick_Config(SystemCoreClock / 100);
  LIS302DL_Config();
  /* Normal measurement configuration. Average 8 samples */
  Init_Compass(0x00, 0x60);
  /* Set the device gain */
  Init_Compass(0x01, 0x00);
  Delay(60);
  while (1)
  {
    if (Compass.flag)
    {
      switch (Compass.flag)
      {
        case MODE_NORMAL:
          /* Get x, y and z */
          Get_Compass();
          LIS302DL_Read((uint8_t*)&Compass.Buffer[0], LIS302DL_OUT_X_ADDR, 6);
          break;
        case MODE_COMPENSATE:
          /* Positive bias configuration. Average 8 samples */
          Init_Compass(0x00, 0x61);
          /* Set the device gain */
          Init_Compass(0x01, 0x60);
          /* Get x, y and z */
          Get_Compass();
          break;
        case MODE_CALIBRATE:
          /* Get x, y and z */
          Get_Compass();
          break;
        case MODE_COMPENSATEOFF:
          /* Normal measurement configuration. Average 8 samples */
          Init_Compass(0x00, 0x60);
          /* Set the device gain */
          Init_Compass(0x01, 0x00);
          Delay(60);
          Get_Compass();
          Delay(60);
          Get_Compass();
          break;
      }
      Compass.flag = MODE_DONE;
    }
  }
}

/**
  * @brief  Sets a register.
  * @param  Reg, Paeam
  * @retval None
  */
void Init_Compass(uint8_t Reg, uint8_t Param)
{
  /* Initiate start sequence */
  I2C_GenerateSTART(I2C1, ENABLE);
  /* Check start bit flag */
  while(!I2C_GetFlagStatus(I2C1, I2C_FLAG_SB));
  /* Send write command to chip */
  I2C_Send7bitAddress(I2C1, I2C1_SLAVE_ADDRESS, I2C_Direction_Transmitter);
  /* Check master is now in Tx mode */
  while(!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_TRANSMITTER_MODE_SELECTED));
  /* Mode register address */
  I2C_SendData(I2C1, Reg);
  /* Wait for byte send to complete */
  while(!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));
  /* Clear bits */
  I2C_SendData(I2C1, Param);
  /* Wait for byte send to complete */
  while(!I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED));
  /* Send STOP Condition */
  I2C_GenerateSTOP(I2C1, ENABLE);
  while(I2C_GetFlagStatus(I2C1, I2C_FLAG_STOPF));
}

/**
  * @brief  Read the compass axis.
  * @param  None
  * @retval None
  */
uint16_t GetCompassAxis(uint8_t NACK)
{
  uint8_t MSB, LSB;

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

/**
  * @brief  Read the compass x, y and z axis.
  * @param  None
  * @retval None
  */
void Get_Compass(void)
{
  /* Re-enable ACK bit incase it was disabled last call */
  I2C_AcknowledgeConfig(I2C1, ENABLE);
  /* Test on BUSY Flag */
  while (I2C_GetFlagStatus(I2C1,I2C_FLAG_BUSY));
  /* Single-Measurement Mode */
  Init_Compass(0x02, 0x01);
  /* Wait for DRDY to go high */
  while ((((u16)GPIOB->IDR) & GPIO_Pin_5) == 0);
/*======================================================*/
  /* Enable the I2C peripheral */
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
  Compass.x = GetCompassAxis(0);
  Compass.z = GetCompassAxis(0);
  Compass.y = GetCompassAxis(1);
}

/**
  * @brief  Configure the RCC.
  * @param  None
  * @retval None
  */
void RCC_Config(void)
{
  /* I2C1 clock enable */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_I2C1, ENABLE);
  /* GPIOB clock enable */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_GPIOB, ENABLE);
}

/**
  * @brief  Configure the GPIO.
  * @param  None
  * @retval None
  */
void GPIO_Config(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;

  /* I2C SDA and SCL pins configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_OD;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  /* Connect I2C1 pins to AF */
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource8, GPIO_AF_I2C1);
  GPIO_PinAFConfig(GPIOB, GPIO_PinSource9, GPIO_AF_I2C1);

  /* GPIOB Input DRDY */
  GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_5;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_OType = GPIO_OType_PP;
  GPIO_InitStructure.GPIO_PuPd = GPIO_PuPd_NOPULL;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
}

/**
  * @brief  Configure the I2C1.
  * @param  None
  * @retval None
  */
void I2C_Config(void)
{
  I2C_InitTypeDef  I2C_InitStructure;

  I2C_Cmd(I2C1,ENABLE);
  /* I2C1 configuration */
  I2C_InitStructure.I2C_ClockSpeed = 100000;
  I2C_InitStructure.I2C_Mode = I2C_Mode_I2C;
  I2C_InitStructure.I2C_DutyCycle = I2C_DutyCycle_2;
  I2C_InitStructure.I2C_OwnAddress1 = 0x00;
  I2C_InitStructure.I2C_Ack = I2C_Ack_Enable;
  I2C_InitStructure.I2C_AcknowledgedAddress = I2C_AcknowledgedAddress_7bit;
  I2C_Init(I2C1, &I2C_InitStructure);
  I2C_Cmd(I2C1,ENABLE);
}

/**
  * @brief  Configure the LIS302DL.
  * @param  None
  * @retval None
  */
void LIS302DL_Config(void)
{
  uint8_t ctrl = 0;
  LIS302DL_InitTypeDef  LIS302DL_InitStruct;
  
  /* Set configuration of LIS302DL*/
  LIS302DL_InitStruct.Power_Mode = LIS302DL_LOWPOWERMODE_ACTIVE;
  LIS302DL_InitStruct.Output_DataRate = LIS302DL_DATARATE_100;
  LIS302DL_InitStruct.Axes_Enable = LIS302DL_X_ENABLE | LIS302DL_Y_ENABLE | LIS302DL_Z_ENABLE;
  LIS302DL_InitStruct.Full_Scale = LIS302DL_FULLSCALE_2_3;
  LIS302DL_InitStruct.Self_Test = LIS302DL_SELFTEST_NORMAL;
  LIS302DL_Init(&LIS302DL_InitStruct);
  /* Required delay for the MEMS Accelerometre: Turn-on time = 3/Output data Rate 
                                                             = 3/100 = 30ms */
  Delay(30);
}

/**
  * @brief  Inserts a delay time.
  * @param  nTime: specifies the delay time length, in milliseconds.
  * @retval None
  */
void Delay(__IO uint32_t nTime)
{ 
  Compass.TimingDelay = nTime;
  while(Compass.TimingDelay != 0);
}

/**
  * @brief  Decrements the TimingDelay variable.
  * @param  None
  * @retval None
  */
void TimingDelay_Decrement(void)
{
  if (Compass.TimingDelay != 0x00)
  { 
    Compass.TimingDelay--;
  }
}

/**
  * @brief  This function handles SysTick Handler.
  * @param  None
  * @retval None
  */
void SysTick_Handler(void)
{
  if (Compass.TimingDelay != 0x00)
  {
    TimingDelay_Decrement();
  }
}

/**
  * @brief  MEMS accelerometre management of the timeout situation.
  * @param  None.
  * @retval None.
  */
uint32_t LIS302DL_TIMEOUT_UserCallback(void)
{
  /* MEMS Accelerometer Timeout error occured */
  while (1)
  {   
  }
}

