typedef struct
{
  STM32_FRQTypeDef STM32_Frequency;                       // 0x20000002
  uint8_t   DDS_WaveType;                                 // 0x20000012
  uint8_t   DDS_SweepMode;                                // 0x20000013
  uint32_t  DDS_PhaseAdd;                                 // 0x20000014
  uint16_t  DDS_Amplitude;                                // 0x20000018
  uint16_t  DDS_DCOffset;                                 // 0x2000001A
  uint32_t  SWEEP_Add;                                    // 0x2000001C
  uint16_t  SWEEP_StepTime;                               // 0x20000020
  uint16_t  SWEEP_StepCount;                              // 0x20000022
  uint32_t  SWEEP_Min;                                    // 0x20000024
  uint32_t  SWEEP_Max;                                    // 0x20000028
  uint16_t Wave[2048];                                    // 0x2000002C
}STM32_CMNDTypeDef;
