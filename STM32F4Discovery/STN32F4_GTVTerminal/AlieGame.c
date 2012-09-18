
/* Includes ------------------------------------------------------------------*/
#include "aliengame.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* External variables --------------------------------------------------------*/
extern volatile uint16_t FrameCount;  // Frame counter
extern SPRITE* Sprites[];             // Max 64 sprites
extern WINDOW WinColl[MAX_WINCOLL];
extern WINDOW* Windows[MAX_WINDOWS+1];


/* Private variables ---------------------------------------------------------*/
ALIEN_GAME AlienGame;

/* Private function prototypes -----------------------------------------------*/
/* Private functions ---------------------------------------------------------*/

void AlienMsgBoxHandler(WINDOW* hwin,uint8_t event,uint32_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      if (param==0x0D && ID==4)
      {
        /* New Game */
        AlienGame.DemoMode=0;
        break;
      }
      else if (param==0x0D && ID==3)
      {
        /* Quit */
        AlienGame.Quit=1;
        break;
      }
    default:
      DefWindowHandler(hwin,event,param,ID);
      break;
  }
}

void AlenGameInit(void)
{
  uint32_t i,j;

  /* Create message box */
  AlienGame.hmsgbox=CreateWindow(0,CLASS_WINDOW,1,(SCREEN_WIDTH-160)/2,(SCREEN_HEIGHT-64)/2,160,64,"Alien\0");
  CreateWindow(AlienGame.hmsgbox,CLASS_STATIC,2,4,15,160-8,20,"GameOver\0");
  CreateWindow(AlienGame.hmsgbox,CLASS_BUTTON,3,5,64-25,70,20,"Quit\0");
  CreateWindow(AlienGame.hmsgbox,CLASS_BUTTON,4,160-75,64-25,70,20,"New Game\0");
  SetHandler(AlienGame.hmsgbox,&AlienMsgBoxHandler);

  /* Setup game boundary */
  AlienGame.AlienBound.left=ALIEN_BOUND_LEFT;
  AlienGame.AlienBound.top=ALIEN_BOUND_TOP;
  AlienGame.AlienBound.right=ALIEN_BOUND_RIGHT;
  AlienGame.AlienBound.bottom=ALIEN_BOUND_BOTTOM;
  /* Setup bomb sprites */
  i=0;
  while (i<ALIEN_MAX_BOMBS)
  {
    AlienGame.Bomb[i].icon.wt=3;
    AlienGame.Bomb[i].icon.ht=8;
    AlienGame.Bomb[i].icon.icondata=*AlienShotIcon;
    AlienGame.Bomb[i].x=0;
    AlienGame.Bomb[i].y=0;
    AlienGame.Bomb[i].visible=0;
    AlienGame.Bomb[i].collision=0;
    AlienGame.Bomb[i].boundary=&AlienGame.AlienBound;
    Sprites[i]=&AlienGame.Bomb[i];
    i++;
  }
  /* Setup alien sprites */
  j=0;
  while (j<ALIEN_ALIEN_ROWS)
  {
    i=0;
    while (i<ALIEN_ALIEN_COLS)
    {
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].icon.wt=16;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].icon.ht=16;
      if (i & 1)
      {
        AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].icon.icondata=*Alien2Icon;
      }
      else
      {
        AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].icon.icondata=*Alien1Icon;
      }
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].x=i*25+10;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].y=j*20+30;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].collision=0;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].boundary=&AlienGame.AlienBound;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].visible=0;
      Sprites[j*ALIEN_ALIEN_COLS+i+ALIEN_MAX_BOMBS]=&AlienGame.Alien[j*ALIEN_ALIEN_COLS+i];
      i++;
    }
    j++;
  }
  /* Setup shot sprites */
  i=0;
  while (i<ALIEN_MAX_SHOTS)
  {
    AlienGame.Shot[i].icon.wt=3;
    AlienGame.Shot[i].icon.ht=8;
    AlienGame.Shot[i].icon.icondata=*AlienShotIcon;
    AlienGame.Shot[i].x=0;
    AlienGame.Shot[i].y=0;
    AlienGame.Shot[i].visible=0;
    AlienGame.Shot[i].collision=0;
    AlienGame.Shot[i].boundary=&AlienGame.AlienBound;
    Sprites[i+ALIEN_MAX_BOMBS+ALIEN_MAX_ALIEN]=&AlienGame.Shot[i];
    i++;
  }
  /* Setup Cannon sprite */
  AlienGame.Cannon.icon.wt=20;
  AlienGame.Cannon.icon.ht=16;
  AlienGame.Cannon.icon.icondata=*AlienCannonIcon;
  AlienGame.Cannon.x=10;
  AlienGame.Cannon.y=ALIEN_BOUND_BOTTOM-16;
  AlienGame.Cannon.visible=0;
  AlienGame.Cannon.collision=0;
  AlienGame.Cannon.boundary=&AlienGame.AlienBound;
  Sprites[ALIEN_MAX_BOMBS+ALIEN_MAX_ALIEN+ALIEN_MAX_SHOTS]=&AlienGame.Cannon;
  AlienGame.DemoMode=0;
  AlienGame.Quit=0;
}

void AlienGameSetup(void)
{
  int16_t i,j,wtshield;

  AlienGame.adir=2;
  AlienGame.sdir=3;
  AlienGame.slen=10;
  AlienGame.Points=0;
  AlienGame.Bombs=0;
  AlienGame.Aliens=ALIEN_MAX_ALIEN;
  AlienGame.Cannons=ALIEN_MAX_CANNONS;
  AlienGame.Shots=0;
  AlienGame.GameOver=0;
  Cls();
  /* Draw game frame */
  Rectangle(0,0,SCREEN_WIDTH,SCREEN_HEIGHT,1);
  /* Hide cursor */
  ShowCursor(0);
  /* Draw spare Cannons */
  i=0;
  while (i<ALIEN_MAX_CANNONS)
  {
    DrawIcon(i*25+10,10,&AlienGame.Cannon.icon,1);
    i++;
  }
  /* Setup shield icon */
  AlienGame.Shield.wt=36;
  AlienGame.Shield.ht=16;
  AlienGame.Shield.icondata=*AlienShieldIcon;
  /* Draw shields */
  wtshield=SCREEN_WIDTH/(ALIEN_MAX_SHIELDS+1);
  i=0;
  while (i<ALIEN_MAX_SHIELDS)
  {
    i++;
    DrawIcon(i*wtshield-36/2,ALIEN_SHIELD_TOP,&AlienGame.Shield,1);
  }
  DrawLargeDec(SCREEN_WIDTH-10-16*5,3,AlienGame.Points,1);
}

void BombDrop(void)
{
  uint32_t i,rnd;

  /* Drop a bomb */
  if (AlienGame.Bombs<ALIEN_MAX_BOMBS)
  {
    rnd=Random(ALIEN_MAX_ALIEN-1);
    while (!AlienGame.Alien[rnd].visible)
    {
      rnd++;
      if (rnd==ALIEN_MAX_ALIEN)
      {
        rnd=0;
      }
    }
    /* Find what bomb sprite to use */
    i=0;
    while (i<ALIEN_MAX_BOMBS)
    {
      if (!AlienGame.Bomb[i].visible)
      {
        AlienGame.Bomb[i].x=AlienGame.Alien[rnd].x+8;
        AlienGame.Bomb[i].y=AlienGame.Alien[rnd].y+16;
        AlienGame.Bomb[i].visible=1;
        AlienGame.Bombs++;
        break;
      }
      i++;
    }
  }
}

void AlienShieldDamage(x,y,dir)
{
  uint32_t xp,yp,i;

  yp=y;
  xp=x-3;;
  i=0;
  while (i<6)
  {
    SetPixel(xp+i,yp,0);
    i++;
  }
  yp+=dir;
  xp=x-2;;
  i=0;
  while (i<4)
  {
    SetPixel(xp+i,yp,0);
    i++;
  }
  yp+=dir;
  xp=x-1;;
  i=0;
  while (i<2)
  {
    SetPixel(xp+i,yp,0);
    i++;
  }
  yp+=dir;
  SetPixel(x,yp,0);
}

void BombMove(void)
{
  uint32_t i,coll;

  /* Check bomb boundary and background collision */
  i=0;
  while (i<ALIEN_MAX_BOMBS)
  {
    if (AlienGame.Bomb[i].visible)
    {
      coll=AlienGame.Bomb[i].collision;
      if (coll & COLL_BOTTOM)
      {
        AlienGame.Bomb[i].visible=0;
        AlienGame.Bombs--;
      }
      else if (coll & COLL_BACKGROUND)
      {
        /* Collision with a shield */
        AlienGame.Bomb[i].visible=0;
        AlienGame.Bombs--;
        /* Make some damage to the shield */
        AlienShieldDamage(AlienGame.Bomb[i].x+1,AlienGame.Bomb[i].y+6,1);
      }
      AlienGame.Bomb[i].y+=2;
    }
    i++;
  }
}

void ShotShoot(void)
{
  uint32_t i;

  i=0;
  while(i<ALIEN_MAX_SHOTS)
  {
    if (!AlienGame.Shot[i].visible)
    {
      AlienGame.Shot[i].x=AlienGame.Cannon.x+10;
      AlienGame.Shot[i].y=216;
      AlienGame.Shot[i].visible=1;
      AlienGame.Shots++;
      break;
    }
    i++;
  }
}

void ShotMove(void)
{
  uint32_t i,j,coll;

  /* Check shot boundary and collision */
  i=0;
  while (i<ALIEN_MAX_SHOTS)
  {
    if (AlienGame.Shot[i].visible)
    {
      coll=AlienGame.Shot[i].collision;
      if (coll & COLL_TOP)
      {
        AlienGame.Shot[i].visible=0;
        AlienGame.Shots--;
      }
      else if (coll & COLL_SPRITE)
      {
        /* Collision with a sprite */
        AlienGame.Shot[i].visible=0;
        AlienGame.Shots--;
        /* Find what the shot collided with */
        j=0;
        while (j<ALIEN_MAX_ALIEN)
        {
          if (AlienGame.Alien[j].visible)
          {
            if (AlienGame.Shot[i].x+3>AlienGame.Alien[j].x && AlienGame.Shot[i].x<AlienGame.Alien[j].x+16)
            {
              if (AlienGame.Shot[i].y+8>AlienGame.Alien[j].y && AlienGame.Shot[i].y<AlienGame.Alien[j].y+16)
              {
                AlienGame.Alien[j].visible=0;
                AlienGame.Aliens--;
                AlienGame.Points+=5;
                DrawLargeDec(SCREEN_WIDTH-10-16*5,3,AlienGame.Points,1);
                break;
              }
            }
          }
          j++;
        }
        j=0;
        while (j<ALIEN_MAX_BOMBS)
        {
          if (AlienGame.Bomb[j].visible)
          {
            if (AlienGame.Shot[i].x+3>AlienGame.Bomb[j].x && AlienGame.Shot[i].x<AlienGame.Bomb[j].x+3)
            {
              if (AlienGame.Shot[i].y+8>AlienGame.Bomb[j].y && AlienGame.Shot[i].y<AlienGame.Bomb[j].y+8)
              {
                AlienGame.Bomb[j].visible=0;
                AlienGame.Bombs--;
                AlienGame.Points++;
                DrawLargeDec(SCREEN_WIDTH-10-16*5,3,AlienGame.Points,1);
                break;
              }
            }
          }
          j++;
        }
      }
      else if (coll & COLL_BACKGROUND)
      {
        /* Collision with a shield */
        AlienGame.Shot[i].visible=0;
        AlienGame.Shots--;
        /* Make some damage to the shield */
        AlienShieldDamage(AlienGame.Shot[i].x+1,AlienGame.Shot[i].y+1,-1);
      }
      else
      {
        AlienGame.Shot[i].y-=2;
      }
    }
    i++;
  }
}

void CannonHit(void)
{
  uint32_t i;

  /* Check if Cannon hit */
  if (AlienGame.Cannon.collision & COLL_SPRITE)
  {
    /* Find bomb(s) */
    i=0;
    while (i<ALIEN_MAX_BOMBS)
    {
      if (AlienGame.Bomb[i].y+8>220)
      {
        if (AlienGame.Bomb[i].x>=AlienGame.Cannon.x && AlienGame.Bomb[i].x<AlienGame.Cannon.x+20)
        {
          AlienGame.Bomb[i].visible=0;
          AlienGame.Bombs--;
        }
      }
      i++;
    }
    AlienGame.Cannons--;
    if (AlienGame.Cannons<0)
    {
      AlienGame.Cannon.visible=0;
      AlienGame.GameOver=1;
    }
    else
    {
      /* Remove spare Cannon */
      DrawIcon(AlienGame.Cannons*25+10,10,&AlienGame.Cannon.icon,0);
    }
    AlienGame.Cannon.x=10;
    AlienGame.sdir=3;
    AlienGame.slen=10;
  }
}

void CannonMove(void)
{
  uint32_t i;

  if (AlienGame.DemoMode)
  {
    AlienGame.GameOver=(GetKeyState(SC_SPACE)) | AlienGame.GameOver;
    /* Move Cannon */
    if (AlienGame.slen)
    {
      if ((AlienGame.sdir>0 && (AlienGame.Cannon.collision & COLL_RIGHT)) || (AlienGame.sdir<0 && (AlienGame.Cannon.collision & COLL_LEFT)))
      {
        AlienGame.sdir=-AlienGame.sdir;
      }
      AlienGame.Cannon.x+=AlienGame.sdir;
      AlienGame.slen--;
    }
    else
    {
      i=Random(100);
      if (i<5)
      {
        AlienGame.slen=Random(40);
        i=Random(9);
        if (i<5)
        {
          AlienGame.sdir=-3;
        }
        else
        {
          AlienGame.sdir=3;
        }
      }
    }
    /* Shoot */
    if (AlienGame.Shots<ALIEN_MAX_SHOTS)
    {
      i=Random(100);
      if (i<5)
      {
        ShotShoot();
      }
    }
  }
  else
  {
    /* Shoot */
    if (AlienGame.ShootWait)
    {
      AlienGame.ShootWait--;
    }
    else
    {
      if (GetKeyState(SC_SPACE))
      {
        /* Shoot */
        if (AlienGame.Shots<ALIEN_MAX_SHOTS)
        {
          ShotShoot();
        }
        AlienGame.ShootWait=ALIEN_SHOOT_WAIT;
      }
    }
    /* Move Cannon */
    if (GetKeyState(SC_L_ARROW) && !GetKeyState(SC_R_ARROW))
    {
      if (!(AlienGame.Cannon.collision & COLL_LEFT))
      {
        AlienGame.Cannon.x-=3;
      }
    }
    else if (GetKeyState(SC_R_ARROW) && !GetKeyState(SC_L_ARROW))
    {
      if (!(AlienGame.Cannon.collision & COLL_RIGHT))
      {
        AlienGame.Cannon.x+=3;
      }
    }
  }
}

void AlienSetup(void)
{
  uint32_t i,j;

  j=0;
  while (j<ALIEN_ALIEN_ROWS)
  {
    i=0;
    while (i<ALIEN_ALIEN_COLS)
    {
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].x=i*25+10;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].y=j*20+30;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].collision=0;
      AlienGame.Alien[j*ALIEN_ALIEN_COLS+i].visible=1;
      i++;
    }
    j++;
  }
  AlienGame.Aliens=ALIEN_MAX_ALIEN;
}

void AlienMove(void)
{
  uint32_t i,coll;

  /* Check alien boundaries, there is no need to check collision */
  i=0;
  coll=0;
  while (i<ALIEN_MAX_ALIEN)
  {
    coll|=AlienGame.Alien[i].collision;
    i++;
  }
  if (!(coll & COLL_BOTTOM))
  {
    if ((AlienGame.adir>0 && (coll & COLL_RIGHT)) || (AlienGame.adir<0 && (coll & COLL_LEFT)))
    {
      /* Move aliens down and change direction */
      i=0;
      while (i<ALIEN_MAX_ALIEN)
      {
        AlienGame.Alien[i].y+=4;
        i++;
      }
      AlienGame.adir=-AlienGame.adir;
    }
    else
    {
      i=0;
      while (i<ALIEN_MAX_ALIEN)
      {
        if (AlienGame.Alien[i].visible)
        {
          if (!(FrameCount & 15))
          {
            /* Change alien icon */
            if (AlienGame.Alien[i].icon.icondata==*Alien1Icon)
            {
              AlienGame.Alien[i].icon.icondata=*Alien2Icon;
            }
            else
            {
              AlienGame.Alien[i].icon.icondata=*Alien1Icon;
            }
          }
          /* Move alien left or right */
          AlienGame.Alien[i].x+=AlienGame.adir;
        }
        i++;
      }
    }
  }
  else
  {
    AlienGame.GameOver=1;
  }
}

void AlienGamePlay(void)
{
  uint16_t i;
  uint32_t rnd;

  AlienSetup();
  /* Wait 25 frames */
  FrameWait(25);
  while (!AlienGame.GameOver)
  {
    /* Syncronize with frame count */
    FrameWait(1);
    ShotMove();
    if (!AlienGame.Aliens)
    {
      /* Setup new alien army */
      AlienSetup();
    }
    BombMove();
    BombDrop();
    CannonHit();
    CannonMove();
    AlienMove();
    if (GetKeyState(SC_ESC))
    {
      AlienGame.GameOver=1;
    }
  }
  /* Game Over, Remove shots */
  i=0;
  while (i<ALIEN_MAX_SHOTS)
  {
    AlienGame.Shot[i].visible=0;
    i++;
  }
  /* Remove bombs */
  i=0;
  while (i<ALIEN_MAX_BOMBS)
  {
    AlienGame.Bomb[i].visible=0;
    i++;
  }
  ShowCursor(1);
  /* Show message box */
  SendEvent(AlienGame.hmsgbox,EVENT_ACTIVATE,0,AlienGame.hmsgbox->ID);
  AlienGame.DemoMode=1;
  /* Wait 2000 frames for a response */
  i=2000;
  while (i && AlienGame.DemoMode && !AlienGame.Quit)
  {
    FrameWait(1);
    i--;
  }
  SendEvent(AlienGame.hmsgbox,EVENT_SHOW,STATE_HIDDEN,AlienGame.hmsgbox->ID);
  ShowCursor(0);
  /* Remove aliens */
  i=0;
  while (i<ALIEN_MAX_ALIEN)
  {
    AlienGame.Alien[i].visible=0;
    i++;
  }
  /* Remove Cannon */
  AlienGame.Cannon.visible=0;
}

void AlienGameLoop(void)
{
  AlenGameInit();
  while (!AlienGame.Quit)
  {
    AlienGameSetup();
    AlienGame.Cannon.visible=1;
    AlienGamePlay();
  }
  DestroyWindow(AlienGame.hmsgbox);
  RemoveSprites();
  /* Clear screen */
  Cls();
}
