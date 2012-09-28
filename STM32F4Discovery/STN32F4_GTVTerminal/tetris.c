
/* Includes ------------------------------------------------------------------*/
#include "tetris.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern SPRITE* Sprites[];             // Max 64 sprites
extern WINDOW* Windows[];             // Max 16 windows
extern WINDOW* Focus;                 // The windpw that has the keyboard focus

/* Private variables ---------------------------------------------------------*/
TETRIS_GAME TetrisGame;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void TetrisGameSetup(void)
{
  uint32_t x,y;

  Cls();
  /* Draw game frame */
  Rectangle(127,0,12*10+2,12*20+2,1);
  DrawLargeDec16(300,3,0,1);
  /* Clear Board and Shape */
  y=0;
  while (y<20)
  {
    x=0;
    while (x<10)
    {
      TetrisGame.Board[y][x]=0;
      TetrisGame.Shape[y][x]=0;
      x++;
    }
    y++;
  }
}

void TetrisMsgBoxHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D && ID==5)
      {
        /* New Game */
        TetrisGame.DemoMode=0;
        break;
      }
      else if (param==0x0D && ID==4)
      {
        /* Quit */
        TetrisGame.Quit=1;
        break;
      }
      else if (param==0x0D && ID==3)
      {
        /* Mode select */
        TetrisGame.Mode++;
        if (TetrisGame.Mode>2)
        {
          TetrisGame.Mode=0;
        }
        TetrisGameSetup();
        break;
      }
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void TetrisGameInit(void)
{
  TetrisGame.hmsgbox=CreateWindow(0,CLASS_WINDOW,1,(SCREEN_WIDTH-160)/2,(SCREEN_HEIGHT-90)/2,160,90,"Tetris\0");
  CreateWindow(TetrisGame.hmsgbox,CLASS_STATIC,2,4,15,160-8,20,"GameOver\0");
  CreateWindow(TetrisGame.hmsgbox,CLASS_BUTTON,3,5,90-50,150,20,0);
  CreateWindow(TetrisGame.hmsgbox,CLASS_BUTTON,4,5,90-25,70,20,"Quit\0");
  CreateWindow(TetrisGame.hmsgbox,CLASS_BUTTON,5,160-75,90-25,70,20,"New Game\0");
  SetHandler(TetrisGame.hmsgbox,&TetrisMsgBoxHandler);
  TetrisGame.tile.wt=12;
  TetrisGame.tile.ht=12;
  TetrisGame.tile.icondata=*TetrisIcon;
}

void TetrisDrawBoard(void)
{
  uint32_t x,y;

  y=0;
  while (y<20)
  {
    x=0;
    while (x<10)
    {
      if (TetrisGame.Board[y][x])
      {
        DrawIcon(x*12+128,y*12+1,&TetrisGame.tile,1);
      }
      x++;
    }
    y++;
  }
}

void TetrisDrawShape(void)
{
  uint32_t x,y;

  y=0;
  while (y<20)
  {
    x=0;
    while (x<10)
    {
      if (TetrisGame.Shape[y][x])
      {
        DrawIcon(x*12+128,y*12+1,&TetrisGame.tile,1);
      }
      x++;
    }
    y++;
  }
}

void TetrisDrawNextShape(void)
{
  uint32_t x,y;
  uint8_t byte;

  y=0;
  while (y<4)
  {
    byte=*TetrisShape[TetrisGame.nxtshape-1][y];
    x=0;
    while (x<4)
    {
      if (byte & 0x80)
      {
        DrawIcon(x*12+50,y*12+50,&TetrisGame.tile,1);
      }
      byte<<=1;
      x++;
    }
    y++;
  }
}

void TetrisGetChar(void)
{
}

void TetrisGamePlay(void)
{
  uint32_t i,rnd;

  TetrisGame.nxtshape=Random(7)+1;
  /* Wait 25 frames */
  FrameWait(25);
  while (!TetrisGame.GameOver)
  {
    if (!TetrisGame.curshape)
    {
      TetrisGame.curshape=TetrisGame.nxtshape;
      TetrisGame.nxtshape=Random(7)+1;
      TetrisDrawNextShape();
    }
    TetrisDrawBoard();
    TetrisGetChar();
    FrameWait(TetrisGame.Speed);
    TetrisGetChar();
    FrameWait(TetrisGame.Speed);
    TetrisGetChar();
    FrameWait(TetrisGame.Speed);
  }
  TetrisGame.GameOver=0;
  ShowCursor(1);
  /* Show message box */
  SendEvent(TetrisGame.hmsgbox,EVENT_ACTIVATE,0,TetrisGame.hmsgbox->ID);
  TetrisGame.DemoMode=1;
  /* Wait 2000 frames */
  i=2000;
  while (i && TetrisGame.DemoMode && !TetrisGame.Quit)
  {
    FrameWait(1);
    i--;
  }
  SendEvent(TetrisGame.hmsgbox,EVENT_SHOW,STATE_HIDDEN,0);
  ShowCursor(0);
}

void TetrisGameLoop(void)
{
  TetrisGame.Mode=0;
  TetrisGame.DemoMode=0;
  TetrisGame.GameOver=0;
  TetrisGame.Quit=0;
  TetrisGameInit();
  while (!TetrisGame.Quit)
  {
    TetrisGameSetup();
    ShowCursor(0);
    TetrisGamePlay();
  }
  DestroyWindow(TetrisGame.hmsgbox);
  /* Clear screen */
  Cls();
}

