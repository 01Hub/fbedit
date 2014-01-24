/*******************************************************************************
* File Name          : main.c
* Author             : KetilO
* Version            : V2.0.0
* Date               : 11/18/2013
* Description        : Main program body
********************************************************************************

/* Includes ------------------------------------------------------------------*/
#include "stm32f10x_lib.h"

/* Private define ------------------------------------------------------------*/
// Uncomment the clock speed you will be using
//#define STM32Clock24MHz
//#define STM32Clock28MHz
//#define STM32Clock32MHz
#define STM32Clock40MHz
//#define STM32Clock48MHz
//#define STM32Clock56MHz

#define MAXECHO           ((u16)512)
#define MAXGPS            ((u16)512)
#define MAXBLUETOOTH      ((u16)512)
#define ADC1_ICDR_Address ((u32)0x4001243C)

typedef struct
{
  vu8 Start;                                    // 0x20000000 0=Wait/Done, 1=Start, 99=In progress
  u8 PingPulses;                                // 0x20000001 Number of ping pulses (0-255)
  u8 PingTimer;                                 // 0x20000002 TIM1 auto reload value, ping frequency
  u8 RangeInx;                                  // 0x20000003 Current range index
  u16 PixelTimer;                               // 0x20000004 TIM2 auto reload value, sample rate
  u16 GainInit[18];                             // 0x20000006 Gain setup array, first half word is initial gain
  u16 GainArray[MAXECHO];                       // 0x2000002A Gain array
  vu16 EchoIndex;                               // 0x2000042A Current index into EchoArray
  vu16 GPSHead;                                 // 0x2000042E GPSArray head, index into GPSArray
  vu16 GPSTail;                                 // 0x20000430 GPSArray tail, index into GPSArray
  u8 GPSArray[MAXGPS];                          // 0x20000432 GPS array, received GPS NMEA 0183 messages
}STM32_SonarTypeDef;

typedef struct
{
	u8 SateliteID;								                // Satelite ID
	u8 Elevation;								                  // Elevation in degrees (0-90)
	u16 Azimuth;								                  // Azimuth in degrees (0-359)
	u8 SNR;									                      // Signal strenght	(0-50, 0 not tracked) 
	u8 Fixed;									                    // TRUE if used in fix
} STM32_SateliteTypeDef;

typedef struct
{
	u8 fixquality;                                // Fix quality
	u8 nsat;                                      // Number of satelites tracked
	u16 hdop;									                    // Horizontal dilution of position * 10
	u16 vdop;									                    // Vertical dilution of position * 10
	u16 pdop;									                    // Position dilution of position * 10
	u16 alt;									                    // Altitude in meters
} STM32_AltitudeTypeDef;

typedef struct
{
  u8 Version;                                   // 201
  u8 PingPulses;                                // Number of pulses in a ping (0 to 128)
  u16 GainSet;                                  // Gain set level (0 to 4095)
  u16 SoundSpeed;                               // Speed of sound in water
  u16 ADCBattery;                               // Battery level
  u16 ADCWaterTemp;                             // Water temprature
  u16 ADCAirTemp;                               // Air temprature
  u32 iTime;                                    // UTC Dos file time. 2 seconds resolution
  u32 iLon;                                     // Longitude, integer
  u32 iLat;                                     // Lattitude, integer
  u16 iSpeed;                                   // Speed in kts
  u16 iBear;                                    // Bearing in degrees
  STM32_SateliteTypeDef Satelite[12];           // 12 Satelites
  STM32_AltitudeTypeDef Altitude;               // Alttude + more
  u8 EchoArray[MAXECHO];                        // Echo array
} STM32_SonarDataTypeDef;

/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
static STM32_SonarTypeDef STM32_Sonar;          // 0x20000000
static STM32_SonarDataTypeDef STM32_SonarData;
vu8 BlueLED;                                    // Current state of the blue led
vu16 Ping;                                      // Value to output to PA1 and PA2 pins
vu8 Setup;                                      // Setup mode
/* Set GPS baudrate to 9600 */
const u8 GPSBaud[]="$PSRF100,1,9600,8,1,0*0D\r\n\0";
/* GPS Initialization */
const u8 GPSInit[]="$PSRF103,04,00,01,00*20\r\n$PSRF103,03,00,05,00*23\r\n$PSRF103,00,00,05,00*20\r\n$PSRF103,02,00,05,00*22\r\n$PSRF103,01,00,00,00*24\r\n$PSRF103,05,00,00,00*20\r\n\0";
/* GPS Reset */
const u8 GPSReset[]="$PSRF104,66.317270,14.196690,0,96000,237759,922,12,4*2A\r\n\0";
/* NMEA Messages */
const u8 szGPRMC[]="$GPRMC\0";
const u8 szGPGSV[]="$GPGSV\0";
const u8 szGPGGA[]="$GPGGA\0";
const u8 szGPGSA[]="$GPGSA\0";

/* Private function prototypes -----------------------------------------------*/
void RCC_Configuration(void);
void GPIO_Configuration(void);
void NVIC_Configuration(void);
void ADC_Startup(void);
void ADC_Configuration(void);
void TIM1_Configuration(void);
void TIM2_Configuration(void);
void TIM3_Configuration(void);
void USART1_Configuration(u32 Baud);
void USART3_Configuration(u32 Baud);
u16 GetADCValue(u8 Channel);
void USART1_puts(char *str);
void USART3_putdata(u8 *dat,u16 len);
void GainSetup(void);
void TrimOutput(void);
void GetEcho(void);
vu32 ParseGPS(void);
u8 StrCmp(u8 *str,u8 *comp);
void ParseGPRMC(vu16 GPSStart);
void ParseGPGSV(vu16 GPSStart);
void ParseGPGGA(vu16 GPSStart);
void ParseGPGSA(vu16 GPSStart);
vu16 ParseSkip(vu16 GPSStart);
vu16 ParseGetItem(vu16 GPSStart,u8 *item);
vu32 ParseLat(u8 *item);
vu32 ParseLon(u8 *item);
vu32 ParseDecToBin(u8 *item);

/* Private functions ---------------------------------------------------------*/

/*******************************************************************************
* Function Name  : main
* Description    : Main program
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
int main(void)
{
  u32 i;
  u32 nrec;
  u8 *ptr;
  STM32_SonarData.Version = 201;
  /* System clocks configuration */
  RCC_Configuration();
  /* NVIC configuration */
  NVIC_Configuration();
  /* GPIO configuration */
  GPIO_Configuration();
  /* TIM1 configuration */
  TIM1_Configuration();
  /* TIM3 configuration */
  TIM3_Configuration();
  /* ADC1 configuration */
  ADC_Startup();
  /* ADC1 injected channel configuration */
  ADC_Configuration();
  /* Enable DAC channel1 and channel2, buffered output */
  DAC->CR = 0x10001;
  /* Set the DAC channel1 to output lowest gain */
  DAC->DHR12R1 = (u16)0x0;
  /* Set the DAC channel2 to output middle output trim */
  DAC->DHR12R2 = (u16)0x400;
  /* Setup USART1 4800 baud */
  USART1_Configuration(4800);
  /* Setup USART3 115200 baud */
  USART3_Configuration(115200);
  /* Wait until GPS module has started up */
  i = 20000000;
  while (i--);
  USART1_puts((char*) GPSBaud);
  i = 2000000;
  while (i--);
  /* Set USART1 baudrate to 9600 */
  USART1_Configuration(9600);
  i = 2000000;
  while (i--);
  USART1_puts((char*) GPSInit);

  Setup = 0;
  if (GPIO_ReadInputDataBit(GPIOA,GPIO_Pin_0))
  {
    /* Enable TIM3 */
    TIM_Cmd(TIM3, ENABLE);
    Setup = 1;
  }
  STM32_SonarData.iLat = 66317270;
  STM32_SonarData.iLon = 14196690;
  while (1)
  {
    nrec=0;
    ptr = (u8 *)&STM32_Sonar;
    while (nrec < 0x2A)
    {
      i = 2000000;
      while((USART3->SR & USART_FLAG_RXNE) == 0 && i != 0)
      {
        i--;
      }
      if (i == 0)
      {
        break;
      }
      ptr[nrec] = (u8)USART3->DR;
      nrec++;
    }
    if (nrec == 0x2A)
    {
      if (STM32_Sonar.Start == 1)
      {
        /* Toggle blue led */
        BlueLED ^= 1;
        GPIO_WriteBit(GPIOC, GPIO_Pin_8, BlueLED);
        /* Setup gain array */
        GainSetup();
        /* Clear the echo array */
        i = 1;
        while (i < MAXECHO)
        {
          STM32_SonarData.EchoArray[i] = 0;
          i++;
        }
        /* Read battery */
        STM32_SonarData.ADCBattery = GetADCValue(ADC_Channel_14);
        /* Read water temprature */
        STM32_SonarData.ADCWaterTemp = GetADCValue(ADC_Channel_6);
        /* Read air temprature */
        STM32_SonarData.ADCAirTemp = GetADCValue(ADC_Channel_7);
        if (Setup)
        {
          /* No ping in setup mode */
          STM32_Sonar.PingPulses = 0;
        }
        else
        {
          TrimOutput();
        }
        /* Enable ADC injected channel */
        ADC_AutoInjectedConvCmd(ADC1, ENABLE);
        /* Set the TIM1 Autoreload value */
        TIM1->ARR = STM32_Sonar.PingTimer;
        /* Set the TIM3 Autoreload value */
        TIM3->ARR = STM32_Sonar.PingTimer*2+1;
        /* Reset TIM1 count */
        TIM1->CNT = 0;
        /* Set TIM1 repetirion counter */
        TIM1->RCR = 0;
        /* Reset echo index */
        STM32_Sonar.EchoIndex = 0;
        /* Init Ping */
        Ping = 0x2;
        /* Disable the USART1 Receive interrupt: this interrupt is generated when the 
           USART1 receive data register is not empty */
        USART_ITConfig(USART1, USART_IT_RXNE, DISABLE);
        /* Enable TIM1 */
        TIM_Cmd(TIM1, ENABLE);
        /* Get the Echo array */
        GetEcho();
        /* Store the current range as the first byte in the echo array */
        STM32_SonarData.EchoArray[0] = STM32_Sonar.RangeInx;
        /* Done, Disable TIM2 */
        TIM2->CR1 = 0;
        /* Disable ADC injected channel */
        ADC_AutoInjectedConvCmd(ADC1, DISABLE);
        /* Set the DAC to output lowest gain */
        DAC->DHR12R1 = (u16)0x0;
        /* Parse the GPS NMEA data */
        while (ParseGPS() != 0xFFFF)
        {
        }
        /* Send the data to bluetooth module */
        USART3_putdata((u8 *)&STM32_SonarData,622);
      }
      else if (STM32_Sonar.Start == 2)
      {
        /* Send NMEA Reset */
        USART1_puts((char*) GPSReset);
      }
      else if (STM32_Sonar.Start == 3)
      {
        /* Send NMEA Buffer */
        USART3_putdata((u8 *)&STM32_Sonar.GPSHead,MAXGPS + 4);
      }
    }
    i = 1000;
    while (i--);
  }
}

void TrimOutput(void)
{
  u16 Trim;
  u16 TrimAdd;
  vu32 i;

  /* Trim echo output to near zero */
  Trim = (u16)0x400;
  TrimAdd = (u16)0x200;
  while (TrimAdd)
  {
    DAC->DHR12R2 = Trim;
    i = 10000;
    while (i--);
    if (GetADCValue(ADC_Channel_3)>32)
    {
      Trim += TrimAdd;
    }
    else
    {
      Trim -= TrimAdd;
    }
    TrimAdd = TrimAdd / 2;
  }
}

u8 StrCmp(u8 *str,u8 *comp)
{
  u8 c;
  while ((c = *comp++))
  {
    c = c - *str;
    if (c)
    {
      break;
    }
    *str++;
  }
  return c;
}

vu16 ParseSkip(vu16 GPSStart)
{
  while (STM32_Sonar.GPSArray[GPSStart] != 0x2C && STM32_Sonar.GPSArray[GPSStart] != 0x0D)
  {
    GPSStart++;
    GPSStart &= (MAXGPS - 1);
  }
  if (STM32_Sonar.GPSArray[GPSStart] == 0x2C)
  {
    GPSStart++;
    GPSStart &= (MAXGPS - 1);
  }
  return GPSStart;
}

vu16 ParseGetItem(vu16 GPSStart,u8 *item)
{
  while (STM32_Sonar.GPSArray[GPSStart] != 0x2C && STM32_Sonar.GPSArray[GPSStart] != 0x0D)
  {
    *item = STM32_Sonar.GPSArray[GPSStart];
    item++;
    GPSStart++;
    GPSStart &= (MAXGPS - 1);
  }
  *item = 0;
  if (STM32_Sonar.GPSArray[GPSStart] == 0x2C)
  {
    GPSStart++;
    GPSStart &= (MAXGPS - 1);
  }
  return GPSStart;
}

vu32 ParseDecToBin(u8 *item)
{
  u8 c;
  vu32 val = 0;
  while (c = *item++)
  {
    if (c != 0x2E)
    {
      val *= 10;
      val += (c & 0x0F);
    }
  }
  return val;
}

vu32 ParseLat(u8 *item)
{
  vu32 val;
  val = (ParseDecToBin((u8 *)&item[2]) * 100) / 60;
  item[2] = 0;
  return ParseDecToBin((u8 *)item) * 1000000 + val;
}

vu32 ParseLon(u8 *item)
{
  vu32 val;
  val = (ParseDecToBin((u8 *)&item[3]) * 100) / 60;
  item[3] = 0;
  return ParseDecToBin((u8 *)item) * 1000000 + val;
}

/*
eg3. $GPRMC,220516,A,5133.82,N,00042.24,W,173.8,231.8,130694,004.2,W
              1    2    3    4    5     6    7    8      9     10  11

      1   220516     Time Stamp
      2   A          validity - A-ok, V-invalid
      3   5133.82    current Latitude
      4   N          North/South
      5   00042.24   current Longitude
      6   W          East/West
      7   173.8      Speed in knots
      8   231.8      True course
      9   130694     Date Stamp
      10  004.2      Variation
      11  W          East/West
*/
void ParseGPRMC(vu16 GPSStart)
{
  u8 itemtime[32];
  u8 item[32];
  GPSStart = ParseSkip(GPSStart);
  GPSStart = ParseGetItem(GPSStart,(u8 *)&itemtime);  // Time Stamp
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // validity - A-ok, V-invalid
  if (item[0] == 'A')
  {
    if (STM32_SonarData.Altitude.fixquality == 0)
    {
      STM32_SonarData.Altitude.fixquality = 1;
    }
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // current Latitude
    STM32_SonarData.iLat = ParseLat((u8 *)&item);
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // North/South
    if (item[0] == 'S')
    {
      STM32_SonarData.iLat = -STM32_SonarData.iLat;
    }
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // current Longitude
    STM32_SonarData.iLon = ParseLon((u8 *)&item);
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // East/West
    if (item[0] == 'W')
    {
      STM32_SonarData.iLon = -STM32_SonarData.iLon;
    }
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // Speed in knots
    STM32_SonarData.iSpeed = ParseDecToBin((u8 *)&item) / 10;
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // True course
    STM32_SonarData.iBear = ParseDecToBin((u8 *)&item) / 100;
  }
  else
  {
    STM32_SonarData.Altitude.fixquality = 0;
    GPSStart = ParseSkip(GPSStart);                     // current Latitude
    GPSStart = ParseSkip(GPSStart);                     // North/South
    GPSStart = ParseSkip(GPSStart);                     // current Longitude
    GPSStart = ParseSkip(GPSStart);                     // East/West
    GPSStart = ParseSkip(GPSStart);                     // Speed in knots
    GPSStart = ParseSkip(GPSStart);                     // True course
  }
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);      // Date Stamp
	// YYYYYYYMMMMDDDDDHHHHHMMMMMMSSSSS
	// 00100100000000000000000000011111
  /* Date */
  STM32_SonarData.iTime = ParseDecToBin((u8 *)&item[4]) << 25;
  item[4] = 0;
  STM32_SonarData.iTime |= ParseDecToBin((u8 *)&item[2]) << 21;
  item[2] = 0;
  STM32_SonarData.iTime |= ParseDecToBin((u8 *)&item) << 16;
  /* Time */
  itemtime[6] = 0;
  STM32_SonarData.iTime |= ParseDecToBin((u8 *)&itemtime[4]) >> 1;
  itemtime[4] = 0;
  STM32_SonarData.iTime |= ParseDecToBin((u8 *)&itemtime[2]) << 5;
  itemtime[2] = 0;
  STM32_SonarData.iTime |= ParseDecToBin((u8 *)&itemtime[0]) << 11;
}

/*
eg. $GPGSV,3,1,11,03,03,111,00,04,15,270,00,06,01,010,00,13,06,292,00
    $GPGSV,3,2,11,14,25,170,00,16,57,208,39,18,67,296,40,19,40,246,00
    $GPGSV,3,3,11,22,42,067,42,24,14,311,43,27,05,244,00,,,,

    $GPGSV,1,1,13,02,02,213,,03,-3,000,,11,00,121,,14,13,172,05

    1    = Total number of messages of this type in this cycle
    2    = Message number
    3    = Total number of SVs in view
    4    = SV PRN number
    5    = Elevation in degrees, 90 maximum
    6    = Azimuth, degrees from true north, 000 to 359
    7    = SNR, 00-99 dB (null when not tracking)
    8-11 = Information about second SV, same as field 4-7
    12-15= Information about third SV, same as field 4-7
    16-19= Information about fourth SV, same as field 4-7
*/
void ParseGPGSV(vu16 GPSStart)
{
  u8 item[32];
  u16 i, n, nsv;
  GPSStart = ParseSkip(GPSStart);
  /* Number of messages */
  GPSStart = ParseSkip(GPSStart);
  /* Message number */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  n = ParseDecToBin((u8 *)&item);
  /* Satellites in View */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  nsv = ParseDecToBin((u8 *)&item);
  while (nsv<12)
  {
    STM32_SonarData.Satelite[nsv].SateliteID = 0;
    nsv++;
  }
  n = (n - 1) * 4;
  i = 0;
  while (i < 4)
  {
    /* SateliteID */
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
    STM32_SonarData.Satelite[n + i].SateliteID = ParseDecToBin((u8 *)&item);
    /* Elevation */
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
    STM32_SonarData.Satelite[n + i].Elevation = ParseDecToBin((u8 *)&item);
    /* Azimuth */
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
    STM32_SonarData.Satelite[n + i].Azimuth = ParseDecToBin((u8 *)&item);
    /* SNR */
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
    STM32_SonarData.Satelite[n + i].SNR = ParseDecToBin((u8 *)&item);
    i++;
  }
}

/*
eg3. $GPGGA,hhmmss.ss,llll.ll,a,yyyyy.yy,a,x,xx,x.x,x.x,M,x.x,M,x.x,xxxx

    1    = UTC of Position
    2    = Latitude
    3    = N or S
    4    = Longitude
    5    = E or W
    6    = GPS quality indicator (0=invalid; 1=GPS fix; 2=Diff. GPS fix)
    7    = Number of satellites in use [not those in view]
    8    = Horizontal dilution of position
    9    = Antenna altitude above/below mean sea level (geoid)
    10   = Meters  (Antenna height unit)
    11   = Geoidal separation (Diff. between WGS-84 earth ellipsoid and
           mean sea level.  -=geoid is below WGS-84 ellipsoid)
    12   = Meters  (Units of geoidal separation)
    13   = Age in seconds since last update from diff. reference station
    14   = Diff. reference station ID#
*/
void ParseGPGGA(vu16 GPSStart)
{
  u8 item[32];
  GPSStart = ParseSkip(GPSStart);
  /* UTC Time */
  GPSStart = ParseSkip(GPSStart);
  /* Lat */
  GPSStart = ParseSkip(GPSStart);
  GPSStart = ParseSkip(GPSStart);
  /* Lon */
  GPSStart = ParseSkip(GPSStart);
  GPSStart = ParseSkip(GPSStart);
  /* Fix quality */
  GPSStart = ParseSkip(GPSStart);
  /* Number of satelites */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  STM32_SonarData.Altitude.nsat = ParseDecToBin((u8 *)&item);
  /* HDOP */
  GPSStart = ParseSkip(GPSStart);
  /* Altitude */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  STM32_SonarData.Altitude.alt = ParseDecToBin((u8 *)&item) / 10;
}

/*
eg1. $GPGSA,A,3,,,,,,16,18,,22,24,,,3.6,2.1,2.2
eg2. $GPGSA,A,3,19,28,14,18,27,22,31,39,,,,,1.7,1.0,1.3

    1    = Mode:
           M=Manual, forced to operate in 2D or 3D
           A=Automatic, 3D/2D
    2    = Mode:
           1=Fix not available
           2=2D
           3=3D
    3-14 = IDs of SVs used in position fix (null for unused fields)
    15   = PDOP
    16   = HDOP
    17   = VDOP
*/
void ParseGPGSA(vu16 GPSStart)
{
  u8 item[32];
  u16 i, j;
  u8 satid;
  GPSStart = ParseSkip(GPSStart);
  /* Mode M or A */
  GPSStart = ParseSkip(GPSStart);
  /* Mode 1=No fix,2=2D or 3=3D */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  STM32_SonarData.Altitude.fixquality = ParseDecToBin((u8 *)&item);
  /* Fixed */
  i = 0;
  while (i < 12)
  {
    STM32_SonarData.Satelite[i].Fixed = 0;
    i++;
  }
  i = 0;
  while (i < 12)
  {
    GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
    satid = ParseDecToBin((u8 *)&item);
    if (satid)
    {
      j = 0;
      while (j < 12)
      {
        if (satid == STM32_SonarData.Satelite[j].SateliteID)
        {
          STM32_SonarData.Satelite[j].Fixed = 1;
          break;
        }
        j++;
      }
    }
    i++;
  }
  /* PDOP */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  STM32_SonarData.Altitude.pdop = ParseDecToBin((u8 *)&item);
  /* HDOP */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  STM32_SonarData.Altitude.hdop = ParseDecToBin((u8 *)&item);
  /* VDOP */
  GPSStart = ParseGetItem(GPSStart,(u8 *)&item);
  STM32_SonarData.Altitude.vdop = ParseDecToBin((u8 *)&item);
}

vu32 ParseGPS(void)
{
  vu16 GPSStart = -1;
  vu16 GPSEnd = -1;
  vu16 i = STM32_Sonar.GPSTail;
  while (i != STM32_Sonar.GPSHead)
  {
    if (STM32_Sonar.GPSArray[i] == 0x0D)
    {
      GPSEnd = i;
      i = STM32_Sonar.GPSTail;
      while (i != GPSEnd)
      {
        if (STM32_Sonar.GPSArray[i] == 0x24)
        {
          GPSStart = i;
          if (StrCmp((u8*)&STM32_Sonar.GPSArray[GPSStart],(u8*)szGPRMC) == 0)
          {
            ParseGPRMC(GPSStart);
          }
          else if (StrCmp((u8*)&STM32_Sonar.GPSArray[GPSStart],(u8*)szGPGSV) == 0)
          {
            ParseGPGSV(GPSStart);
          }
          else if (StrCmp((u8*)&STM32_Sonar.GPSArray[GPSStart],(u8*)szGPGGA) == 0)
          {
            ParseGPGGA(GPSStart);
          }
          else if (StrCmp((u8*)&STM32_Sonar.GPSArray[GPSStart],(u8*)szGPGSA) == 0)
          {
            ParseGPGSA(GPSStart);
          }
          break;
        }
        i++;
        i &= (MAXGPS - 1);
      }
      GPSEnd++;
      GPSEnd &= (MAXGPS - 1);
      STM32_Sonar.GPSTail = GPSEnd;
      break;
    }
    i++;
    i &= (MAXGPS - 1);
  }
  return GPSStart;
}

void GetEcho(void)
{
  u32* ADC;
  u8 Echo;

  /* Get pointer to injected channel */
  ADC = ( (u32 *) ADC1_ICDR_Address);
  while (STM32_Sonar.Start)
  {
    /* To eliminate the need for an advanced AM demodulator the largest */ 
    /* ADC reading is stored in its echo array element */
    /* Get echo */
    Echo = ( (*(u32*) (((*(u32*)&ADC)))) >> 4);
    /* If echo larger than previous echo then update the echo array */
    if (Echo > STM32_SonarData.EchoArray[STM32_Sonar.EchoIndex])
    {
      STM32_SonarData.EchoArray[STM32_Sonar.EchoIndex] = Echo;
    }
  }
}

/*******************************************************************************
* Function Name  : GetADCValue
* Description    : This function sums 16 ADC conversions and returns the average.
* Input          : ADC channel
* Output         : None
* Return         : The ADC cannel reading
*******************************************************************************/
u16 GetADCValue(u8 Channel)
{
  vu8 i;
  vu16 ADCValue;
  ADC_InitTypeDef ADC_InitStructure;

  ADCValue = 0;
  ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfChannel = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* ADC1 regular channel configuration */ 
  ADC_RegularChannelConfig(ADC1, Channel, 1, ADC_SampleTime_239Cycles5);
  /* Start ADC1 Software Conversion */ 
  ADC_SoftwareStartConvCmd(ADC1, ENABLE);
  /* Add 16 conversions to reduce thermal noise */
  i = 16;
  while (i--)
  {
    ADC_ClearFlag(ADC1, ADC_FLAG_EOC);
    while (ADC_GetFlagStatus(ADC1, ADC_FLAG_EOC) == RESET)
    {
    }
    ADCValue += ADC1->DR;
  }
  /* Stop ADC1 Software Conversion */ 
  ADC_SoftwareStartConvCmd(ADC1, DISABLE);
  /* Return average of the 16 added conversions */
  return (ADCValue >> 4);
}

/*******************************************************************************
* Function Name  : GainSetup
* Description    : This function sets up the gain levels for each pixel
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void GainSetup(void)
{
  vu32 GainInitInx;
  vu32 i;
  vu32 GainInx;
  vu32 GainInc;
  vu32 GainVal;
  GainInitInx=1;
  GainInx=0;
  while (GainInitInx<17)
  {
    GainVal=STM32_Sonar.GainInit[GainInitInx]<<13;
    GainInc=(STM32_Sonar.GainInit[GainInitInx+1]-STM32_Sonar.GainInit[GainInitInx])<<8;
    i=0;
    while (i<32)
    {
      STM32_Sonar.GainArray[GainInx]=(GainVal>>13)+STM32_Sonar.GainInit[0];
      if ((GainVal>>12) && 1)
      {
        STM32_Sonar.GainArray[GainInx]++;
      }
      if (STM32_Sonar.GainArray[GainInx]>4095)
      {
        STM32_Sonar.GainArray[GainInx]=4095;
      }
      GainVal+=GainInc;
      GainInx++;
      i++;
    }
    GainInitInx++;
  }
}

/*******************************************************************************
* Function Name  : TIM1_UP_IRQHandler
* Description    : This function handles TIM1 global interrupt request.
*                  It is used to generate the ping.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_UP_IRQHandler(void)
{
  /* Set ping outputs high (FET's off) */
  GPIOA->BSRR = (u16) (GPIO_Pin_2 | GPIO_Pin_1);
  if (STM32_Sonar.PingPulses)
  {
    GPIOA->ODR = Ping;
    if (Ping == 0x2)
    {
      Ping = 0x4;     // PA02
    }
    else
    {
      Ping = 0x2;     // PA01
      STM32_Sonar.PingPulses--;
    }
  }
  else
  {
    /* Ping done, Disable TIM1 */
    TIM_Cmd(TIM1, DISABLE);
    /* TIM2 configuration */
    TIM2_Configuration();
    /* Clear TIM2 Update interrupt pending bit */
    TIM2->SR = (u16)~TIM_IT_Update;
    /* Enable TIM2 */
    TIM_Cmd(TIM2, ENABLE);
    /* Enable the USART1 Receive interrupt: this interrupt is generated when the 
       USART1 receive data register is not empty */
    USART_ITConfig(USART1, USART_IT_RXNE, ENABLE);
  }
  /* Clear TIM1 Update interrupt pending bit */
  TIM1->SR = (u16)~TIM_IT_Update;
}

/*******************************************************************************
* Function Name  : TIM2_IRQHandler
* Description    : This function handles TIM2 global interrupt request.
*                  It increments the echo array index.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM2_IRQHandler(void)
{
  /* Clear TIM2 Update interrupt pending bit */
  asm("mov    r0,#0x40000000");               /* TIM2 */
  asm("strh   r0,[r0,#0x8 *2]");              /* TIM2->SR */

  /* Increment the echo array index */
  asm("mov    r1,#0x20000000");               /* STM32_Sonar */
  asm("ldrh   r2,[r1,#0x42A]");               /* STM32_Sonar.EchoIndex */
  asm("add    r2,r2,#0x1");
  asm("cmp    r2,#0x200");
  asm("ite    ne");
  asm("strhne r2,[r1,#0x42A]");               /* Update STM32_Sonar.EchoIndex */
  asm("strbeq r2,[r1,#0x0]");                 /* Reset STM32_Sonar.Start */

  /* Update the DAC to output next gain level */
  asm("movw   r0,#0x7400");                   /* DAC1 */
  asm("movt   r0,#0x4000");
  asm("add    r2,r2,0x15");                   /* Offset gain array / 2 */
  asm("ldrh   r3,[r1,r2,lsl #0x1]");
  asm("strh   r3,[r0,#0x8]");                 /* DAC_DHR12R1 */
}

/*******************************************************************************
* Function Name  : USART1_puts
* Description    : This function transmits a zero terminated string
* Input          : Zero terminated string
* Output         : None
* Return         : None
*******************************************************************************/
void USART1_puts(char *str)
{
  char c;
  /* Characters are transmitted one at a time. */
  while ((c = *str++))
  {
    /* Wait until transmit register empty */
    while((USART1->SR & USART_FLAG_TXE) == 0);
    /* Transmit Data */
    USART1->DR = (u16)c;
  }
}

/*******************************************************************************
* Function Name  : USART3_putdata
* Description    : This function transmits data
* Input          : dat, len
* Output         : None
* Return         : None
*******************************************************************************/
void USART3_putdata(u8 *dat,u16 len)
{
  /* Data are transmitted one at a time. */
  while (len--)
  {
    /* Wait until transmit register empty */
    while((USART3->SR & USART_FLAG_TXE) == 0);          
    /* Transmit Data */
    USART3->DR = (u16)*dat;
    *dat++;
  }
}

/*******************************************************************************
* Function Name  : USART1_IRQHandler
* Description    : This function handles USART1 global interrupt request.
*                  An interrupt is generated when a character is recieved.
*                  It is used to get GPS data.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USART1_IRQHandler(void)
{
  // /* Get pointer to USART1->DR */
  // asm("movw   r0,#0x3800");
  // asm("movt   r0,#0x4001");
  // /* Get recieved halfword */
  // asm("ldrh   r3,[r0,#0x2*2]");
  // /* Get pointer to STM32_Sonar */
  // asm("mov    r0,#0x20000000");
  // /* Get GPSHead value */
  // asm("ldrh   r2,[r0,#0x0x452]");
  // /* Get offset to GPSArray */
  // asm("movw   r1,#0x634");
  // /* Get pointer to GPSArray */
  // asm("add    r1,r1,r0");
  // /* Store received byte at GPSArray[GPSHead] */
  // asm("strb   r3,[r1,r2]");
  // /* Increment GPSHead */
  // asm("add    r2,r2,#0x1");
  // /* Limit GPSHead to 512 bytes*/
  // asm("mov    r2,r2,lsl #23");
  // asm("mov    r2,r2,lsr #23");
  // /* Store GPSHead */
  // asm("strh   r2,[r0,#0x7*2]");

  STM32_Sonar.GPSArray[STM32_Sonar.GPSHead++]=USART1->DR;
  /* Limit GPSHead to 512 bytes array*/
  STM32_Sonar.GPSHead&=MAXGPS-1;
}

/*******************************************************************************
* Function Name  : ADC_Startup
* Description    : This function calibrates ADC1.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ADC_Startup(void)
{
  ADC_InitTypeDef ADC_InitStructure;
  /* ADCCLK = PCLK2/2 */
  RCC_ADCCLKConfig(RCC_PCLK2_Div2);
  /* ADC1 configuration ------------------------------------------------------*/
  ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  ADC_InitStructure.ADC_NbrOfChannel = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* ADC1 regular channel2 configuration */ 
  ADC_RegularChannelConfig(ADC1, ADC_Channel_3, 1, ADC_SampleTime_55Cycles5);
  /* Enable ADC1 */
  ADC_Cmd(ADC1, ENABLE);
  /* Enable ADC1 reset calibaration register */   
  ADC_ResetCalibration(ADC1);
  /* Check the end of ADC1 reset calibration register */
  while(ADC_GetResetCalibrationStatus(ADC1));
  /* Start ADC1 calibaration */
  ADC_StartCalibration(ADC1);
  /* Check the end of ADC1 calibration */
  while(ADC_GetCalibrationStatus(ADC1));
}

/*******************************************************************************
* Function Name  : ADC_Configuration
* Description    : This function prepares ADC1 for Injected conversion
*                  on channel 2.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void ADC_Configuration(void)
{
  ADC_InitTypeDef ADC_InitStructure;

  /* ADCCLK = PCLK2/2 */
  RCC_ADCCLKConfig(RCC_PCLK2_Div2);
  ADC_InitStructure.ADC_Mode = ADC_Mode_Independent;
  ADC_InitStructure.ADC_ScanConvMode = ENABLE;
  ADC_InitStructure.ADC_ContinuousConvMode = ENABLE;
  ADC_InitStructure.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
  ADC_InitStructure.ADC_DataAlign = ADC_DataAlign_Right;
  /* ADC1 single channel configuration */
  ADC_InitStructure.ADC_NbrOfChannel = 1;
  ADC_Init(ADC1, &ADC_InitStructure);
  /* Setup injected channel */
  ADC_InjectedSequencerLengthConfig(ADC1,1);
  /* Sonar echo */
  ADC_InjectedChannelConfig(ADC1,ADC_Channel_3,1,ADC_SampleTime_1Cycles5);
}

/*******************************************************************************
* Function Name  : RCC_Configuration
* Description    : Configures the different system clocks.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void RCC_Configuration(void)
{
  ErrorStatus HSEStartUpStatus;
  /* RCC system reset(for debug purpose) */
  RCC_DeInit();
  /* Enable HSE */
  RCC_HSEConfig(RCC_HSE_ON);
  /* Wait till HSE is ready */
  HSEStartUpStatus = RCC_WaitForHSEStartUp();
  if(HSEStartUpStatus == SUCCESS)
  {
    /* Enable Prefetch Buffer */
    FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);
    /* Flash 2 wait state */
    FLASH_SetLatency(FLASH_Latency_0);
    /* HCLK = SYSCLK */
    RCC_HCLKConfig(RCC_SYSCLK_Div1); 
    /* PCLK2 = HCLK */
    RCC_PCLK2Config(RCC_HCLK_Div1); 
    /* PCLK1 = HCLK */
    RCC_PCLK1Config(RCC_HCLK_Div1);
    /* ADCCLK = PCLK2/2 */
    RCC_ADCCLKConfig(RCC_PCLK2_Div2);
#ifdef STM32Clock24MHz
    /* PLLCLK = 8MHz * 3 = 24 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_3);
#endif
#ifdef STM32Clock28MHz
    /* PLLCLK = 8MHz / 2 * 7 = 28 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div2, RCC_PLLMul_7);
#endif
#ifdef STM32Clock32MHz
    /* PLLCLK = 8MHz * 4 = 32 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_4);
#endif
#ifdef STM32Clock40MHz
    /* PLLCLK = 8MHz * 5 = 40 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_5);
#endif
#ifdef STM32Clock48MHz
    /* PLLCLK = 8MHz * 6 = 48 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_6);
#endif
#ifdef STM32Clock56MHz
    /* PLLCLK = 8MHz * 7 = 56 MHz */
    RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_7);
#endif
    /* Enable PLL */ 
    RCC_PLLCmd(ENABLE);
    /* Wait till PLL is ready */
    while(RCC_GetFlagStatus(RCC_FLAG_PLLRDY) == RESET)
    {
    }
    /* Select PLL as system clock source */
    RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);
    /* Wait till PLL is used as system clock source */
    while(RCC_GetSYSCLKSource() != 0x08)
    {
    }
    /* Enable TIM1, ADC1, USART1, GPIOA, GPIOB and GPIOC peripheral clocks */
    RCC_APB2PeriphClockCmd(RCC_APB2Periph_TIM1 | RCC_APB2Periph_ADC1 | RCC_APB2Periph_USART1 | RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB | RCC_APB2Periph_GPIOC, ENABLE);
    /* Enable DAC, TIM2 and TIM3 peripheral clocks */
    RCC_APB1PeriphClockCmd(RCC_APB1Periph_DAC | RCC_APB1Periph_TIM2 | RCC_APB1Periph_TIM3 | RCC_APB1Periph_USART3, ENABLE);
  }
}

/*******************************************************************************
* Function Name  : GPIO_Configuration
* Description    : Configures the different GPIO ports.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void GPIO_Configuration(void)
{
  GPIO_InitTypeDef GPIO_InitStructure;
  /* Set ping outputs high (FET's off) */
  GPIO_WriteBit(GPIOA, GPIO_Pin_2 | GPIO_Pin_1, Bit_SET);
  /* Configure PA.02 and PA.01 as outputs */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_2 | GPIO_Pin_1;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure ADC Channel7 (PA.07), ADC Channel6 (PA.06), DAC Channel2 (PA.05), DAC Channel1 (PA.04) and ADC Channel3 (PA.03) as analog input */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_7 | GPIO_Pin_6 | GPIO_Pin_5 | GPIO_Pin_4 | GPIO_Pin_3;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure ADC Channel14 (PC.04) */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_4;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AIN;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* Configure PA9 USART1 Tx as alternate function push-pull */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PA10 USART1 Rx as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOA, &GPIO_InitStructure);
  /* Configure PC.09 (LED3) and PC.08 (LED4) as output */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_9 | GPIO_Pin_8;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_Out_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOC, &GPIO_InitStructure);
  /* TIM3 channel 3 pin (PB0) configuration */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_0;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB10 USART3 Tx as alternate function push-pull */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_10;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB11 USART3 Rx as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_11;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB13 USART3 CTS as input floating */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_13;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IN_FLOATING;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
  /* Configure PB14 USART3 RTS as alternate function push-pull */
  GPIO_InitStructure.GPIO_Pin = GPIO_Pin_14;
  GPIO_InitStructure.GPIO_Mode = GPIO_Mode_AF_PP;
  GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
  GPIO_Init(GPIOB, &GPIO_InitStructure);
}

/*******************************************************************************
* Function Name  : NVIC_Configuration
* Description    : Configures Vector Table base location.
*                  Configures interrupts.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void NVIC_Configuration(void)
{
  NVIC_InitTypeDef NVIC_InitStructure;
  /* Set the Vector Table base location at 0x08000000 */ 
  NVIC_SetVectorTable(NVIC_VectTab_FLASH, 0x0);   
  /* Enable the TIM1 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM1_UP_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable the TIM2 global Interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = TIM2_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
  /* Enable USART1 interrupt */
  NVIC_InitStructure.NVIC_IRQChannel = USART1_IRQChannel;
  NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
  NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
  NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
  NVIC_Init(&NVIC_InitStructure);
}

/*******************************************************************************
* Function Name  : TIM1_Configuration
* Description    : Configures TIM1 to count up and generate interrupt on overflow
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM1_Configuration(void)
{
  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  /* Time base configuration 56MHz clock */
  //TIM_TimeBaseStructure.TIM_Period = 139;
  /* Time base configuration 48MHz clock */
  //TIM_TimeBaseStructure.TIM_Period = 119;
  /* Time base configuration 40MHz clock */
  TIM_TimeBaseStructure.TIM_Period = 99;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM1, &TIM_TimeBaseStructure);
  /* Enable TIM1 Update interrupt */
  TIM_ClearITPendingBit(TIM1,TIM_IT_Update);
  TIM_ITConfig(TIM1, TIM_IT_Update, ENABLE);
}

/*******************************************************************************
* Function Name  : TIM2_Configuration
* Description    : Configures TIM2 to count up and generate interrupt on overflow
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM2_Configuration(void)
{
  TIM_TimeBaseInitTypeDef TIM_TimeBaseStructure;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_Period = STM32_Sonar.PixelTimer;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM2, &TIM_TimeBaseStructure);
  /* Enable TIM2 Update interrupt */
  TIM_ClearITPendingBit(TIM2,TIM_IT_Update);
  TIM_ITConfig(TIM2, TIM_IT_Update, ENABLE);
}

/*******************************************************************************
* Function Name  : TIM3_Configuration
* Description    : Configures TIM3 to count up and generate PWM output on PB0
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void TIM3_Configuration(void)
{
  TIM_TimeBaseInitTypeDef  TIM_TimeBaseStructure;
  TIM_OCInitTypeDef  TIM_OCInitStructure;
  TIM_TimeBaseStructure.TIM_ClockDivision = 0;
  TIM_TimeBaseStructure.TIM_Prescaler = 0;
  TIM_TimeBaseStructure.TIM_CounterMode = TIM_CounterMode_Up;
  /* Time base configuration 56MHz clock */
  //TIM_TimeBaseStructure.TIM_Period = 139;
  /* Time base configuration 48MHz clock */
  //TIM_TimeBaseStructure.TIM_Period = 119;
  /* Time base configuration 40MHz clock */
  TIM_TimeBaseStructure.TIM_Period = 199;
  TIM_TimeBaseStructure.TIM_RepetitionCounter = 0;
  TIM_TimeBaseInit(TIM3, &TIM_TimeBaseStructure);
  /* PWM1 Mode configuration: Channel3 */
  TIM_OCInitStructure.TIM_OCMode = TIM_OCMode_PWM1;
  TIM_OCInitStructure.TIM_OutputState = TIM_OutputState_Enable;
  TIM_OCInitStructure.TIM_OutputNState = TIM_OutputState_Disable;
  TIM_OCInitStructure.TIM_Pulse = 99;
  TIM_OCInitStructure.TIM_OCPolarity = TIM_OCPolarity_High;
  TIM_OCInitStructure.TIM_OCNPolarity = TIM_OCPolarity_Low;
  TIM_OCInitStructure.TIM_OCIdleState = TIM_OCIdleState_Reset;
  TIM_OCInitStructure.TIM_OCNIdleState = TIM_OCIdleState_Reset;
  TIM_OC3Init(TIM3, &TIM_OCInitStructure);
  TIM_OC1PreloadConfig(TIM3, TIM_OCPreload_Enable);
  TIM_ARRPreloadConfig(TIM3, ENABLE);
  /* TIM3 Main Output Enable */
  TIM_CtrlPWMOutputs(TIM3, ENABLE);
}

/*******************************************************************************
* Function Name  : USART1_Configuration
* Description    : Configures USART1 Rx and Tx for communication with GPS module.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USART1_Configuration(u32 BaudRate)
{
  /* USART1 configured as follow:
        - BaudRate = 4800 or 9600 baud  
        - Word Length = 8 Bits
        - One Stop Bit
        - No parity
        - Hardware flow control disabled
        - Receive and transmit enabled
  */
  USART_InitTypeDef USART_InitStructure;

  USART_DeInit(USART1);
  USART_InitStructure.USART_BaudRate = BaudRate;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No ;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_None;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART1, &USART_InitStructure);
  /* Enable the USART Receive interrupt: this interrupt is generated when the 
     USART1 receive data register is not empty */
  USART_ITConfig(USART1, USART_IT_RXNE, ENABLE);
  /* Enable the USART1 */
  USART_Cmd(USART1, ENABLE);
}

/*******************************************************************************
* Function Name  : USART3_Configuration
* Description    : Configures USART3 Rx and Tx for communication with Bluetooth module.
* Input          : None
* Output         : None
* Return         : None
*******************************************************************************/
void USART3_Configuration(u32 BaudRate)
{
  /* USART3 configured as follow:
        - BaudRate = 9600 or 115200 baud  
        - Word Length = 8 Bits
        - One Stop Bit
        - No parity
        - Hardware flow control enabled
        - Receive and transmit enabled
  */
  USART_InitTypeDef USART_InitStructure;

  USART_DeInit(USART3);
  USART_InitStructure.USART_BaudRate = BaudRate;
  USART_InitStructure.USART_WordLength = USART_WordLength_8b;
  USART_InitStructure.USART_StopBits = USART_StopBits_1;
  USART_InitStructure.USART_Parity = USART_Parity_No ;
  USART_InitStructure.USART_HardwareFlowControl = USART_HardwareFlowControl_RTS_CTS;
  USART_InitStructure.USART_Mode = USART_Mode_Rx | USART_Mode_Tx;
  USART_Init(USART3, &USART_InitStructure);
  /* Enable the USART Receive interrupt: this interrupt is generated when the 
     USART3 receive data register is not empty */
  USART_ITConfig(USART3, USART_IT_RXNE, ENABLE);
  /* Enable the USART3 */
  USART_Cmd(USART3, ENABLE);
}

/*****END OF FILE****/
