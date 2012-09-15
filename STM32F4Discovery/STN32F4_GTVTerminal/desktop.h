
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "window.h"
#include "video.h"
#include "keycodes.h"

/* Private define ------------------------------------------------------------*/
/* Private typedef -----------------------------------------------------------*/
typedef struct
{
  WINDOW MenuBar;                       // Menubar window
  WINDOW MenuBarButtons[4];             // Button controls for mrnubar
  WINDOW Menu1Popup;                    // Menu popup windpw
  WINDOW Menu1ItemButtons[4];           // Button controls
  WINDOW Menu2Popup;                    // Menu popup windpw
  WINDOW Menu2ItemButtons[4];           // Button controls
  WINDOW Menu3Popup;                    // Menu popup windpw
  WINDOW Menu3ItemButtons[4];           // Button controls
  WINDOW Menu4Popup;                    // Menu popup windpw
  WINDOW Menu4ItemButtons[2];           // Button controls
  volatile uint8_t SelectedID;
} DESKTOP;
