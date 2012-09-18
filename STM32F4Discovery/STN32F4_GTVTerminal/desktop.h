
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

/* Private define ------------------------------------------------------------*/
/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  WINDOW* hmnubar;
  WINDOW* hpopup1;
  WINDOW* hpopup2;
  WINDOW* hpopup3;
  WINDOW* hpopup4;
  volatile uint8_t SelectedID;
} DESKTOP;

/* Private function prototypes -----------------------------------------------*/
void MenuBarHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void MenuPopupHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID);
void DeskTopSetup(void);

