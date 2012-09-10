
/* Includes ------------------------------------------------------------------*/
#include "stm32f4_discovery.h"
#include "video.h"
#include "alien.h"

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/

extern volatile uint16_t FrameCount;// Frame counter

volatile int8_t Shooters;           // Number of spare shooters
volatile uint8_t Bombs;             // Number of active bombs
volatile uint8_t Aliens;            // Number of active aliens
volatile uint8_t Shots;             // Number of active shots
volatile DemoMode=1;                // Demo mode flag
volatile GameOver;                  // Game over flag

RECT AlienBound;                    // Game bounds
extern SPRITE* Sprites[];           // Max 64 sprites
extern WINDOW* Windows[];           // Max 4 windows
extern WINDOW* Focus;               // The windpw that has the keyboard focus
SPRITE Alien[MAX_ALIEN];            // Alien sprites
SPRITE Shooter;                     // Shooter sprite
SPRITE Bomb[MAX_BOMBS];             // Bomb sprites
SPRITE Shot[MAX_SHOTS];             // Shot sprites

ICON Shield;                        // Shield icon
volatile uint32_t RNDSeed;          // Random seed
WINDOW MsgBox;                      // Message box window
WINDOW Static1;                     // Static control
WINDOW Button1;                     // Button control

/* Private function prototypes -----------------------------------------------*/
uint32_t Random(uint32_t Range);    // Random generator

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
  rnd=RNDSeed-(RNDSeed/Range)*Range;
  return rnd;
}

void MsgBoxHandler(WINDOW* hwin,uint8_t event,uint16_t param,uint8_t ID)
{
  switch (event)
  {
    case EVENT_CHAR:
      if ((param & 0xFF)==13)
      {
        DemoMode=0;
      }
      break;
    default:
      DefWindowHandler(hwin,event,param,ID);
  }
}

void AlienGameSetup(void)
{
  int16_t i;

  Focus=0;
  Bombs=0;
  Aliens=32;
  Shots=0;
  GameOver=0;
  i=0;
  while (i<MAX_WINDOWS)
  {
    Windows[i]=0;
    i++;
  }
  Cls();
  /* Draw game frame */
  Rectangle(0,0,480,250,1);
  AlienBound.left=10;
  AlienBound.top=26;
  AlienBound.right=469;
  AlienBound.bottom=239;
  i=0;
  /* Setup bomb sprites */
  while (i<MAX_BOMBS)
  {
    Bomb[i].icon.wt=3;
    Bomb[i].icon.ht=8;
    Bomb[i].icon.icondata=*ShotIcon;
    Bomb[i].x=0;
    Bomb[i].y=0;
    Bomb[i].visible=0;
    Bomb[i].collision=0;
    Bomb[i].boundary=&AlienBound;
    Sprites[i]=&Bomb[i];
    i++;
  }
  /* Setup alien sprites */
  i=0;
  while (i<MAX_ALIEN)
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
    Alien[i].collision=0;
    Alien[i].boundary=&AlienBound;
    Alien[i].visible=1;
    Sprites[i+MAX_BOMBS]=&Alien[i];
    i++;
  }
  /* Setup shot sprites */
  i=0;
  while (i<MAX_SHOTS)
  {
    Shot[i].icon.wt=3;
    Shot[i].icon.ht=8;
    Shot[i].icon.icondata=*ShotIcon;
    Shot[i].x=0;
    Shot[i].y=0;
    Shot[i].visible=0;
    Shot[i].collision=0;
    Shot[i].boundary=&AlienBound;
    Sprites[i+MAX_BOMBS+MAX_ALIEN]=&Shot[i];
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
  Sprites[MAX_BOMBS+MAX_ALIEN+MAX_SHOTS]=&Shooter;
  /* Setup cursor */
  SetCursor(0);
  MoveCursor(240,125);
  ShowCursor(1);
  /* Draw spare shooters */
  Shooters=MAX_SHOOTERS;
  i=0;
  while (i<MAX_SHOOTERS)
  {
    DrawIcon(i*25+10,10,&Shooter.icon,1);
    i++;
  }
  /* Setup shield icon */
  Shield.wt=36;
  Shield.ht=16;
  Shield.icondata=*ShieldIcon;
  /* Draw shields */
  i=0;
  while (i<MAX_SHIELDS)
  {
    DrawIcon(i*125+40,SHIELD_TOP,&Shield,1);
    i++;
  }
  /* Setup the message box */
  Static1.hwin=&Static1;
  Static1.owner=&MsgBox;
  Static1.winclass=CLASS_STATIC;
  Static1.ID=1;
  Static1.x=4;
  Static1.y=20;
  Static1.wt=130-8;
  Static1.ht=20;
  Static1.state=STATE_VISIBLE;
  Static1.caplen=9;
  Static1.caption="Game Over";
  Static1.control[0]=0;
  Static1.handler=(void*)&DefWindowHandler;

  Button1.hwin=&Button1;
  Button1.owner=&MsgBox;
  Button1.winclass=CLASS_BUTTON;
  Button1.ID=2;
  Button1.x=130-75;
  Button1.y=64-25;
  Button1.wt=70;
  Button1.ht=20;
  Button1.state=STATE_VISIBLE;
  Button1.caplen=8;
  Button1.caption="New Game";
  Button1.control[0]=0;
  Button1.handler=(void*)&DefWindowHandler;

  MsgBox.hwin=&MsgBox;
  MsgBox.owner=0;
  MsgBox.winclass=CLASS_WINDOW;
  MsgBox.ID=0;
  MsgBox.x=(SCREEN_WIDTH-4)*8/2-130/2;
  MsgBox.y=SCREEN_HEIGHT/2-64/2;
  MsgBox.wt=130;
  MsgBox.ht=64;
  MsgBox.state=0;
  MsgBox.caplen=5;
  MsgBox.caption="Alien";
  MsgBox.control[0]=&Button1;
  MsgBox.control[1]=&Static1;
  MsgBox.handler=(void*)&MsgBoxHandler;
  Windows[0]=&MsgBox;
  SendEvent(MsgBox.hwin,EVENT_SHOW,STATE_HIDDEN,0);
}

void AlienGameLoop(void)
{
  int16_t dir,i,j,fc,coll;
  volatile int16_t sdir,slen,Points;
  volatile uint32_t rnd;
  char key;

  dir=2;
  sdir=3;
  slen=20;
  Points=0;
  DrawLargeDec(480-10-16*5,3,Points,1);
  while (!GameOver)
  {
    /* Syncronize with frame count */
    if (FrameCount!=fc)
    {
      if (FrameCount==(FrameCount/25)*25)
      {
        STM_EVAL_LEDToggle(LED3);
        rnd=Random(0xFF);
      }
      fc=FrameCount;
      /* Check shot boundary and collision */
      i=0;
      while (i<MAX_SHOTS)
      {
        coll=Shot[i].collision;
        if (coll & COLL_TOP)
        {
          Shot[i].visible=0;
          Shots--;
        }
        else if (coll & COLL_SPRITE)
        {
          /* Collision with a sprite */
          Shot[i].visible=0;
          Shots--;
          /* Find what the shot collided with */
          j=0;
          while (j<MAX_ALIEN)
          {
            if (Alien[j].visible)
            {
              if (Shot[i].x+3>=Alien[j].x && Shot[i].x<Alien[j].x+16)
              {
                if (Alien[j].y+16>Shot[i].y && Alien[j].y<=Shot[i].y)
                {
                  Alien[j].visible=0;
                  Aliens--;
                  Points+=5;
                  DrawLargeDec(480-10-16*5,3,Points,1);
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
          Shot[i].visible=0;
          Shots--;
          /* Make some damage to the shield */
          SetPixel(Shot[i].x-3,Shot[i].y,0);
          SetPixel(Shot[i].x-2,Shot[i].y,0);
          SetPixel(Shot[i].x-1,Shot[i].y,0);
          SetPixel(Shot[i].x,Shot[i].y,0);
          SetPixel(Shot[i].x+1,Shot[i].y,0);
          SetPixel(Shot[i].x+2,Shot[i].y,0);
          SetPixel(Shot[i].x+3,Shot[i].y,0);

          SetPixel(Shot[i].x-2,Shot[i].y-1,0);
          SetPixel(Shot[i].x-1,Shot[i].y-1,0);
          SetPixel(Shot[i].x,Shot[i].y-1,0);
          SetPixel(Shot[i].x+1,Shot[i].y-1,0);
          SetPixel(Shot[i].x+2,Shot[i].y-1,0);

          SetPixel(Shot[i].x-1,Shot[i].y-2,0);
          SetPixel(Shot[i].x,Shot[i].y-2,0);
          SetPixel(Shot[i].x+1,Shot[i].y-2,0);

          SetPixel(Shot[i].x,Shot[i].y-3,0);
        }
        Shot[i].y-=2;
        i++;
      }
      /* Setup new alien army */
      if (!Aliens)
      {
        i=0;
        while (i<32)
        {
          Alien[i].x=(i & 7)*25+10;
          Alien[i].y=(i>>3)*20+30;
          Alien[i].visible=1;
          i++;
        }
        Aliens=32;
      }
      /* Check bomb boundary and background collision */
      i=0;
      while (i<MAX_BOMBS)
      {
        if (Bomb[i].visible)
        {
          coll=Bomb[i].collision;
          if (coll & COLL_BOTTOM)
          {
            Bomb[i].visible=0;
            Bombs--;
          }
          else if (coll & COLL_BACKGROUND)
          {
            /* Collision with a shield */
            Bomb[i].visible=0;
            Bombs--;
            /* Make some damage to the shield */
            SetPixel(Bomb[i].x-3,Bomb[i].y+6,0);
            SetPixel(Bomb[i].x-2,Bomb[i].y+6,0);
            SetPixel(Bomb[i].x-1,Bomb[i].y+6,0);
            SetPixel(Bomb[i].x,Bomb[i].y+6,0);
            SetPixel(Bomb[i].x+1,Bomb[i].y+6,0);
            SetPixel(Bomb[i].x+2,Bomb[i].y+6,0);
            SetPixel(Bomb[i].x+3,Bomb[i].y+6,0);

            SetPixel(Bomb[i].x-3,Bomb[i].y+7,0);
            SetPixel(Bomb[i].x-2,Bomb[i].y+7,0);
            SetPixel(Bomb[i].x-1,Bomb[i].y+7,0);
            SetPixel(Bomb[i].x,Bomb[i].y+7,0);
            SetPixel(Bomb[i].x+1,Bomb[i].y+7,0);
            SetPixel(Bomb[i].x+2,Bomb[i].y+7,0);
            SetPixel(Bomb[i].x+3,Bomb[i].y+7,0);

            SetPixel(Bomb[i].x-2,Bomb[i].y+8,0);
            SetPixel(Bomb[i].x-1,Bomb[i].y+8,0);
            SetPixel(Bomb[i].x,Bomb[i].y+8,0);
            SetPixel(Bomb[i].x+1,Bomb[i].y+8,0);
            SetPixel(Bomb[i].x+2,Bomb[i].y+8,0);

            SetPixel(Bomb[i].x-1,Bomb[i].y+9,0);
            SetPixel(Bomb[i].x,Bomb[i].y+9,0);
            SetPixel(Bomb[i].x+1,Bomb[i].y+9,0);

            SetPixel(Bomb[i].x,Bomb[i].y+10,0);
          }
          Bomb[i].y+=2;
        }
        i++;
      }
      /* Drop a bomb */
      if (Bombs<MAX_BOMBS)
      {
        rnd=Random(31);
        while (!Alien[rnd].visible)
        {
          rnd++;
          rnd&=31;
        }
        /* Find what bomb sprite to use */
        i=0;
        while (i<MAX_BOMBS)
        {
          if (!Bomb[i].visible)
          {
            Bomb[i].x=Alien[rnd].x+8;
            Bomb[i].y=Alien[rnd].y+16;
            Bomb[i].visible=1;
            Bombs++;
            break;
          }
          i++;
        }
      }
      /* Check if shooter hit */
      if (Shooter.collision & COLL_SPRITE)
      {
        /* Find bomb(s) */
        i=0;
        while (i<MAX_BOMBS)
        {
          if (Bomb[i].y+8>220)
          {
            if (Bomb[i].x>=Shooter.x && Bomb[i].x<Shooter.x+20)
            {
              Bomb[i].visible=0;
              Bombs--;
            }
          }
          i++;
        }
        Shooters--;
        if (Shooters<0)
        {
          Shooter.visible=0;
          GameOver=1;
        }
        else
        {
          /* Remove spare shooter */
          DrawIcon(Shooters*25+10,10,&Shooter.icon,0);
        }
        Shooter.x=10;
        sdir=3;
        slen=10;
      }
      if (DemoMode)
      {
        GameOver=(GetKey()!=0) | GameOver;
        /* Move shooter */
        if (slen)
        {
          if ((sdir>0 && (Shooter.collision & COLL_RIGHT)) || (sdir<0 && (Shooter.collision & COLL_LEFT)))
          {
            sdir=-sdir;
          }
          Shooter.x+=sdir;
          slen--;
        }
        else
        {
          i=Random(100);
          if (i<5)
          {
            slen=Random(40);
            i=Random(9);
            if (i<5)
            {
              sdir=-3;
            }
            else
            {
              sdir=3;
            }
          }
        }
        /* Shoot */
        if (Shots<MAX_SHOTS)
        {
          i=Random(100);
          if (i<5)
          {
            i=0;
            while(i<MAX_SHOTS)
            {
              if (!Shot[i].visible)
              {
                Shot[i].x=Shooter.x+10;
                Shot[i].y=216;
                Shot[i].visible=1;
                Shots++;
                break;
              }
              i++;
            }
          }
        }
      }
      else
      {
        key=GetKey();
        switch (key)
        {
          case 0:
            break;
          case 0x20:
            /* Shoot */
            if (Shots<MAX_SHOTS)
            {
              i=0;
              while(i<MAX_SHOTS)
              {
                if (!Shot[i].visible)
                {
                  Shot[i].x=Shooter.x+10;
                  Shot[i].y=216;
                  Shot[i].visible=1;
                  Shots++;
                  break;
                }
                i++;
              }
            }
            break;
          default:
DrawHex(50,0,key,1);
        }
      }
      /* Check alien boundaries, there is no need to check collision */
      i=0;
      coll=0;
      while (i<MAX_ALIEN)
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
          while (i<MAX_ALIEN)
          {
            Alien[i].y+=4;
            i++;
          }
          dir=-dir;
        }
        else
        {
          i=0;
          while (i<MAX_ALIEN)
          {
            if (!(FrameCount & 15))
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
  /* Remove shots */
  i=0;
  while (i<MAX_SHOTS)
  {
    Shot[i].visible=0;
    i++;
  }
  /* Remove bombs */
  i=0;
  while (i<MAX_BOMBS)
  {
    Bomb[i].visible=0;
    i++;
  }
  SendEvent(MsgBox.hwin,EVENT_SHOW,STATE_VISIBLE,0);
  SendEvent(Button1.hwin,EVENT_GOTFOCUS,0,0);
  DemoMode=1;
  /* Wait 1000 frames */
  fc=FrameCount+1000;
  while (fc!=FrameCount && DemoMode);
}
