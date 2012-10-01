
/* Includes ------------------------------------------------------------------*/
#include "tetris.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern SPRITE* Sprites[];             // Max 64 sprites
extern WINDOW* Windows[];             // Max 16 windows
extern WINDOW* Focus;                 // The windpw that has the keyboard focus
extern uint8_t BackBuff[SCREEN_BUFFHEIGHT][SCREEN_BUFFWIDTH];

/* Private variables ---------------------------------------------------------*/
TETRIS_GAME TetrisGame;
uint8_t tetrisstr[3][7]={{"Easy\0"},{"Medium\0"},{"Hard\0"}};

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void TetrisSetup(void)
{
  uint32_t x,y;

  Cls();
  /* Draw game frame */
  Rectangle(TETRIS_LEFT-1,TETRIS_TOP-1,TETRIS_WIDTH+2,TETRIS_HEIGHT+2,1);
  DrawLargeDec16(300,3,0,1);
  /* Clear Board */
  y=0;
  while (y<20)
  {
    x=0;
    while (x<10)
    {
      TetrisGame.Board[y][x]=0;
      x++;
    }
    y++;
  }
  SetCaption(GetControlHandle(TetrisGame.hmsgbox,3),tetrisstr[TetrisGame.Mode]);
  if (TetrisGame.Mode==0)
  {
    TetrisGame.Speed=25;
  }
  else if (TetrisGame.Mode==1)
  {
    TetrisGame.Speed=20;
  }
  else if (TetrisGame.Mode==2)
  {
    TetrisGame.Speed=15;
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
        TetrisSetup();
        break;
      }
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void TetrisInit(void)
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
  TetrisGame.Speed=25;
}

void TetrisClearBoard(void)
{
  uint32_t x,y;

  y=TETRIS_TOP;
  while (y<TETRIS_TOP+TETRIS_HEIGHT)
  {
    x=TETRIS_LEFT/8;
    while (x<TETRIS_LEFT/8+TETRIS_WIDTH/8)
    {
      BackBuff[y][x]=0;
      x++;
    }
    y++;
  }
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
        DrawIcon(x*12+TETRIS_LEFT,y*12+TETRIS_TOP,&TetrisGame.tile,1);
      }
      x++;
    }
    y++;
  }
}
void TetrisSetShape(void)
{
  uint32_t x,y;
  uint8_t byte;

  y=0;
  while (y<5)
  {
    byte=TetrisShape[TetrisGame.curshape-1][TetrisGame.curshapeo][y];
    x=0;
    while (x<5)
    {
      TetrisGame.Shape[y][x]=0;
      if (byte & 0x10)
      {
        TetrisGame.Shape[y][x]=1;
      }
      byte<<=1;
      x++;
    }
    y++;
  }
}

void TetrisDrawShape(void)
{
  uint32_t x,y;

  y=0;
  while (y<5)
  {
    x=0;
    while (x<5)
    {
      if (TetrisGame.Shape[y][x])
      {
        DrawIcon((TetrisGame.curshapex+x)*12+TETRIS_LEFT,(TetrisGame.curshapey+y)*12+TETRIS_TOP,&TetrisGame.tile,1);
      }
      x++;
    }
    y++;
  }
}

void TetrisDrawNextShape(void)
{
  int32_t x,y;
  uint8_t byte;

  y=0;
  while (y<12*5)
  {
    x=0;
    while (x<8)
    {
      BackBuff[y+8][x+1]=0;
      x++;
    }
    y++;
  }
  y=0;
  while (y<5)
  {
    byte=TetrisShape[TetrisGame.nxtshape-1][0][y];
    x=0;
    while (x<5)
    {
      if (byte & 0x10)
      {
        DrawIcon(x*12+8,y*12+8,&TetrisGame.tile,1);
      }
      byte<<=1;
      x++;
    }
    y++;
  }
}

int8_t TetrisTestColl(void)
{
  int8_t x,y,coll;

  coll=0;
  y=0;
  while (y<5)
  {
    x=0;
    while (x<5)
    {
      if (TetrisGame.Shape[y][x])
      {
        if (TetrisGame.curshapex+x<0)
        {
          coll|=1;
        }
        if (TetrisGame.curshapex+x>=10)
        {
          coll|=2;
        }
        if (TetrisGame.curshapey+y>=20)
        {
          coll|=4;
        }
        if (!coll)
        {
          if (TetrisGame.Board[TetrisGame.curshapey+y][TetrisGame.curshapex+x])
          {
            coll|=8;
          }
        }
      }
      x++;
    }
    y++;
  }
  return coll;
}

void TetrisUpdate(void)
{
  TetrisClearBoard();
  TetrisDrawBoard();
  if (TetrisGame.curshape)
  {
    TetrisSetShape();
    TetrisDrawShape();
  }
}

void TetrisShapeMove(void)
{
  uint32_t i;
  uint8_t chr;

  i=0;
  while (i<TetrisGame.Speed)
  {
    if (TetrisGame.DemoMode)
    {
      chr=Random(127)+128;
    }
    else
    {
      // chr=GetChar();
      chr=GetClick();
      if (chr & 1)
      {
        chr=K_LEFT;
      }
      else if (chr & 2)
      {
        chr=K_RIGHT;
      }
      else if (chr & 4)
      {
        chr=K_UP;
      }
    }
    if (chr==K_LEFT)
    {
      TetrisGame.curshapex--;
      if (TetrisTestColl())
      {
        TetrisGame.curshapex++;
      }
    }
    else if (chr==K_RIGHT)
    {
      TetrisGame.curshapex++;
      if (TetrisTestColl())
      {
        TetrisGame.curshapex--;
      }
    }
    else if (chr==K_UP)
    {
      TetrisGame.curshapeo++;
      TetrisGame.curshapeo&=3;
      TetrisSetShape();
      if (TetrisTestColl())
      {
        TetrisGame.curshapeo--;
        TetrisGame.curshapeo&=3;
        TetrisSetShape();
      }
    }
    TetrisUpdate();
    FrameWait(1);
    i++;
  }
}

void TetrisShapeStuck(void)
{
  int8_t x,y;

  y=0;
  while (y<5)
  {
    x=0;
    while (x<5)
    {
      if (TetrisGame.Shape[y][x])
      {
        TetrisGame.Board[TetrisGame.curshapey+y][TetrisGame.curshapex+x]=1;
      }
      x++;
    }
    y++;
  }
}

void TetrisRowFull(void)
{
  uint32_t i,x,y,p;

  y=0;
  p=10;
  while (y<20)
  {
    x=0;
    while(x<10)
    {
      if (!TetrisGame.Board[y][x])
      {
        break;
      }
      x++;
    }
    if (x==10)
    {
      i=y;
      while (i)
      {
        x=0;
        while (x<10)
        {
          TetrisGame.Board[i][x]=TetrisGame.Board[i-1][x];
          x++;
        }
        i--;
      }
      x=0;
      while (x<10)
      {
        TetrisGame.Board[0][x]=0;
        x++;
      }
      TetrisGame.Points+=p;
      p=p*2+p;
    }
    y++;
  }
}

void TetrisPlay(void)
{
  uint32_t i,x,y;

  TetrisGame.curshape=0;
  TetrisGame.Points=0;
  TetrisGame.nxtshape=Random(7)+1;
  /* Wait 25 frames */
  FrameWait(25);
  GetClick();
  while (!TetrisGame.GameOver)
  {
    if (!TetrisGame.curshape)
    {
      TetrisGame.curshape=TetrisGame.nxtshape;
      TetrisGame.curshapeo=0;
      TetrisGame.curshapex=2;
      TetrisGame.curshapey=0;
      TetrisGame.nxtshape=Random(7)+1;
      TetrisDrawNextShape();
      TetrisSetShape();
      if (TetrisTestColl())
      {
        TetrisUpdate();
        TetrisGame.GameOver=1;
        break;
      }
    }
    TetrisShapeMove();
    TetrisGame.curshapey++;
    if (TetrisTestColl())
    {
      TetrisGame.curshapey--;
      TetrisShapeStuck();
      TetrisGame.curshape=0;
    }
    TetrisUpdate();
    TetrisRowFull();
    DrawLargeDec16(300,3,TetrisGame.Points,1);
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
  TetrisInit();
  while (!TetrisGame.Quit)
  {
    TetrisSetup();
    ShowCursor(0);
    TetrisPlay();
  }
  DestroyWindow(TetrisGame.hmsgbox);
  /* Clear screen */
  Cls();
}

