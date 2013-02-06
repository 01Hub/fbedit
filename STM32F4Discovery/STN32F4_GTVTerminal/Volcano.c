/* Includes ------------------------------------------------------------------*/
#include "Volcano.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;  // Frame counter
extern SPRITE* Sprites[];             // Max 64 sprites
extern WINDOW WinColl[MAX_WINCOLL];
extern WINDOW* Windows[MAX_WINDOWS+1];

/* Private variables ---------------------------------------------------------*/
VOLCANO_GAME VolcanoGame;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void VolcanoMsgBoxHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D && ID==4)
      {
        /* New Game */
        VolcanoGame.DemoMode=0;
        break;
      }
      else if (param==0x0D && ID==3)
      {
        /* Quit */
        VolcanoGame.Quit=1;
        break;
      }
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void VolcanoGameInit(void)
{
  uint32_t i;

  /* Create message box */
  VolcanoGame.hmsgbox=CreateWindow(0,CLASS_WINDOW,1,(SCREEN_WIDTH-160)/2,(SCREEN_HEIGHT-64)/2,160,64,"Volcano\0");
  CreateWindow(VolcanoGame.hmsgbox,CLASS_STATIC,2,4,15,160-8,20,"GameOver\0");
  CreateWindow(VolcanoGame.hmsgbox,CLASS_BUTTON,3,5,64-25,70,20,"Quit\0");
  CreateWindow(VolcanoGame.hmsgbox,CLASS_BUTTON,4,160-75,64-25,70,20,"New Game\0");
  SetHandler(VolcanoGame.hmsgbox,&VolcanoMsgBoxHandler);

  /* Setup game boundary */
  VolcanoGame.VolcanoBound.left=VOLCANO_BOUND_LEFT;
  VolcanoGame.VolcanoBound.top=VOLCANO_BOUND_TOP;
  VolcanoGame.VolcanoBound.right=VOLCANO_BOUND_RIGHT;
  VolcanoGame.VolcanoBound.bottom=VOLCANO_BOUND_BOTTOM;
  /* Setup volcano sprites */
  i=0;
  while (i<VOLCANO_MAX_VOLCANO)
  {
    VolcanoGame.Volcano[i].VolcanoSprite.icon.wt=16;
    VolcanoGame.Volcano[i].VolcanoSprite.icon.ht=16;
    if (i & 1)
    {
      VolcanoGame.Volcano[i].VolcanoSprite.icon.icondata=*Volcano2Icon;
    }
    else
    {
      VolcanoGame.Volcano[i].VolcanoSprite.icon.icondata=*Volcano1Icon;
    }
    VolcanoGame.Volcano[i].VolcanoSprite.x=SCREEN_WIDTH/2;
    VolcanoGame.Volcano[i].VolcanoSprite.y=VOLCANO_BOUND_TOP+16;
    VolcanoGame.Volcano[i].VolcanoSprite.collision=0;
    VolcanoGame.Volcano[i].VolcanoSprite.boundary=&VolcanoGame.VolcanoBound;
    VolcanoGame.Volcano[i].VolcanoSprite.visible=0;
    VolcanoGame.Volcano[i].vdir=2;
    Sprites[i]=&VolcanoGame.Volcano[i].VolcanoSprite;
    i++;
  }
  /* Setup shot sprites */
  i=0;
  while (i<VOLCANO_MAX_SHOTS)
  {
    VolcanoGame.Shot[i].icon.wt=3;
    VolcanoGame.Shot[i].icon.ht=8;
    VolcanoGame.Shot[i].icon.icondata=*VolcanoShotIcon;
    VolcanoGame.Shot[i].x=0;
    VolcanoGame.Shot[i].y=0;
    VolcanoGame.Shot[i].visible=0;
    VolcanoGame.Shot[i].collision=0;
    VolcanoGame.Shot[i].boundary=&VolcanoGame.VolcanoBound;
    Sprites[i+VOLCANO_MAX_VOLCANO]=&VolcanoGame.Shot[i];
    i++;
  }
  /* Setup Cannon sprite */
  VolcanoGame.Cannon.icon.wt=20;
  VolcanoGame.Cannon.icon.ht=16;
  VolcanoGame.Cannon.icon.icondata=*VolcanoCannonIcon;
  VolcanoGame.Cannon.x=10;
  VolcanoGame.Cannon.y=VOLCANO_BOUND_BOTTOM-16;
  VolcanoGame.Cannon.visible=0;
  VolcanoGame.Cannon.collision=0;
  VolcanoGame.Cannon.boundary=&VolcanoGame.VolcanoBound;
  Sprites[VOLCANO_MAX_VOLCANO+VOLCANO_MAX_SHOTS]=&VolcanoGame.Cannon;
  VolcanoGame.DemoMode=0;
  VolcanoGame.Quit=0;
}

void VolcanoGameSetup(void)
{
  int16_t i,j,wtshield;

  VolcanoGame.sdir=3;
  VolcanoGame.slen=10;
  VolcanoGame.Points=0;
  VolcanoGame.Volcanos=VOLCANO_MAX_VOLCANO;
  VolcanoGame.Cannons=VOLCANO_MAX_CANNONS;
  VolcanoGame.Shots=0;
  VolcanoGame.GameOver=0;
  Cls();
  /* Draw game frame */
  Rectangle(0,0,SCREEN_WIDTH,SCREEN_HEIGHT,1);
  /* Hide cursor */
  ShowCursor(0);
  /* Draw spare Cannons */
  i=0;
  while (i<VOLCANO_MAX_CANNONS)
  {
    DrawIcon(i*25+10,10,&VolcanoGame.Cannon.icon,1);
    i++;
  }
  DrawLargeDec16(SCREEN_WIDTH-10-16*5,3,VolcanoGame.Points,1);
}

void VolcanoShoot(void)
{
  uint32_t i;

  i=0;
  while(i<VOLCANO_MAX_SHOTS)
  {
    if (!VolcanoGame.Shot[i].visible)
    {
      VolcanoGame.Shot[i].x=VolcanoGame.Cannon.x+10;
      VolcanoGame.Shot[i].y=216;
      VolcanoGame.Shot[i].visible=1;
      VolcanoGame.Shots++;
      break;
    }
    i++;
  }
}

void VolcanoShotMove(void)
{
  uint32_t i,j,coll;

  /* Check shot boundary and collision */
  i=0;
  while (i<VOLCANO_MAX_SHOTS)
  {
    if (VolcanoGame.Shot[i].visible)
    {
      coll=VolcanoGame.Shot[i].collision;
      if (coll & COLL_TOP)
      {
        VolcanoGame.Shot[i].visible=0;
        VolcanoGame.Shots--;
      }
      else if (coll & COLL_SPRITE)
      {
        /* Collision with a sprite */
        VolcanoGame.Shot[i].visible=0;
        VolcanoGame.Shots--;
        /* Find what the shot collided with */
        j=0;
        while (j<VOLCANO_MAX_VOLCANO)
        {
          if (VolcanoGame.Volcano[j].VolcanoSprite.visible)
          {
            if (VolcanoGame.Shot[i].x+3>VolcanoGame.Volcano[j].VolcanoSprite.x && VolcanoGame.Shot[i].x<VolcanoGame.Volcano[j].VolcanoSprite.x+16)
            {
              if (VolcanoGame.Shot[i].y+8>VolcanoGame.Volcano[j].VolcanoSprite.y && VolcanoGame.Shot[i].y<VolcanoGame.Volcano[j].VolcanoSprite.y+16)
              {
                VolcanoGame.Volcano[j].VolcanoSprite.visible=0;
                VolcanoGame.Volcanos--;
                VolcanoGame.Points+=5;
                DrawLargeDec16(SCREEN_WIDTH-10-16*5,3,VolcanoGame.Points,1);
                break;
              }
            }
          }
          j++;
        }
      }
      else
      {
        VolcanoGame.Shot[i].y-=2;
      }
    }
    i++;
  }
}

void VolcanoCannonMove(void)
{
  uint32_t i;

  if (VolcanoGame.DemoMode)
  {
    VolcanoGame.GameOver=(GetKeyState(SC_SPACE)) | VolcanoGame.GameOver;
    /* Move Cannon */
    if (VolcanoGame.slen)
    {
      if ((VolcanoGame.sdir>0 && (VolcanoGame.Cannon.collision & COLL_RIGHT)) || (VolcanoGame.sdir<0 && (VolcanoGame.Cannon.collision & COLL_LEFT)))
      {
        VolcanoGame.sdir=-VolcanoGame.sdir;
      }
      VolcanoGame.Cannon.x+=VolcanoGame.sdir;
      VolcanoGame.slen--;
    }
    else
    {
      i=Random(100);
      if (i<5)
      {
        VolcanoGame.slen=Random(40);
        i=Random(9);
        if (i<5)
        {
          VolcanoGame.sdir=-3;
        }
        else
        {
          VolcanoGame.sdir=3;
        }
      }
    }
    /* Shoot */
    if (VolcanoGame.Shots<VOLCANO_MAX_SHOTS)
    {
      i=Random(100);
      if (i<5)
      {
        VolcanoShoot();
      }
    }
  }
  else
  {
    /* Shoot */
    if (VolcanoGame.ShootWait)
    {
      VolcanoGame.ShootWait--;
    }
    else
    {
      if (GetKeyState(SC_SPACE))
      {
        /* Shoot */
        if (VolcanoGame.Shots<VOLCANO_MAX_SHOTS)
        {
          VolcanoShoot();
        }
        VolcanoGame.ShootWait=VOLCANO_SHOOT_WAIT;
      }
    }
    /* Move Cannon */
    if (GetKeyState(SC_L_ARROW) && !GetKeyState(SC_R_ARROW))
    {
      if (!(VolcanoGame.Cannon.collision & COLL_LEFT))
      {
        VolcanoGame.Cannon.x-=3;
      }
    }
    else if (GetKeyState(SC_R_ARROW) && !GetKeyState(SC_L_ARROW))
    {
      if (!(VolcanoGame.Cannon.collision & COLL_RIGHT))
      {
        VolcanoGame.Cannon.x+=3;
      }
    }
  }
}

void VolcanoMove(void)
{
  uint32_t i,coll;

  /* Check volcano boundaries and collision */
  i=0;
  while (i<VOLCANO_MAX_VOLCANO)
  {
    if (VolcanoGame.Volcano[i].VolcanoSprite.visible)
    {
      coll=VolcanoGame.Volcano[i].VolcanoSprite.collision;
      if ((coll & COLL_RIGHT)!=0 && VolcanoGame.Volcano[i].vdir>0)
      {
        VolcanoGame.Volcano[i].vdir=-2;
        VolcanoGame.Volcano[i].VolcanoSprite.y+=16;
      }
      else if ((coll & COLL_LEFT)!=0 && VolcanoGame.Volcano[i].vdir<0)
      {
        VolcanoGame.Volcano[i].vdir=2;
        VolcanoGame.Volcano[i].VolcanoSprite.y+=16;
      }
      else if (coll & COLL_BOTTOM)
      {
        VolcanoGame.GameOver=1;
      }
      else if (coll & COLL_SPRITE)
      {
      }
      else
      {
        VolcanoGame.Volcano[i].VolcanoSprite.x+=VolcanoGame.Volcano[i].vdir;
      }
    }
    i++;
  }
}

void VolcanoSetup(void)
{
  uint32_t i;

  i=0;
  while (i<VOLCANO_MAX_VOLCANO)
  {
    VolcanoGame.Volcano[i].VolcanoSprite.x=SCREEN_WIDTH/2;
    VolcanoGame.Volcano[i].VolcanoSprite.y=VOLCANO_BOUND_TOP+16;
    VolcanoGame.Volcano[i].VolcanoSprite.collision=0;
    VolcanoGame.Volcano[i].VolcanoSprite.visible=0;
    VolcanoGame.Volcano[i].vdir=2;
    i++;
  }
  VolcanoGame.Volcanos=VOLCANO_MAX_VOLCANO;
}

void VolcanoGamePlay(void)
{
  uint16_t i;
  uint32_t rnd;

  /* Wait 25 frames */
  FrameWait(25);
  while (!VolcanoGame.GameOver)
  {
    /* Syncronize with frame count */
    FrameWait(1);
    VolcanoShotMove();
    if (!VolcanoGame.Volcanos)
    {
      /* Setup new volcano army */
      VolcanoSetup();
    }
    VolcanoCannonMove();
    VolcanoMove();
    if (GetKeyState(SC_ESC))
    {
      VolcanoGame.GameOver=1;
    }
  }
  /* Game Over, Remove shots */
  i=0;
  while (i<VOLCANO_MAX_SHOTS)
  {
    VolcanoGame.Shot[i].visible=0;
    i++;
  }
  ShowCursor(1);
  /* Show message box */
  SendEvent(VolcanoGame.hmsgbox,EVENT_ACTIVATE,0,VolcanoGame.hmsgbox->ID);
  VolcanoGame.DemoMode=1;
  /* Wait 2000 frames for a response */
  i=2000;
  while (i && VolcanoGame.DemoMode && !VolcanoGame.Quit)
  {
    FrameWait(1);
    i--;
  }
  SendEvent(VolcanoGame.hmsgbox,EVENT_SHOW,STATE_HIDDEN,VolcanoGame.hmsgbox->ID);
  ShowCursor(0);
  /* Remove aliens */
  i=0;
  while (i<VOLCANO_MAX_VOLCANO)
  {
    VolcanoGame.Volcano[i].VolcanoSprite.visible=0;
    i++;
  }
  /* Remove Cannon */
  VolcanoGame.Cannon.visible=0;
}

void VolcanoGameLoop(void)
{
  VolcanoGameInit();
  while (!VolcanoGame.Quit)
  {
    VolcanoGameSetup();
    VolcanoGame.Cannon.visible=1;
    VolcanoGamePlay();
  }
  DestroyWindow(VolcanoGame.hmsgbox);
  RemoveSprites();
  /* Clear screen */
  Cls();
}
