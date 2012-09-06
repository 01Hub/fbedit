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
* RS232
* PA2   USART2 Tx
* PA3   USART2 Rx
* Keyboard
* PB0   Keyboard clock in
* PB1   Keyboard data in
* Mouse
* PB2   Mouse clock in
* PB3   Mouse data in
* Leds
* PA9   Green
* PD5   Red
* PD12  Green
* PD13  Orange
* PD14  Red
* PD15  Blue
* User button
* PA0   User button
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
#define SHIELD_TOP      210

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
extern volatile uint16_t FrameCount;

extern uint8_t rs232buf[256];
extern uint8_t rs232buftail;
extern uint8_t rs232bufhead;

extern uint8_t charbuf[256];
extern uint8_t charbuftail;
extern uint8_t charbufhead;

volatile int8_t Shooters;       // Number of spare shooters
volatile uint8_t Shots;         // Number of active shots
volatile uint8_t Bombs;         // Number of active bombs
volatile GameOver;              // Game over flag

RECT AlienBound;
extern SPRITE* Sprites[];
SPRITE Alien[32];
SPRITE Shooter;
SPRITE Bomb[8];
SPRITE Shot[4];
extern SPRITE Cursor;
ICON Shield;
volatile uint32_t RNDSeed;

uint8_t Alien1Icon[16][16] = {
{2,2,1,1,1,1,1,1,1,1,1,1,1,1,2,2},
{2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1},
{1,1,1,0,0,0,1,1,1,1,0,0,0,1,1,1},
{1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1},
{1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1},
{1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,1},
{2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
{2,2,2,2,1,1,2,2,2,2,1,1,2,2,2,2},
{2,2,2,1,1,2,2,2,2,2,2,1,1,2,2,2},
{2,2,1,1,2,2,2,2,2,2,2,2,1,1,2,2},
{2,1,1,2,2,2,2,2,2,2,2,2,2,1,1,2},
{1,1,1,2,2,2,2,2,2,2,2,2,2,1,1,1}
};

uint8_t Alien2Icon[16][16] = {
{2,2,1,1,1,1,1,1,1,1,1,1,1,1,2,2},
{2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1},
{1,1,1,0,0,0,1,1,1,1,0,0,0,1,1,1},
{1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,0,0,1,1,1,1,0,0,1,1,1,1},
{1,1,1,1,0,0,0,0,0,0,0,0,1,1,1,1},
{1,1,1,1,1,1,1,0,0,1,1,1,1,1,1,1},
{2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
{2,2,2,2,1,1,2,2,2,2,1,1,2,2,2,2},
{2,2,2,1,1,2,2,2,2,2,2,1,1,2,2,2},
{2,2,1,1,2,2,2,2,2,2,2,2,1,1,2,2},
{2,2,1,1,2,2,2,2,2,2,2,2,1,1,2,2},
{2,2,1,1,1,1,2,2,2,2,1,1,1,1,2,2}
};

uint8_t ShooterIcon[16][20] = {
{2,2,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,2,2},
{2,2,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,2,2},
{2,2,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,2,2},
{2,2,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,2,2},
{2,2,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,2,2},
{2,2,2,2,2,2,1,1,1,1,1,1,1,1,2,2,2,2,2,2},
{2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2},
{2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1},
{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
};

uint8_t ShieldIcon[16][32] = {
{2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2},
{2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2},
{2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2},
{2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2},
{2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2},
{2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2},
{1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1},
{1,1,1,1,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,1,1,1,1},
{1,1,1,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,1,1,1},
{1,1,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,1,1},
{1,1,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,1,1},
{1,1,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,1,1},
{1,1,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,1,1},
{1,1,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,1,1},
{1,1,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,1,1},
{1,1,2,2,2,2,2,2,2,2,2,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,2,2,2,2,1,1}
};

uint8_t ShotIcon[8][4] = {
{1,1,1,1},
{1,1,1,1},
{1,1,1,1},
{1,1,1,1},
{1,1,1,1},
{1,1,1,1},
{1,1,1,1},
{1,1,1,1}
};

/* Private function prototypes -----------------------------------------------*/
void RCC_Config(void);
void NVIC_Config(void);
void GPIO_Config(void);
void TIM_Config(void);
void SPI_Config(void);
void DMA_Config(void);
void USART_Config(uint32_t Baud);
uint32_t Random(uint32_t Range);

/* Private functions ---------------------------------------------------------*/

/**
  * @brief  This function generates a random number
  * @param  None
  * @retval None
  */
uint32_t Random(uint32_t Range)
{
  uint32_t rnd;
  RNDSeed=(((RNDSeed*23+7) & 0xFFFFFFFF)>>1)^RNDSeed;
  rnd=RNDSeed/Range;
  return rnd;
}
/**
  * @brief  Main program
  * @param  None
  * @retval None
  */
void main(void)
{
  int16_t dir,i,fc,coll;
  volatile uint32_t rnd;

  RCC_Config();
  NVIC_Config();
  GPIO_Config();
  TIM_Config();
  SPI_Config();
  DMA_Config();
  USART_Config(115200);
  /* Enable TIM3 */
  TIM_Cmd(TIM3, ENABLE);
  STM_EVAL_LEDInit(LED3);

  /* Draw game frame */
  Rectangle(0,0,480,250,1);
  /* Setup alien sprites */
  AlienBound.left=10;
  AlienBound.top=10;
  AlienBound.right=469;
  AlienBound.bottom=239;
  i=0;
  while (i<32)
  {
    Alien[i].icon.wt=16;
    Alien[i].icon.ht=16;
    if (i & 1)
    {
      Alien[i].icon.icondata=*Alien2Icon;
    }
    else
    {
      Alien[i].icon.icondata=*Alien1Icon;
    }
    Alien[i].x=(i & 7)*25+10;
    Alien[i].y=(i>>3)*20+30;
    Alien[i].visible=1;
    Alien[i].collision=0;
    Alien[i].boundary=&AlienBound;
    Sprites[i]=&Alien[i];
    i++;
  }
  /* Setup bomb sprites */
  while (i<40)
  {
    Bomb[i-32].icon.wt=4;
    Bomb[i-32].icon.ht=8;
    Bomb[i-32].icon.icondata=*ShotIcon;
    Bomb[i-32].x=0;
    Bomb[i-32].y=0;
    Bomb[i-32].visible=0;
    Bomb[i-32].collision=0;
    Bomb[i-32].boundary=&AlienBound;
    Sprites[i]=&Bomb[i-32];
    i++;
  }
  /* Setup shot sprites */
  while (i<44)
  {
    Shot[i-40].icon.wt=4;
    Shot[i-40].icon.ht=8;
    Shot[i-40].icon.icondata=*ShotIcon;
    Shot[i-40].x=0;
    Shot[i-40].y=0;
    Shot[i-40].visible=0;
    Shot[i-40].collision=0;
    Shot[i-40].boundary=&AlienBound;
    Sprites[i]=&Shot[i-40];
    i++;
  }
  /* Setup shooter sprite */
  Shooter.icon.wt=20;
  Shooter.icon.ht=16;
  Shooter.icon.icondata=*ShooterIcon;
  Shooter.x=10;
  Shooter.y=SCREEN_HEIGHT-10-16;
  Shooter.visible=1;
  Shooter.collision=0;
  Shooter.boundary=&AlienBound;
  Sprites[i]=&Shooter;
  i++;
  /* Setup cursor */
  SetCursor(0);
  MoveCursor(240,125);
  ShowCursor(1);
  Sprites[i]=&Cursor;
  /* Draw spare shooters */
  Shooters=3;
  i=0;
  while (i<3)
  {
    DrawIcon(i*25+10,10,Shooter.icon,1);
    i++;
  }
  /* Setup shield icon */
  Shield.wt=32;
  Shield.ht=16;
  Shield.icondata=*ShieldIcon;
  /* Draw shields */
  i=0;
  while (i<4)
  {
    DrawIcon(i*125+20,SHIELD_TOP,Shield,1);
    i++;
  }
  /* Game loop */
  dir=2;
  while (1)
  {
    /* Syncronize with frame count */
    if (FrameCount!=fc)
    {
      if (FrameCount>=25)
      {
        FrameCount=0;
        STM_EVAL_LEDToggle(LED3);
        rnd=Random(0xFF);
        DrawHex(0,0,rnd,1);
      }
      fc=FrameCount;
      if (!GameOver)
      {
        /* Check shot boundary and collision */
        i=0;
        while (i<4)
        {
          coll=Shot[i].collision;
          if (coll & COLL_TOP)
          {
            Shot[i].visible=0;
            Shots--;
          }
          else if (coll & COLL_SPRITE)
          {
            /* Find what the shot collided with */
            Shot[i].visible=0;
            Shots--;
          }
          Shot[i].y--;
          i++;
        }
        /* Check bomb boundary and collision */
        i=0;
        while (i<8)
        {
          coll=Bomb[i].collision;
          if (coll & COLL_BOTTOM)
          {
            Bomb[i].visible=0;
            Bombs--;
          }
          else if (coll & COLL_SPRITE)
          {
            /* Find what the bomb collided with, only shields need to be tested */
            Bomb[i].visible=0;
            Bombs--;
            if (Bomb[i].y+8>=SHIELD_TOP)
            {
              /* Make some damage to the shield */
              SetPixel(Bomb[i].x-1,Bomb[i].y+8,0);
              SetPixel(Bomb[i].x,Bomb[i].y+8,0);
              SetPixel(Bomb[i].x+1,Bomb[i].y+8,0);
              SetPixel(Bomb[i].x-1,Bomb[i].y+9,0);
              SetPixel(Bomb[i].x,Bomb[i].y+9,0);
              SetPixel(Bomb[i].x+1,Bomb[i].y+9,0);
              SetPixel(Bomb[i].x,Bomb[i].y+10,0);
            }
          }
          Bomb[i].y++;
          i++;
        }
        /* Drop a bomb */
        if (Bombs<8)
        {
          rnd=Random(31);
          if (Alien[rnd].visible)
          {
            /* Find what bomb sprite to use */
            i=0;
            while (i<8)
            {
              if (!Bomb[i].visible)
              {
                Bomb[i].visible=1;
                Bomb[i].x=Alien[rnd].x+8;
                Bomb[i].y=Alien[rnd].y+16;
                break;
              }
              i++;
            }
          }
        }
        /* Check if shooter hit */
        if (Shooter.collision & COLL_SPRITE)
        {
          Shooters--;
          if (Shooters<0)
          {
            Shooter.visible=0;
            GameOver=1;
          }
          else
          {
            /* Remove spare shooter */
            DrawIcon(Shooters*25+10,10,Shooter.icon,0);
          }
          Shooter.x=0;
        }
        /* Check alien boundaries, there is no need to check collision */
        i=0;
        coll=0;
        while (i<32)
        {
          coll|=Alien[i].collision;
          i++;
        }
        if (!(coll & COLL_BOTTOM))
        {
          if ((dir>0 && (coll & COLL_RIGHT)) || (dir<0 && (coll & COLL_LEFT)))
          {
            /* Move aliens down and change direction */
            i=0;
            while (i<32)
            {
              Alien[i].y+=4;
              i++;
            }
            dir=-dir;
          }
          else
          {
            i=0;
            while (i<32)
            {
              if (!FrameCount)
              {
                /* Change alien icon */
                if (Alien[i].icon.icondata==*Alien1Icon)
                {
                  Alien[i].icon.icondata=*Alien2Icon;
                }
                else
                {
                  Alien[i].icon.icondata=*Alien1Icon;
                }
              }
              /* Move alien left or right */
              Alien[i].x+=dir;
              i++;
            }
          }
        }
        else
        {
          GameOver=1;
        }
      }
    }
  }
}

/**
  * @brief  Configure peripheral clocks
  * @param  None
  * @retval None
  */
void RCC_Config(void)
{
  /* Enable DMA1, GPIOA, GPIOB clocks */
  RCC_AHB1PeriphClockCmd(RCC_AHB1Periph_DMA1 | RCC_AHB1Periph_GPIOA | RCC_AHB1Periph_GPIOB, ENABLE);
  /* Enable USART2, TIM3, TIM4, TIM5 and SPI2 clocks */
  RCC_APB1PeriphClockCmd(RCC_APB1Periph_USART2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_TIM4 | RCC_APB1Periph_TIM5 | RCC_APB1Periph_SPI2, ENABLE);
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
  /* Enable the TIM3 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM3_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM4 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM4_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM5 gloabal Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM5_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 3;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
	/* Enable USART interrupt */
	NVIC_InitStructure.NVIC_IRQChannel = USART2_IRQn;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_InitStructure);
  /* Enable and set EXTI Line0 Interrupt to the lowest priority */
  NVIC_InitStructure.NVIC_IRQChannel = EXTI0_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 2;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable and set EXTI Line2 Interrupt to the lowest priority */
  NVIC_InitStructure.NVIC_IRQChannel = EXTI2_IRQn;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 2;
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

  /* GPIOB Pin3, Pin2, Pin1 and Pin0 as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_3 | GPIO_Pin_2 | GPIO_Pin_1 | GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN;
  GPIO_Init(GPIOB, &GPIO_InitStructure);

  /* Connect EXTI Line0 to PB0 pin */
  SYSCFG_EXTILineConfig(EXTI_PortSourceGPIOB, EXTI_PinSource0);
  /* Configure EXTI Line0 */
  EXTI_InitStructure.EXTI_Line = EXTI_Line0;
  EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
  EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Falling;  
  EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  EXTI_Init(&EXTI_InitStructure);

  /* Connect EXTI Line2 to PB2 pin */
  SYSCFG_EXTILineConfig(EXTI_PortSourceGPIOB, EXTI_PinSource2);
  /* Configure EXTI Line2 */
  EXTI_InitStructure.EXTI_Line = EXTI_Line2;
  EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
  EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Falling;  
  EXTI_InitStructure.EXTI_LineCmd = ENABLE;
  EXTI_Init(&EXTI_InitStructure);
}

/**
  * @brief  Configure timers
  * @param  None
  * @retval None
  */
void TIM_Config(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;

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
  TIM_TimeBaseInit(TIM5, &TIM_TimeBaseStructure);
  /* Enable TIM5 Update interrupt */
  TIM_ClearITPendingBit(TIM5,TIM_IT_Update);
  TIM_ITConfig(TIM5, TIM_IT_Update, ENABLE);
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
  DMA_InitStructure.DMA_BufferSize = (uint16_t)SCREEN_WIDTH/2;
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
