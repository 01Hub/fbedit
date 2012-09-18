
/* Includes ------------------------------------------------------------------*/
#include "pong.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern SPRITE* Sprites[];             // Max 64 sprites
extern WINDOW* Windows[];             // Max 16 windows
extern WINDOW* Focus;                 // The windpw that has the keyboard focus

/* Private variables ---------------------------------------------------------*/
PONG_GAME PongGame;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void PongGameSetup(void)
{
  Cls();
  /* Draw game frame */
  Line(0,0,479,0,1);
  Line(0,249,479,249,1);
  Line(480/2,0,480/2,249,1);
  DrawLargeDec16(SCREEN_WIDTH/2+5,3,0,1);
  PongGame.Paddle[0].visible=1;
  if (PongGame.Mode==0)
  {
    Line(479,0,479,249,1);
    PongGame.Paddle[1].visible=0;
    SetCaption(GetControlHandle(PongGame.hmsgbox,3),"1P VS Wall\0");
  }
  else if (PongGame.Mode==1)
  {
    SetCaption(GetControlHandle(PongGame.hmsgbox,3),"1P VS STM\0");
    DrawLargeDec16(SCREEN_WIDTH/2-50-16*5,3,0,1);
    PongGame.Paddle[1].visible=1;
  }
  else
  {
    SetCaption(GetControlHandle(PongGame.hmsgbox,3),"2 Player\0");
    DrawLargeDec16(SCREEN_WIDTH/2-50-16*5,3,0,1);
    PongGame.Paddle[1].visible=1;
  }
  PongGame.bxdir=4;
  PongGame.bydir=3;
  PongGame.Points[0]=0;
  PongGame.Points[1]=0;
  PongGame.Ball.x=480/2-4;
  PongGame.Ball.y=250/2-4;
  PongGame.Ball.collision=0;
}

void PongMsgBoxHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D && ID==5)
      {
        /* New Game */
        PongGame.DemoMode=0;
        break;
      }
      else if (param==0x0D && ID==4)
      {
        /* Quit */
        PongGame.Quit=1;
        break;
      }
      else if (param==0x0D && ID==3)
      {
        /* Mode select */
        PongGame.Mode++;
        if (PongGame.Mode>2)
        {
          PongGame.Mode=0;
        }
        PongGameSetup();
        break;
      }
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void PongGameInit(void)
{
  uint32_t i;

  PongGame.hmsgbox=CreateWindow(0,CLASS_WINDOW,1,(SCREEN_WIDTH-160)/2,(SCREEN_HEIGHT-90)/2,160,90,"Pong\0");
  CreateWindow(PongGame.hmsgbox,CLASS_STATIC,2,4,15,160-8,20,"GameOver\0");
  CreateWindow(PongGame.hmsgbox,CLASS_BUTTON,3,5,90-50,150,20,0);
  CreateWindow(PongGame.hmsgbox,CLASS_BUTTON,4,5,90-25,70,20,"Quit\0");
  CreateWindow(PongGame.hmsgbox,CLASS_BUTTON,5,160-75,90-25,70,20,"New Game\0");
  SetHandler(PongGame.hmsgbox,&PongMsgBoxHandler);

  PongGame.PongBound.left=5;
  PongGame.PongBound.top=5;
  PongGame.PongBound.right=480-5;
  PongGame.PongBound.bottom=250-5;
  i=0;
  while (i<2)
  {
    /* Setup paddle sprite */
    PongGame.Paddle[i].icon.wt=6;
    PongGame.Paddle[i].icon.ht=24;
    PongGame.Paddle[i].icon.icondata=*PongPaddleIcon;
    PongGame.Paddle[i].x=i*(479-16)+8;
    PongGame.Paddle[i].y=250/2-12;
    PongGame.Paddle[i].visible=0;
    PongGame.Paddle[i].collision=0;
    PongGame.Paddle[i].boundary=&PongGame.PongBound;
    Sprites[i]=&PongGame.Paddle[i];
    i++;
  }
  /* Setup ball sprite */
  PongGame.Ball.icon.wt=8;
  PongGame.Ball.icon.ht=8;
  PongGame.Ball.icon.icondata=*PongBallIcon;
  PongGame.Ball.x=480/2-4;
  PongGame.Ball.y=250/2-4;
  PongGame.Ball.visible=0;
  PongGame.Ball.collision=0;
  PongGame.Ball.boundary=&PongGame.PongBound;
  Sprites[2]=&PongGame.Ball;
}

void PongPaddleMove(uint8_t Paddle)
{
  PongGame.pydir[0]=0;
  PongGame.pydir[1]=0;
  if (Paddle==0)
  {
    /* Left paddle */
    if (PongGame.DemoMode)
    {
      /* Game moves paddle */
      if ((PongGame.Ball.x<200) && (PongGame.bxdir<0))
      {
        if (PongGame.Ball.y+4>PongGame.Paddle[0].y+12)
        {
          if (!(PongGame.Paddle[0].collision & COLL_BOTTOM))
          {
            PongGame.Paddle[0].y+=3;
            PongGame.pydir[0]=1;
          }
        }
        else if (PongGame.Ball.y+4<PongGame.Paddle[0].y+12)
        {
          if (!(PongGame.Paddle[0].collision & COLL_TOP))
          {
            PongGame.Paddle[0].y-=3;
            PongGame.pydir[0]=-1;
          }
        }
      }
    }
    else
    {
      /* Player moves paddle */
      if (GetKeyState(SC_L_SHFT) && !GetKeyState(SC_L_CTRL))
      {
        if (!(PongGame.Paddle[0].collision & COLL_TOP))
        {
          PongGame.Paddle[0].y-=3;
          PongGame.pydir[0]=-1;
        }
      }
      else if (GetKeyState(SC_L_CTRL) && !GetKeyState(SC_L_SHFT))
      {
        if (!(PongGame.Paddle[0].collision & COLL_BOTTOM))
        {
          PongGame.Paddle[0].y+=3;
          PongGame.pydir[0]=1;
        }
      }
    }
  }
  else
  {
     /* Right paddle */
    if (PongGame.DemoMode || PongGame.Mode==1)
    {
      /* Game moves paddle */
      if ((PongGame.Ball.x>280) && (PongGame.bxdir>0))
      {
        if ((PongGame.Ball.y+4)>(PongGame.Paddle[1].y+12))
        {
          if (!(PongGame.Paddle[1].collision & COLL_BOTTOM))
          {
            PongGame.Paddle[1].y+=3;
            PongGame.pydir[1]=1;
          }
        }
        else if ((PongGame.Ball.y+4)<(PongGame.Paddle[1].y+12))
        {
          if (!(PongGame.Paddle[1].collision & COLL_TOP))
          {
            PongGame.Paddle[1].y-=3;
            PongGame.pydir[1]=-1;
          }
        }
      }
    }
    else
    {
      /* Player moves paddle */
      if (GetKeyState(SC_R_SHFT) && !GetKeyState(SC_R_CTRL))
      {
        if (!(PongGame.Paddle[1].collision & COLL_TOP))
        {
          PongGame.Paddle[1].y-=3;
          PongGame.pydir[1]=-1;
        }
      }
      else if (GetKeyState(SC_R_CTRL) && !GetKeyState(SC_R_SHFT))
      {
        if (!(PongGame.Paddle[1].collision & COLL_BOTTOM))
        {
          PongGame.Paddle[1].y+=3;
          PongGame.pydir[1]=1;
        }
      }
    }
  }
}

void PongBallMove()
{
  uint8_t coll;
  int16_t pydir;

  coll=PongGame.Ball.collision;
  if (coll & COLL_SPRITE)
  {
    /* Ball hit a paddle */
    if (PongGame.Ball.x>SCREEN_WIDTH/2)
    {
      /* Ball moves right */
      pydir=PongGame.pydir[1];
    }
    else
    {
      /* Ball moves left */
      pydir=PongGame.pydir[0];
    }
    if (pydir<0 && PongGame.bydir<0 && PongGame.bydir>-5)
    {
      /* Increment ball y speed */
      PongGame.bydir--;
    }
    else if (pydir>0 && PongGame.bydir>0 && PongGame.bydir<5)
    {
      /* Increment ball y speed */
      PongGame.bydir++;
    }
    else if (PongGame.bydir<-3)
    {
      /* Decrement ball y speed */
      PongGame.bydir++;
    }
    else if (PongGame.bydir>3)
    {
      /* Decrement ball y speed */
      PongGame.bydir--;
    }
    /* Move the ball */
    PongGame.bxdir=-PongGame.bxdir;
    PongGame.Ball.x+=PongGame.bxdir;
    PongGame.Ball.collision=0;
    coll=0;
  }
  if (coll & (COLL_LEFT | COLL_RIGHT))
  {
    if (coll & COLL_LEFT)
    {
      /* Ball went out to the left */
      PongGame.Points[1]++;
      DrawLargeDec16(SCREEN_WIDTH/2+5,3,PongGame.Points[1],1);
      PongGame.Ball.x=480-16;
      PongGame.Ball.y=Random(200)+20;
      PongGame.bxdir=-4;
      /* Random ball y direction and speed */
      PongGame.bydir=3+Random(2);
      if (Random(9)<5)
      {
        PongGame.bydir=-PongGame.bydir;
      }
    }
    else
    {
      /* Ball went out to the right or hit the right wall */
      if (PongGame.Mode)
      {
        /* Ball went out to the right */
        PongGame.Points[0]++;
        DrawLargeDec16(SCREEN_WIDTH/2-50-16*5,3,PongGame.Points[0],1);
        PongGame.Ball.x=16;
        PongGame.Ball.y=Random(200)+20;
        PongGame.bxdir=4;
        /* Random ball y direction and speed */
        PongGame.bydir=3+Random(2);
        if (Random(9)<5)
        {
          PongGame.bydir=-PongGame.bydir;
        }
      }
      else
      {
        /* Ball hit right wall, Switch ball x direction */
        PongGame.bxdir=-PongGame.bxdir;
      }
    }
    PongGame.Ball.collision=0;
    coll=0;
  }
  if (coll & (COLL_TOP | COLL_BOTTOM))
  {
    /* Switch ball y direction */
    PongGame.bydir=-PongGame.bydir;
    PongGame.Ball.collision=0;
    coll=0;
  }
  PongGame.Ball.x+=PongGame.bxdir;
  PongGame.Ball.y+=PongGame.bydir;
}

void PongGamePlay(void)
{
  uint32_t i,rnd;

  /* Wait 25 frames */
  FrameWait(25);
  while (!PongGame.GameOver)
  {
    /* Syncronize with frame count */
    FrameWait(1);
    PongBallMove();
    if (PongGame.Mode==0)
    {
      /* Paddle VS Wall */
      PongPaddleMove(0);
    }
    else
    {
      /* Paddle VS STM or Paddle VS Paddle */
      PongPaddleMove(0);
      PongPaddleMove(1);
    }
    PongGame.GameOver=PongGame.Points[0]==10 || PongGame.Points[1]==10 || GetKeyState(SC_ESC);
  }
  PongGame.GameOver=0;
  PongGame.Ball.visible=0;
  ShowCursor(1);
  /* Show message box */
  SendEvent(PongGame.hmsgbox,EVENT_ACTIVATE,0,PongGame.hmsgbox->ID);
  PongGame.DemoMode=1;
  /* Wait 2000 frames */
  i=2000;
  while (i && PongGame.DemoMode && !PongGame.Quit)
  {
    FrameWait(1);
    i--;
  }
  SendEvent(PongGame.hmsgbox,EVENT_SHOW,STATE_HIDDEN,0);
  ShowCursor(0);
}

void PongGameLoop(void)
{
  PongGame.Mode=0;
  PongGame.DemoMode=0;
  PongGame.GameOver=0;
  PongGame.Quit=0;
  PongGameInit();
  while (!PongGame.Quit)
  {
    PongGameSetup();
    ShowCursor(0);
    PongGame.Ball.visible=1;
    PongGamePlay();
  }
  DestroyWindow(PongGame.hmsgbox);
  RemoveSprites();
  /* Clear screen */
  Cls();
}

