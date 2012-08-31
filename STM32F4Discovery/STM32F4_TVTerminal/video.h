
/* Private define ------------------------------------------------------------*/
#define SCREEN_WIDTH        40  // 40 characters on each line.
#define SCREEN_HEIGHT       25  // 25 lines.

/* Private function prototypes -----------------------------------------------*/
void video_putc(char c);
void video_puts(char *str);
void video_puthex(uint8_t n);
