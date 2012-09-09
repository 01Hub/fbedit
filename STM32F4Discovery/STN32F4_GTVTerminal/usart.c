
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"

/* Private function prototypes -----------------------------------------------*/
void rs232_putc(char c);
void rs232_puts(char *str);

/* Private variables ---------------------------------------------------------*/
uint8_t rs232buf[256];
volatile uint8_t rs232buftail;
volatile uint8_t rs232bufhead;

/**
  * @brief  This function transmits a character
  * @param  Character
  * @retval None
  */
void rs232_putc(char c)
{
  /* Wait until transmit register empty*/
  while((USART2->SR & USART_FLAG_TXE) == 0);          
  /* Transmit Data */
  USART2->DR = (u16)c;
}

/**
  * @brief  This function transmits a zero terminated string
  * @param  Zero terminated string
  * @retval None
  */
void rs232_puts(char *str)
{
  char c;
  /* Characters are transmitted one at a time. */
  while ((c = *str++))
    rs232_putc(c);
}

/**
  * @brief  This function handles USART2_IRQHandler interrupt request.
            An interrupt is generated when a character is recieved
  * @param  None
  * @retval None
  */
void USART2_IRQHandler(void)
{
  rs232buf[rs232bufhead++]=USART2->DR;
  USART2->SR = (u16)~USART_FLAG_RXNE;
}

